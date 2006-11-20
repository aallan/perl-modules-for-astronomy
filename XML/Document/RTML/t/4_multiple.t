# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More;
BEGIN { plan tests => 168 };

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
print "# Testing document t/rtml2.2/example_multiple_observe.xml\n";
my $rtml = new XML::Document::RTML( File => 't/rtml2.2/example_multiple_observe.xml' );

# check the parsed document
is( $rtml->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml->type(), 'observation', "Comparing type of document" );
is( $rtml->role(), 'observation', "Comparing type of document" );
is( $rtml->determine_type(), 'observation', "Comparing type of document" );

is( $rtml->version(), '2.2', "Comparing version of document" );

my $num = $rtml->number_of_observations();
is( $num, 2, "We have $num observations (expected 2)");
print "# We have $num observations ################################\n";
is( $rtml->observation(), 0, "We're looking at observation 0" );
print "# OBSERVATION 0 #########################################\n";

# Observation 1 of 2

is( $rtml->group_count(), 2, "Comparing the group count" );
is( $rtml->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml->exposure_time(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml->exposuretime(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml->exposure(), '==', 63.5, "Comparing the exposure time" );

is( $rtml->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml->series_count(), 8, "Comparing the series count" );
is( $rtml->seriescount(), 8, "Comparing the series count" );

is( $rtml->interval(), "PT2700.0S", "Comparing the series intervals" );
is( $rtml->tolerance(), "PT1350.0S", "Comparing the tolerance of the intervals" );

is( $rtml->priority(), undef, "Comparing the priority " );
is( $rtml->schedule_priority(), undef, "Comparing the priority" );

my @times_a = $rtml->time_constraint();
is( $times_a[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times_a[1], "2005-05-13T03:00:00", "Observation end time" );
my @times_b = $rtml->timeconstraint();
is( $times_b[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times_b[1], "2005-05-13T03:00:00", "Observation end time" );
is( $rtml->start_time(), "2005-05-12T09:00:00", "Observation start time" );
is( $rtml->end_time(), "2005-05-13T03:00:00", "Observation end time" );

is( $rtml->device_type(), "camera", "Comparing the device type" );
is( $rtml->devicetype(), "camera", "Comparing the device type" );
is( $rtml->device(), "camera", "Comparing the device type" );
is( $rtml->filter(), "R", "Comparing the filter type" );
is( $rtml->filtertype(), "R", "Comparing the filter type" );
is( $rtml->filter_type(), "R", "Comparing the filter type" );

is( $rtml->target_type(), "normal", "Comparing the target type" );
is( $rtml->targettype(), "normal", "Comparing the target type" );
is( $rtml->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml->target_name(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml->targetname(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml->target(), "OGLE-2005-blg-158", "Comparing the target name" );

is( $rtml->ra(), "18 06 04.24", "Comparing the RA" );
is( $rtml->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml->ra_units(), "hms", "Comparing the RA units" );

is( $rtml->dec(), "-28 30 51.50", "Comparing the Dec" );
is( $rtml->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml->host(), "144.173.229.20", "Comparing the host" );
is( $rtml->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml->port(), "2050", "Comparing the port" );
is( $rtml->portnumber(), "2050", "Comparing the port" );
is( $rtml->port_number(), "2050", "Comparing the port" );

is( $rtml->id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml->unique_id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml->user(), "Robonet/keith.horne", "Comparing the observer's user name" );
is( $rtml->user_name(), "Robonet/keith.horne", "Comparing the observer's user name" );

is( $rtml->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml->project(), "Planetsearch1", "Comparing the projects" );

cmp_ok( $rtml->score(), '==', 0.4530854938271604, "Comparing the score" );

is( $rtml->completion_time(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml->completiontime(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml->time(), '2005-05-12T08:59:08', "Comparing the completion time" );

my @data = $rtml->data();

foreach my $k ( 0 ... $#data ) {
   my $size = keys %{$data[$k]};
   is ( $size, 3, "Size of data hash $k (got $size, expected 3)" );
}
my @headers = $rtml->headers();
is ( scalar(@headers), 4, "Number of headers (got ". scalar(@headers) . ", expected 4)" );
foreach my $head ( 0 ... $#headers ) {
   is ( $headers[$head], undef, "Header $head is undefined as expected" );
}   
my @images = $rtml->images();
is ( scalar(@images), 4, "Number of images (got ". scalar(@images) . ", expected 4)" );
is ( $images[0], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_198_1_1_1.fits', "Image 1 present as expected" );
is ( $images[1], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_198_2_1_1.fits', "Image 2 present as expected" );
is ( $images[2], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_208_1_1_1.fits', "Image 3 present as expected" );
is ( $images[3], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_208_2_1_1.fits', "Image 3 present as expected" );
my @catalog = $rtml->catalogues();
is ( scalar(@catalog), 4, "Number of catalogues (got ". scalar(@catalog) . ", expected 4)" );
foreach my $cat ( 0 ... $#catalog ) {
   is ( $catalog[$cat], undef, "Catalogue $cat is undefined as expected" );
} 


# Change observation block
$rtml->observation( 1 );
is( $rtml->observation(), 1, "We're looking at observation 1" );
print "# OBSERVATION 1 #########################################\n";

# Observation 2 of 2

is( $rtml->group_count(), 3, "Comparing the group count" );
is( $rtml->groupcount(), 3, "Comparing the group count" );

cmp_ok( $rtml->exposure_time(), '==', 127, "Comparing the exposure time" );
cmp_ok( $rtml->exposuretime(), '==', 127, "Comparing the exposure time" );
cmp_ok( $rtml->exposure(), '==', 127, "Comparing the exposure time" );

is( $rtml->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml->series_count(), 5, "Comparing the series count" );
is( $rtml->seriescount(), 5, "Comparing the series count" );

is( $rtml->interval(), "PT2700.0S", "Comparing the series intervals" );
is( $rtml->tolerance(), "PT1350.0S", "Comparing the tolerance of the intervals" );

is( $rtml->priority(), undef, "Comparing the priority " );
is( $rtml->schedule_priority(), undef, "Comparing the priority" );

my @times_c = $rtml->time_constraint();
is( $times_c[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times_c[1], "2005-05-13T03:00:00", "Observation end time" );
my @times_d = $rtml->timeconstraint();
is( $times_d[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times_d[1], "2005-05-13T03:00:00", "Observation end time" );
is( $rtml->start_time(), "2005-05-12T09:00:00", "Observation start time" );
is( $rtml->end_time(), "2005-05-13T03:00:00", "Observation end time" );

is( $rtml->device_type(), "camera", "Comparing the device type" );
is( $rtml->devicetype(), "camera", "Comparing the device type" );
is( $rtml->device(), "camera", "Comparing the device type" );
is( $rtml->filter(), "R", "Comparing the filter type" );
is( $rtml->filtertype(), "R", "Comparing the filter type" );
is( $rtml->filter_type(), "R", "Comparing the filter type" );

is( $rtml->target_type(), "normal", "Comparing the target type" );
is( $rtml->targettype(), "normal", "Comparing the target type" );
is( $rtml->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml->target_name(), "OGLE-2005-blg-XXX", "Comparing the target name" );
is( $rtml->targetname(), "OGLE-2005-blg-XXX", "Comparing the target name" );
is( $rtml->target(), "OGLE-2005-blg-XXX", "Comparing the target name" );

is( $rtml->ra(), "18 36 04.24", "Comparing the RA" );
is( $rtml->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml->ra_units(), "hms", "Comparing the RA units" );

is( $rtml->dec(), "+28 30 51.50", "Comparing the Dec" );
is( $rtml->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml->host(), "144.173.229.20", "Comparing the host" );
is( $rtml->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml->port(), "2050", "Comparing the port" );
is( $rtml->portnumber(), "2050", "Comparing the port" );
is( $rtml->port_number(), "2050", "Comparing the port" );

is( $rtml->id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml->unique_id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml->user(), "Robonet/keith.horne", "Comparing the observer's user name" );
is( $rtml->user_name(), "Robonet/keith.horne", "Comparing the observer's user name" );

is( $rtml->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml->project(), "Planetsearch1", "Comparing the projects" );

cmp_ok( $rtml->score(), '==', 0.4530854938271604, "Comparing the score" );

is( $rtml->completion_time(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml->completiontime(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml->time(), '2005-05-12T08:59:08', "Comparing the completion time" );

my @data2 = $rtml->data();

foreach my $k ( 0 ... $#data2 ) {
   my $size = keys %{$data2[$k]};
   is ( $size, 3, "Size of data hash $k (got $size, expected 3)" );
}
my @headers2 = $rtml->headers();
is ( scalar(@headers2), 4, "Number of headers (got ". scalar(@headers2) . ", expected 4)" );
foreach my $head ( 0 ... $#headers2 ) {
   is ( $headers2[$head], undef, "Header $head is undefined as expected" );
}   
my @images2 = $rtml->images();
is ( scalar(@images2), 4, "Number of images (got ". scalar(@images2) . ", expected 4)" );
is ( $images2[0], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_207_1_1_1.fits', "Image 1 present as expected" );
is ( $images2[1], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_207_2_1_1.fits', "Image 2 present as expected" );
is ( $images2[2], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_209_1_1_1.fits', "Image 3 present as expected" );
is ( $images2[3], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_209_2_1_1.fits', "Image 3 present as expected" );
my @catalog2 = $rtml->catalogues();
is ( scalar(@catalog2), 4, "Number of catalogues (got ". scalar(@catalog2) . ", expected 4)" );
foreach my $cat ( 0 ... $#catalog2 ) {
   is ( $catalog2[$cat], undef, "Catalogue $cat is undefined as expected" );
} 

