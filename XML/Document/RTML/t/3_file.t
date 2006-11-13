# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More;
BEGIN { plan tests => 14 };

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# define variables
my ( $type );

# SCORE REQUEST
# -------------

# grab the test document
my $rtml1 = new XML::Document::RTML( File => 't/rtml2.2/example_score.xml' );

# check the parsed document
is( $rtml1->dtd(), '2.2', "Comparing the RTML specification version used" );
is( $rtml1->type(), 'score', "Comparing type of document" );
is( $rtml1->group_count(), 2, "<Observation><Schedule><Exposure><Count>" );
is( $rtml1->series_count(), 3, "<Observation><Schedule><SeriesConstraint><Count>" );
#is( $rtml1->interval(), "PT1H" );
#is( $rtml1->tolerance(), "PT30M" );
#is( $rtml1->start_time(), "2005-01-01T12:00:00" );
#is( $rtml1->end_time(), "2005-12-31T12:00:00" );

#print Dumper($rtml1);

# UPDATE MESSAGE
# --------------

# grab the test document
my $rtml2 = new XML::Document::RTML( File => 't/rtml2.2/problem.xml' );

# check the parsed document
is( $rtml2->dtd(), '2.2', "Comparing the RTML specification version used" );
is( $rtml2->type(), 'update', "Comparing type of document" );
is( $rtml2->group_count(), 2, "<Observation><Schedule><Exposure><Count>" );
is( $rtml2->series_count(), 8, "<Observation><Schedule><SeriesConstraint><Count>" );
#is( $rtml2->interval(), "PT2700.0S" );
#is( $rtml2->tolerance(), "PT1350.0S" );
#is( $rtml2->start_time(), "2005-05-12T09:00:00" );
#is( $rtml2->end_time(), "2005-05-13T03:00:00" );

#print Dumper($rtml2);

# OBSERVE MESSAGE
# --------------

# grab the test document
my $rtml3 = new XML::Document::RTML( File => 't/rtml2.2/observe.xml' );

# check the parsed document
is( $rtml3->dtd(), '2.2', "Comparing the RTML specification version used" );
is( $rtml3->type(), 'confirmation', "Comparing type of document" );
is( $rtml3->group_count(), 2, "<Observation><Schedule><Exposure><Count>" );
is( $rtml3->series_count(), 8, "<Observation><Schedule><SeriesConstraint><Count>" );
#is( $rtml3->interval(), "PT2700.0S" );
#is( $rtml3->tolerance(), "PT1350.0S" );
#is( $rtml3->start_time(), "2005-05-12T09:00:00" );
#is( $rtml3->end_time(), "2005-05-13T03:00:00" );

#print Dumper($rtml3);

exit;
