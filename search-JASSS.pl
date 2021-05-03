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
my $n_context = 50;

# Process command-line arguments

if(scalar(@ARGV) == 0) {
  die "Usage: $0 <summary.md> <search terms...>";
}

my $summary_file = shift(@ARGV);
my @search_terms = @ARGV;

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

my @articles;
my $n_index_links = 0;
foreach my $link ($index->links()) {
  $n_index_links++;
  if($link->url() =~ /\/(\d+)\/(\d+)\/(\d+)\.html?$/i) {
    my ($vol, $iss, $art) = ($1, $2, $3);
    push(@articles, [$link->url(), $vol, $iss, $art, $link->text()]);
  }
}

if(scalar(@articles) == 0) {
  die "Unable to extract URLs of any articles from JASSS index URL \"",
    $index_url, "\" ($n_index_links links found)\n";
}
else {
  print "Found ", scalar(@articles), " articles from JASSS index URL \"",
    $index_url, "\"\n";
}

# Now search each of the articles for the term

my %sentences;  # Search-term -> article URL -> [sentences]
my %counts;     # Search-term -> count of appearances

foreach my $search_term(@search_terms) {
  $counts{$search_term} = 0;
  $sentences{$search_term} = {};
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
      $sentences{$search_term}->{$$article[0]} =
        &extract_sentences($$article[0], $text, $search_term);
    }
  }
}

# Print the results

print "Searched $n_searched of ", scalar(@articles), " articles\n";
print "Search Term,Number of Articles\n";
foreach my $search_term (sort @search_terms) {
  print "$search_term,$counts{$search_term}\n";
}

# Save a markdown file

open(FP, ">", $summary_file)
  or die "Cannot create summary markdown file $summary_file: $!\n";

print FP "# JASSS article search results\n";
print FP "Search of $n_searched articles of all ", scalar(@articles), " JASSS ",
  "articles listed on the [JASSS article index page]($index_url) as at ",
  "$search_time. Search is for whole words (case insensitive).\n";
foreach my $search_term (sort @search_terms) {

  if($counts{$search_term} > 0) {
    print FP "## Search term `$search_term`\n";

    foreach my $article (sort keys(%{$sentences{$search_term}})) {
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
