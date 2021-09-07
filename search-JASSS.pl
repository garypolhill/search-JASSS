#!/usr/bin/perl
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

use strict;
use WWW::Mechanize;
use Time::Piece;

# Globals

my $index_url = "http://www.jasss.org/index_by_issue.html";
                # Update this if the JASSS website is changed. It is
                # the webpage to search for URLs of JASSS articles.
my $adent_id = "search-JASSS v2021-09-06"
my $n_context = 75;
my $include_forum = 0;
my $include_reviews = 0;
my $include_research = 1;
my $max_hist_bins = 10;
my $only_text = 1;
my $concordance = 0;
my $concordance_file;
my %concord;
my $cache = 0;
my $cache_dir;
my $do_hist = 0;
my $hist_file;
my %tags;       # Counts of tags and special characters in paragraph text found
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

if(scalar(@ARGV) == 0) {
  die "Usage: $0 <summary.md> <search terms...>\n";
}

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
  elsif($option eq "-t" || $option eq "--text-all") {
    $only_text = 0;
  }
  elsif($option eq "-c" || $option eq "--context") {
    $n_context = shift(@ARGV);
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
  elsif($option eq "-h" || $option eq "--help") {
    print <<USAGE_END;
$0 {options...} <summary file> <search terms...>

    Search for research articles in JASSS at $index_url
    and then download and search those articles for the search terms.

    summary file: markdown format file giving detailed search results
    search terms...: one or more (case insensitive) search terms

    options...:
\t-a (--include-all): search review, forum and research articles
\t-b (--hist-file-bins) <file> <n>: prepare a histogram in CSV file with n bins
\t-c (--context): number of characters to display around each occurrence
\t-C (--concordance) <file>: prepare a concordance in CSV file
\t-f (--include-forum): include forum articles in the search
\t-F (--only-forum): only search forum articles
\t-h (--help): display this message
\t-H (--histogram) <file>: prepare a histogram in CSV file with $max_hist_bins bins
\t-r (--include-reviews): include review articles in the search (requires -t)
\t-R (--only-reviews): only search review articles (requires -t)
\t-s (--save-cache) <dir>: cache downloaded articles in dir
\t-t (--text-all): search in all text not just numbered paragraphs (allows -r and -R)
\t-u (--use-cache) <dir>: use cache in dir
USAGE_END
    exit 0;
  }
  else {
    die "Option $option not recognized\n";
  }
}

my $summary_file = shift(@ARGV);
my @search_terms = @ARGV;

if($include_research + $include_reviews + $include_forum == 0) {
  die "The options you've selected to search for articles mean none will be searched.\n"
}
if(scalar(@search_terms) == 0) {
  die "No search terms provided.\n";
}

if($include_reviews && $only_text) {
  die "Including reviews in the search means you can't only extract text from numbered paragraphs\n";
}

if($cache > 0) {
  if(-e "$cache_dir" && !(-d "$cache_dir")) {
    die "Cache directory $cache_dir exists, but not as a directory\n";
  }
  if(!(-d "$cache_dir")) {
    mkdir(0777, $cache_dir) or die "Cannot create cache directory $cache_dir: $!\n";
  }
  else {
    warn "Cache directory $cache_dir exists -- files will be over-written\n";
  }
}
elsif($cache < 0 && !(-d "$cache_dir")) {
  die "Cache directory $cache_dir does not exist or is not a directory, so cannot use it\n";
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

# Extract a list of JASSS articles

my $search_time = localtime->datetime;
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
          ($a_sec, $a_no) = split(/\./, $a);
          ($b_sec, $b_no) = split(/\./, $b);

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

  foreach my $search_term (@search_terms) {

    my @all_sentences;

    foreach my $para (sort {
      ($a_sec, $a_no) = split(/\./, $a);
      ($b_sec, $b_no) = split(/\./, $b);

      $a_sec <=> $b_sec || $a_no <=> $b_no;
    } keys(%paras)) {
      my $txt = $paras{$para};

      if($txt =~ /\W$search_term\W/i) {
        my $sent_arr = &extract_sentences($$article[0], $para, $txt, $search_term);

        push(@all_sentences, @$sent_arr);
      }

      if($concordance) {
        &do_concordance($$article[0], $para, $txt);
      }
    }

    if(scalar(@all_sentences) > 0) {
      $counts{$search_term}++;
      $sentences{$search_term}->{$$article[0]} = \@all_sentences;
      my $n = scalar(@all_sentences);
      $hists{$search_term}->[$n]++;
      $max_n = $n if $max_n < $n;
    }
  }
}

# Print the results

