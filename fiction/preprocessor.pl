#! /usr/bin/perl -w
use locale;
use Encode;

open (FILEIN, "<dirlist.txt");
while (<FILEIN>) { chomp; push @dirlist, $_; }
close (FILEIN);

foreach (@dirlist)
	{
	%contents = ();
	($current_dir, $output_dir) = ($_ . "r/", $_ . "t/");
	opendir (INPUT, $current_dir);
	while (defined ($handle = readdir(INPUT)))
		{
		if ($handle =~ /\.txt$/)
			{
			($inhandle, $outhandle) = ($current_dir . $handle, $output_dir . $handle);
			$outhandle =~ s/^\.|\.txt$//g;
			open (FILEIN, "<$inhandle"); { local $/; $file = <FILEIN>; } close (FILEIN);
			Encode::from_to($file, 'cp1251', 'utf8');
			$contents{$outhandle} = $file;
			}
		}
	open (FILEOUT, ">fulldir.txt");
	foreach (keys %contents) { print FILEOUT "$_\n$contents{$_}\n"; }
	close (FILEOUT);
	
	print "Tokenizing all files at once...\n";
	system("perl utf8-tokenize.pl -f fulldir.txt > tokenized.txt");
	open (FILEIN, "<tokenized.txt"); { local $/; $contents = <FILEIN>; } close (FILEIN);
	Encode::from_to($contents, 'utf8', 'cp1251');
	open (FILEOUT, ">tokenized.txt"); print FILEOUT $contents; close (FILEOUT);
	
	open (FILEIN, "<tokenized.txt");
	while (<FILEIN>)
		{
		chomp;
		if (/\/t/) { close (FILEOUT); open (FILEOUT, ">." . $_ . ".txt"); }
		else { print FILEOUT $_ . "\n"; }
		}
	close (FILEIN);

	unlink("fulldir.txt");
	unlink("tokenized.txt");
	}
