# eSTAR::RTML test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 2 };

# load modules
use eSTAR::RTML;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my $rtml = new eSTAR::RTML( File => 't/rtml/ia_score_request.xml' );
my $type = $rtml->determine_type();

ok( $type, 'score' );

exit;
