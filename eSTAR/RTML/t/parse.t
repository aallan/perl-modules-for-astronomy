# eSTAR::RTML::Parse test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 7 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Parse;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# SCORE REQUEST
# -------------

# grab the test document
my $rtml1 = new eSTAR::RTML( File => 't/rtml/ia_score_request.xml' );
my $type = $rtml1->determine_type();
ok( $type, 'score' );

# pass it to the Parse module
my $message1 = new eSTAR::RTML::Parse( RTML => $rtml1 );

# check the parsed document
ok( $message1->dtd(), '2.1' );
ok( $message1->type(), 'score' );

print Dumper($message1);

# OBS REQUEST
# -----------

# grab the test document
my $rtml2 = new eSTAR::RTML( File => 't/rtml/ia_observation_request.xml' );
$type = $rtml2->determine_type();
ok( $type, 'request' );

# pass it to the Parse module
my $message2 = new eSTAR::RTML::Parse( RTML => $rtml2 );

# check the parsed document
ok( $message2->dtd(), '2.1' );
ok( $message2->type(), 'request' );

print Dumper($message2);


exit;
