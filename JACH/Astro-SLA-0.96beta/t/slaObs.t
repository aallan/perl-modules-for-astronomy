
# Test of slaObs

use strict;
use Test;

BEGIN { plan tests => 6 }

use Astro::SLA;

ok(1);

# First ask for telescope 1

my $i = 1;
my ($n, $name1, $w1, $p1, $h1);

slaObs($i, $n, $name1, $w1, $p1, $h1);

ok(1);

# Now ask for the parameters associated with the short telescope
# name associated with telescope 1

slaObs(-1, $n, my $name2, my $w2, my $p2, my $h2);

ok($name1, $name2);
ok($w1, $w2);
ok($p1, $p2);
ok($h1, $h2);

print "# $i $n $name2 $w2 $p2 $h2\n";


