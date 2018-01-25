#! /bin/perl

sub process {
  my $n       = shift;
  my $daryref = shift;
  my $doryref = shift;

  if ($n eq "") {
    return;
  }

  print "Dear $n, you gave:\n";
  for my $i (0..$#$daryref) {
    printf "%s\t%f\n", $$daryref[$i], $$doryref[$i];
  }
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
