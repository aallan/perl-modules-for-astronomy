#!perl
# Astro::Catalog::Query::MPC test harness

# strict
use strict;

#load test
use Test::More tests => 202;
use Data::Dumper;

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
    my %vmag = ( V => $vmag );
    $star->magnitudes( \%vmag );

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
my $catalog_byname = $mpc_byname->querydb();
print "# Continuing tests\n";

# C O M P A R I S O N ------------------------------------------------------

# check sizes
print "# DAT has " . $catalog_data->sizeof() . " stars\n";
print "# NET has " . $catalog_byname->sizeof() . " stars\n";

# Compare catalogues
compare_mpc_catalog( $catalog_byname, $catalog_data);

#print join("\n",$mpc_byname->_dump_raw)."\n";

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------
# Name                   RA         Dec       V_mag raoff  decoff pm_ra pm_dec orbits  comment
__DATA__
(32467) 2000 SL174       07 19 03.9 -12 33 05  19.1  78.1E  89.0N     6-    12+    9o  None needed at this time.
(15834) 1995 CT1         07 23 30.5 -12 48 58  18.3 142.7E  73.1N    16-     4+    7o  None needed at this time.
(75285) 1999 XY24        07 05 55.6 -12 04 20  18.0 113.1W 117.7N     0+    22+    4o  None needed at this time.
 (4116) Elachi           07 18 12.6 -10 57 42  15.6  65.2E 184.3N    14+    65+   11o  None needed at this time.
(24972) 1998 FC116       07 28 31.7 -13 36 45  18.8 216.5E  25.4N     4-    31+    7o  None needed at this time.
        1999 XA6         07 21 57.7 -17 06 09  19.2 120.1E 184.0S    13+    20+    2o  Desirable between 2004 Dec. 22-2005 Jan. 21.  At the first date, object will be within 60 deg of the sun.
        2000 KK60        07 14 36.0 -09 56 53  19.9  13.4E 245.2N     7-    16+    3o  Desirable between 2004 Dec. 22-2005 Jan. 21.  ( 76.3,-24.8,20.2)
(30505) 2000 RW82        07 06 00.4 -10 20 36  18.6 112.0W 221.4N     4-    14+    7o  None needed at this time.
        2002 TT191       07 17 06.0 -09 57 58  20.0  49.7E 244.2N     6-    15+  111d  Desirable between 2004 Dec. 22-2005 Jan. 6.  ( 84.1,-24.9,20.9)
 (6911) Nancygreen       07 32 07.1 -14 26 21  15.5 268.1E  24.3S     0-    43+    9o  None needed at this time.
        2000 RS48        07 07 08.6 -09 38 09  19.8  95.3W 263.9N     4+    32+    2o  Desirable between 2004 Dec. 22-2005 Jan. 21.  At the first date, object will be within 60 deg of the sun.
        2003 BY18        07 22 24.3 -09 52 17  18.0 127.1E 250.0N     6-    13+    3o  Desirable between 2004 Dec. 22-2005 Jan. 21.  ( 69.1,-29.4,19.3)
        1999 TM234       07 23 18.9 -09 57 14  18.9 140.4E 244.9N     7-    20+    2o  Desirable between 2004 Dec. 22-2005 Jan. 21.  ( 64.9,-26.0,20.1)
(54857) 2001 OY22        07 33 03.8 -15 42 43  19.2 282.0E 100.7S    13-    24+    6o  None needed at this time.
