#! /bin/perl

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
  $n =~ s!\&!and!;

  my $ndate = @$daryref;
  my $ndoll = @$doryref;
  my $fname = sprintf "letter%d.tex", $letterno++;
  print "Processing $ndate,$ndoll dates,dollars for '$n' --> $fname\n";

  my $latex = $template;
  $latex =~ s!NAMEGOESHERE!$n!;

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
%opt = ();
getopts('hv', \%opt);

$usage  = "write_letters.pl giving.csv addresses.csv\n";
$usage .= " -v      verbose\n";
$usage .= " -h      help; print this message\n";


$template = slurp('template.tex');



while (<>) {
  next if /Type.*Date.*Num.*Memo/;
  next if /^\"total/i;
  if (/hymnal/i) {
    print "Skipping hymnal record for $name\n";
    next;
  }

  if (m!^\"(.*?)\",,,,,!) {
    $new_name = $1;

    process($name, \@dates, \@dollas);

    $name = $new_name;
    @dates = @dollas = ();
  }

  elsif (m!,\"(\d\d/\d\d/\d\d\d\d)\"!) { #,.*,(\-?\d+\.\d\d)(\s*)$!) {
    $date  = $1;
    push @dates,  $date;

    $dolla = (split /,/)[-3];
    push @dollas, $dolla;
  }
}

# and one last time for the last donor
process($name, \@dates, \@dollas);
