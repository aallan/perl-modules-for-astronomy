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
  use_ok("Astro::Catalog::Query::Sesame");
}
use Astro::Coords;

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# T E S T -----------------------------------------------------------------

my $sesame = new Astro::Catalog::Query::Sesame( Target => 'EX Hya' );
my $catalog = $sesame->querydb();


isa_ok( $catalog, "Astro::Catalog" );

# reference star
my $star = new Astro::Catalog::Star( id => 'EX Hya',
				     coords => new Astro::Coords(
				       ra =>'12 52 25', dec =>'-29 14 57',
					type=> 'j2000' ) );

#print Dumper ( $star );

compare_star( $catalog->starbyindex(0), $star);

my $sesame2 = new Astro::Catalog::Query::Sesame( Target => 'HT Cas' );
my $catalog2 = $sesame2->querydb();
