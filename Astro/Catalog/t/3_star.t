# Astro::Catalog::Star test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 16 };

# load modules
use Astro::Catalog::Star;
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# magnitude and colour hashes
my %mags = ( R => '16.1', B => '16.4', V => '16.3' );
my %mag_error = ( R => '0.1', B => '0.4', V => '0.3' );
my %colours = ( 'B-V' => '0.1', 'B-R' => '0.3' );
my %col_error = ( 'B-V' => '0.02', 'B-R' => '0.05' );

# create a star
my $star = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                     RA         => '17.55398',
                                     Dec        => '60.07673',
                                     Magnitudes => \%mags,
                                     MagErr     => \%mag_error,
                                     Colours    => \%colours,
                                     ColErr     => \%col_error,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );

# FILTERS AND MAGNITUDES
# ----------------------
                                     
# grab input filters
my @input;
for my $key ( sort keys %mags ) {
   push ( @input, $key );
}

# grab used filters
my @filters = $star->what_filters();

# report to user
print "# input  = @input\n";
print "# output = @filters\n";

# compare input and returned filters
for my $i (0 .. $#filters) {
 ok( $filters[$i], $input[$i] );
 ok( $star->get_magnitude($filters[$i]), $mags{$filters[$i]} );
 ok( $star->get_errors($filters[$i]), $mag_error{$filters[$i]} );
}

# grab input colours
my @cols;
for my $key ( sort keys %colours ) {
   push ( @cols, $key );
}

# grab used filters
my @cols2 = $star->what_colours();

# report to user
print "# input  = @cols\n";
print "# output = @cols2\n";

# compare input and returned filters
for my $i (0 .. $#cols2) {
 ok( $cols[$i], $cols2[$i] );
 ok( $star->get_colour($cols2[$i]), $colours{$cols2[$i]} );
 ok( $star->get_colourerr($cols2[$i]), $col_error{$cols2[$i]} );
}



# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

# Dump star object to screen
#print Dumper($star);

# T I M E   A T   T H E   B A R ---------------------------------------------
exit;                                     
