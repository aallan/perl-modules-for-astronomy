#!perl

# Test UKIRT Bright Standards catalogue format read

# Astro::Catalog test harness
use Test::More tests => 5;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'UKIRTBS', Data => \*DATA );
isa_ok( $cat, "Astro::Catalog" );

print Dumper( $cat );

my $star = $cat->popstar();
my $id = $star->id;
is($id,147064,"Last ID");

#is($star->ra, "00 44 35.50", "Gaia star RA");
#is($star->dec,"+40 41 03.38",  "Gaia star dec");

__DATA__
    9098  0.005145878-0.307427168   26.   -4.  4.6B9.5Vn
  147064  0.007713899-0.293330848   37.  -55.  5.8K0
