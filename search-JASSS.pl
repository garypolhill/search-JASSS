#!/usr/bin/perl -CSDA
#
# N.B. -CSDA instructs Perl to treat all filehandles as UTF-8 by default
#
# search-JASSS.pl
#
# Script to help search for papers in JASSS.
#
# Gary Polhill, 3 May 2021
#
# Copyright (C) 2021  The James Hutton Institute
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

# WordNet (R) is a registered tradename of Princeton University
# Princeton University (2010) "About WordNet" https://wordnet.princeton.edu.
use strict;
use WWW::Mechanize;
use Time::Piece;

# Globals

my $index_url = "http://www.jasss.org/index_by_issue.html";
                # Update this if the JASSS website is changed. It is
                # the webpage to search for URLs of JASSS articles.
my $agent_id = "search-JASSS v2021-09-06";
my $include_forum = 0;
my $include_reviews = 0;
my $include_research = 1;
my $max_hist_bins = 10;
my $only_text = 1;
my $concordance = 0;
my $concordance_file;
my $concordance_md = 0;
my %concord;
my $cache = 0;
my $cache_dir;
my $do_hist = 0;
my $hist_file;
my $save_tags = 0;
my $min_freq = 1;
my $keywords = 0;
my $keywords_url = "https://www.jasss.org/keywords.html";
my %kw;
my $tag_file;
my $use_word_net = 0;
my $wn = "/usr/local/WordNet-3.0/bin/wn";
my $max_polysemy = 0;
my %tags;       # Counts of tags and special characters in paragraph text found
my %titles;
my %auyr;
my %years;
my %n_occurs;
my $do_search = 1;
my @ignore_words = ("a", "able", "about", "above", "absolute", "absolutely", "actual",
                      "actually", "afore", "aforementioned", "after", "again", "against",
                      "al", "all", "almost", "already", "alright", "also", "although",
                      "always", "alternative", "alternatives", "am", "among", "an",
                      "and", "another", "any", "anymore", "anyone", "anything",
                      "anyway", "apparent", "apparently", "are", "around", "article",
                      "articles", "as", "at", "author", "authors", "away",
                    "back", "backward", "backwards", "bad", "barely", "be", "because",
                      "been", "before", "began", "begin", "behind", "below",
                      "beside", "besides", "best", "better", "between", "both",
                      "bottom", "bottommost", "but", "by",
                    "came", "can", "come", "coming", "comment", "commentary", "commented",
                      "commenting", "comments", "cannot", "conclude", "concluded",
                      "condludes", "concluding", "conclusion", "could", "current",
                      "currently",
                    "definitely", "despite", "did", "different", "discuss", "discussed",
                      "discusses", "discussing", "discussion", "discussions", "do", "does",
                      "doing", "done", "down",
                    "each", "eight", "eighth", "eighthly", "either", "else", "end",
                      "ended", "ending", "ends", "enough", "entire", "especially",
                      "et", "even", "eventual", "eventually", "ever", "evermore",
                      "everyone", "everything", "every", "exact", "exactly", "except",
                      "exception", "exceptions",
                    "far", "farther", "few", "fewer", "fewest", "fifth", "fifthly",
                      "figure", "figures", "final", "finally", "find", "finding",
                      "finds", "finish", "finishes", "finished", "finishing", "first",
                      "firstly", "five", "focus", "focused", "focuses", "focusing",
                      "follow", "followed", "following", "follows", "footnote",
                      "footnotes", "for", "fore", "foregoing", "foremost", "forward",
                      "forwards", "found", "four", "fourth", "fourthly", "frequent",
                      "frequently", "from", "front", "further", "furthermore",
                    "gave", "get", "getting", "gets", "give", "given", "gives",
                      "giving", "go", "goes", "good", "going", "gone", "got",
                    "had", "has", "have", "having", "he", "hence", "henceforth",
                      "her", "here", "hers", "herself", "high", "higher", "highest",
                      "him", "himself", "his", "how", "however",
                    "i", "if", "important", "importantly", "in", "inside", "instead",
                      "interesting", "interestingly", "into", "introduce", "introduced",
                      "introduces", "introducing", "indroduction", "is", "issue",
                      "issues", "it", "its",
                    "last", "lastly", "lead", "leading", "leads", "least", "led",
                      "less", "lesser", "let", "little", "long", "low", "lower", "lowest",
                    "may", "maybe", "many", "matter", "mattered", "mattering", "matters",
                      "me", "might", "mine", "more", "most", "much", "must", "my",
                      "myself",
                    "near", "nearly", "need", "neither", "never", "new", "next",
                      "nine", "ninth", "ninthly", "no", "none", "nor", "not", "nothing",
                      "novel", "now",
                    "obvious", "obviously", "of", "off", "often", "old", "olden",
                      "on", "once", "one", "only", "onto", "or", "other", "others",
                      "ought", "our", "ours", "ourselves", "out", "outwith", "over",
                      "own",
                    "particular", "particularly", "paper", "papers", "past",
                      "perhaps", "possible", "possibly", "precise", "precisely",
                      "present", "presented", "presenting", "presents", "previous",
                      "previously", "probable", "probably",
                    "quite",
                    "raise", "raised", "raises", "raising", "rather", "really",
                      "replied", "replies", "reply", "replying", "respond", "responded",
                      "responding", "responds", "response",
                    "same", "said", "say", "saying", "says", "second", "secondly",
                      "seem", "seemed", "seeming", "seemingly", "seems", "self",
                      "seven", "seventh", "seventhly", "several", "shall", "she",
                      "short", "should", "similar", "simple", "simply", "since",
                      "sixthly", "slight", "slightly", "small", "so", "some",
                      "somehow", "someone", "something", "sometimes", "somewhere",
                      "stop", "stopped", "stopping", "stops", "straight", "such",
                    "ten", "tenth", "tenthly", "than", "that", "the", "their", "theirs",
                      "them", "themself", "themselves", "then", "there", "therefore",
                      "these", "they", "thing", "third", "thirdly", "this", "those",
                      "though", "three", "through", "thus", "to", "together", "too",
                      "top", "topmost", "total", "totally", "toward", "towards",
                      "tried", "tries", "try", "trying", "twice", "two",
                    "under", "until", "up", "upon", "upper", "uppermost", "us", "use",
                      "used", "uses", "using", "usual", "usually", "utilise", "utilised",
                      "utilises", "utilising", "utilize", "utilized", "utilizes",
                      "utilizing",
                    "varieties", "variety", "various", "variously", "very",
                    "was", "way", "ways", "we", "were", "went", "what", "whatever",
                      "when", "where", "whether", "which", "while", "who", "whoever",
                      "whom", "whomever", "whole", "will", "why", "with", "within",
                      "without", "wo", "worse", "worst", "would", "write", "writes",
                      "writing", "wrote",
                    "yes", "yet", "you", "your", "yourself",
                    );

