#!perl
# Astro::Catalog::Query::MPC test harness

# strict
use strict;

#load test
use Test::More tests => 246;
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
compare_catalog( $catalog_byname, $catalog_data);

#print join("\n",$mpc_byname->_dump_raw)."\n";

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------
# Name                   RA         Dec       V_mag raoff  decoff pm_ra pm_dec orbits  comment
__DATA__
(32467) 2000 SL174       07 19 04.1 -12 32 58  19.1  78.1E  89.0N     6-    12+    9o  None needed at this time.
(15834) 1995 CT1         07 23 31.4 -12 48 35  18.3 142.9E  73.4N    16-     4+    7o  None needed at this time.
(75285) 1999 XY24        07 05 58.2 -12 04 05  18.0 112.5W 117.9N     0+    22+    4o  None needed at this time.
 (4116) Elachi           07 18 13.0 -10 57 35  15.6  65.7E 184.4N    14+    65+   11o  None needed at this time.
        1999 XA6         07 21 59.7 -17 05 34  19.2 120.7E 183.6S    13+    20+    2o  Desirable between 2004 Mar. 2-Apr. 1.  (122.1,-16.9,19.2)
(24972) 1998 FC116       07 28 41.1 -13 36 06  18.8 218.1E  25.9N     4-    31+    7o  None needed at this time.
        2002 VB8         07 26 27.7 -11 35 25  19.2 185.7E 146.6N     5-    17+    5d  Leave for survey recovery.
        2000 KK60        07 14 40.5 -09 56 27  19.9  14.2E 245.5N     7-    16+    3o  Desirable between 2004 Mar. 2-Apr. 1.  (122.3,-09.8,19.9)
(30505) 2000 RW82        07 06 00.4 -10 20 32  18.6 112.0W 221.5N     4-    14+    7o  None needed at this time.
        2002 TT191       07 17 09.9 -09 57 28  20.0  50.4E 244.5N     6-    15+  111d  Desirable between 2004 Mar. 2-17.  (122.9,-09.8,20.0)
 (6911) Nancygreen       07 32 12.0 -14 26 01  15.5 269.2E  24.0S     0-    43+    9o  None needed at this time.
        2000 RS48        07 07 13.9 -09 37 54  19.8  94.1W 264.1N     4+    32+    2o  Desirable between 2004 Mar. 2-Apr. 1.  (120.8,-09.4,19.8)
        2003 BY18        07 22 29.9 -09 51 26  18.0 128.0E 250.6N     6-    13+    3o  Desirable between 2004 Mar. 2-Apr. 1.  (124.2,-09.8,18.0)
        1999 TM234       07 23 25.9 -09 56 34  18.9 141.6E 245.4N     7-    20+    2o  Desirable between 2004 Mar. 2-Apr. 1.  (124.4,-09.8,18.9)
(54857) 2001 OY22        07 33 08.3 -15 42 26  19.2 282.9E 100.4S    13-    24+    6o  None needed at this time.
