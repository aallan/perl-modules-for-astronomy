#!perl

# Test the source catalog class

use Test::More tests => 15;
use Astro::SLA;

require_ok( 'SrcCatalog' );
require_ok( 'SrcCatalog::JCMT' );

SrcCatalog::JCMT->defaultCatalog( 'pointing.cat' );

my $cat = new SrcCatalog::JCMT( 'default' );

ok($cat, "object instantiated");

is( scalar(@{$cat->sources}), 352, "count number of sources [inc planets]");

# check that we are using Astro::Coords

isa_ok( $cat->sources->[0], "Astro::Coords", "check class type");


# search by substring
my @results = $cat->searchByName("3C");
is( scalar(@results), 6, "search by name");

# search by radius
my $refcoords = new Astro::Coords( ra => "23:14:00",
				   dec => "61:27:00",
				   type => "J2000");

# 10 arcmin
$cat->reset;
@results = $cat->findByArea( $refcoords, (10*60*Astro::SLA::DAS2R));
is( scalar(@results), 4, "search by radius");

# search for string
@results = $cat->searchFor( name => "N7538IRS1" );
is( scalar(@results), 3, "search by full name - N7538IRS1");

$cat->reset;
@results = $cat->searchFor( name => "HLTau" );
is( scalar(@results), 1, "search by full name - HLTAU");



# search for coords
$cat->reset;
@results = $cat->searchFor( ra => "02:22:39" );
is( scalar(@results), 1, "search by exact ra match");

#use Data::Dumper;
#print Dumper(@results);

# Write catalog
$cat->reset;
$cat->writeCatalog( "catalog.dat" );
ok( -e "catalog.dat", "Check catalog file was created");
# and remove it
unlink "catalog.dat";

# Test object constructor
my $cat2 = new SrcCatalog::JCMT( new Astro::Coords::Calibration );
ok( $cat2, "Explicit object constructor - single Coords object" );
$cat2 = new SrcCatalog::JCMT( [ new Astro::Coords::Calibration ] );
ok( $cat2, "Explicit object constructor - array ref" );

eval { $cat2 = new SrcCatalog::JCMT( { } ); };
ok( $@, "Explicit object constructor failure - hash ref");

eval { $cat2 = new SrcCatalog( "hello" ); };
ok( $@, "Explicit object constructor failure - string in base class");
