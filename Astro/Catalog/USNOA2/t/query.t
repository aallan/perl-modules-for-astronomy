# Astro::Catalog::USNOA2::Query test harness

# strict
use strict;

#load test
use Test;
use Math::Libm qw(:all);
use Data::Dumper;
BEGIN { plan tests => 36 };

# load modules
use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Catalog::USNOA2::Query;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# Grab USNO-A2 sample from the DATA block
# ---------------------------------------
my @buffer = <DATA>;
chomp @buffer;

# test catalog
my $catalog_data = new Astro::Catalog();

# create a temporary object to hold stars
my $star;
  
# Parse data block
# ----------------
foreach my $line ( 0 .. $#buffer ) {
                      
   # split each line
   my @separated = split( /\s+/, $buffer[$line] );
            
   # check that there is something on the line
   if ( defined $separated[0] ) {
              
       # create a temporary place holder object
       $star = new Astro::Catalog::Star();            
           
       # ID
       my $id = $separated[2];
       $star->id( $id );
       #print "# ID $id star $line\n";      
       
       # RA
       my $objra = "$separated[3] $separated[4] $separated[5]";
       $star->ra( $objra );
              
       # Dec
       my $objdec = "$separated[6] $separated[7] $separated[8]";
       $star->dec( $objdec );
              
       # R Magnitude
       my %r_mag = ( R => $separated[9] );
       $star->magnitudes( \%r_mag );
              
       # B Magnitude
       my %b_mag = ( B => $separated[10] );
       $star->magnitudes( \%b_mag );
              
       # Quality
       my $quality = $separated[11];
       $star->quality( $quality );
              
       # Field
       my $field = $separated[12];
       $star->field( $field );
              
       # GSC
       my $gsc = $separated[13];
       if ( $gsc eq "+" ) {
          $star->gsc( "TRUE" );
       } else {
          $star->gsc( "FALSE" );
       }
              
       # Distance
       my $distance = $separated[14];
       $star->distance( $distance );
              
       # Position Angle
       my $pos_angle = $separated[15];
       $star->posangle( $pos_angle );

    }
             
    # Push the star into the catalog
    # ------------------------------
    $catalog_data->pushstar( $star );
           
           
    # Calculate error
    # ---------------
    
    my ( $power, $delta_r, $delta_b );
                      
    # delta.R
    $power = 0.8*( $star->get_magnitude( 'R' ) - 19.0 );
    $delta_r = 0.15*sqrt( 1.0 + pow( 10.0, $power ) );
           
    # delta.B
    $power = 0.8*( $star->get_magnitude( 'B' ) - 19.0 );
    $delta_b = 0.15*sqrt( 1.0 + pow( 10.0, $power ) );
           
    # mag errors
    my %mag_errors = ( B => $delta_b,  R => $delta_r );
    $star->magerr( \%mag_errors );
           
    # calcuate B-R colour and error
    # -----------------------------
           
    my $b_minus_r = $star->get_magnitude( 'B' ) - 
                    $star->get_magnitude( 'R' );
                           
    my %colours = ( 'B-R' => $b_minus_r );
    $star->colours( \%colours );
           
    # delta.(B-R)
    my $delta_bmr = sqrt( pow( $delta_r, 2.0 ) + pow( $delta_b, 2.0 ) );
           
    # col errors
    my %col_errors = ( 'B-R' => $delta_bmr );
    $star->colerr( \%col_errors );

}

# field centre
$catalog_data->fieldcentre( RA => '01 10 12.9', Dec => '+60 04 35.9', Radius => '1' );


# Grab comparison from ESO/ST-ECF Archive Site
# --------------------------------------------

my $usno_byname = new Astro::Catalog::USNOA2::Query( Target => 'HT Cas',
                                                     Radius => '1' );
                                                     
print "# Connecting to ESO/ST-ECF USNO-A2 Catalogue\n";
my $catalog_byname = $usno_byname->querydb();
print "# Continuing tests\n";

# C O M P A R I S O N ------------------------------------------------------

# check sizes
print "# DAT has " . $catalog_data->sizeof() . " stars\n";
print "# NET has " . $catalog_byname->sizeof() . " stars\n";

ok( $catalog_data->sizeof(), $catalog_byname->sizeof() );

# grab the 1st star in both catalogues
# ------------------------------------
my $star_dat = $catalog_data->starbyindex( 0 );
my $star_net = $catalog_byname->starbyindex( 0 );

ok( $star_dat->id(), $star_net->id() );
ok( $star_dat->ra(), $star_net->ra() );
ok( $star_dat->dec(), $star_net->dec() );

