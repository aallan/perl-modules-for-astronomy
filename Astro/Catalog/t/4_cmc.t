#!perl
# Astro::Catalog::Query::BSC test harness

# strict
use strict;

#load test
use Test::More tests => 3;
use Data::Dumper;

BEGIN {
  # load modules
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog");
  use_ok("Astro::Catalog::Query::CMC");
}

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# T E S T   H A R N E S S --------------------------------------------------

# Grab catalogue from Vizier

my $bsc = new Astro::Catalog::Query::CMC( RA     => "01 10 13.0",
                                          Dec    => "+60 04 36",
                                          Radius => '60' );

print "# Connecting to Vizier CMC/11 Catalogue\n";
my $catalog = $bsc->querydb();
print "# Continuing tests\n";

print Dumper( $catalog );
my $buffer;
$catalog->write_catalog( File => \$buffer, Format => 'Cluster' );
print "\n" . $buffer . "\n";                         



exit;
