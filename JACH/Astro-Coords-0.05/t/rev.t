#!perl

# This script tests that the coordinates are reversible
use strict;
use Test::More tests => 24;
use Time::Piece qw/ :override /;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');
require_ok('Astro::SLA');

my %test = (
	    equatorial => {
			   name => '0221+067',
			   ra   => '02 24 28.428',
			   dec  => '+06 59 23.34',
			   type => 'J2000',
			  },
	    planet      => { 
			    planet => 'mars' 
			   },
	    elements    => { 
			    elements => {
				     # from JPL horizons
				     EPOCH => 52440.0000,
				     EPOCHPERIH => 50538.179590069,
				     ORBINC => 89.4475147* &Astro::SLA::DD2R,
				     ANODE =>  282.218428* &Astro::SLA::DD2R,
				     PERIH =>  130.7184477* &Astro::SLA::DD2R,
				     AORQ => 0.9226383480674554,
				     E => 0.9949722217794675,
					},
			    name => "Hale-Bopp",
			   },
	   );

# telescope
my $tel = new Astro::Telescope( 'JCMT' );

# reference time
my $date = gmtime;

for my $chash (keys %test) {

  # Create a new coordinate object
  my $c = new Astro::Coords( %{ $test{$chash} } );
  ok($c, "instantiate object $chash");
  $c->datetime( $date );
  $c->telescope( $tel );

  #print $c->status;

  # now instantiate an AZEL object
  my $azel = new Astro::Coords( az => $c->az, el => $c->el,
				units => 'radians');

  $azel->datetime( $date );
  $azel->telescope( $c->telescope );

  #print $azel->status;

  # compare
  my $fmt = '%.5g';
  for my $type (qw/ az el ra_app dec_app _lst /) {
    is(sprintf($fmt,$azel->$type), sprintf($fmt,$c->$type),
       "compare $type");
  }
  is(sprintf($fmt,$azel->ha(normalize=>1)), sprintf($fmt,$c->ha(normalize=>1)),
						   "compare HA");

}
