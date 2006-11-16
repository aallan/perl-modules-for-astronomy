# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More;
BEGIN { plan tests => 206 };

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# grab test document 1
# --------------------
print "Testing document t/rtml2.2/example_score.xml\n";
my $rtml1 = new XML::Document::RTML( File => 't/rtml2.2/example_score.xml' );

# check the parsed document
is( $rtml1->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml1->type(), 'score', "Comparing type of document" );
is( $rtml1->role(), 'score', "Comparing type of document" );
is( $rtml1->determine_type(), 'score', "Comparing type of document" );

is( $rtml1->version(), '2.2', "Comparing version of document" );

is( $rtml1->group_count(), 2, "Comparing the group count" );
is( $rtml1->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml1->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml1->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml1->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml1->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml1->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml1->series_count(), 3, "Comparing the series count" );
is( $rtml1->seriescount(), 3, "Comparing the series count" );

is( $rtml1->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml1->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml1->priority(), "3", "Comparing the priority of the invtervals" );
is( $rtml1->schedule_priority(), "3", "Comparing the priority of the intervals" );

my @times1a = $rtml1->time_constraint();
is( $times1a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times1a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times1b = $rtml1->timeconstraint();
is( $times1b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times1b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml1->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml1->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml1->device_type(), "camera", "Comparing the device type" );
is( $rtml1->devicetype(), "camera", "Comparing the device type" );
is( $rtml1->device(), "camera", "Comparing the device type" );
is( $rtml1->filter(), "R", "Comparing the filter type" );
is( $rtml1->filtertype(), "R", "Comparing the filter type" );
is( $rtml1->filter_type(), "R", "Comparing the filter type" );

is( $rtml1->target_type(), "normal", "Comparing the target type" );
is( $rtml1->targettype(), "normal", "Comparing the target type" );
is( $rtml1->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml1->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml1->identity(), "test-ident", "Comparing the target identity" );

is( $rtml1->target_name(), "test", "Comparing the target name" );
is( $rtml1->targetname(), "test", "Comparing the target name" );
is( $rtml1->target(), "test", "Comparing the target name" );

is( $rtml1->ra(), "01 02 03.0", "Comparing the RA" );
is( $rtml1->ra_format(), "hh mm ss.s", "Comparing the RA format" );
is( $rtml1->ra_units(), "hms", "Comparing the RA units" );

is( $rtml1->dec(), "+45 56 01.0", "Comparing the Dec" );
is( $rtml1->dec_format(), "sdd mm ss.s", "Comparing the Dec format" );
is( $rtml1->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml1->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml1->host(), "localhost", "Comparing the host" );
is( $rtml1->host_name(), "localhost", "Comparing the host" );
is( $rtml1->agent_host(), "localhost", "Comparing the host" );

is( $rtml1->port(), "1234", "Comparing the port" );
is( $rtml1->portnumber(), "1234", "Comparing the port" );
is( $rtml1->port_number(), "1234", "Comparing the port" );

is( $rtml1->id(), "12345", "Comparing the unique id" );
is( $rtml1->unique_id(), "12345", "Comparing the unique id" );

is( $rtml1->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml1->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml1->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml1->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml1->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml1->institution(), "LJM", "Comparing the observer's instituiton" );
is( $rtml1->institution_affiliation(), "LJM", "Comparing the observer's instituiton" );

is( $rtml1->project(), undef, "Comparing the projects" );

is( $rtml1->score(), undef, "Comparing the score" );

is( $rtml1->completion_time(), undef, "Comparing the completion time" );
is( $rtml1->completiontime(), undef, "Comparing the completion time" );
is( $rtml1->time(), undef, "Comparing the completion time" );

my @data1 = $rtml1->data();
foreach my $i ( 0 ... $#data1 ) {
   is ( keys %{$data1[$i]}, 0, "Size of data hash $i" );
}
my @headers1 = $rtml1->headers();
is ( $#headers1, -1, "Number of headers" );
my @images1 = $rtml1->images();
is ( $#images1, -1, "Number of images" );
my @catalog1 = $rtml1->catalogues();
is ( $#catalog1, -1, "Number of catalogues" );

# grab test document 2
# --------------------
print "Testing document t/rtml2.2/example_score_reply.xml\n";
my $rtml2 = new XML::Document::RTML( File => 't/rtml2.2/example_score_reply.xml' );

# check the parsed document
is( $rtml2->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml2->type(), 'score', "Comparing type of document" );
is( $rtml2->role(), 'score', "Comparing type of document" );
is( $rtml2->determine_type(), 'score', "Comparing type of document" );

is( $rtml2->version(), '2.2', "Comparing version of document" );

is( $rtml2->group_count(), 2, "Comparing the group count" );
is( $rtml2->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml2->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml2->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml2->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml2->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml2->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml2->series_count(), 3, "Comparing the series count" );
is( $rtml2->seriescount(), 3, "Comparing the series count" );

is( $rtml2->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml2->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml2->priority(), undef, "Comparing the priority of the invtervals" );
is( $rtml2->schedule_priority(), undef, "Comparing the priority of the intervals" );

my @times2a = $rtml2->time_constraint();
is( $times2a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times2a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times2b = $rtml2->timeconstraint();
is( $times2b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times2b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml2->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml2->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml2->device_type(), "camera", "Comparing the device type" );
is( $rtml2->devicetype(), "camera", "Comparing the device type" );
is( $rtml2->device(), "camera", "Comparing the device type" );
is( $rtml2->filter(), "R", "Comparing the filter type" );
is( $rtml2->filtertype(), "R", "Comparing the filter type" );
is( $rtml2->filter_type(), "R", "Comparing the filter type" );

is( $rtml2->target_type(), "normal", "Comparing the target type" );
is( $rtml2->targettype(), "normal", "Comparing the target type" );
is( $rtml2->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml2->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml2->identity(), "test-ident", "Comparing the target identity" );

is( $rtml2->target_name(), "test", "Comparing the target name" );
is( $rtml2->targetname(), "test", "Comparing the target name" );
is( $rtml2->target(), "test", "Comparing the target name" );

is( $rtml2->ra(), "01 02 03.00", "Comparing the RA" );
is( $rtml2->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml2->ra_units(), "hms", "Comparing the RA units" );

is( $rtml2->dec(), "+45 56 01.00", "Comparing the Dec" );
is( $rtml2->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml2->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml2->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml2->host(), "localhost", "Comparing the host" );
is( $rtml2->host_name(), "localhost", "Comparing the host" );
is( $rtml2->agent_host(), "localhost", "Comparing the host" );

is( $rtml2->port(), "1234", "Comparing the port" );
is( $rtml2->portnumber(), "1234", "Comparing the port" );
is( $rtml2->port_number(), "1234", "Comparing the port" );

is( $rtml2->id(), "12345", "Comparing the unique id" );
is( $rtml2->unique_id(), "12345", "Comparing the unique id" );

is( $rtml2->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml2->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml2->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml2->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml2->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml2->institution(), undef, "Comparing the observer's instituiton" );
is( $rtml2->institution_affiliation(), undef, "Comparing the observer's instituiton" );

is( $rtml2->project(), "agent_test", "Comparing the projects" );

is( $rtml2->score(), 0.25, "Comparing the score" );

is( $rtml2->completion_time(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml2->completiontime(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml2->time(), '2005-01-02T12:00:00', "Comparing the completion time" );

my @data2 = $rtml2->data();
foreach my $j ( 0 ... $#data2 ) {
   is ( keys %{$data2[$j]}, 0, "Size of data hash $j" );
}
my @headers2 = $rtml2->headers();
is ( $#headers2, -1, "Number of headers" );
my @images2 = $rtml2->images();
is ( $#images2, -1, "Number of images" );
my @catalog2 = $rtml2->catalogues();
is ( $#catalog2, -1, "Number of catalogues" );


# grab test document 3
# --------------------
print "Testing document t/rtml2.2/example_request.xml\n";
my $rtml3 = new XML::Document::RTML( File => 't/rtml2.2/example_request.xml' );

# check the parsed document
is( $rtml3->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml3->type(), 'request', "Comparing type of document" );
is( $rtml3->role(), 'request', "Comparing type of document" );
is( $rtml3->determine_type(), 'request', "Comparing type of document" );

is( $rtml3->version(), '2.2', "Comparing version of document" );

is( $rtml3->group_count(), 2, "Comparing the group count" );
is( $rtml3->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml3->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml3->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml3->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml3->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml3->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml3->series_count(), 3, "Comparing the series count" );
is( $rtml3->seriescount(), 3, "Comparing the series count" );

is( $rtml3->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml3->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml3->priority(), undef, "Comparing the priority of the invtervals" );
is( $rtml3->schedule_priority(), undef, "Comparing the priority of the intervals" );

my @times3a = $rtml3->time_constraint();
is( $times3a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times3a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times3b = $rtml3->timeconstraint();
is( $times3b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times3b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml3->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml3->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml3->device_type(), "camera", "Comparing the device type" );
is( $rtml3->devicetype(), "camera", "Comparing the device type" );
is( $rtml3->device(), "camera", "Comparing the device type" );
is( $rtml3->filter(), "R", "Comparing the filter type" );
is( $rtml3->filtertype(), "R", "Comparing the filter type" );
is( $rtml3->filter_type(), "R", "Comparing the filter type" );

is( $rtml3->target_type(), "normal", "Comparing the target type" );
is( $rtml3->targettype(), "normal", "Comparing the target type" );
is( $rtml3->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml3->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml3->identity(), "test-ident", "Comparing the target identity" );

is( $rtml3->target_name(), "test", "Comparing the target name" );
is( $rtml3->targetname(), "test", "Comparing the target name" );
is( $rtml3->target(), "test", "Comparing the target name" );

is( $rtml3->ra(), "01 02 03.00", "Comparing the RA" );
is( $rtml3->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml3->ra_units(), "hms", "Comparing the RA units" );

is( $rtml3->dec(), "+45 56 01.00", "Comparing the Dec" );
is( $rtml3->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml3->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml3->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml3->host(), "localhost", "Comparing the host" );
is( $rtml3->host_name(), "localhost", "Comparing the host" );
is( $rtml3->agent_host(), "localhost", "Comparing the host" );

is( $rtml3->port(), "1234", "Comparing the port" );
is( $rtml3->portnumber(), "1234", "Comparing the port" );
is( $rtml3->port_number(), "1234", "Comparing the port" );

is( $rtml3->id(), "12345", "Comparing the unique id" );
is( $rtml3->unique_id(), "12345", "Comparing the unique id" );

is( $rtml3->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml3->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml3->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml3->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml3->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml3->institution(), undef, "Comparing the observer's instituiton" );
is( $rtml3->institution_affiliation(), undef, "Comparing the observer's instituiton" );

is( $rtml3->project(), "agent_test", "Comparing the projects" );

is( $rtml3->score(), 0.25, "Comparing the score" );

is( $rtml3->completion_time(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml3->completiontime(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml3->time(), '2005-01-02T12:00:00', "Comparing the completion time" );

my @data3 = $rtml3->data();
foreach my $k ( 0 ... $#data3 ) {
   is ( keys %{$data3[$k]}, 0, "Size of data hash $k" );
}
my @headers3 = $rtml3->headers();
is ( $#headers3, -1, "Number of headers" );
my @images3 = $rtml3->images();
is ( $#images3, -1, "Number of images" );
my @catalog3 = $rtml3->catalogues();
is ( $#catalog3, -1, "Number of catalogues" );

exit;
