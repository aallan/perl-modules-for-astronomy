#!perl

# Astro::Catalog test harness
use Test::More tests => 2;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog::Query::Sesame");

# T E S T -----------------------------------------------------------------

my $sesame = new Astro::Catalog::Query::Sesame( Target => 'EX Hya' );
my $catalog = $sesame->querydb();

isa_ok( $catalog, "Astro::Catalog" );

print Dumper( $catalog );
