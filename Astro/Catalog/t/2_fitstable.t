#!perl

# Test FITS binary table read

# Astro::Catalog test harness
use Test::More;

use File::Spec;

use strict;

eval { require Astro::FITS::CFITSIO; };
if( $@ ) {
  plan skip_all => "Tests require Astro::FITS::CFITSIO";
} else {
  plan tests => 7;
}

require_ok( "Astro::Catalog" );
require_ok( "Astro::Catalog::IO::FITSTable" );

my $file = File::Spec->catfile( "t", "data", "cat.fit" );

my $cat = new Astro::Catalog( Format => 'FITSTable',
                              File => $file );

isa_ok( $cat, "Astro::Catalog" );

is( $cat->sizeof, 672, "Size of catalog" );

my $star = $cat->popstar();
my $id = $star->id;

is( $id, 672, "Last object's ID" );

is( $star->dec, "-02 03 51.95", "Last object's Dec" );

my $mag = $star->get_magnitude( 'unknown' );
is( $mag, -17.6606562131603, "Last object's magnitude" );


