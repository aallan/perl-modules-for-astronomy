#!perl

# compare results from direct call to GSC with Skycat version.

use strict;

#load test
use Test::More tests => 160;
use Data::Dumper;

BEGIN {
  # load modules
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog");
  use_ok("Astro::Catalog::Query::SkyCat");
  use_ok("Astro::Catalog::Query::GSC");
}

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";



my $skycat_q = new Astro::Catalog::Query::SkyCat( # Target => 'HT Cas',
						 RA => '01 10 12.9',
						 Dec => '+60 04 35.9',
						 Radius => '5',
						 Catalog => 'gsc',
						);

my $gsc_q = new Astro::Catalog::Query::GSC( # Target => 'HT Cas',
					   RA => '01 10 12.9',
					   Dec => '+60 04 35.9',
					   Radius => '5',
					  );

my $gsc_cat = $gsc_q->querydb();
my $skycat_cat = $skycat_q->querydb();

$gsc_cat->sort_catalog( "ra" );
$skycat_cat->sort_catalog( "ra" );

compare_catalog( $skycat_cat, $gsc_cat );