my %ignore;

# Process command-line arguments

while($ARGV[0] =~ /^-/) {
  my $option = shift(@ARGV);

  if($option eq "-f" || $option eq "--include-forum") {
    $include_forum = 1;
  }
  elsif($option eq "-r" || $option eq "--include-reviews") {
    $include_reviews = 1;
  }
  elsif($option eq "-a" || $option eq "--include-all") {
    $include_forum = 1;
    $include_reviews = 1;
  }
  elsif($option eq "-F" || $option eq "--only-forum") {
    $include_forum = 1;
    $include_reviews = 0;
    $include_research = 0;
  }
  elsif($option eq "-R" || $option eq "--only-reviews") {
    $include_reviews = 1;
    $include_forum = 0;
    $include_research = 0;
  }
  elsif($option eq "-T" || $option eq "--text-all") {
    $only_text = 0;
  }
  elsif($option eq "-i" || $option eq "--index") {
    $index_url = shift(@ARGV);
  }
  elsif($option eq "-u" || $option eq "--use-cache") {
    $cache_dir = shift(@ARGV);
    $cache = -1; # Then < 0 looks like input redirection
  }
  elsif($option eq "-s" || $option eq "--save-cache") {
    $cache_dir = shift(@ARGV);
    $cache = 1; # Then > 0 looks like output redirection
  }
  elsif($option eq "-C" || $option eq "--concordance") {
    $concordance_file = shift(@ARGV);
    $concordance = 1;
  }
  elsif($option eq "-H" || $option eq "--histogram") {
    $hist_file = shift(@ARGV);
    $do_hist = 1;
  }
  elsif($option eq "-b" || $option eq "--hist-file-bins") {
    $hist_file = shift(@ARGV);
    $max_hist_bins = shift(@ARGV);
    $do_hist = 1;
  }
  elsif($option eq "-t" || $option eq "--save-tags") {
    $save_tags = 1;
    $tag_file = shift(@ARGV);
  }
  elsif($option eq "-m" || $option eq "--minimum-frequency") {
    $min_freq = shift(@ARGV);
  }
  elsif($option eq "-k" || $option eq "--include-keywords") {
    $keywords = 1;
  }
  elsif($option eq "-K" || $option eq "--keywords-url") {
    $keywords = 1;
    $keywords_url = shift(@ARGV);
  }
  elsif($option eq "-j" || $option eq "--jasss-url") {
    $index_url = shift(@ARGV);
  }
  elsif($option eq "-i" || $option eq "--agent-id") {
    $agent_id = shift(@ARGV);
  }
  elsif($option eq "-w" || $option eq "--use-WordNet") {
    if(-x "$wn") {
      $use_word_net = 1;
    }
    else {
      warn "WordNet $wn is not executable -- ignoring $option\n";
    }
  }
  elsif($option eq "-W" || $option eq "--with-WordNet") {
    $wn = shift(@ARGV);
    if(-x "$wn") {
      open(FP, "-|", "$wn -l") or die "Cannot open pipe from $wn -l: $!\n";
      my $line = <FP>;
      if($line !~ /^WordNet Release/) {
        die "$wn doesn't look like WordNet to me\n";
      }
      close(FP);
      $use_word_net = 1;
    }
  }
  elsif($option eq "-p" || $option eq "--maximum-polysemy") {
    $max_polysemy = shift(@ARGV);
    $use_word_net = 1;
  }
  elsif($option eq "-h" || $option eq "--help") {
    print <<USAGE_END;
$0 {options...} <summary file> <search terms...>
$0 {other options...} --concordance <CSV file>
$0 {other options...} --concordance <CSV file> <concordance markdown file>
$0 --help

    Search for research articles in JASSS at $index_url
    and then download and search those articles for the search terms, and/or
    build a concordance of all words, digrams and trigrams in JASSS.

    summary file: markdown format file giving detailed search results
    search terms...: one or more (case insensitive) search terms

    general options...:
\t-a (--include-all): search review, forum and research articles
\t-f (--include-forum): include forum articles in the search
\t-F (--only-forum): only search forum articles
\t-h (--help): display this message
\t-i (--agent-id) <ID>: agent ID to use in HTTP GET
\t-j (--jasss-url) <URL>: page to access JASSS index from (default $index_url)
\t-r (--include-reviews): include review articles in the search (requires -T)
\t-R (--only-reviews): only search review articles (requires -T)
\t-s (--save-cache) <dir>: cache downloaded articles in dir
\t-T (--text-all): search in all text not just numbered paragraphs (allows -r and -R)
\t-t (--save-tags) <file>: save tags in paragraph text to CSV file
\t-u (--use-cache) <dir>: use cache in dir

    search options...:
\t-b (--hist-file-bins) <file> <n>: prepare a histogram in CSV file with n bins
\t-H (--histogram) <file>: prepare a histogram in CSV file with $max_hist_bins bins
\t-m (--minimum-frequency) <n>: only include papers mentioning search term >= n times

    concordance options...:
\t-C (--concordance) <file>: prepare a concordance in CSV file
\t-k (--include-keywords): include keywords in concordance
\t-K (--keywords-url) <URL>: page to load keywords from (default $keywords_url)
\t-p (--maximum-polysemy) <n>: maximum polysemy count to include term in concordance (implies -w)
\t-w (--use-WordNet): use WordNet to get polysemy count
\t-W (--with-WordNet) <exe>: where to find WordNet (default $wn) (implies -w)

WordNet is a registered trade name of Princeton University
USAGE_END
    exit 0;
  }
  else {
    die "Option $option not recognized\n";
  }
}

