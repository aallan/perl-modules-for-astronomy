#!perl

# Test script for rise and set times

use strict;
use Test::More tests => 13;
use Time::Piece qw/ :override /;

# Need this since the constants from Astro::Coords will 
# not be defined if we only require
BEGIN { use_ok('Astro::Coords') };
require_ok('Astro::SLA');
require_ok('Astro::Telescope');

# telescope
my $tel = new Astro::Telescope( 'JCMT' );

# reference time (basically locks us into a day)
# Wed Jul 15 14:46:44 2003 UT
my $date = gmtime( 1058280404 );

# The Sun
my $c = new Astro::Coords( planet => 'sun' );
$c->datetime( $date );
$c->telescope( $tel );

#print $c->status;

# According to http://aa.usno.navy.mil/cgi-bin/aa_pap.pl
# Long = -155 29 Lat = 19 49
# Sun set is 19:04 and civil twilight is 19:28
# Sun rise is 05:51 and civil twilight start is 05:27
# Midday is 12:28

my $mtime = $c->meridian_time();
my $civtwiri = $c->rise_time( horizon => Astro::Coords::CIVIL_TWILIGHT );
my $rise = $c->rise_time( horizon => Astro::Coords::SUN_RISE_SET );
my $set  = $c->set_time( horizon => Astro::Coords::SUN_RISE_SET );
my $civtwi = $c->set_time( horizon => Astro::Coords::CIVIL_TWILIGHT );

print "# SUN:\n";
print "#  Local start civil twi:" . localtime($civtwiri->epoch)."\n";
test_time( $civtwiri, [15,27], "Civil twilight start");

print "#  Local Rise time:      " . localtime($rise->epoch) ."\n";
test_time( $rise, [15, 51], "Sun rise");

print "#  Local Transit time:   " . localtime($mtime->epoch) ."\n";
test_time( $mtime, [22,27],"Noon");

print "#  Local Set time:       " . localtime($set->epoch) ."\n";
test_time( $set, [5,4], "Sun set");

print "#  Local end Civil twi:  " . localtime($civtwi->epoch) ."\n";
test_time( $civtwi, [5,28], "Civil twilight end");

exit;

sub test_time {
  my ($ref, $answer, $text) = @_;

  is($ref->hour, $answer->[0], "$text: hour");
  is($ref->min, $answer->[1], "$text: minute");

}
