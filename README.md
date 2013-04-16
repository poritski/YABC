## General info ##

This is an early partial preview of Yet Another Belorussian Corpus being under construction at the BSU Department of Philology, Minsk (Oksana Volchek and Vladislav Poritski are the principal investigators). We haven't arranged any copyright issues, which are, indeed, likely to arise, so you may access the newspaper and fiction texts available here __at your own risk__. You should also mind ANSI 1251 encoding of all text files.

## Data ##

### Overview ###

So far we have the following directory tree:

*  `/fiction`
   *  `/mags`
      *  `/dzsl`
      *  `/mal`
      *  `/pol`
   *  `/kolas`
*  `/newspapers`
   *  `/holas`
   *  `/zmena`
   *  `/zvyazda`
*  `/np_old`

Here `/fiction` stands just for belorussian prose fiction. A minimalistic sample of present-day prose published in 2009...2011 by [_Dziejaslou_](http://www.dziejaslou.by), [_Maladosc'_](http://www.maladost.lim.by), and [_Polymya_](http://www.polymja.lim.by) literary magazines is grouped into `/mags` subdirectory (with respective subcategorization inside, 10 files in each folder), while `/kolas` contains a significant part of non-poetic heritage left by Yakub Kolas (1882-1956); as far as we know, these texts are in public domain since 2006.

Unsurprisingly, `/newspapers` is a teaser collection of belorussian newspaper articles from years 2008-2009. We've crawled three newspaper sites with publicly available archives, [_Zvyazda_](http://www.zvyazda.minsk.by/ru/main), [_Chyrvonaja zmena_](http://www.zvyazda.minsk.by/ru/pril/index.php?id=30), and [_Holas Radzimy_](http://www.golas.by), to obtain 9.2 thousand articles in total. Three samples currently being delivered are 150 files each.

`/np_old` is a preview of OCRed belorussian newspapers dating back to 1961-1962. Digital copies have been kindly provided by [National library of Belarus)](http://nlb.by). We've processed them with ABBYY FineReader and done some automated and semi-automated postediting to obtain a searchable collection spanning one year for both _Holas Radzimy_ and [_Litaratura i mastactva_](http://www.main.lim.by). The preview sample contains _LiM_ for January 1961 and _Holas Radzimy_ for January 1962.

There are two subfolders, `/r` and `/t`, inside each of the said folders: `/r` contains raw text data, while `/t` is the destination place for tokenized texts (cf. software description below).

### Naming conventions ###

In `/mags/mal` and `/mags/pol`, file names are self-explanatory. E.g. `PROSE_m1-09_7_18` indicates that the text was published in 2009'01 issue of _Maladosc'_ on pages 7-18. In `/mags/dzsl`, file names encode explicitly only the magazine issue, e.g. `39_bab` is a text published in issue 39 of _Dziejaslou_, 2009 (and authored by Natalka Babina, yet the author's identity generally cannot be revealed through examining file name only). All over `/mags`, there are `author`, `title`, and `genre` definitions inside the text files.

Yakub Kolas's trilogy _Na rostanyakh_ is presented in `/kolas` chapterwise with initial "r" in file names, so that, e.g., chapter 7 of the second part would be entitled `r2_7`. Likewise, chapters of _Drygva_ novel have initial "d" in their names. Initial "k" marker is associated with short stories _Kazki zhycia_.

Naming of newspaper articles in our text sample is rather unsystematic. Except for `/newspapers/holas`, we use five-digit numeric identifiers inherited from the online archives. Text files sampled from _Holas Radzimy_ are enumerated consistently, `1` to `150`. Older newspapers are presented in larger chunks, one file by month (numbers in the file names are actually month numbers).

## Software ##

Both in `/fiction` and in `/newspapers` one can find certain Perl scripts and accompanying files. Let's explore this uncomplicated programmatic tool in some detail.

*  `dirlist.txt` is a newline-delimited list of relative paths to all relevant folders containing text data. Assume each of them has an `/r` subfolder with raw texts and an empty `/t` subfolder.
*  `preprocessor.pl` takes `dirlist.txt` as input and invokes `utf8-tokenize.pl` script by Helmut Schmid, borrowed from [_TreeTagger_](http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger) and slightly fine-tuned, to populate `/t`'s with tokenized texts.
*  `indexer.pl` takes `dirlist.txt` as input. The script then reads all available tokenized texts one by one and produces a tokenwise inverted index, `index.dat`. Technically, this index is a serialized two-dimensional hash with wordform tokens as primary keys. Each token has been seen in certain tokenized text(s) on certain line(s), so all relevant file identifiers and line numbers are stored in the index to reduce search-related overhead. __Notice:__ with Perl version prior to 5.8, `indexer.pl` may require `Storable` module to be installed.
*  As a by-product, `indexer.pl` counts frequencies of individual tokens all over the subcorpus and outputs the results into `wforms.txt`. It also counts tokens in each text file and outputs the results into `wforms_count.txt`. Both these files are omitted here.
*  `wordlist.txt` is a (default) list of queries. Each line is tab-separated into two columns, a regex query and its identifier. Each query in the sample list is designed so as to match all inflectional variants of certain noun, with Nom. sg. of the same noun being the identifier; actually, you can employ any regexes and any identifiers. To comment out a query, just add initial `#` to the line.
*  `finder.pl` takes `index.dat` and `wordlist.txt` as input. For each valid query, the script greps all matching tokens from the index and looks for their occurrences in the respective text files. Entries found in the corpus are then written into `results.txt` (this file is omitted). One covert parameter here is context width in tokens. The default value is 10. To modify it, have a look at the source code of `finder.pl`.

Note that we have two copies of the same search engine just for convenience. You may decide to have a single copy in the root directory instead. To make this change, move `wordlist.txt` and all `.pl` files one level up the directory tree, then merge two `dirlist`s and tweak the paths to persist their correctness. Finally, rebuild the index.

## What's new ##

_2013-04-01 release:_ We've added a tokenization tool and rewritten indexer and finder to speed up the search in tokenized texts. Word counts have been omitted.

_2013-04-15 release:_ A searchable diachronic newspaper collection is now available, description is coming soon. (See `/np_old/DEPENDENCIES.md` for a sketch.)

## Directions of future work ##

__TODO__

1. _Morphology._
2. _Enhanced search (MWE)._
3. _More texts, less doubles, better boilerplate removal._
