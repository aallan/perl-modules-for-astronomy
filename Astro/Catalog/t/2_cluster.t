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


# Write Catalog to Cluster File
# -----------------------------

my $in_name = File::Spec->catfile( File::Spec->tmpdir(), "input.cat" );
my $out_name = File::Spec->catfile( File::Spec->tmpdir(), "output.cat" );

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

my $catalog = new Astro::Catalog( Format => 'Cluster', File => $in_name );

#$catalog->write_catalog( Format => 'Cluster', File => $out_name );

my @mags = ( 'B', 'V' );
my @cols = ( 'B-R', 'B-V' );
$catalog->write_catalog(  Format => 'Cluster', File => $out_name, 
                          Magnitudes => \@mags, Colours => \@cols );


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
5 colours were created
B R V B-R B-V
A sub-set of USNO-A2: Field centre at RA 01 10 12.90, Dec +60 04 35.90, Search Radius 1 arcminutes 
00080  A  09 55 39.00  +60 07 23.60  0.000  0.000  16.4  0.4  0  16.1  0.1  0  16.3  0.3  0  0.3  0.05  0  0.1  0.02  0  
00081  B  10 44 57.00  +12 34 53.50  0.000  0.000  9.3  0.2  0  9.5  0.6  0  9.1  0.1  0  0.2  0.07  0  -0.2  0.05  0  
