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


$template = slurp('template.tex');


sub process {
  my $n       = shift;
  my $daryref = shift;
  my $doryref = shift;

  if ($n eq "") {
    return;
  }

  my $latex = $template;
  $latex =~ s!NAMEGOESHERE!$n!;

  my $half = int(@$daryref / 2);
  my $rows = '';
  for $i (0..$half) {
    my $date1 = $$daryref[$i];
    my $dola1 = $$doryref[$i];
    my $date2 = $$daryref[$half+$i];
    my $dola2 = $$doryref[$half+$i];
    $rows .= "$date1 & $dola1 & $date2 & $dola2 \\\\ \n";
  }
  $latex =~ s!ROWSGOHERE!$rows!;

  my $fname = sprintf "letter%d.tex", $letterno++;
  spew($fname, $latex);
  `pdflatex $fname`;
}


while (<>) {
  if (/Type.*Date.*Num.*Memo/) {
    next;
  }

  if (m!^\"(.*?)\",,,,,!) {
    $new_name = $1;

    process($name, \@dates, \@dollas);

    $name = $new_name;
    @dates = @dollas = ();
  }

  elsif (m!,\"(\d\d/\d\d/\d\d\d\d)\",.*,(\-?\d+\.\d\d)(\s*)$!) {
    $date  = $1;
    $dolla = $2;
    push @dates,  $date;
    push @dollas, $dolla;
  }
}

# and one last time for the last donor
process($name, \@dates, \@dollas);