my $summary_file;
my @search_terms;

if(scalar(@ARGV) == 0) {
  if(!$concordance) {
    die "Usage: $0 [options/--help] <summary.md> <search terms...>\n";
  }
  else {
    $do_search = 0;
  }
}
elsif(scalar(@ARGV) == 1) {
  if(!$concordance) {
    die "Usage: $0 [options/--help] <summary.md> <search terms...>\n";
  }
  else {
    $summary_file = shift(@ARGV);
    $do_search = 0;
    $concordance_md = 1;
  }
}
else {
  $summary_file = shift(@ARGV);
  @search_terms = @ARGV;
}

if($include_research + $include_reviews + $include_forum == 0) {
  die "The options you've selected to search for articles mean none will be searched.\n"
}
if(scalar(@search_terms) == 0 && !$concordance) {
  die "No search terms provided.\n";
}

if($include_reviews && $only_text) {
  die "Including reviews in the search means you can't only extract text from numbered paragraphs\n";
}

my $search_time = localtime->datetime;

if($cache > 0) {
  if(-e "$cache_dir" && !(-d "$cache_dir")) {
    die "Cache directory $cache_dir exists, but not as a directory\n";
  }
  if(!(-d "$cache_dir")) {
    mkdir($cache_dir) or die "Cannot create cache directory $cache_dir: $!\n";
  }
  else {
    warn "Cache directory $cache_dir exists -- files will be over-written\n";
  }
  open(FP, ">", "$cache_dir/DATE") or die "Cannot create $cache_dir/DATE: $!\n";
  print FP "$search_time\n";
  close(FP);
}
elsif($cache < 0) {
  if(!(-d "$cache_dir")) {
    die "Cache directory $cache_dir does not exist or is not a directory, so cannot use it\n";
  }
  open(FP, "<", "$cache_dir/DATE") or die "Cannot read $cache_dir/DATE: $!\n";
  $search_time = <FP>;
  $search_time =~ s/\s+$//;
  close(FP);
}

foreach my $ignore_word (@ignore_words) {
  $ignore{$ignore_word} = 1;
}

my $searched_text;

if($include_research) {
  if($include_reviews) {
    if($include_forum) {
      $searched_text = "research articles, reviews and forum articles";
    }
    else {
      $searched_text = "research articles and reviews";
    }
  }
  else {
    if($only_text) {
      $searched_text = "numbered paragraphs in ";
    }
    else {
      $searched_text = "";
    }
    if($include_forum) {
      $searched_text .= "research and forum articles";
    }
    else {
      $searched_text .= "research articles";
    }
  }
}
elsif($include_reviews) {
  if($include_forum) {
    $searched_text = "reviews and forum articles";
  }
  else {
    $searched_text = "reviews";
  }
}
else {
  $searched_text = "forum articles";
}

# Extract a list of JASSS articles from the index page

my $index = WWW::Mechanize->new(agent => $agent_id);

$index->get($index_url);
if(!$index->success()) {
  die "Could not load JASSS index URL \"$index_url\": HTTP response code ",
    $index->status(), "\n";
}
if(!$index->is_html()) {
  die "Content type of JASSS index URL \"$index_url\" is not HTML\n";
}

