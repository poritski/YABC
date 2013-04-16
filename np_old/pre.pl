#! /usr/bin/perl -w
use locale;
use Encode;

# Read a dictionary-based list of wordforms
%correct = ();
open (FILEIN, "<wforms_full.txt");
while (<FILEIN>)
	{
	chomp;
	++$correct{$_};
	}
close (FILEIN);

# Read a hand-crafted list of substitutions
%subst = ();
open (FILEIN, "<substitution.txt");
while (<FILEIN>)
	{
	chomp;
	($old, $new) = split (/\t/, $_);
	$subst{$old} = $new;
	}
close (FILEIN);

# Read an experimental list of pairwise substitutions, prepared by glue.pl
open (FILEIN, "<glue.txt");
while (<FILEIN>)
	{
	chomp;
	($a, $b, $new, $f) = split (/\t/, $_);
	$glue{$a}{$b} = $new;
	}
close (FILEIN);

# Read an experimental list of substitutions, prepared by lev1.pl (beware, no proofreading!)
# =pod
open (FILEIN, "<suggestions_EXPERIMENTAL.txt");
while (<FILEIN>)
	{
	chomp;
	($old, $new) = split (/\t/, $_);
	$subst{$old} = $new;
	}
close (FILEIN);
# =cut

$recognized = 0;
$nonrecognized = 0;
%hapax = ();

%contents = ();
($current_dir, $output_dir) = ("./r/", "./t/");
opendir (INPUT, $current_dir) or die "No such directory: $current_dir";
while (defined ($handle = readdir(INPUT)))
	{
	unless ($handle =~ /^\.{1,2}$/)
		{
		print "Reading $handle...\n";
		($inhandle, $outhandle) = ($current_dir . $handle, $output_dir . $handle);
		$outhandle =~ s/^\.|\.txt$//g;
		open (FILEIN, "<$inhandle");
		{ local $/; $file = <FILEIN>; }
		close (FILEIN);
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

open (FILEIN, "<tokenized.txt"); { local $/; $contents = <FILEIN>; } close (FILEIN);
@lines = split (/\n/, $contents);
for $idx (0..$#lines)
	{
	$line = $lines[$idx];
	if ($line =~ /^\/t/)
		{
		close (FILEOUT);
		open (FILEOUT, ">." . $line . ".txt");
		print "Writing $line...\n";
		}
	else
		{
		if ($idx < $#lines && $glue{$line}{$lines[$idx+1]})
			{ ++$recognized; print FILEOUT $glue{$line}{$lines[$idx+1]} . "\n"; }
		else
			{
			($a1, $a2) = (lc($line), lc($line));
			$a2 =~ s/^Ґ/у/g;
			# Case 1: the wordform is known (or is an integer)
			if (($line =~ /^\d+$/g) or ($correct{$line})
				or ($correct{$a1}) or ($correct{$a2})) { ++$recognized; print FILEOUT $line . "\n"; }
			# Case 2: the wordform can be substituted for something known
			elsif ($subst{lc($line)}) { ++$recognized; print FILEOUT $subst{lc($line)} . "\n"; }
			elsif ($subst{$line}) { ++$recognized; print FILEOUT $subst{$line} . "\n"; }
			else
				{
				$line = refine($line);
				# Case 3: refined wordform is known
				if (($correct{$line}) or ($correct{lc($line)})) { ++$recognized; print FILEOUT $line . "\n"; }
				# Case 4: refined wordform can be substituted for something known
				elsif ($subst{lc($line)}) { ++$recognized; print FILEOUT $subst{lc($line)} . "\n"; }
				elsif ($subst{$line}) { ++$recognized; print FILEOUT $subst{$line} . "\n"; }
				# Case 5: refining doesn't help
				else { ++$hapax{$line}; ++$nonrecognized; print FILEOUT $line . "\n"; }
				}
			}
		}
	}
close (FILEOUT);

unlink("fulldir.txt");
unlink("tokenized.txt");

open (FILEOUT, ">hapax.txt");
foreach $w (sort {$hapax{$b} <=> $hapax{$a}} keys %hapax) { print FILEOUT "$w\t$hapax{$w}\n"; }
close (FILEOUT);

print STDOUT "Done!\nThe good news is that $recognized tokens have been recognized :)\nThe bad news is that $nonrecognized tokens have not been recognized :(\n";

##################################

sub refine
	{
	$s = shift @_;

	# с => е
	$s =~ s/(м|л)с(р|н|с)/$1е$2/g;
	$s =~ s/с(Ґ|й)/е$1/g;
	$s =~ s/всдн/ведн/g;

	# л => д
	$s =~ s/лз/дз/g;

	# а <=> в, л
	$s =~ s/аай/вай/g;
	$s =~ s/(м|р|ч)вс/$1ас/g;
	$s =~ s/в(Ґ|кт)/а$1/g;
	$s =~ s/клм/кам/g;
	$s =~ s/асв$/аса/g;
	$s =~ s/вдн(в|ы)/адн$1/g;
	$s =~ s/квгв/кага/g;
	$s =~ s/пврт/парт/g;
	$s =~ s/Ґаа/Ґва/g;

	# € => а, в
	$s =~ s/(т|ч|р)€/$1а/g;
	$s =~ s/д€(р|Ґ)/да$1/g;
	$s =~ s/€ы(к|н|х)/вы$1/g;
	$s =~ s/€Єс(к|ц)/вЄс$1/g;

	# ≥≥ => several letters
	$s =~ s/Ґ≥≥/Ґн/g;
	$s =~ s/^≥≥р/пр/g;
	$s =~ s/ас≥≥≥/асц≥/g;

	# э => з
	$s =~ s/≥эа/≥за/g;
	$s =~ s/дэ(в|е|≥|€)/дз$1/g;
	$s =~ s/аэ(в|е|о)/аз$1/g;
	$s =~ s/э\'(€|ю)/з\'$1/g;
	$s =~ s/эо(Ґ|н|в|л|р)/зо$1/g;
	$s =~ s/(^|[а€уҐюоеы])эа(Ґ|н|в|л|р)/$1зо$2/g;
	$s =~ s/рв(э|з)/раз/g;
	$s =~ s/\'сэ/'ез/g;

	# varia
	$s =~ s/ь≥/ы/g;
	$s =~ s/≥лыч/≥ль≥ч/ig;
	$s =~ s/лы≥/льн/g;
	$s =~ s/^вела(р|з)/бела$1/g;
	$s =~ s/^вела(е|л|ю|нн)/веда$1/g;
	$s =~ s/кнмнн/каман/g;
	$s =~ s/\-//g;

	return $s;
	}