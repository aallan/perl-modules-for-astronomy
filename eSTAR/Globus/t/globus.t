# eSTAR::Globus test harness

# strict
use strict;

# load test
use Test;
BEGIN { plan tests => 9 };

# load modules
use eSTAR::Globus qw / :all /;

# debugging
use Data::Dumper;


# ---------------------------------------------------------------------------- 

# test the test system
ok( 1 );

my $status;

# create the IO and COMMON modules
my $io_module = eSTAR::Globus::IO;
my $common_module = eSTAR::Globus::COMMON;

# activate the IO module
$status = $io_module->activate();
ok( $status, GLOBUS_SUCCESS );

# deactivate the IO module
$status = $io_module->deactivate();
ok( $status, GLOBUS_SUCCESS );

# re-activate the IO module
$status = $io_module->activate();
ok( $status, GLOBUS_SUCCESS );

# deactivate the IO module
$status = $common_module->deactivate();
ok( $status, GLOBUS_SUCCESS );

# re-activate the IO module
$status = $common_module->activate();
ok( $status, GLOBUS_SUCCESS );

# deactivate both the IO and COMMON modules
$status = eSTAR::Globus::deactivate_all();
ok( $status, GLOBUS_SUCCESS );

# attempt to deactivate the IO module again, should fail!
$status = $io_module->deactivate();
ok( $status, GLOBUS_FAILURE );

# attempt to deactivate the IO module again, should fail!
$status = $common_module->deactivate();
ok( $status, GLOBUS_FAILURE );

exit;

# ---------------------------------------------------------------------------- 
