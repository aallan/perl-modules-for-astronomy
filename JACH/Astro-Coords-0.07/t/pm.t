#!perl
use strict;
use Test::More tests => 6;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');
use Time::Piece qw/ :override /;

my $tel = new Astro::Telescope('JCMT');

# Hard wire a reference date
my $t  = gmtime( 1077557000 );
print "# Epoch : ". Astro::SLA::slaEpj( $t->mjd)."\n";

# RA/Dec in J2000 at 2000.0:     6 14 1.584  +15 9 54.36
# RA/Dec in J2000 at 2004.1457:  6 14 1.777  +15 9 49.17
# Proper motion: 739, -1248 milliarcsec/yr
my $fs = new Astro::Coords( 
			   name => "LHS216",
			   ra => '6 14 1.584',
			   dec => '15 9 54.36',
#			   parallax => 0.3,
			   pm => [0.739, -1.248 ],
			   type => 'J2000',
			   units => 's',
			  );
$fs->datetime( $t );
$fs->telescope( $tel );

is( $fs->ra(format=>'s'),  " 06:14:01.79", "RA of LHS 216");
is( $fs->dec(format=>'s'), " 15:09:49.19", "Dec of LHS216");

# Test out of SUN/67, section titled "Mean Place Transformations"
my $c = new Astro::Coords( name => "target",
                           ra => '16 9 55.13',
                           dec => '-75 59 27.2',
                           type => 'B1900',
                           epoch => 1963.087,
                           pm => [ -0.468, 0.103 ],
                           parallax => 0.062,
                           units => 's',
                         );
$t = gmtime( 768427560 );
$c->datetime( $t );

is( $c->ra( format => 's' ), " 16:23:07.89", "RA for SUN/67 test");
is( $c->dec( format => 's' ), "-76:13:58.93", "Dec for SUN/67 test");
