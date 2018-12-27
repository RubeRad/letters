#! /bin/perl

use Text::CSV; # sudo cpan Text::CSV

sub slurp {
  my @lns;
  for (@_) {
    if (-r) {
      open FILE, $_;
      push @lns, (<FILE>);
      close FILE;
    } else {
      my @files = glob;
      for (@files) {
        open FILE, $_;
        push @lns, (<FILE>);
        close FILE;
      }
    }
  }

  return wantarray ? @lns : (join '', @lns);
}

sub spew {
  my $fname = shift;
  open OUT, ">$fname" or die "Can't write to '$fname'";
  for (@_) { print OUT }
  close OUT;
}


sub process {
  my $n       = shift;
  my $daryref = shift;
  my $doryref = shift;

  if ($n eq "") {
    return;
  }

  my $ndate = @$daryref;
  my $ndoll = @$doryref;
  my $fname = sprintf "letter%d.tex", $letterno++;
  $thename = $nam{$n};
  $thename =~ s!\&!and!;
  print "Processing $ndate,$ndoll dates,dollars for '$n' ($thename) --> $fname\n";

  my $latex = $template;
  $latex =~ s!NAMEGOESHERE!$thename!;

  $a = $add{$n};
  $c = $cty{$n};
  if ($a and $c) { $address = "\\\\ $a \\\\ $c" }
  else           { $address = ""                }
  $address =~ s!\#!\\\#!;
  $latex =~ s!ADDRESSGOESHERE!$address!;

  my $total = 0;
  my $half = int(@$daryref / 2);
  my $rows = '';
  for $i (0..$half) {
    my $date1 = $$daryref[$i];
    my $dola1 = $$doryref[$i];
    my $date2 = $$daryref[$half+$i];
    my $dola2 = $$doryref[$half+$i];
    $rows .= "$date1 & $dola1 & $date2 & $dola2 \\\\ \n";
    $total += $dola1 + $dola2;
  }
  $totstr = sprintf "\\\$%.2f", $total;
  $rows .= "\\hline {\\bf Total} & & & {\\bf $totstr} \\\\ \n";
  $latex =~ s!ROWSGOHERE!$rows!;

  print "Writing $fname\n"  if $opt{v};
  spew($fname, $latex);
  print "pdflatex $fname\n" if $opt{v};
  `pdflatex $fname`;
  print "Done with '$n'\n"  if $opt{v};
}



use Getopt::Std;
%opt = (t=>'template.tex');
%opt = (a=>'addresses.csv');
getopts('hvt:a:', \%opt);

$usage  = "write_letters.pl giving.csv addresses.csv\n";
$usage .= " -a addresses.csv\n";
$usage .= " -t template.tex\n";
$usage .= " -v      verbose\n";
$usage .= " -h      help; print this message\n";


$template  = slurp($opt{t});

$csv = Text::CSV->new( {binary=>1} );
open $fh, "<:encoding(utf8)", $opt{a} or die $opt{a}.": $!";
while ($row = $csv->getline($fh)) {
  $n       = $row->[2];
  $nam{$n} = $row->[17];
  $add{$n} = $row->[18];
  $cty{$n} = $row->[19];
}
close $fh;
$name = $new_name = '';

$fname = $ARGV[0];
$csv = Text::CSV->new( {binary=>1} );
open $fh, "<:encoding(utf8)", $fname or die $fname.": $!";
while ($row = $csv->getline($fh)) {
  next if $row->[0] eq '' and $row->[1] eq 'Type';
  next if $row->[0] =~ /^total/i;
  if ($row->[4] =~ /Trinity Psalter Hymnal/) {
    print "Skipping hymnal record for $name\n";
    next;
  }

  $stophere=1;
  if ($row->[0] ne '' and $row->[1] eq '' and $row->[2] eq ''
                      and $row->[3] eq '' and $row->[4] eq '')
  {
    $new_name = $row->[0];             # we found a new name
    process($name, \@dates, \@dollas); # process previous

    $name = $new_name;                 # reinit with new name
    @dates = @dollas = ();
  }

  elsif ($row->[2] =~ m!(\d\d/\d\d/\d\d\d\d)!) {
    $date  = $1;
    push @dates,  $date;

    $dolla = $row->[8];
    push @dollas, $dolla;
  }
}

# and one last time for the last donor
process($name, \@dates, \@dollas);
