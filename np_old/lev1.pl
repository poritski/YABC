#! /usr/bin/perl -w
use locale;
use List::Util qw/min/;

# Read a dictionary-based list of wordforms
%correct = ();
open (FILEIN, "<wforms_full.txt");
while (<FILEIN>)
	{
	chomp;
	++$correct{$_};
	}
close (FILEIN);

# Read all permitted alternations (as a graph)
%alt = ();
%coalt = ();
open (FILEIN, "<alternations.txt");
while (<FILEIN>)
	{
	chomp;
	($a, $b) = split (/\t/, $_);
	$alt{$a}{$b} = 1;
	$coalt{$b}{$a} = 1;
	}
close (FILEIN);

# Read a list of (sufficiently long) hapax wordforms which have never been recognized
open (FILEIN, "<hapax.txt");
while (<FILEIN>)
	{
	chomp;
	($w, $f) = split (/\t/, $_);
	if (length($w) > 5) { push @suspended, $w; }
	}
close (FILEIN);

# Main loop
open (FILEOUT, ">suggestions_lev1.txt");
foreach $s (@suspended)
	{
	@tmp = ();
	foreach $pos (0..length($s)-1)
		{
		$single = substr($s, $pos, 1);
		foreach $cand (keys %{$alt{$single}}, keys %{$coalt{$single}})
			{
			$copy = $s;
			substr($copy, $pos, 1) = $cand;
			if ($correct{$copy} || $correct{lc($copy)}) { push @tmp, $copy; }
			}
		$pair = substr($s, $pos, 2);
		foreach $cand (keys %{$alt{$pair}}, keys %{$coalt{$pair}})
			{
			$copy = $s;
			substr($copy, $pos, 2) = $cand;
			if ($correct{$copy} || $correct{lc($copy)}) { push @tmp, $copy; }
			}
		}
	if (@tmp)
		{
		@u = unique(@tmp);
		if ($#u == 0) { print FILEOUT $s . "\t" . $u[0] . "\n"; }
		}
	}
close (FILEOUT);

sub unique
	{
	my %hash = ();
	foreach (@_) { $hash{$_}++; }
	return sort keys %hash;
	}