#!perl
# Astro::Catalog::Query::GSC test harness

# strict
use strict;

#load test
use Test::More tests => 24;
use Data::Dumper;

# load modules
use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Catalog::Query::GSC;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# Grab GSC sample from the DATA block
# -----------------------------------
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
                      
       # debugging
       #print "# ID $id star $line\n";      
              
       # RA
       my $objra = "$separated[3] $separated[4] $separated[5]";
              
       # Dec
       my $objdec = "$separated[6] $separated[7] $separated[8]";

       $star->coords( new Astro::Coords( name => $id,
					 ra => $objra,
					 dec => $objdec,
					 units => 'sex',
					 type => 'J2000',
				       ));

       # B Magnitude
       my %b_mag = ( B => $separated[10] );
       $star->magnitudes( \%b_mag );
              
       # B mag error
       my %mag_errors = ( B => $separated[11] );
       $star->magerr( \%mag_errors );
              
       # Quality
       my $quality = $separated[11];
       $star->quality( $quality );
              
       # Field
       my $field = $separated[12];
       $star->field( $field );
              
       # GSC, obvious!
       $star->gsc( "TRUE" );
              
       # Distance
       my $distance = $separated[16];
       $star->distance( $distance );
              
       # Position Angle
       my $pos_angle = $separated[17];
       $star->posangle( $pos_angle );

    }
             
    # Push the star into the catalog
    # ------------------------------
    $catalog_data->pushstar( $star );
}

# field centre
$catalog_data->fieldcentre( RA => '01 10 12.9', 
                            Dec => '+60 04 35.9', 
                            Radius => '5' );


# Grab comparison from ESO/ST-ECF Archive Site
# --------------------------------------------

my $gsc_byname = new Astro::Catalog::Query::GSC( Target => 'HT Cas',
                                                  Radius => '5' );
                                                     
print "# Connecting to ESO/ST-ECF GSC Catalogue\n";
my $catalog_byname = $gsc_byname->querydb();
print "# Continuing tests\n";

# C O M P A R I S O N ------------------------------------------------------

# check sizes
print "# DAT has " . $catalog_data->sizeof() . " stars\n";
print "# NET has " . $catalog_byname->sizeof() . " stars\n";

is( $catalog_data->sizeof(), $catalog_byname->sizeof(), "compare size" );

# grab the 1st star in both catalogues
# ------------------------------------
my $star_dat = $catalog_data->starbyindex( 0 );
my $star_net = $catalog_byname->starbyindex( 0 );

is( $star_dat->id(), $star_net->id(), "compare ID" );
is( $star_dat->ra(), $star_net->ra(), "compare RA" );
is( $star_dat->dec(), $star_net->dec(), "comapre dec" );

my @dat_filters = $star_dat->what_filters();
my @net_filters = $star_net->what_filters();
foreach my $filter ( 0 ... $#net_filters ) {
   is( $dat_filters[$filter], $net_filters[$filter], "compare filter $filter" );
   is( $star_dat->get_magnitude($dat_filters[$filter]),
       $star_net->get_magnitude($net_filters[$filter]),
       "compare magnitude in filter $filter"
     );
   is( $star_dat->get_errors($dat_filters[$filter]),
       $star_net->get_errors($net_filters[$filter]),
     "compare magerr in filter $filter");   
}   
  
my @dat_cols = $star_dat->what_colours();
my @net_cols = $star_net->what_colours();
foreach my $col ( 0 ... $#net_cols ) {
   is( $dat_cols[$col], $net_cols[$col],"compare color $col" );
   is( $star_dat->get_colour($dat_cols[$col]), 
       $star_net->get_colour($net_cols[$col]),
     "compare value of color $col");
   is( $star_dat->get_colourerr($dat_cols[$col]), 
       $star_net->get_colourerr($net_cols[$col]), "compare color error $col" );
}    
  
is( $star_dat->quality(), $star_net->quality(), "check quality" );
is( $star_dat->field(), $star_net->field(), "check field" );
is( $star_dat->gsc(), $star_net->gsc(), "check GSC flag" );
is( $star_dat->distance(), $star_net->distance(), "check distance" );
is( $star_dat->posangle(), $star_net->posangle(), "check posangle" );

# grab the last star in both catalogues
# ------------------------------------
$star_dat = $catalog_data->starbyindex( $catalog_data->sizeof() - 1 );
$star_net = $catalog_byname->starbyindex( $catalog_byname->sizeof() - 1 );

is( $star_dat->id(), $star_net->id(), "compare star ID" );
is( $star_dat->ra(), $star_net->ra(), "compare star RA" );
is( $star_dat->dec(), $star_net->dec(), "Compare star Dec" );

@dat_filters = $star_dat->what_filters();
@net_filters = $star_net->what_filters();
foreach my $filter ( 0 ... $#net_filters ) {
   is( $dat_filters[$filter], $net_filters[$filter],"compare filter $filter" );
   is( $star_dat->get_magnitude($dat_filters[$filter]),
       $star_net->get_magnitude($net_filters[$filter]),
       "compare magnitude $filter");
   is( $star_dat->get_errors($dat_filters[$filter]),
       $star_net->get_errors($net_filters[$filter]),
     "compare magerr $filter");   
}   
  
@dat_cols = $star_dat->what_colours();
@net_cols = $star_net->what_colours();
foreach my $col ( 0 ... $#net_cols ) {
   is( $dat_cols[$col], $net_cols[$col],"compare color $col" );
   is( $star_dat->get_colour($dat_cols[$col]), 
       $star_net->get_colour($net_cols[$col]),
     "compare value of color $col");
   is( $star_dat->get_colourerr($dat_cols[$col]), 
       $star_net->get_colourerr($net_cols[$col]),"compare color error $col" );
}    
  
is( $star_dat->quality(), $star_net->quality(), "check quality" );
is( $star_dat->field(), $star_net->field(), "check field" );
is( $star_dat->gsc(), $star_net->gsc() , "check GSC flag");
is( $star_dat->distance(), $star_net->distance() ,"check distance");
is( $star_dat->posangle(), $star_net->posangle(), "check posangle" );

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------

__DATA__
   1 0403000551 01 09 55.34 +60 00 37.4   0.2 12.18 0.40  1 0 01MU F;   4.54 209
   2 0403000725 01 10 02.45 +60 01 05.6   0.3 13.94 0.40  1 0 01MU F;   3.74 200
   3 0403000383 01 10 06.76 +60 05 25.9   0.2 11.54 0.40  1 0 01MU F;   1.13 317
   4 0403000719 01 10 12.73 +60 04 14.4   0.2 13.91 0.40  1 0 01MU F;   0.36 183
   5 0403000581 01 10 34.84 +60 03 09.7   0.2 10.08 0.40  1 3 01MU F;   3.09 118
   6 0403000727 01 10 37.55 +60 04 33.6   0.2 13.94 0.40  1 0 01MU F;   3.07  91
   7 0403000561 01 10 38.58 +60 01 46.1   0.2 10.29 0.40  1 0 01MU F;   4.28 131
   8 0403000187 01 10 42.48 +60 07 24.3   0.2 11.89 0.40  1 0 01MU F;   4.63  53
   9 0403000655 01 10 50.99 +60 04 15.8   0.3 12.95 0.40  1 3 01MU F;   4.76  94
