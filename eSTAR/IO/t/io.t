# eSTAR::IO test harness

# strict
use strict;

# load test
use Test;
BEGIN { plan tests => 1 };

# load modules
use eSTAR::Globus qw / :all /;

# debugging
use Data::Dumper;


# ---------------------------------------------------------------------------- 

# test the test system
ok( 1 );

exit;

# ---------------------------------------------------------------------------- 
