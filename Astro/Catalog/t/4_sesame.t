#!perl

# Astro::Catalog test harness
use Test::More tests => 14;

# Load the generic test code
chdir "t" if -d "t";
do "helper.pl" or die "Error reading test functions: $!";

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog::Star");
require_ok("Astro::Catalog::Query::Sesame");

# T E S T -----------------------------------------------------------------

my $sesame = new Astro::Catalog::Query::Sesame( Target => 'EX Hya' );
my $catalog = $sesame->querydb();

isa_ok( $catalog, "Astro::Catalog" );

# reference star
my $star = new Astro::Catalog::Star( id => 'EX Hya',
				     coords => new Astro::Coords(
								 ra =>'12 52 25',
								 dec =>'-29 14 57',
								 type=> 'j2000',
								),
				   );

compare_star( $catalog->starbyindex(0), $star);