my @research;
my @reviews;
my @forum;
my $n_index_links = 0;
foreach my $link ($index->links()) {
  $n_index_links++;
  if($link->url() =~ /\/(\d+)\/(\d+)\/(\d+)\.html?$/i) {
    my ($vol, $iss, $art) = ($1, $2, $3);
    push(@research, [$link->url(), $vol, $iss, $art, $link->text()]);
  }
  elsif($link->url() =~ /\/(\d+)\/(\d+)\/review(\d+)\.html?$/i
    || $link->url() =~ /\/(\d+)\/(\d+)\/reviews\/(\w+)\.html?$/i) {

    my ($vol, $iss, $review) = ($1, $2, "R$3");
    push(@reviews, [$link->url(), $vol, $iss, $review, $link->text()]);
  }
  elsif($link->url() =~ /\/(\d+)\/(\d+)\/forum\/(\d+)\.html?$/i) {
    my ($vol, $iss, $art) = ($1, $2, "F$3");
    push(@forum, [$link->url(), $vol, $iss, $art, $link->text()]);
  }
}

my @articles = ();
if($include_research) {
  @articles = (@articles, @research);
}
if($include_reviews) {
  @articles = (@articles, @reviews);
}
if($include_forum) {
  @articles = (@articles, @forum);
}

if(scalar(@research) + scalar(@reviews) + scalar(@forum) == 0) {
  die "Unable to extract URLs of any articles from JASSS index URL \"",
    $index_url, "\" ($n_index_links links found)\n";
}
else {
  print "Found ", scalar(@research), " research articles, ", scalar(@reviews),
    " reviews, and ", scalar(@forum), " forum articles from JASSS index URL \"",
    $index_url, "\". Searching ", scalar(@articles), ".\n";
}

if($keywords) {
  $index->get($keywords_url);
  if(!$index->success()) {
    die "Could not load JASSS keywords URL \"$keywords_url\": HTTP response code ",
      $index->status(), "\n";
  }
  if(!$index->is_html()) {
    die "Content type of JASSS keywords URL \"$keywords_url\" is not HTML\n";
  }

  my $html = $index->content();

  foreach my $htmlkw (split(/(<dt><b>[^<]+<\/b><\/dt>)/, $html)) {
    if($htmlkw =~ /^<dt><b>\s*([^<]+)\s*<\/b><\/dt>$/) {
      my $keyword = $1;
      $keyword =~ tr/A-Z/a-z/;
      $keyword =~ s/^\s+//; # Paranoia given \s* in match
      $keyword =~ s/\s+$//; # More paranoia
      $keyword =~ s/\s+/ /;
      my @kwwords = split(/\s+|-/, $keyword);
      $kw{$keyword} = \@kwwords;
    }
  }

  print "Found ", scalar(keys(%kw)), " keywords from $keywords_url\n";
}

# Now search each of the articles for the term

my %sentences;  # Search-term -> article URL -> [sentences]
my %counts;     # Search-term -> count of appearances
my %hists;      # Search-term -> array of counts (index + 1 = n)
my $max_n = 0;

foreach my $search_term(@search_terms) {
  $counts{$search_term} = 0;
  $sentences{$search_term} = {};
  $hists{$search_term} = [];
}

