# eSTAR::Globus test harness

# strict
use strict;

# load test
use Test;
BEGIN { plan tests => 5 };

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

# deactivate both the IO and COMMON modules
my $rc = eSTAR::Globus::deactivate_all();
ok( $rc, GLOBUS_SUCCESS );


exit;

# ---------------------------------------------------------------------------- 
