#!perl

# Test SExtractor format read

# Astro::Catalog test harness
use Test::More tests => 5;

use strict;

require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'SExtractor', Data => \*DATA );

isa_ok( $cat, "Astro::Catalog" );

my $star = $cat->popstar();
my $id = $star->id;

is( $id, "4", "SExtractor Star ID" );

my $ra = $star->ra;

is( $ra, "21 03 40.39", "SExtractor Star RA" );

my $dec = $star->dec;

is( $dec, "+30 17 30.02", "SExtractor Star Dec" );

exit;

# D A T A   B L O C K ------------------------------------------------------

__DATA__
#   1 NUMBER          Running object number
#   2 X_IMAGE         Object position along x                         [pixel]
#   3 Y_IMAGE         Object position along y                         [pixel]
#   4 ALPHA_J2000     Right ascension of barycenter (J2000)           [deg]
#   5 DELTA_J2000     Declination of barycenter (J2000)               [deg]
#   6 MAG_ISOCOR      Corrected isophotal magnitude                   [mag]
#   7 MAGERR_ISOCOR   RMS error for corrected isophotal magnitude     [mag]
         1   1160.914    156.721 315.9242555 +30.2954421 -11.6518   0.0084
         2    974.360    119.990 315.9290281 +30.2747915 -11.5543   0.0087
         3    536.835    102.059 315.9314674 +30.2264130 -13.2800   0.0058
         4   1126.861    203.352 315.9182782 +30.2916713 -13.2317   0.0073
