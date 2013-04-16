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

%seen = ();
$current_dir = "./t/";
opendir (INPUT, $current_dir) or die "No such directory: $current_dir";
while (defined ($handle = readdir(INPUT)))
	{
	unless ($handle =~ /^\.{1,2}$/)
		{
		print "Working on $handle...\n";
		$inhandle = $current_dir . $handle;
		@contents = ();
		open (FILEIN, "<$inhandle");
		while (<FILEIN>)
			{
			chomp;
			push @contents, $_;
			}
		close (FILEIN);
		for $i (0..$#contents-1)
			{
			if (length($contents[$i]) > 1 && length($contents[$i+1]) > 1 && !$correct{lc($contents[$i])} && !$correct{lc($contents[$i])})
				{
				$hyp = $contents[$i] . $contents[$i+1];
				($a1, $a2) = (lc($hyp), lc($hyp));
				$a2 =~ s/^Ґ/у/g;
				# Case 1: the wordform is known (or is an integer)
				if (($correct{$hyp}) or ($correct{$a1}) or ($correct{$a2}))
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $hyp}; }
				# Case 2: the wordform can be substituted for something known
				elsif ($subst{lc($hyp)})
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{lc($hyp)}}; }
				elsif ($subst{$hyp})
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{$hyp}}; }
				else
					{
					$hyp = refine($hyp);
					# Case 3: refined wordform is known
					if (($correct{$hyp}) or ($correct{lc($hyp)}))
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $hyp}; }
					# Case 4: refined wordform can be substituted for something known
					elsif ($subst{lc($hyp)})
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{lc($hyp)}}; }
					elsif ($subst{$hyp})
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{$hyp}}; }
					}
				}
			}
		}
	}

open (FILEOUT, ">glue.txt");
foreach (keys %seen) { print FILEOUT "$_\t$seen{$_}\n"; }
close (FILEOUT);

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