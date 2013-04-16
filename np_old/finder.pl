#! /usr/bin/perl -w
use locale;
use Storable;
use Encode;
use List::Util;

$width = 10; # left & right context width in tokens

$hashref = retrieve('index.dat');
%inverted_index = %{$hashref};

open (WORDLIST, "<wordlist.txt");
while (<WORDLIST>)
	{
	chomp;
	unless (/^\#/) # except those queries which are commented out
		{
		($query, $signature) = ($_, $_); # by default
		if (/\t/) { ($query, $signature) = split (/\t/, $_); } # queries with IDs
		push @queries, $query;
		$substitute{$query} = $signature;
		}
	}
close (WORDLIST);

# Only single-word queries are currently served
%relevant = ();
foreach $query (@queries)
	{
	foreach (grep { /(^|\-)$query(\-|$)/ } keys %inverted_index) # HERE BE DRAGONS!!!
		{ ++$relevant{$_}{$substitute{$query}}; }
	}
@ambiguous = grep { scalar (keys %{$relevant{$_}}) > 1 } keys %relevant;
if (@ambiguous) { print "The following tokens are matched by more than one query:\n" . join ("\n", @ambiguous); }

# Now let's speed up the search
@actual = keys %relevant;
%files_to_open = ();
foreach $token (@actual)
	{
	@src_queries = keys %{$relevant{$token}};
	foreach $location (keys %{$inverted_index{$token}})
		{
		($file, $line) = split (/\t/, $location);
		foreach (@src_queries) { ++$files_to_open{$file}{$line - 1 . "\t" . $_}; }
		}
	}

open (FILEOUT, ">results.txt");
foreach $f (keys %files_to_open)
	{
	open (DATA, "<$f");
	{ local $/; $contents = <DATA>; }
	close (DATA);
	@lines = split (/\n/, $contents);
	foreach $pair (keys %{$files_to_open{$f}})
		{
		($l, $id) = split (/\t/, $pair);
		if ($l - $width < 0) { $start = 0; }
		else { $start = $l - $width; }
		if ($l + $width > $#lines) { $finish = $#lines; }
		else { $finish = $l + $width; }
		print FILEOUT join ("\t", ($f, $id, $lines[$l], join (" ", @lines[$start..$l-1]), $lines[$l], join (" ", @lines[$l+1..$finish]))) . "\n";
		}
	}
close (FILEOUT);