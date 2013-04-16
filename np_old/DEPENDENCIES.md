### Calls ###

*  `pre.pl` <= `utf8-tokenize.pl`

### Input & output ###

*  `pre.pl` <= `./r/` (required), `wforms_full.txt` (required), `substitution.txt` (possibly void), `glue.txt` (may be commented out), `suggestions_EXPERIMENTAL.txt` (may be commented out)
*  `pre.pl` => `./t/`, `hapax.txt`
*  `glue.pl` <= `wforms_full.txt` (required), `substitution.txt` (possibly void)
*  `glue.pl` => `glue.txt`
*  `lev1.pl` <= `wforms_full.txt` (required), `alternations.txt` (required), `hapax.txt` (required)
*  `lev1.pl` => `suggestions_lev1.txt` (may be renamed into `suggestions_EXPERIMENTAL.txt`)

Input & output of `indexer.pl` and `finder.pl` are as usual.