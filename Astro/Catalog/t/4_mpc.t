#!perl
# Astro::Catalog::Query::MPC test harness

# strict
use strict;

#load test
use Test::More tests => 202;
use Data::Dumper;

use Astro::Flux;
use Astro::Fluxes;
use Number::Uncertainty;

# Catalog modules need to be loaded first
BEGIN {
  use_ok( "Astro::Catalog::Star");
  use_ok( "Astro::Catalog");
  use_ok( "Astro::Catalog::Query::MPC");
}


# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# T E S T   H A R N E S S --------------------------------------------------

# Grab MPC sample from the DATA block
# -----------------------------------
my @buffer = <DATA>;
chomp @buffer;

# test catalog
my $catalog_data = new Astro::Catalog();

my $epoch = 2004.16427554485;

# create a temporary object to hold stars
my $star;

# Parse data block
# ----------------
foreach my $line ( 0 .. $#buffer ) {

  my( $name, $ra, $dec, $vmag, $raoff, $decoff, $pm_ra, $pm_dec, $orbit, $comment ) = unpack("A24A11A10A6A7A7A7A7A6A*", $buffer[$line]);

  if( defined( $ra ) ) {

    $star = new Astro::Catalog::Star();

    $name =~ s/^\s+//;
    $star->id( $name );

    $vmag =~ s/^\s+//;

    $star->fluxes( new Astro::Fluxes( new Astro::Flux( new Number::Uncertainty( Value => $vmag ),
                                                       'mag', "V" )));

    $comment =~ s/^\s+//;
    $star->comment( $comment );

    # Deal with the coordinates. RA and Dec are almost in the
    # right format (need to replace separating spaces with colons).
    $ra =~ s/^\s+//;
    $ra =~ s/ /:/g;
    $dec =~ s/^\s+//;
    $dec =~ s/ /:/g;

    my $coords = new Astro::Coords( name => $name,
                                    ra => $ra,
                                    dec => $dec,
                                    type => 'J2000',
                                    epoch => $epoch,
                                  );

    $star->coords( $coords );

    # Push the star onto the catalog.
    $catalog_data->pushstar( $star );

  }

}

# field centre
$catalog_data->fieldcentre( RA => '07 13 42',
                            Dec => '-14 02 00',
                            Radius => '300' );

# Grab comparison from ESO/ST-ECF Archive Site
# --------------------------------------------

my $mpc_byname = new Astro::Catalog::Query::MPC( RA => "07 13 42",
                                                 Dec => "-14 02 00",
                                                 Radmax => '300',
                                                 Year => 2004,
                                                 Month => 03,
                                                 Day => 1.87, );

print "# Connecting to MPC Minor Planet Checker\n";
my $catalog_byname;
eval { $catalog_byname = $mpc_byname->querydb() };
SKIP: {
  skip "Cannot connect to MPC website", 199 unless ! $@;
  print "# Continuing tests\n";

# C O M P A R I S O N ------------------------------------------------------

  # check sizes
  print "# DAT has " . $catalog_data->sizeof() . " stars\n";
  print "# NET has " . $catalog_byname->sizeof() . " stars\n";

  # Compare catalogues
  compare_mpc_catalog( $catalog_byname, $catalog_data);

} # End SKIP

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------
# Name                   RA         Dec       V_mag raoff  decoff pm_ra pm_dec orbits  comment
__DATA__
(32467) 2000 SL174       07 19 04.7 -12 33 22  19.1  78.3E  88.6N     6-    12+   10o  None needed at this time.
(75285) 1999 XY24        07 06 06.4 -12 05 25  18.0 110.5W 116.6N     0+    22+    5o  None needed at this time.
(15834) McBride          07 23 37.3 -12 50 19  18.3 144.4E  71.7N    16-     4+    8o  None needed at this time.
 (4116) Elachi           07 18 31.3 -10 57 56  15.6  70.2E 184.1N    14+    65+   12o  None needed at this time.
(24972) 1998 FC116       07 28 10.8 -13 36 47  18.8 210.7E  25.2N     4-    31+    8o  None needed at this time.
        1999 XA6         07 22 10.4 -17 07 52  19.2 123.3E 185.9S    13+    20+    2o  Desirable between 2005 Sept. 12-Oct. 12.  ( 96.3,-08.0,22.4)
        2000 KK60        07 14 16.4 -09 57 09  20.0   8.3E 244.8N     6-    16+    4o  Very desirable between 2005 Sept. 12-Oct. 12.  At the first date, object will be within 60 deg of the sun.
        2002 TT191       07 16 48.6 -09 59 28  20.0  45.3E 242.5N     6-    15+  111d  Desirable between 2005 Sept. 12-27.  At the first date, object will be within 60 deg of the sun.
(30505) 2000 RW82        07 06 02.2 -10 20 42  18.6 111.5W 221.3N     4-    14+    7o  None needed at this time.
 (6911) Nancygreen       07 32 18.5 -14 26 56  15.5 270.8E  24.9S     0-    43+   10o  None needed at this time.
        2003 BY18        07 22 01.7 -09 53 52  18.2 121.2E 248.1N     5-    13+    4o  Very desirable between 2005 Sept. 12-Oct. 12.  At the first date, object will be within 60 deg of the sun.
        2000 RS48        07 07 18.3 -09 38 49  19.5  93.1W 263.2N     4+    32+    3o  None needed at this opposition.
        1999 TM234       07 22 59.1 -09 57 19  18.9 135.1E 244.7N     7-    20+    2o  Desirable between 2005 Sept. 12-Oct. 12.  At the first date, object will be within 60 deg of the sun.
(54857) 2001 OY22        07 33 02.1 -15 42 51  19.2 281.4E 100.8S    13-    24+    7o  None needed at this time.
