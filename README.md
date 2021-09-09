# search-JASSS
One or more scripts to help with searching papers in JASSS

## `search-JASSS.pl`

This program uses the Perl `WWW::Mechanize` module, which you can install using `cpanm`. See the [CPAN install page](http://www.cpan.org/modules/INSTALL.html). You will also need the `LWP::Protocol::https` module if any of the links use `https` instead of `http`. (As of August 2021, they do.) If it is installed, this program can also use Princeton University's [WordNet](https://wordnet.princeton.edu/) with its 'concordance' mode.

It parses HTML in JASSS's articles to perform analyses of the articles' text. By volume 23 of JASSS (2020), there were six articles that are only available in PDF format (either due to their length or due to extensive use of mathematical symbols), and/or do not have any numbered paragraphs. Regrettably the PDFs cannot currently be included in the search, though with the script's `-T` option, any text in title, abstract or references included on the HTML landing page for the article can be included. The affected articles are:

+ Conte and Moss (1999) "[Special Interest Group on Agent-Based Social Simulation](https://www.jasss.org/2/1/4.html)" _JASSS_ 2(1), 4. (No numbered paragraphs.)
+ Hegselmann and Krause (2002) "[Opinion dynamics and bounded confidence: models, analysis and simulation](https://www.jasss.org/5/3/2.html)" _JASSS_ 5(3), 2. (PDF only; no numbered paragraphs in PDF.)
+ Hegselmann and Krause (2006) "[Truth and cognitive division of labour: first steps towards a computer aided social epistemology](https://www.jasss.org/9/3/10.html)" _JASSS_ 9(3), 10. (PDF only; no numbered paragraphs in PDF.)
+ Tambayong (2007) "[Dynamics of network formation processes in the co-author model](https://www.jasss.org/10/3/2.html)" _JASSS_ 10(3), 2. (PDF only.)
+ Hegselmann et al. (2015) "[Optimal opinion control: the campaign problem](https://www.jasss.org/18/3/18.html)" _JASSS_ 18(3), 18. (PDF only; no numbered paragraphs in PDF.)
+ Hegselmann (2017) "[Thomas C. Schelling and James M. Sakoda: The intellectual, technical, and social history of a model](https://www.jasss.org/20/3/15.html)" _JASSS_ 20(3), 15. (PDF only; no numbered paragraphs in PDF.)

The subject material and authorship of these articles does disproprortionately discriminate against them. Until the script is updated to parse PDFs, users are advised to take heed of the deficiency.

### Searching JASSS

Usage: `./search-JASSS.pl {Options...} <Markdown Search Summary File> <Search Terms...>`

The script uses JASSS's [Index page](https://www.jasss.org/index_by_issue.html) to find the list of all published JASSS articles. It then downloads the papers and looks for each search term as a 'whole word' (i.e. `/\W$search_term\W/i`), case insensitive.

If the `-H` or `-b` options are give, a summary of the number of articles containing each search term is saved to the specified file. A more detailed output is written to the `Markdown Search Summary File`, which includes a list of each article containing the search term, and some detail on the context in the text of the article in which the search term appears.

By default, the search attempts to parse the HTML to find text that only appears in numbered paragraphs (i.e. ignoring text in title, abstract, acknowledgements and references). Since review articles don't have numbered paragraphs, the `-r` and `-R` options are incompatible with the default. With the `-T` option, the search occurs in whatever text is returned by the `WWW::Mechanize` module's method to extract text from the HTML, and review articles can be included in the search.

Options:

  + `-a` (`--include-all`): search review, forum and research articles
  + `-b` (`--hist-file-bins`) `<file> <n>`: prepare a histogram in CSV `file` with `n` bins
	+ `-f` (`--include-forum`): include forum articles in the search
	+ `-F` (`--only-forum`): only search forum articles
  + `-H` (`--histogram`) `<file>`: prepare a histogram in CSV `file` with 10 bins
  + `-i` (`--agent-id`) `<ID>`: agent `ID` to use in HTTP GET
	+ `-j` (`--jasss-url`) `<URL>`: page to access JASSS index from (default http://www.jasss.org/index_by_issue.html)
  + `-m` (`--minimum-frequency`) `<n>`: only include papers mentioning search term >= `n` times
	+ `-r` (`--include-reviews`): include review articles in the search (requires `-T`)
	+ `-R` (`--only-reviews`): only search review articles (requires `-T`)
	+ `-s` (`--save-cache`) `<dir>`: cache downloaded articles in `dir`
	+ `-T` (`--text-all`): search in all text not just numbered paragraphs (allows `-r` and `-R`)
	+ `-t` (`--save-tags`) `<file>`: save tags in paragraph text to CSV `file` (incompatible with `-T`)
	+ `-u` (`--use-cache`) `<dir>`: use cache in `dir`

### Concordance of JASSS

Usage: `./search-JASSS.pl {Other options...} --concordance <CSV file> [Markdown Concordance File]`

A concordance is an alphabetical list of terms (in this case, individual words, and 2-3 word combinations) and references to where they are mentioned in a body of text. To allow analysis of which terms are used and how often, the concordance is saved in a CSV file. If no search terms are specified, the single remaining commandline argument after the options is assumed to be the name of a markdown file to which to save a document form of the same data, with the slight difference that the year is not included.

Using the `-p` option means that more commonly-used words will not be included -- shortening the concordance and concentrating more on specialist terminology. Use `-p 0` to include words regardless of polysemy count; use `-p -1` to include words even if they are in the program's list of words to ignore by default (determinants, prepositions and pronouns, but also some other very common words that pretty much every paper, even every paragraph, can be expected to contain). The 2-3 word combinations may not include any of these words, regardless of any argument given to `-p`.

Options:

+ `-a` (`--include-all`): include review, forum and research articles in the concordance
+ `-C` (`--concordance`) `<file>`: prepare a concordance in CSV `file`
+ `-f` (`--include-forum`): include forum articles in the concordance
+ `-F` (`--only-forum`): only search forum articles
+ `-i` (`--agent-id`) `<ID>`: agent `ID` to use in HTTP GET
+ `-j` (`--jasss-url`) `<URL>`: page to access JASSS index from (default http://www.jasss.org/index_by_issue.html)
+ `-k` (`--include-keywords`): make sure all keywords are included in the concordance
+ `-K` (`--keywords-url`) `<URL>`: page to load keywords from (default https://www.jasss.org/keywords.html)
+ `-p` (`--maximum-polysemy`) `<n>`: maximum polysemy count to include term in concordance (implies `-w`)
+ `-r` (`--include-reviews`): include review articles in the concordance (requires `-T`)
+ `-R` (`--only-reviews`): only include review articles in the concordance (requires `-T`)
+ `-s` (`--save-cache`) `<dir>`: cache downloaded articles in `dir`
+ `-T` (`--text-all`): look for words to include in all text not just numbered paragraphs (allows `-r` and `-R`)
+ `-t` (`--save-tags`) `<file>`: save tags in paragraph text to CSV `file` (incompatible with `-T`)
+ `-u` (`--use-cache`) `<dir>`: use cache in `dir`
+ `-w` (`--use-WordNet`): use [WordNet](https://wordnet.princeton.edu) to get polysemy count
+ `-W` (`--with-WordNet`) `<exe>`: where to find [WordNet](https://wordnet.princeton.edu) (`default /usr/local/WordNet-3.0/bin/wn`) (implies `-w`)

### Help

Usage: `./search-JASSS.pl --help`
