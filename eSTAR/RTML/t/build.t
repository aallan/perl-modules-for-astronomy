# eSTAR::RTML::Build test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 3 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Build;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# Create an RTML object
my $message = new eSTAR::RTML::Build( 
                              Port => '2000',
                              ID   => 'IA:aa@bofh.astro.ex.ac.uk:2000:0001'
                              );

# build a score request
my $status = $message->score_observation();

# check Port and id
ok( $message->port(), 2000 );
ok( $message->id(), 'IA:aa@bofh.astro.ex.ac.uk:2000:0001' );

# dump out the request
my $doc = $message->dump_rtml();

print $doc;

