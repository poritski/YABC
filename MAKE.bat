cd main/data
type corpus_ZV_1.txt corpus_ZV_2.txt > corpus_ZV.txt
del corpus_ZV_*.txt
cd ..
perl indexer.pl
cd ../np_old
perl indexer.pl
pause