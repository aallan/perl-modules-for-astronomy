# eSTAR::RTML::Build test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 45 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Build;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# SCORE REQUEST
# -------------

# grab the test document
my $rtml_1 = new eSTAR::RTML( File => 't/rtml2.2/example_score.xml' );
my $type = $rtml_1->determine_type();
ok( $type, 'score' );

my $orig_1 = $rtml_1->dump_rtml();
my @array1_1 = split "\n", $orig_1 ;

# Create an RTML object
my $message_1 = new eSTAR::RTML::Build( 
             Port        => '1234',
             Host        => 'localhost',
             ID          => '12345',
             User        => 'TMC/estar',
             Name        => 'Chris Mottram',
             Institution => 'LJM',
             Email       => 'cjm@astro.livjm.ac.uk' );

# build a score request
my $status = $message_1->score_observation(
             Target => 'test',
             TargetIdent => 'test-ident',
             RA     => '01 02 03.0',
             Dec    => '+45 56 01.0',
             Exposure => '120',
             Filter => 'R',
             GroupCount  => '2',
             TimeConstraint => [ '2005-01-01T12:00:00',
                                 '2005-12-31T12:00:00' ],
             SeriesCount => '3',
             Interval    => '1H',
             Tolerance   => '30M'  );

# dump out the request
my $doc_1 = $message_1->dump_rtml();
my @array2_1 = split "\n", $doc_1;


foreach my $i ( 0 ... $#array1_1 ) {
   ok( $array2_1[$i], $array1_1[$i] );
}   

print $doc_1;