print "Searched $n_searched of ", scalar(@articles), " articles\n";
if($only_text) {
  foreach my $tag (sort { $a cmp $b } keys(%tags)) {
    if(substr($tag, -2, 1) ne "/") {
      my $close_tag = substr($tag, 0, -1)."/>";
      if(defined($tags{$close_tag})) {
        print "Tag $tag appeared $tags{$tag} times, and $close_tag $tags{$close_tag} times in numbered paragraph HTML\n";
      }
      else {
        print "Tag $tag appeared $tags{$tag} times, with no $close_tag in numbered paragraph HTML\n";
      }
    }
    else {
      my $open_tag = substr($tag, 0, -2).">";
      if(!defined($tags{$open_tag})) {
        print "Tag $tag appeared $tags{$tag} times, with no $open_tag in numbered paragraph HTML\n";
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

# Save a markdown file

open(FP, ">", $summary_file)
  or die "Cannot create summary markdown file $summary_file: $!\n";

print FP "# JASSS article search results\n";
print FP "Search (using [search-JASSS.pl](https://github.com/garypolhill/search-JASSS)) ",
  "of $n_searched articles out of all the ", scalar(@articles)," JASSS ",
  "$searched_text listed on the [JASSS article index page]($index_url) as at ",
  "$search_time. Search is for whole words (case insensitive), and articles are ",
  "listed in descending order of the number of times the search term appears.\n";
foreach my $search_term (sort @search_terms) {

  if($counts{$search_term} > 0) {
    print FP "## Search term `$search_term`\n";

    foreach my $article (sort {
        scalar(@{$sentences{$search_term}->{$b}}) <=> scalar(@{$sentences{$search_term}->{$a}})
      } keys(%{$sentences{$search_term}})) {

      print FP "### Article [$article]($article)\n";

      foreach my $sentence (@{$sentences{$search_term}->{$article}}) {
        print FP "  + $sentence\n";
      }
    }
  }
  else {
    print FP "## Search term `$search_term`\nNot found.\n"
  }
}

close(FP);

exit 0;

sub extract_sentences {
  my ($article, $para, $text, $term) = @_;

  my @sentences;

  my @occurs = split(/\W$term\W/i, $text);

  # For now, lazy approach: print 50 characters either side

  for(my $i = 1; $i <= $#occurs; $i++) {
    my $sentence =
      substr($occurs[$i - 1], -$n_context)." **$term** ".substr($occurs[$i], 0, $n_context);
    $sentence =~ s/[^[:ascii:]]/?/g; # Get rid of non-ASCII characters

    if($para ne "all") {
      $sentence = "(para [$para]($article#$para)) $sentence";
    }

    push(@sentences, $sentence);
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
  elsif($html =~ /<dt class="numbered" id="par\d+\.\d+">/i) {
    @parts = split(/(<dt class="numbered" id="par\d+\.\d+">)/i, $html);
  }
  elsif($html =~ /<p id="\d+.\d+">/i) {
    @parts = split(/(<p id="\d+.\d+">)/i, $html);
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
    if($idtag =~ /(\d+.\d+))/) {
      $id = $1;
    }
    else {
      die "Could not extract paragraph ID from tag \"$idtag\" in article $vol/$iss/$no\n";
    }
    # Headings, tables and figures act as terminators for the text
    $text =~ s/<table.*$//; # Some articles use tables to position figures
    $text =~ s/<h\d+.*$//;
    $text =~ s/<figure.*$//;
    $text =~ s/<pre.*$//; # Code too
    $text = &untag_text($text);
    $paras{$id} = $text;
  }
  return %paras;
}

sub untag_text {
  my ($html) = @_;

  my @markup = split(/(<[^>]+>)/, $html);
  my $text = "";
  foreach my $mu (@markup) {
    if(substr($mu, 0, 1) eq "<" && substr($mu, -1, 1) eq ">") {
      $tags{$mu}++;
    }
    else {
      my @special = split(/(&\w+;)/, $mu);
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

  $para =~ s/n't/ not/g;
  $para =~ s/'ll/ will/g;
  $para =~ s/'ve/ have/g;
  $para =~ s/'re/ are/g;
  my @phrases = split(/[.;,:'"()!?]/, $para);

  foreach my $phrase (@phrases) {
    $lc_phrase = $phrase;
    $lc_phrase =~ tr/A-Z/a-z/;
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
      if(!defined($ignore{$word})) {
        push(@{$concord{$word}}, [$url, $para]);
      }
    }
    foreach my $word (@digrams) {
      push(@{$concord{$word}}, [$url, $para]);
    }
    foreach my $word (@trigrams) {
      push(@{$concord{$word}}, [$url, $para]);
    }
  }
}
