#!perl

# strict
use strict;

# Astro::Catalog test harness
use Test::More tests => 16;

#load test
use File::Spec;
use Data::Dumper;

# load modules
BEGIN {
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog::Query::SIMBAD");
}

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# T E S T -----------------------------------------------------------------

my $simbad = new Astro::Catalog::Query::SIMBAD( Target => 'EX Hya', radius => 0.1 );
my $catalog = $simbad->querydb();

isa_ok( $catalog, "Astro::Catalog" );

# reference star
my $star = new Astro::Catalog::Star( id => 'V* EX Hya',
				     coords => new Astro::Coords(
								 ra =>'12 52 24.4',
								 dec =>'-29 14 56.7',
								 type=> 'j2000',
								),
				   );

compare_star( $catalog->starbyindex(0), $star);