my $n_searched = 0;
foreach my $article (@articles) {
  my $cache_html = "$cache_dir/$$article[1]_$$article[2]_$$article[3].html";
  my $cache_text = "$cache_dir/$$article[1]_$$article[2]_$$article[3].txt";
  my $cache_para = "$cache_dir/$$article[1]_$$article[2]_$$article[3].csv";

  my $html;
  my $text;
  if($cache < 0 && -e "$cache_html" && -e "$cache_text") {
    open(FP, "<", $cache_html) or die "Cannot open cached HTML file $cache_html: $!\n";
    while(my $line = <FP>) {
      $html .= $line;
    }
    close(FP);
    open(FP, "<", $cache_text) or die "Cannot open cached text file $cache_text: $!\n";
    while(my $line = <FP>) {
      $text .= $line;
    }
    close(FP);
  }
  else {
    $index->get($$article[0]);
    if(!$index->success()) {
      warn "Could not load article URL \"$$article[0]\": HTTP response code ",
        $index->status(), "\n";
        next;
    }
    if(!$index->is_html()) {
      warn "Context type of article URL \"$$article[0]\" is not HTML\n";
      next;
    }
    $html = $index->content();
    $text = $index->text();

    if($cache > 0) {
      open(FP, ">", $cache_html) or die "Cannot create HTML cache file $cache_html: $!\n";
      print FP $html;
      close(FP);
      open(FP, ">", $cache_text) or die "Cannot create text cache file $cache_text: $!\n";
      print FP $text;
      close(FP);
    }
  }
  $html =~ s/\s+/ /g;
  $html = &uncomment_html($html);

  my $title;
  my @date;

  if($html =~ /<meta name="DC.Title" content="([^"]+)" ?\/?>/i) {
    $title = $1;
  }
  elsif($html =~ /<meta content="([^"]+)" name="DC.Title" ?\/?>/i) {
    $title = $1;
  }
  if(defined($title)) {
    $title =~ s/^\s+//;   # Sometimes there is space before the quotes
    $title =~ s/\s+$//;   # Sometimes after
    $titles{$$article[0]} = $title;
  }

  if($html =~ /<meta name="DC.(Date|Issued)" content=" ?(\d+)-([A-Za-z0-9]+)-(\d+) ?" ?\/?>/i) {
    @date = ($2, $3, $4);
  }
  elsif($html =~ /<meta content=" ?(\d+)-([A-Za-z0-9]+)-(\d+) ?" name="DC.(Date|Issued)" ?\/?>/i) {
    @date = ($1, $2, $3);
  }
  if(scalar(@date) > 0) {
    my $yr = ($date[1] =~ /[A-Za-z]/) ? $date[2] : $date[0];
    if($yr < 1900) {
      if($yr >= 97) {
        $yr += 1900;
      }
      else {
        $yr += 2000;
      }
    }
    $years{$$article[0]} = $yr;
  }

  if(defined($years{$$article[0]})) {
    my $yr = $years{$$article[0]};
    my $author;

    if($html =~ /<meta name="DC.Creator" content="([^"]+)" ?\/?>/i) {
      $author = $1;
    }
    elsif($html =~ /<meta content="([^"]+)" name="DC.Creator" ?\/?>/i) {
      $author = $1;
    }

    if(defined($author)) {
      if($author =~ /^([^,]+,)/) {
        $author = "$1 et al.";
      }

      $auyr{$$article[0]} = "$author ($yr)";
    }
  }

  $n_searched++;

  my %paras;

  if($only_text) {
    # Try to ensure that the text searched is only that from numbered
    # paragraphs -- requires parsing the HTML

    if($cache < 0 && -e "$cache_para") {
      open(FP, "<", $cache_para) or die "Cannot open cached paragraph text file $cache_para: $!\n";
      while(my $line = <FP>) {
        $line =~ s/\s+$//;
        my ($para, @txt) = split(/,/, $line);
        $paras{$para} = join(",", @txt);
      }
      close(FP);
    }
    else {
      %paras = &extract_paragraph_text($html, $$article[1], $$article[2], $$article[3]);

      if($cache > 0) {
        open(FP, ">", $cache_para) or die "Cannot create cached paragraph text file $cache_para: $!\n";

        foreach my $para (sort {
          my ($a_sec, $a_no) = split(/\./, $a);
          my ($b_sec, $b_no) = split(/\./, $b);

          $a_sec <=> $b_sec || $a_no <=> $b_no;
        } keys(%paras)) {
          print FP "$para,$paras{$para}\n";
        }

        close(FP);
      }
    }
  } else {
    $paras{'all'} = $text;
  }

  if($concordance) {
    foreach my $para (keys(%paras)) {
      my $txt = $paras{$para};
      &do_concordance($$article[0], $para, $txt);
    }
  }

  if($do_search) {
    foreach my $search_term (@search_terms) {

      my @all_sentences;

      $n_occurs{$search_term}->{$$article[0]} = 0;

      foreach my $para (sort {
        my ($a_sec, $a_no) = split(/\./, $a);
        my ($b_sec, $b_no) = split(/\./, $b);

        $a_sec <=> $b_sec || $a_no <=> $b_no;
      } keys(%paras)) {
        my $txt = $paras{$para};

        if($txt =~ /\W$search_term\W/i) {
          my $sent_arr = &extract_sentences($$article[0], $para, $txt, $search_term);

          push(@all_sentences, @$sent_arr);
        }
      }

      if(scalar(@all_sentences) > 0) {
        $counts{$search_term}++;
        $sentences{$search_term}->{$$article[0]} = \@all_sentences;
        my $n = $n_occurs{$search_term}->{$$article[0]};
        $hists{$search_term}->[$n]++;
        $max_n = $n if $max_n < $n;
      }
    }
  }
}

# Print the results

print "Searched $n_searched of ", scalar(@articles), " articles\n";
if($only_text && $save_tags) {
  open(FP, ">", $tag_file) or die "Cannot open save tags file $tag_file: $!\n";
  print FP "Tag,Close,Frequency,Close.Freq\n";
  foreach my $tag (sort { $tags{$b} <=> $tags{$a} } keys(%tags)) {
    if(substr($tag, 0, 1) eq "&") {
      print FP "$tag,NA,$tags{$tag},NA\n";
    }
    elsif(substr($tag, 1, 1) ne "/") {
      if(substr($tag, -2, 1) eq "/") {
        print FP "$tag,NA,$tags{$tag},NA\n";
      }
      else {
        my $close_tag = "</".substr($tag, 1);
        if(defined($tags{$close_tag})) {
          print FP "$tag,$close_tag,$tags{$tag},$tags{$close_tag}\n";
        }
        else {
          print FP "$tag,$close_tag,$tags{$tag},0\n";
        }
      }
    }
    else {
      my $open_tag = "<".substr($tag, 2);
      if(!defined($tags{$open_tag})) {
        print FP "$open_tag,$tag,0,$tags{$tag}\n";
      }
    }
  }
}

