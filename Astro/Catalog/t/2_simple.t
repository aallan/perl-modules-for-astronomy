# Astro::Catalog test harness

# strict
use strict;

#load test
use Test;
use File::Spec;
use Data::Dumper;
BEGIN { plan tests => 1 };

# load modules
use Astro::Catalog;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);


# Write Catalog to Simple File
# -----------------------------

my $in_name = File::Spec->catfile( File::Spec->tmpdir(), "simple-input.cat" );
my $out_name = File::Spec->catfile( File::Spec->tmpdir(), "simple-output.cat" );

# read from data block
my @buffer = <DATA>;
chomp @buffer;

# write to temporary file
unless ( open( FILE, ">$in_name" ) ) {
  print "Could not open $in_name\n";
  exit;
}  

foreach my $i ( 0 ... $#buffer ) {
   print FILE $buffer[$i] . "\n";
}   
close(FILE);

# Create Catalog Object
# ---------------------

my $catalog = new Astro::Catalog( Format => 'Simple', File => $in_name );

$catalog->write_catalog( Format => 'Simple', File => $out_name );

# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

END {
  # clean up after ourselves
  #print "# Cleaning up temporary files\n";
  #my @list = ( $in_name, $out_name );
  #print "# Deleting:@list\n";
  #unlink(@list); 
}        


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
# Catalog written automatically by class Astro::Catalog::IO::Simple
# on date Sun Jul 27 03:37:59 2003UT
# Origin of catalogue: <UNKNOWN>
A  09 55 39.00  +60 07 23.60 B1950 # This is a comment
B  10 44 57.00  +12 34 53.50 J2000 # This is another comment
