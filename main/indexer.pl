#! /usr/bin/perl -w
use locale;
use Storable;

# Autoflush mode on. Do not disable
$| = 1;
# Full names of text collections
%alias =
	(
	"MAL" => "Maladosc'",
	"POL" => "Polymia",
	"DZSL" => "Dziejaslou",
	"G" => "Holas Radzimy",
	"ZV" => "Zviazda",
	"ZM" => "Chyrvonaja zmena",
	"OLD" => "old fiction"
	);

@subcorpora = ("G", "ZM", "ZV", "MAL", "POL", "DZSL", "OLD");

foreach $sc (@subcorpora)
	{
	print STDOUT "Indexing $alias{$sc}...\t";
	%inverted_index = ();
	if (open (CORPUS, "<./data/corpus_" . $sc . ".txt"))
		{
		$line_counter = -1;
		while (<CORPUS>)
			{
			++$line_counter;
			chomp;
			($fid, $tid, $wform, $lemma, $gram) = split (/\t/, $_);
			($fid, $tid) = (); # unnecessary
			@l = split (/\|/, $lemma);
			@g = split (/\|/, $gram);
			push @{$inverted_index{'w'}{$wform}}, $line_counter;
			foreach (@l) { push @{$inverted_index{'l'}{$_}}, $line_counter; }
			foreach (@g) { push @{$inverted_index{'g'}{$_}}, $line_counter; }
			}
		close (CORPUS);
		store \%inverted_index, "./index/index_" . $sc . ".dat";
		print STDOUT "Done\n";
		}
	else { print STDOUT "Not found\n"; }
	}