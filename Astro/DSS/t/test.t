# Astro::DSS test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 1 };

# load modules
use Astro::DSS;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

print "# Connecting to ESO-ECF Archive\n";
my $dss = new Astro::DSS( Target => 'HT Cas' );
print "# Continuing Tests\n";
$dss->querydb();
