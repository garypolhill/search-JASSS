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

my $index_url = "http://jasss.soc.surrey.ac.uk/index_by_issue.html";
                # Update this if the JASSS website is changed. It is
                # the webpage to search for URLs of JASSS articles.
my $n_context = 75;
my $include_forum = 0;
my $include_reviews = 0;
my $include_research = 1;
my $max_hist_bins = 10;

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
  elsif($option eq "-c" || $option eq "--context") {
    $n_context = shift(@ARGV);
  }
  elsif($option eq "-i" || $option eq "--index") {
    $index_url = shift(@ARGV);
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
\t-c (--context): number of characters to display around each occurrence
\t-f (--include-forum): include forum articles in the search
\t-F (--only-forum): only search forum articles
\t-h (--help): display this message
\t-r (--include-reviews): include review articles in the search
\t-R (--only-reviews): only search review articles
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
    if($include_forum) {
      $searched_text = "research and forum articles";
    }
    else {
      $searched_text = "research articles";
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
my $index = WWW::Mechanize->new();
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

    my ($vol, $iss, $review) = ($1, $2, $3);
    push(@reviews, [$link->url(), $vol, $iss, $review, $link->text()]);
  }
  elsif($link->url() =~ /\/(\d+)\/(\d+)\/forum\/(\d+)\.html?$/i) {
    my ($vol, $iss, $art) = ($1, $2, $3);
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
  $n_searched++;

  my $text = $index->text();

  foreach my $search_term (@search_terms) {
    if($text =~ /\W$search_term\W/i) {
      $counts{$search_term}++;
      my $sent_arr = &extract_sentences($$article[0], $text, $search_term);
      $sentences{$search_term}->{$$article[0]} = $sent_arr;
      my $n = scalar(@$sent_arr);
      $hists{$search_term}->[$n]++;
      $max_n = $n if $max_n < $n;
    }
  }
}

# Print the results

print "Searched $n_searched of ", scalar(@articles), " articles\n";

my $bins = $max_n;
my $binterval = 1;
if($bins > $max_hist_bins) {
  $bins = $max_hist_bins;
  $binterval = $max_n / $max_hist_bins;
  if(int($binterval) != $binterval) {
    $binterval = 1 + int($binterval);
  }
}

print "Search Term,Number of Articles";
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
  print ",$n_times.gt.X.le.";
  $n_times += $binterval;
  print "$n_times";
}
print "\n";
foreach my $search_term (sort @search_terms) {
  print "$search_term,$counts{$search_term}";
  my @histo = @{$hist_bins{$search_term}};
  for(my $i = 0; $i <= $#histo; $i++) {
    print ",$histo[$i]";
  }
  print "\n";
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
  my ($article, $text, $term) = @_;

  my @sentences;

  my @occurs = split(/\W$term\W/i, $text);

  # For now, lazy approach: print 50 characters either side

  for(my $i = 1; $i <= $#occurs; $i++) {
    my $sentence =
      substr($occurs[$i - 1], -$n_context)." **$term** ".substr($occurs[$i], 0, $n_context);
    $sentence =~ s/[^[:ascii:]]/?/g; # Get rid of non-ASCII characters

    push(@sentences, $sentence);
  }

  return \@sentences;
}
