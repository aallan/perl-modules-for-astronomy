#!perl

# Test comparison with coco output

use strict;
use Test::More tests => 94;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');
use Time::Piece ':override';

my $tel = new Astro::Telescope("JCMT");

# Simulataneously test negative zero dec and B1950 to J2000 conversion
my $c = new Astro::Coords( ra => "15:22:33.3",
	                   dec => "-0:13:4.5",
			   type => "B1950");

ok($c, "create object");
print "#J2000: $c\n";
# Compare with J2000 values
is( $c->ra(format=>'s'), " 15:25:07.36","compare J2000 RA");
is( $c->dec(format=>'s'), "-00:23:35.63","compare J2000 Dec");

# Use midday on Fri Sep 14 2001
$c->telescope( $tel );
my $midday = gmtime(1000468800);
$c->datetime( $midday );
print "# Julian epoch: ". Astro::SLA::slaEpj( $midday->mjd ) ."\n";
print $c->status();

# FK5 J2000
is( $c->ra(format=>'s'), " 15:25:07.35", "Check RA 2000");
is( $c->dec(format=>'s'), "-00:23:35.76", "Check Dec 2000");

# FK5 apparent
is( $c->ra_app(format=>'s'), " 15:25:10.95", "Check geocentric apparent RA");
is( $c->dec_app(format=>'s'), "-00:24:45.19", "Check geocentric apparent Dec");


# Ecliptic coordinates
is( $c->ecllong(format=>'d'), 228.98457403, "Check ecliptic longitude");
is( $c->ecllat(format=>'d'), 17.7007993, "Check ecliptic latitdue");

exit;
