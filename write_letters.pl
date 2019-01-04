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
  my $cknoref = shift;

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
  my $nrec = @$daryref;
  print "Processing $nrec rows\n" if $opt{v};
  # e.g. 12-->6, 13-->7
  my $nrows = int(($nrec+1)/2);
  my $rows = '';
  for $i (0..$nrows-1) {
    my $date1 = $$daryref[$i];
    my $dola1 = $$doryref[$i];
    my $ckno1 = $$cknoref[$i];
    my $date2 = $$daryref[$nrows+$i];
    my $dola2 = $$doryref[$nrows+$i];
    my $ckno2 = $$cknoref[$nrows+$i];
    $rows .= "$date1 & $ckno1 & $dola1 & $date2 & $ckno2 & $dola2 \\\\ \n";
    $total += $dola1 + $dola2;
    print " + $dola1 + $dola2 --> $total\n" if $opt{v};
  }
  $totstr = sprintf "\\\$%.2f", $total;
  $rows .= "\\hline {\\bf Total} & & & & & {\\bf $totstr} \\\\ \n";
  $latex =~ s!ROWSGOHERE!$rows!;

  print "Writing $fname\n"  if $opt{v};
  spew($fname, $latex);
  print "pdflatex $fname\n" if $opt{v};
  `pdflatex $fname`;
  print "Done with '$n'\n"  if $opt{v};

  return $total;
}



use Getopt::Std;
%opt = (t=>'template.tex');
%opt = (a=>'addresses.csv');
getopts('hvt:a:', \%opt);

$usage  = "write_letters.pl [-a addr.csv] [-t templ.tex] giving.csv\n";
$usage .= " -a addresses.csv\n";
$usage .= " -t template.tex\n";
$usage .= " -v      verbose\n";
$usage .= " -h      help; print this message\n";
if ($opt{h}) {
  print $usage;
  exit;
}

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

$fname = $ARGV[0];
$csv = Text::CSV->new( {binary=>1} );
open $fh, "<:encoding(utf8)", $fname or die $fname.": $!";
#$csv->getline($fh); # skip ,"Type","Date",...
while ($row = $csv->getline($fh)) {

  if ($row->[0] =~ /Total/) {
    $stophere=1
  }

  if ($row->[4] =~ /Trinity Psalter Hymnal/) {
    print "Skipping hymnal record for $name\n";
    $hymnal += $row->[9];
  }

  # Current name is done, process data to create a letter
  elsif ($row->[0] eq "Total $name") {
    $total = $row->[-2] - $hymnal; # this is what the total should be
    $check = process($name, \@dates, \@dollas, \@cknos);
    $error = abs($check - $total);
    if ($error >= 0.01) { # less than a penny is just roundoff error
      $stophere=1;
      die "Total mismatch $check != $total\n";
    }

    @dates = @dollas = @cknos = ();# reinit with empty data
    $hymnal = 0;
  }

  # First row for new name
  elsif ($row->[0] ne '' and $row->[1] eq '' and $row->[2] eq ''
                         and $row->[3] eq '' and $row->[4] eq '')
  {
    $name = $row->[0];             # we found a new name
    @dates = @dollas = @cknos = ();# start with empty data
    $hymnal = 0;
  }

  # Another record for current name
  elsif ($row->[2] =~ m!(\d\d/\d\d/\d\d\d\d)!) {
    push @dates,  $1;
    push @dollas, $row->[9];
    push @cknos,  $row->[11]
  }
}