my @dat_filters = $star_dat->what_filters();
my @net_filters = $star_net->what_filters();
foreach my $filter ( 0 ... $#net_filters ) {
   ok( $dat_filters[$filter], $net_filters[$filter] );
   ok( $star_dat->get_magnitude($dat_filters[$filter]),
       $star_net->get_magnitude($net_filters[$filter]) );
   ok( $star_dat->get_errors($dat_filters[$filter]),
       $star_net->get_errors($net_filters[$filter]) );   
}   
  
my @dat_cols = $star_dat->what_colours();
my @net_cols = $star_net->what_colours();
foreach my $col ( 0 ... $#net_cols ) {
   ok( $dat_cols[$col], $net_cols[$col] );
   ok( $star_dat->get_colour($dat_cols[$col]), 
       $star_net->get_colour($net_cols[$col]) );
   ok( $star_dat->get_colourerr($dat_cols[$col]), 
       $star_net->get_colourerr($net_cols[$col]) );
}    
  
ok( $star_dat->quality(), $star_net->quality() );
ok( $star_dat->field(), $star_net->field() );
ok( $star_dat->gsc(), $star_net->gsc() );
ok( $star_dat->distance(), $star_net->distance() );
ok( $star_dat->posangle(), $star_net->posangle() );

# grab the last star in both catalogues
# ------------------------------------
$star_dat = $catalog_data->starbyindex( $catalog_data->sizeof() - 1 );
$star_net = $catalog_byname->starbyindex( $catalog_byname->sizeof() - 1 );

ok( $star_dat->id(), $star_net->id() );
ok( $star_dat->ra(), $star_net->ra() );
ok( $star_dat->dec(), $star_net->dec() );

@dat_filters = $star_dat->what_filters();
@net_filters = $star_net->what_filters();
foreach my $filter ( 0 ... $#net_filters ) {
   ok( $dat_filters[$filter], $net_filters[$filter] );
   ok( $star_dat->get_magnitude($dat_filters[$filter]),
       $star_net->get_magnitude($net_filters[$filter]) );
   ok( $star_dat->get_errors($dat_filters[$filter]),
       $star_net->get_errors($net_filters[$filter]) );   
}   
  
@dat_cols = $star_dat->what_colours();
@net_cols = $star_net->what_colours();
foreach my $col ( 0 ... $#net_cols ) {
   ok( $dat_cols[$col], $net_cols[$col] );
   ok( $star_dat->get_colour($dat_cols[$col]), 
       $star_net->get_colour($net_cols[$col]) );
   ok( $star_dat->get_colourerr($dat_cols[$col]), 
       $star_net->get_colourerr($net_cols[$col]) );
}    
  
ok( $star_dat->quality(), $star_net->quality() );
ok( $star_dat->field(), $star_net->field() );
ok( $star_dat->gsc(), $star_net->gsc() );
ok( $star_dat->distance(), $star_net->distance() );
ok( $star_dat->posangle(), $star_net->posangle() );

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------

__DATA__
   1 U1500_01193693  01 10 08.76 +60 05 10.2  16.2  18.8   0 00080  -   0.770 317.921
   2 U1500_01194083  01 10 10.31 +60 04 42.4  18.2  19.6   0 00080  -   0.341 288.524
   3 U1500_01194433  01 10 11.62 +60 04 49.8  17.5  18.8   0 00080  -   0.281 325.435
   4 U1500_01194688  01 10 12.60 +60 04 14.3  13.4  14.6   0 00080  -   0.362 185.885
   5 U1500_01194713  01 10 12.67 +60 04 26.8  17.6  18.2   0 00080  -   0.154 190.684
   6 U1500_01194715  01 10 12.68 +60 04 43.0  17.8  18.9   0 00080  -   0.122 346.850
   7 U1500_01194794  01 10 12.95 +60 04 36.2  16.1  16.4   0 00080  -   0.009  50.761
   8 U1500_01195060  01 10 13.89 +60 05 28.7  18.1  19.1   0 00080  -   0.889   7.975
   9 U1500_01195140  01 10 14.23 +60 05 25.5  16.5  17.9   0 00080  -   0.843  11.328
  10 U1500_01195144  01 10 14.26 +60 04 38.1  18.4  19.5   0 00080  -   0.173  77.596
  11 U1500_01195301  01 10 14.83 +60 04 19.1  14.2  16.8   0 00080  -   0.370 139.435
  12 U1500_01195521  01 10 15.71 +60 04 43.8  18.7  19.6   0 00080  -   0.374  69.469
  13 U1500_01195912  01 10 17.30 +60 05 22.1  14.1  16.9   0 00080  -   0.944  35.466
  14 U1500_01196088  01 10 18.00 +60 04 37.1  15.1  17.7   0 00080  -   0.636  88.143
  15 U1500_01196555  01 10 20.00 +60 04 12.3  18.2  19.1   0 00080  -   0.969 113.908
