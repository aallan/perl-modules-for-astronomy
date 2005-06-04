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
(32467) 2000 SL174       07 19 03.9 -12 33 12  19.1  78.1E  88.8N     6-    12+   10o  None needed at this time.
(15834) 1995 CT1         07 23 32.1 -12 49 19  18.3 143.1E  72.7N    16-     4+    8o  None needed at this time.
(75285) 1999 XY24        07 05 57.8 -12 04 35  18.0 112.6W 117.4N     0+    22+    5o  None needed at this time.
 (4116) Elachi           07 18 19.2 -10 57 47  15.6  67.2E 184.2N    14+    65+   11o  None needed at this time.
(24972) 1998 FC116       07 28 20.7 -13 36 55  18.8 213.1E  25.1N     4-    31+    8o  None needed at this time.
        1999 XA6         07 22 00.4 -17 06 40  19.2 120.9E 184.7S    13+    20+    2o  Desirable between 2005 June 4-July 4.  (151.4,-10.1,21.3)
        2000 KK60        07 14 28.6 -09 57 14  20.0  11.3E 244.8N     7-    16+    4o  Very desirable between 2005 June 4-July 4.  (113.0,-15.2,19.6)
        2002 TT191       07 17 00.3 -09 58 39  20.0  48.1E 243.4N     6-    15+  111d  Desirable between 2005 June 4-19.  (100.7,-16.9,20.8)
(30505) 2000 RW82        07 06 00.9 -10 20 39  18.6 111.8W 221.3N     4-    14+    7o  None needed at this time.
 (6911) Nancygreen       07 32 08.0 -14 26 28  15.5 268.2E  24.5S     0-    43+    9o  None needed at this time.
        2003 BY18        07 22 16.1 -09 53 13  18.2 124.7E 248.8N     6-    13+    4o  Very desirable between 2005 June 4-July 4.  (120.0,-25.0,19.1)
        2000 RS48        07 07 08.9 -09 38 15  19.5  95.3W 263.8N     4+    32+    3o  Desirable between 2005 June 17-July 17.  (117.8,+18.0,18.9)
        1999 TM234       07 23 10.0 -09 57 32  18.9 137.8E 244.5N     7-    20+    2o  Desirable between 2005 June 4-July 4.  (125.3,-18.7,18.9)
(54857) 2001 OY22        07 33 00.4 -15 42 45  19.2 281.0E 100.8S    13-    24+    7o  None needed at this time.
