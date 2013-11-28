#! /usr/bin/perl -w
use locale;
use Getopt::Std;
use Storable;
use Array::Utils qw/intersect unique/;
use Benchmark;

# Autoflush mode on. Do not disable
$| = 1;
# Command line options: -w is left & right context width in tokens
getopts('w:');
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

# Erasing the previously written results file
unlink ("results.txt");

# Reading the list of subcorpora
print STDOUT "Reading the list of subcorpora...\t";
open (FILEIN, "<subcorpora.txt") or die "The list does not exist!\n";
while (<FILEIN>)
	{
	chomp;
	($id, $search) = split (/\t/, $_);
	if ($search == 1) { push @subcorpora, $id; }
	}
close (FILEIN);
print STDOUT "Done\n";

# Reading the list of queries
print STDOUT "Reading the list of queries...\t";
open (WORDLIST, "<wordlist.txt") or die "The list does not exist!\n";
while (<WORDLIST>)
	{
	chomp;
	@line = split (/\t/, $_);
	$id = shift @line;
	$queries{$id} = join ("\t", @line);
	}
close (WORDLIST);
print STDOUT "Done\n";

# Processing queries
foreach $sc (@subcorpora)
	{
	++$sc_count;
	print STDOUT "\n" . $sc_count . ": " . uc($alias{$sc}) . "\n";
	
	# Loading index
	print STDOUT "Loading index...\t";
	$hashref = retrieve("./index/index_" . $sc . ".dat") or die "The index does not exist!\n";
	%inverted_index = %{$hashref};
	print STDOUT "Done\n";

	print STDOUT "Searching index...\t";
	$findings = 0;
	%res = ();
	foreach $id (keys %queries)
		{
		# Parsing query into token conditions and span conditions
		$query = $queries{$id};
		@q = split (/\t/, $query);
		@tokens = ();
		@spans = ();
		foreach $i (0..$#q)
			{
			if ($i % 2 == 0) { push @tokens, $q[$i]; }
			else { push @spans, $q[$i]; }
			}
		# Computing sets of strings to match token conditions
		# TODO: if the intersection is empty, do not continue
		@lines = ();
		foreach $i (0..$#tokens)
			{
			%sets = ();
			($cond_w, $cond_l, $cond_g) = split (/\#/, $tokens[$i]);
			(@set_w, @set_l, @set_g) = ();
			# Chinese code begin
			# TODO: Rewrite in a more idiomatic way
			if ($cond_w)
				{
				foreach (keys %{$inverted_index{'w'}}) { if (/$cond_w/) { push @set_w, @{$inverted_index{'w'}{$_}}; } }
				++$sets{'w'};
				}
			if ($cond_l)
				{
				foreach (keys %{$inverted_index{'l'}}) { if (/$cond_l/) { push @set_l, @{$inverted_index{'l'}{$_}}; } }
				++$sets{'l'};
				}
			if ($cond_g)
				{
				foreach (keys %{$inverted_index{'g'}}) { if (/$cond_g/) { push @set_g, @{$inverted_index{'g'}{$_}}; } }
				++$sets{'g'};
				}
			@defined_sets = keys %sets;
			if (@defined_sets == 3) { @tmp = intersect(@set_w , @set_l); %{$lines[$i]} = map { $_ => 1 } intersect(@tmp, @set_g); }
			elsif ($sets{'w'} && $sets{'l'}) { %{$lines[$i]} = map { $_ => 1 } intersect(@set_w , @set_l); }
			elsif ($sets{'w'} && $sets{'g'}) { %{$lines[$i]} = map { $_ => 1 } intersect(@set_w , @set_g); }
			elsif ($sets{'l'} && $sets{'g'}) { %{$lines[$i]} = map { $_ => 1 } intersect(@set_l , @set_g); }
			elsif ($sets{'w'}) { %{$lines[$i]} = map { $_ => 1 } @set_w; }
			elsif ($sets{'l'}) { %{$lines[$i]} = map { $_ => 1 } @set_l; }
			elsif ($sets{'g'}) { %{$lines[$i]} = map { $_ => 1 } @set_g; }
			# Chinese code end
			}
		
		# KERNEL BEGIN
		# For each array of lines containing tokens which satisfy the respective token condition:
		#     Ц compute the array of lines located within the conditioned spans from it (example: (2, 9, 17) + [1..2] = (3, 4, 10, 11, 18, 19))
		#     Ц intersect it with the array of lines containing tokens which satisfy the next token condition
		#     Ц remember all satisfactory pairs, take their second elements and repeat with pairs of lines as hash keys (and so on)
		@output = map { [ $_ ] } keys %{$lines[0]};
		if (@spans)
			{
			foreach $i (0..$#spans)
				{
				@this_span = eval($spans[$i]);
				@current_iter = map { my @a = @{$_}; $a[$#a] } @output;
				%link = ();
				foreach $n (@current_iter)
					{ foreach $s (@this_span) { if (${$lines[$i+1]}{$n + $s}) { ++$link{$n}{$n + $s}; } } }
				@new_output = ();
				while (@output)
					{
					@group = @{shift @output};
					if ($link{$group[$#group]})
						{
						foreach $next (keys %{$link{$group[$#group]}})
							{
							@newgroup = (@group, $next);
							push @new_output, [ @newgroup ];
							}
						}
					}
				@output = @new_output;
				}
			}
		# KERNEL END

		if (@output) { @{$res{$id}} = @output; $findings = 1; }
		}

	unless ($findings) { print STDOUT "Nothing found!\n"; }
	else
		{
		print STDOUT "There are some matches!\nOutputting results...\t";
		
		# Loading corpus
		open ($corpus, "<./data/corpus_" . $sc . ".txt") or die "The corpus does not exist!\n";
		{ local $/; @data = split (/\n/, <$corpus>); }
		close ($corpus);

		# Loading metadata
		(%author, %title, %genre, %edition, %url_address) = ();
		open ($md, "<./metadata/metadata_" . $sc . ".txt") or die "The metadata file does not exist!\n";
		while (<$md>)
			{
			chomp;
			($fid, $fname, $a, $t, $g, $ed, $url) = split (/\t/, $_);
			$fname = ""; # unnecessary
# 			($a_name, $a_surname) = split (/\s/, $a);
#			$author{$fid} = substr($a_name, 0, 1) . ". " . $a_surname;
			$author{$fid} = $a;
			$title{$fid} = $t;
			$genre{$fid} = $g;
			$edition{$fid} = $ed;
			$url_address{$fid} = $url;
			}
		close ($md);

		# Printing formatted output
		open (FILEOUT, ">>results.txt");
		foreach $id (keys %res)
			{
			@lines = @{$res{$id}};
			foreach $tuple (@lines)
				{
				@found_tokens = map { $data[$_] } @{$tuple};
				%fids = ();
				foreach (0..$#found_tokens)
					{
					($fid, $tid, $wform, $lemma, $gram) = split (/\t/, $found_tokens[$_]);
					++$fids{$fid};
					if ($_ == 0) { $first_tid = $tid; }
					}
				if (scalar keys %fids == 1)
					{
					@f = keys %fids;
					$look_forward = ${$tuple}[$#{$tuple}] + $opt_w;
					if ($first_tid > $opt_w) { $look_behind = ${$tuple}[0] - $opt_w; }
					else { $look_behind = ${$tuple}[0] - $first_tid + 1; }
					@wseq = ();
					foreach (@data[$look_behind..$look_forward])
						{
						($fid, $tid, $wform, $lemma, $gram) = split (/\t/, $_);
						if ($fid == $f[0]) { push @wseq, $wform; }
						}
					$context_passport = $author{$fid} .  ". " . $title{$fid} . " [" . $genre{$fid} . "] // " . $edition{$fid};
					if ($url_address{$fid} ne "NONE") { $context_passport .= ". Ёлектронны тэкст: " . $url_address{$fid}; }
					$context_passport =~ s/\[{2}/[/g;
					$context_passport =~ s/\]{2}/]/g;
					$context_passport =~ s/[^\S\n]\[NONE\]//g;
					print FILEOUT join ("\t", ($id, join (" ", @wseq), $context_passport)) . "\n";
					}
				}
			}
		close (FILEOUT);
		
		print STDOUT "Done\n";
		}
	}