if($do_hist) {
  # Histogram the results

  open(FP, ">", $hist_file) or die "Cannot create histogram file $hist_file: $!\n";

  my $bins = $max_n;
  my $binterval = 1;
  if($bins > $max_hist_bins) {
    $bins = $max_hist_bins;
    $binterval = $max_n / $max_hist_bins;
    if(int($binterval) != $binterval) {
      $binterval = 1 + int($binterval);
    }
  }

  print FP "Search Term,Number of Articles";
  my $n_times = 0;
  my %hist_bins;
  foreach my $search_term (sort @search_terms) {
    my @array;
    my $times_min = 0;
    my $times_max = $binterval;
    for(my $i = 0; $i < $bins; $i++) {
      $array[$i] = 0;
      my @hist = @{$hists{$search_term}};
      for(my $j = $times_min; $j <= $#hist && $j < $times_max; $j++) {
        $array[$i] += $hist[$j];
      }
      $times_min = $times_max;
      $times_max += $binterval;
    }
    $hist_bins{$search_term} = \@array;
  }
  for(my $i = 1; $i <= $bins; $i++) {
    print FP ",$n_times.gt.X.le.";
    $n_times += $binterval;
    print FP "$n_times";
  }
  print FP "\n";
  foreach my $search_term (sort @search_terms) {
    print FP "$search_term,$counts{$search_term}";
    my @histo = @{$hist_bins{$search_term}};
    for(my $i = 0; $i <= $#histo; $i++) {
      print FP ",$histo[$i]";
    }
    print FP "\n";
  }
  close(FP);
}

# Save the concordance

if($concordance) {
  &save_concordance();
}

# Save a markdown file

if($do_search) {
  open(FP, ">", $summary_file)
    or die "Cannot create summary markdown file $summary_file: $!\n";

  print FP "# JASSS article search results\n";
  print FP "Search (using [search-JASSS.pl](https://github.com/garypolhill/search-JASSS)) ",
    "of $n_searched articles out of all the ", scalar(@articles)," JASSS ",
    "$searched_text listed on the [JASSS article index page]($index_url) as at ",
    "$search_time. Search is for whole words (case insensitive), and articles are ",
    "listed in descending order of the number of times the search term appears, ",
    "with a minimum occurrence of $min_freq.\n";

  foreach my $search_term (sort @search_terms) {

    if($counts{$search_term} > 0) {
      print FP "## Search term `$search_term`\n";

      foreach my $article (sort {
        $n_occurs{$search_term}->{$b} <=> $n_occurs{$search_term}->{$a};
      } keys(%{$sentences{$search_term}})) {

        my $n = $n_occurs{$search_term}->{$article};

        if($n >= $min_freq) {
          my $title = defined($titles{$article}) ? "\"[$titles{$article}]($article)\"" : "[$article]($article)";
          if(defined($auyr{$article})) {
            $title = $auyr{$article}." $title";
          }
          print FP "### $title ($n times)\n";

          foreach my $sentence (@{$sentences{$search_term}->{$article}}) {
            print FP "  + $sentence\n";
          }
        }
      }
    }
    else {
      print FP "## Search term `$search_term`\nNot found.\n"
    }
  }

  close(FP);
}

exit 0;

