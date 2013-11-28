#! /usr/bin/perl -w
use locale;
use Storable;

# Autoflush mode on. Do not disable
$| = 1;

print STDOUT "Indexing old newspapers...\t";

%inverted_index = ();
%words = ();

open (FILEIN, "<dirlist.txt");
while (<FILEIN>) { chomp; push @dirlist, $_; }
close (FILEIN);

foreach $current_dir (@dirlist)
	{
	opendir (INPUT, $current_dir);
	while (defined ($handle = readdir(INPUT)))
		{
		unless ($handle =~ /^\.{1,2}$/)
			{
			$inhandle = $current_dir . $handle;
			open (ITEM, "<$inhandle");
			$line_counter = 0;
			while (<ITEM>)
				{
				++$line_counter;
				chomp;
				++$inverted_index{$_}{$inhandle . "\t" . $line_counter};
				++$words{$_};
				}
			close (ITEM);
			}
		}
	}

store \%inverted_index, 'index.dat';

open (FILEOUT, ">wforms.txt");
foreach (keys %words) { print FILEOUT "$_\t$words{$_}\n"; }
close (FILEOUT);

print STDOUT "Done\n";