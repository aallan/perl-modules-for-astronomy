# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More;
BEGIN { plan tests => 20 };

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# grab test document 5
# --------------------
print "# Testing document t/rtml2.2/supircam.rtml\n";
my $rtml = new XML::Document::RTML( File => 't/rtml2.2/supircam.rtml' );

# check the parsed document
is( $rtml->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml->type(), 'request', "Comparing type of document" );
is( $rtml->role(), 'request', "Comparing type of document" );
is( $rtml->determine_type(), 'request', "Comparing type of document" );

is( $rtml->version(), '2.2', "Comparing version of document" );

my $num = $rtml->number_of_observations();
is( $num, 1, "We have $num observations (expected 1)");
is( $rtml->observation(), 0, "We're looking at observation 0" );

# Observation 1 of 2

is( $rtml->group_count(), 9, "Comparing the group count" );
is( $rtml->groupcount(), 9, "Comparing the group count" );

cmp_ok( $rtml->exposure_time(), '==', 20, "Comparing the exposure time" );
cmp_ok( $rtml->exposuretime(), '==', 20, "Comparing the exposure time" );
cmp_ok( $rtml->exposure(), '==', 20, "Comparing the exposure time" );

is( $rtml->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml->series_count(), 72, "Comparing the series count" );
is( $rtml->seriescount(), 72, "Comparing the series count" );

is( $rtml->device_type(), "camera", "Comparing the device type" );
is( $rtml->device_region(), "infrared", "Comparing the deveice region" );



