
# Simple test of Modified Julian Date commands

use strict;
use Test;

BEGIN {plan tests => 4 }

use Astro::SLA;

# Pass first test by loading
ok(1);

# Pick a MJD

use constant MJD => 51603.5;  # midday on 29 Feb 2000


# Convert the MJD to d,m,y

slaDjcl(MJD, my $iy, my $im, my $id, my $frac, my $status);

ok($status, 0);

# Convert the fraction to hour/min/sec

my @ihmsf= ();

slaCd2tf(0, $frac, my $sign, @ihmsf);

# Now convert the year/mon/day to a MJD via the 
# ut2lst_tel() command [mainly to test that command as well]

my ($lst, $mjd) = ut2lst_tel($iy, $im, $id, $ihmsf[0], $ihmsf[1], $ihmsf[2], 'JCMT');
print "# MJD is $mjd and expected ". MJD ."\n";
ok($mjd, MJD);

# and test LST because at one point we broke it
ok(sprintf("%.3f",$lst),"3.196");
