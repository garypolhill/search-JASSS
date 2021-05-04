# search-JASSS
One or more scripts to help with searching papers in JASSS

## `search-JASSS.pl`

Uses the Perl `WWW::Mechanize` module, which you can install using `cpanm`. See the [CPAN install page](http://www.cpan.org/modules/INSTALL.html).

Usage: `./search-JASSS.pl {Options...} <Markdown Search Summary File> <Search Terms...>`

The script uses JASSS's [Index page](jasss.soc.surrey.ac.uk/index_by_issue.html) to find the list of all published JASSS articles. It then downloads the papers and looks for each search term as a 'whole word' (i.e. `/\W$search_term\W/i`), case insensitive.

On standard output, it prints a summary of the number of articles containing each search term. A more detailed output is written to the `Markdown Search Summary File`, which includes a list of each article containing the search term, and some detail on the context in the text of the article in which the search term appears.

Options:

  + `-a` (`--include-all`): search review, forum and research articles
	+ `-c` (`--context`): number of characters to display around each occurrence
	+ `-f` (`--include-forum`): include forum articles in the search
	+ `-F` (`--only-forum`): only search forum articles
	+ `-h` (`--help`): display a usage message
	+ `-r` (`--include-reviews`): include review articles in the search
	+ `-R` (`--only-reviews`): only search review articles
