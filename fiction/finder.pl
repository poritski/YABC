#! /usr/bin/perl -w
use locale;
use Storable;
use Encode;
use List::Util;

$width = 100; # left & right context width in symbols

$hashref = retrieve('index_regex.dat');
%inverted_index = %{$hashref};

open (WORDLIST, "<wordlist.txt");
while (<WORDLIST>)
	{
	chomp;
	unless (/^\#/) # except those queries which are commented out
		{
		if (/\t/) { ($query, $signature) = split (/\t/, $_); }
		else { ($query, $signature) = ($_, $_); } # otherwise
		push @queries, $query;
		$substitute{$query} = $signature;
		}
	}
close (WORDLIST);

open (FILEOUT, ">results_regex.txt");
foreach $query (@queries)
	{
	@relevant = sort grep { /(^|\-)$query(\-|$)/ } keys %inverted_index; # BEWARE! To be improved
	foreach $instance (@relevant)
		{
		foreach $handle (keys %{$inverted_index{$instance}})
			{
			$i = 0;
			open ($filein, "<$handle");
			{ local $/; $contents = <$filein>; }
			$contents =~ s/(\-)+/-/g;
			$contents =~ s/\s+/ /igsx;
			# BEWARE! To be improved
			while ($contents =~ /(.{0,$width}[^à-ÿ¢³'À-ß¡²a-zA-Z])($instance)(?'right'[^à-ÿ¢³'À-ß¡²a-zA-Z].{0,$width})/igs)
				{
				print FILEOUT "$handle\t$substitute{$query}\t$instance\t$1\t$2\t$+{right}\n";
				$i++;
				}
			close ($filein);
			unless ($i == $inverted_index{$instance}{$handle})
				{ print FILEOUT "The search results on $handle may be inconsistent: $inverted_index{$instance}{$handle} awaited, $i found.\n"; }
			}
		}
	}
close (FILEOUT);