sub extract_sentences {
  my ($article, $para, $text, $term) = @_;

  my @sentences;

  my @textsents = split(/(\.\s+[A-Z])/, $text);

  my $prevcap = "";
  foreach my $textsent (@textsents) {
    if(substr($textsent, 0, 1) eq ".") {
      $prevcap = substr($textsent, -1, 1);
    }
    else {
      my $whole_sentence = $prevcap.$textsent.".";
      # $sentence =~ s/[^[:ascii:]]/?/g; # Get rid of non-ASCII characters
      # Commented out to remember how it's done; but should not be necessary
      # now we've assumed UTF-8 output streams by default on line 1.

      $whole_sentence =~ s/^\s*\d+\.\d+//; # Sometimes the paragraph number slips in
      $whole_sentence =~ s/^\s+//;
      $whole_sentence = " $whole_sentence";

      if($whole_sentence =~ /\W$term\W/i) {
        my @occurs = split(/(\W$term\W)/i, $whole_sentence);

        my $sentence = ($para eq "all" ? "" : "(para [$para]($article#$para))");

        my $n = 0;
        foreach my $occur (@occurs) {
          if($occur =~ /\W$term\W/i) {
            $sentence .= substr($occur, 0, 1)."**".substr($occur, 1, -1)."**".substr($occur, -1, 1);
            $n++;
          }
          else {
            # Remove confounding markdown
            $occur =~ s/\*/ /g;
            $occur =~ s/\_/ /g;
            $occur =~ s/\`/ /g;
            $sentence .= $occur;
          }
        }

        $sentence =~ s/\.\s*\.$/./;

        push(@sentences, $sentence);
        $n_occurs{$term}->{$article} += $n;
      }
    }
  }

  return \@sentences;
}

# JASSS has varied the way it represents numbered paragraphs over the years; the
# following is based on a sample, where $N is substituted for the paragraph
# number and $text for the paragraph content (which may have HTML tags in).
# The notes below of the format should not be considered as representing a
# temporal ordering to changes in format. Especially in the earlier articles,
# there is little consistency.
#
#  1/1/3: Paragraph numbers are <DT><B><A name="$N">$N</A></B><DD>$text ... <P>
#  1/3/1: As 1/1/3 but tags are lowercase
#  2/1/1: As 1/3/1 but <p> is first not last
#  2/3/2: As 2/1/1 but </p> at the end of each paragraph, with <ul>s, etc. outwith
#         the <p> ... </p> content
#  4/2/3: <dt> <a name="$N"></a><b>$N</b> <dd>$text ...</dd>
#  6/2/1: <p><dt><b><a name="$N">$N</a></b></dt><dd>$text ... </p>
# 14/2/5: <p><dt class="numbered" id="par$N"><b>$N</b></dt><dd>$text ...
# 18/4/6: The <p> at the end of the paragraph is <p></p> and the paragraph ended
#         with </dd> before the next <dt>...
# 19/2/3: <p id="$N">$text</p> <ol> outwith <p> ... </p> content
#
# N.B. Some articles (e.g. 18/3/18) are only available in PDF format


sub extract_paragraph_text {
  my ($html, $vol, $iss, $no) = @_;

  $html =~ s[&nbsp;][ ]g;
  $html =~ s/\s+/ /g;

  my %paras; # ID -> text and any ensuing <ol> or <ul> <li> text
  my @parts;
  if($html =~ /<a name="\d+\.\d+">/i) {
    @parts = split(/(<a name="\d+\.\d+">)/i, $html);
  }
  elsif($html =~ /<a name=\d+\.\d+>/i) {
    @parts = split(/(<a name=\d+\.\d+>)/i, $html);
  }
  elsif($html =~ /<a name='\d+\.\d+'>/i) {
    @parts = split(/(<a name='\d+\.\d+'>)/i, $html);
  }
  elsif($html =~ /<a name="\d+\.\d+" id="\d+\.\d+">/i) {
    @parts = split(/(<a name="\d+\.\d+" id="\d+\.\d+">)/i, $html);
  }
  elsif($html =~ /<a name="\d+\.\d+" >/i) {
    @parts = split(/(<a name="\d+\.\d+" >)/i, $html);
  }
  elsif($html =~ /<dt class="numbered" id="par\d+\.\d+">/i) {
    @parts = split(/(<dt class="numbered" id="par\d+\.\d+">)/i, $html);
  }
  elsif($html =~ /<p class="numbered" id="par\d+\.\d+">/i) {
    @parts = split(/(<p class="numbered" id="par\d+\.\d+">)/i, $html);
  }
  elsif($html =~ /<p id="\d+.\d+">/i) {
    @parts = split(/(<p id="\d+.\d+">)/i, $html);
  }
  elsif($html =~ /<p id ="\d+.\d+">/i) {
    @parts = split(/(<p id ="\d+.\d+">)/i, $html);
  }
  elsif($html =~ /<p id=\d+.\d+>/i) {
    @parts = split(/(<p id=\d+.\d+>)/i, $html);
  }
  else {
    warn "Cannot find paragraph identification tags in article $vol/$iss/$no\n";
    return %paras;
  }
  shift(@parts); # Get rid of all preamble to the first paragraph
  while(scalar(@parts) > 2) {
    my $idtag = shift(@parts);
    my $text = shift(@parts);
    my $id;
    if($idtag =~ /(\d+.\d+)/) {
      $id = $1;
    }
    else {
      die "Could not extract paragraph ID from tag \"$idtag\" in article $vol/$iss/$no\n";
    }
    # Headings, tables and figures act as terminators for the text
    $text =~ s/<table.*$//i; # Some articles use tables to position figures
    $text =~ s/<h\d+.*$//i;
    $text =~ s/<figure.*$//i;
    $text =~ s/<section.*$//i;
    $text =~ s/<pre.*$//i; # Code too
    $text = &untag_text($text);
    $paras{$id} = $text;
  }
  return %paras;
}

sub untag_text {
  my ($html) = @_;

  my @markup = split(/(<[a-zA-Z\/][^>]*>)/, $html); # Several papers don't &lt;
  my $text = "";
  foreach my $mu (@markup) {
    if(substr($mu, 0, 1) eq "<" && substr($mu, -1, 1) eq ">") {
      $mu =~ s/\s+\S+="[^"]+"//g; # Remove attributes
      $mu =~ s/\s+\S+='[^']+'//g; # Remove attributes
      $mu =~ s/\s+\S+=\S+//g;     # Remove attributes
      $tags{$mu}++;
    }
    else {
      my @special = split(/(&[^; ]+;)/, $mu);
      foreach my $sp (@special) {
        if(substr($sp, 0, 1) eq "&" && substr($sp, -1, 1) eq ";") {
          $tags{$sp}++;
        }
        else {
          $text .= length($text == 0) ? $sp : " $sp";
        }
      }
    }
  }
  $text =~ s/\s+/ /g;

  return $text;
}

sub do_concordance {
  my ($url, $para, $text) = @_;

  $text =~ s/n't/ not/g;
  $text =~ s/'ll/ will/g;
  $text =~ s/'ve/ have/g;
  $text =~ s/'re/ are/g;
  my @phrases = split(/[.;,:'"()!?]/, $text);

  foreach my $phrase (@phrases) {
    my $lc_phrase = $phrase;
    $lc_phrase =~ tr/A-Z/a-z/;
    $lc_phrase =~ s/\s+/ /;
    my %added;
    if($keywords) {
      foreach my $keyword (keys(%kw)) {
        if(index($lc_phrase, $keyword) >= 0) {
          push(@{$concord{$keyword}}, [$url, $para]);
          $added{$keyword} = 1;
        }
      }
    }
    my @words = split(/\s+|-/, $lc_phrase);
    my @digrams;
    my @trigrams;
    for(my $i = 1; $i <= $#words; $i++) {
      if(!defined($ignore{$words[$i - 1]}) && !defined($ignore{$words[$i]})) {
        push(@digrams, $words[$i - 1]." ".$words[$i]);
        if($i > 1 && !defined($ignore{$words[$i - 2]})) {
          push(@trigrams, $words[$i - 2]." ".$digrams[$#digrams]);
        }
      }
    }
    foreach my $word (@words) {
      if(!defined($ignore{$word}) || $max_polysemy < 0) {
        if(!defined($added{$word})) {
          push(@{$concord{$word}}, [$url, $para]);
        }
        else {
          undef($added{$word});
        }
      }
    }
    foreach my $word (@digrams) {
      if(!defined($added{$word})) {
        push(@{$concord{$word}}, [$url, $para]);
      }
      else {
        undef($added{$word});
      }
    }
    foreach my $word (@trigrams) {
      if(!defined($added{$word})) {
        push(@{$concord{$word}}, [$url, $para]);
      }
      else {
        undef($added{$word});
      }
    }
  }
}

sub save_concordance {
  open(FP, ">", $concordance_file)
    or die "Cannot create concordance file $concordance_file: $!\n";

  print FP "Term,Term.N,", ($use_word_net ? "Familiarity," : ""),
    ($keywords ? "Keyword," : ""), "Article,Article.Y,Article.N,Para,Para.N\n";

  if($concordance_md) {
    open(MD, ">", $summary_file)
      or die "Cannot create concordance markdown file $summary_file: $!\n";

    print MD "# Concordance of [JASSS]($index_url) articles $search_time\n";

    if($use_word_net) {
      print MD "Familiarity (polysemy count) provided by ",
        "[WordNet](https://wordnet.princeton.edu), which is a registered trade ",
        "name of Princeton University\n";
    }
    if($keywords) {
      print MD "Concordance includes JASSS's list of [keywords]($keywords_url)\n";
    }
  }

  foreach my $term (sort {$a cmp $b} keys(%concord)) {

    my $familiarity = ($use_word_net ? &wn_familiarity($term) : 0);

    if($familiarity <= $max_polysemy || $max_polysemy == 0 || defined($kw{$term})) {
      my @refs = @{$concord{$term}};
      my $n = scalar(@refs);

      my %urls;
      my %paras;
      foreach my $ref (@refs) {
        my ($url, $para) = @$ref;

        $url =~ tr/A-Z/a-z/;

        $urls{$url}++;

        $paras{"$url#$para"}++;
      }

      my $prev_url;
      foreach my $paraurl (sort {
        my ($ua, $pa) = split(/\#/, $a);
        my ($ub, $pb) = split(/\#/, $b);

        my ($ha, $ba, $da, $ua1, $ua2, $ua3) = split(/\//, $ua);
        my ($hb, $bb, $db, $ub1, $ub2, $ub3) = split(/\//, $ub);

        my ($pa1, $pa2) = split(/\./, $pa);
        my ($pb1, $pb2) = split(/\./, $pb);

        $ua1 <=> $ub1 || $ua2 <=> $ub2 || $ua3 <=> $ub3 || $pa1 <=> $pb1 || $pa2 <=> $pb2;
      } keys(%paras)) {

        my ($url, $para) = split(/\#/, $paraurl);

        my $year = defined($years{$url}) ? $years{$url} : "NA";

        my $short_url = $url;
        $short_url =~ s/^https?:\/\///;
        $short_url =~ s/\.html?$//;
        my @su = split(/\//, $short_url);
        shift(@su); # Chuck out the domain
        $short_url = join("/", @su);

        print FP "$term,$n,";
        print FP "$familiarity," if $use_word_net;
        print FP (defined($kw{$term}) ? "T," : "F,") if $keywords;
        print FP "$short_url,$year,$urls{$url},$short_url#$para,$paras{$paraurl}\n";

        if($concordance_md) {
          print MD "\n## $term ($n)\n" if !defined($prev_url);
          if(!defined($prev_url) || $url ne $prev_url) {
            print MD "\n### [$short_url]($url) ($urls{$url})\n";
            $prev_url = $url;
          }
          else {
            print MD ", ";
          }
          print MD "[$para]($paraurl) ($paras{$paraurl})";
        }
      }
    }
  }

  if($concordance_md) {
    print MD "\n";
    close(MD);
  }

  close(FP);
}

sub uncomment_html {
  my ($html) = @_;

  my @comments = split(/(<!--|-->)/, $html);

  my $uncomment;

  my $incomment = 0;

  foreach my $comment (@comments) {
    if(!$incomment && $comment eq "<!--") {
      $incomment = 1;
    }
    elsif($incomment && $comment eq "-->") {
      $incomment = 0;
    }
    else {
      $uncomment .= $comment;
    }
  }

  return $uncomment;
}

sub wn_familiarity {
  my ($term) = @_;

  my @famls;
  open(FP, "-|", "$wn \"$term\"")
    or die "Cannot open pipe from WordNet $wn \"$term\": $!\n";
  while(my $line = <FP>) {
    if($line =~ /\s(-faml.)\s/) {
      push(@famls, $1);
    }
  }
  close(FP);
  if(scalar(@famls) == 0) {
    return 0;
  }
  my $tfaml = 0;
  foreach my $faml (@famls) {
    open(FP, "-|", "$wn \"$term\" $faml")
      or die "Cannot open pipe from WordNet $wn \"$term\" $faml: $!\n";

    while(my $line = <FP>) {
      if($line =~ /polysemy count = (\d+)/) {
        $tfaml += $1;
      }
    }

    close(FP);
  }

  return $tfaml / scalar(@famls);
}
