# eSTAR::RTML::Build test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 5 };

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
             Port        => '2000',
             ID          => 'IA:aa@bofh.astro.ex.ac.uk:2000:0001',
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk' );

# build a score request
my $status = $message->score_observation(
             Target => 'Test Target',
             RA     => '09 00 00',
             Dec    => '+60 00 00');

# check some tag information
ok( $message->port(), 2000 );
ok( $message->id(), 'IA:aa@bofh.astro.ex.ac.uk:2000:0001' );
ok( $message->ra(), '09 00 00' );
ok( $message->dec(), '+60 00 00' );

# dump out the request
my $doc = $message->dump_rtml();

print $doc;

