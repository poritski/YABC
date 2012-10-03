#! /usr/bin/perl -w
use locale;
use Storable;

%inverted_index = ();
%wforms_count = ();

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
			while (<ITEM>)
				{
				chomp;
				$_ =~ s/[^à-ÿ¢¸³'À-ß¡¨²a-zA-Z0-9\-]/ /g;
				$_ =~ s/\s+/ /g;
				@wforms = map { unless ($_ eq "") { lc($_); } } split (" ", $_);
				foreach (@wforms) { $inverted_index{$_}{$inhandle}++; }
				$wforms_count{$inhandle} += scalar (@wforms);
				}
			close (ITEM);
			}
		}
	}

store \%inverted_index, 'index_regex.dat';

open (FILEOUT, ">wforms_count.txt");
foreach (keys %wforms_count) { print FILEOUT "$_\t$wforms_count{$_}\n"; }
close (FILEOUT);