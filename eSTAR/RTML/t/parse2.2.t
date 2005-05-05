# eSTAR::RTML::Parse test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 10 };

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


exit;
