# Astro::Catalog test harness

# strict
use strict;

#load test
use Test;
use File::Spec;
use Data::Dumper;
BEGIN { plan tests => 11 };

# load modules
use Astro::Catalog;
use Astro::Catalog::Star;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# setup environemt
my dir = File::Spec->tmpdir();

my @star;

# STAR 1
# ------

# magnitude and colour hashes
my %mags1 = ( R => '16.1', B => '16.4', V => '16.3' );
my %mag_error1 = ( R => '0.1', B => '0.4', V => '0.3' );
my %colours1 = ( 'B-V' => '0.1', 'B-R' => '0.3' );
my %col_error1 = ( 'B-V' => '0.02', 'B-R' => '0.05' );

# create a star
$star[0] = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                      RA         => '09 55 39',
                                      Dec        => '+60 07 23.6',
                                      Magnitudes => \%mags1,
                                      MagErr     => \%mag_error1,
                                      Colours    => \%colours1,
                                      ColErr     => \%col_error1,
                                      Quality    => '0',
                                      GSC        => 'FALSE',
                                      Distance   => '0.09',
                                      PosAngle   => '50.69',
                                      Field      => '00080' );

# STAR 2
# ------

# magnitude and colour hashes
my %mags2 = ( R => '9.5', B => '9.3', V => '9.1' );
my %mag_error2 = ( R => '0.6', B => '0.2', V => '0.1' );
my %colours2 = ( 'B-V' => '-0.2', 'B-R' => '0.2' );
my %col_error2 = ( 'B-V' => '0.05', 'B-R' => '0.07' );

# create a star
$star[1] = new Astro::Catalog::Star( ID         => 'U1500_01194795',
                                     RA         => '10 44 57',
                                     Dec        => '+12 34 53.5',
                                     Magnitudes => \%mags2,
                                     MagErr     => \%mag_error2,
                                     Colours    => \%colours2,
                                     ColErr     => \%col_error2,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.08',
                                     PosAngle   => '12.567',
                                     Field      => '00081' );
                                     
# Create Catalog Object
# ---------------------

my $catalog = new Astro::Catalog( RA     => '01 10 12.9',
                                  Dec    => '+60 04 35.9',
                                  Radius => '1',
                                  Stars  => \@star );

# Write Catalog to Cluster File
# -----------------------------

my $file_name = File::Spec->catfile( $dir, "temporary.cat" );

# write it to /tmp/temporary.cat under UNIX
$catalog->write_catalog( Format => 'Cluster', File => $file_name );

# Compare output file and DATA block
# ----------------------------------

# data block
my @buffer = <DATA>;
chomp @buffer;

# temporary file
open( FILE, $file_name );
my @file = <FILE>;
chomp @file;
close(FILE);

for my $i (0 .. $#buffer) {
   ok( $file[$i], $buffer[$i] );
}

# Create another catalog object from the Cluster file
# ---------------------------------------------------

my $cluster = new Astro::Catalog( RA      => '01 10 12.9',
                                  Dec     => '+60 04 35.9',
                                  Radius  => '1',
                                  File => $file_name,
				  Format => 'Cluster',
				);

# Write Catalog to Cluster File
# -----------------------------

$file_name = File::Spec->catfile( $dir, "other.cat" );

# write it to /tmp/other.cat under UNIX
$cluster->write_catalog( Format => 'Cluster', File => $file_name );

# Compare output file and DATA block
# ----------------------------------

# clean out @file
@file = [];

# temporary file
open( FILE, $file_name );
@file = <FILE>;
chomp @file;
close(FILE);

for my $i (0 .. $#buffer) {
   ok( $file[$i], $buffer[$i] );
}


# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

# Dump catalog object to screen
#print Dumper($catalog);
#print Dumper($cluster);

#END {
  # clean up after ourselves
#  print "# Cleaning up temporary files\n";
#  print "# Deleting: $file_name\n";
#  my @list = ( $file_name );
#  unlink(@list); 
#}        


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
5 colours were created
B R V B-R B-V
A sub-set of USNO-A2: Field centre at RA 01 10 12.90, Dec +60 04 35.90, Search Radius 1 arcminutes 
00080  U1500_01194794  09 55 39.00  +60 07 23.60  0.000 0.000 16.4  0.4  0  16.1  0.1  0  16.3  0.3  0  0.3  0.05  0  0.1  0.02  0  
00081  U1500_01194795  10 44 57.00  +12 34 53.50  0.000 0.000 9.3  0.2  0  9.5  0.6  0  9.1  0.1  0  0.2  0.07  0  -0.2  0.05  0  
