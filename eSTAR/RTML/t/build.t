# eSTAR::RTML::Build test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 1 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Build;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);
