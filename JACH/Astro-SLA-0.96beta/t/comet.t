#!perl

# Test orbital elements for comet
# HaleBopp
# We know that at the time:
#   MJD = 50745.7083333335
# HaleBopp had an apparent RA/Dec of
#   Apparent RA :    08:09:03.91
#   Apparent dec:   -47:24:51.53
#  [at JCMT SCUBA observing]

# This test makes sure that we get that.
# If this test fails it probably indicates that you need to
# update slalib to a version that can handle perturbation of
# elements correctly.

# Copyright (C) 2003 Particle Physics and Astronomy Research Council
# All Rights Reserved.

use strict;
use Test;
BEGIN { plan tests => 8 }
use Astro::SLA;

# Elements
my %halebopp = (
		# from JPL horizons
		EPOCH => 52440.0000,
		EPOCHPERIH => 50538.179590069,
		ORBINC => 89.4475147* &Astro::SLA::DD2R,
		ANODE =>  282.218428* &Astro::SLA::DD2R,
		PERIH =>  130.7184477* &Astro::SLA::DD2R,
		AORQ => 0.9226383480674554,
		E => 0.9949722217794675,
		AORL => 0.0,
	      );

# Time UT: 1997-10-24T17:00:00
# MJD should be 50745.7083333335
my $yy = 1997;
my $mm = 10;
my $dd = 24;
my $hh = 17;
my ($lst, $MJD) = ut2lst_tel($yy, $mm, $dd, $hh, 0, 0, 'JCMT');

ok(sprintf("%.4f",$MJD),"50745.7083", "Verify MJD");

# Correct to TT
my $offset = Astro::SLA::slaDtt( $MJD );
$MJD += ($offset / (86_400));

print "# TT MJD = $MJD\n";

# Perturb the elements
my $jform = 3;
Astro::SLA::slaPertel($jform,$halebopp{EPOCH},$MJD,
		      $halebopp{EPOCHPERIH},$halebopp{ORBINC},$halebopp{ANODE},
		      $halebopp{PERIH},$halebopp{AORQ},$halebopp{E},
		      $halebopp{AORL},
		      $halebopp{EPOCH},$halebopp{ORBINC}, $halebopp{ANODE},
		      $halebopp{PERIH},$halebopp{AORQ},$halebopp{E},
		      $halebopp{AORL},
		      my $jstat);

ok( $jstat, 0, "Status return from perturbing the elements");

# Telescope information
my $name = 'JCMT';
Astro::SLA::slaObs(-1, $name, my $fullname, my $long, my $lat, my $h);
$long *= -1; # Need east positive
print "# $fullname, $long, $lat, $h \n";



# Now use the elements
Astro::SLA::slaPlante($MJD, $long, $lat, $jform,
		      $halebopp{EPOCH}, $halebopp{ORBINC}, 
		      $halebopp{ANODE}, $halebopp{PERIH}, 
		      $halebopp{AORQ}, $halebopp{E}, $halebopp{AORL},
		      $halebopp{DM},
		      my $ra, my $dec, my $dist, my $j);

ok( $j, 0, "Status from slaPlante");

# Convert from observed to apparent place
Astro::SLA::slaOap("r", $ra, $dec, $MJD, 0.0, $long, $lat, 
		   0.0,0.0,0.0,
		   0.0,0.0,0.0,0.0,0.0,$ra, $dec);

# Convert RA and Dec to sexagesimal
my $ra_str = fromrad( $ra / 15 );
my $dec_str = fromrad( $dec );
print "# app RA: $ra -> $ra_str  App Dec: $dec -> $dec_str \n";

ok(substr($ra_str,1,8),"08:09:03","Hale-Bopp app RA");
ok(substr($dec_str,0,11),"-47:24:51.5","Hale-Bopp app Dec");


# Calculate hour angle
my $ha = $lst -$ra;
ok(sprintf("%.2f",($ha * Astro::SLA::DR2H)), "0.69", "Hour Angle");

Astro::SLA::slaDe2h($ha, $dec, $lat, my $az, my $el);

$az *= Astro::SLA::DR2D;
$el *= Astro::SLA::DR2D;
print "# Az: $az El: $el\n";

ok( sprintf("%.1f",$el),"22.1", "EL");
ok( sprintf("%.2f",$az),"187.57", "AZ");


exit;

sub fromrad {
  # Convert rad to sexagesimal
  my $in = shift;
  my @dmsf;
  my $res = 2;
  Astro::SLA::slaDr2af($res, $in, my $sign, @dmsf);
  $sign = ' ' if $sign eq "+";
  $in = $sign . sprintf("%02d:%02d:%02d.%0$res"."d",@dmsf);
  return $in;
}
