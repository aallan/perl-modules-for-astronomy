# eSTAR::RTML::Parse test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 22 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Parse;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# define variables
my ( $type );

# SCORE REQUEST
# -------------

# grab the test document
my $rtml1 = new eSTAR::RTML( File => 't/rtml/ia_score_request.xml' );
$type = $rtml1->determine_type();
ok( $type, 'score' );

# pass it to the Parse module
my $message1 = new eSTAR::RTML::Parse( RTML => $rtml1 );

# check the parsed document
ok( $message1->dtd(), '2.1' );
ok( $message1->type(), 'score' );

#print Dumper($message1);

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

#print Dumper($message2);

# ERS MESSAGES
# ============

# ACCEPT
# ------

print "# ACCEPT MESSAGE\n#\n#\n";

my $ers_accept = new eSTAR::RTML( File =>'t/rtml/ers_observation_accepted.xml');
$type = $ers_accept->determine_type();
ok( $type, 'confirmation' );

# pass it to the Parse module
my $accept_message = new eSTAR::RTML::Parse( RTML => $ers_accept );

# check the parsed document
ok( $accept_message->dtd(), '2.1' );
ok( $accept_message->type(), 'confirmation' );

#print Dumper($accept_message);

# REJECT
# ------

print "# REJECT MESSAGE\n#\n#\n";

my $ers_reject = new eSTAR::RTML( File =>'t/rtml/ers_observation_rejected.xml');
$type = $ers_reject->determine_type();
ok( $type, 'reject' );

# pass it to the Parse module
my $reject_message = new eSTAR::RTML::Parse( RTML => $ers_reject );

# check the parsed document
ok( $reject_message->dtd(), '2.1' );
ok( $reject_message->type(), 'reject' );

#print Dumper($reject_message);

# COMPLETED
# ---------

print "# COMPLETED MESSAGE\n#\n#\n";

my $ers_finish = new eSTAR::RTML(File =>'t/rtml/ers_observations_complete.xml');
$type = $ers_finish->determine_type();
ok( $type, 'observation' );

# pass it to the Parse module
my $finish_message = new eSTAR::RTML::Parse( RTML => $ers_finish );

# check the parsed document
ok( $finish_message->dtd(), '2.1' );
ok( $finish_message->type(), 'observation' );

#print Dumper($finish_message);

# SCORE
# -----

print "# SCORE MESSAGE\n#\n#\n";

my $ers_score = new eSTAR::RTML( File =>'t/rtml/ers_score_reply.xml');
$type = $ers_score->determine_type();
ok( $type, 'score' );

# pass it to the Parse module
my $score_message = new eSTAR::RTML::Parse( RTML => $ers_score );

# check the parsed document
ok( $score_message->dtd(), '2.1' );
ok( $score_message->type(), 'score' );

#print Dumper($score_message);

# UPDATE
# ------

print "# UPDATE MESSAGE\n#\n#\n";

my $ers_obs = new eSTAR::RTML( File =>'t/rtml/ers_target_observed.xml');
$type = $ers_obs->determine_type();
ok( $type, 'update' );

# pass it to the Parse module
my $update_message = new eSTAR::RTML::Parse( RTML => $ers_obs );

# check the parsed document
ok( $update_message->dtd(), '2.1' );
ok( $update_message->type(), 'update' );

print Dumper($update_message);

exit;
