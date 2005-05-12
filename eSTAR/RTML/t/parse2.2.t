# eSTAR::RTML::Parse test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 28 };

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
my $rtml1 = new eSTAR::RTML( File => 't/rtml2.2/example_score.xml' );
$type = $rtml1->determine_type();
ok( $type, 'score' );

# pass it to the Parse module
my $message1 = new eSTAR::RTML::Parse( RTML => $rtml1 );

# check the parsed document
ok( $message1->dtd(), '2.2' );
ok( $message1->type(), 'score' );


ok( $message1->group_count(), 2 );

ok( $message1->series_count(), 3 );
ok( $message1->interval(), "PT1H" );
ok( $message1->tolerance(), "PT30M" );

ok( $message1->start_time(), "2005-01-01T12:00:00" );
ok( $message1->end_time(), "2005-12-31T12:00:00" );

#print Dumper($message1);

# UPDATE MESSAGE
# --------------

# grab the test document
my $rtml2 = new eSTAR::RTML( File => 't/rtml2.2/problem.xml' );
$type = $rtml2->determine_type();
ok( $type, 'update' );

# pass it to the Parse module
my $message2 = new eSTAR::RTML::Parse( RTML => $rtml2 );

# check the parsed document
ok( $message2->dtd(), '2.2' );
ok( $message2->type(), 'update' );


ok( $message2->group_count(), 2 );

ok( $message2->series_count(), 8 );
ok( $message2->interval(), "PT2700.0S" );
ok( $message2->tolerance(), "PT1350.0S" );

ok( $message2->start_time(), "2005-05-12T09:00:00" );
ok( $message2->end_time(), "2005-05-13T03:00:00" );

#print Dumper($message2);

# OBSERVE MESSAGE
# --------------

# grab the test document
my $rtml3 = new eSTAR::RTML( File => 't/rtml2.2/observe.xml' );
$type = $rtml3->determine_type();
ok( $type, 'confirmation' );

# pass it to the Parse module
my $message3 = new eSTAR::RTML::Parse( RTML => $rtml3 );

# check the parsed document
ok( $message3->dtd(), '2.2' );
ok( $message3->type(), 'confirmation' );


ok( $message3->group_count(), 2 );

ok( $message3->series_count(), 8 );
ok( $message3->interval(), "PT2700.0S" );
ok( $message3->tolerance(), "PT1350.0S" );

ok( $message3->start_time(), "2005-05-12T09:00:00" );
ok( $message3->end_time(), "2005-05-13T03:00:00" );

print Dumper($message3);

exit;
