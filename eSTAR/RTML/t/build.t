# eSTAR::RTML::Build test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 17 };

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

# Create an RTML object
my $message2 = new eSTAR::RTML::Build( 
             Port        => '2000',
             ID          => 'IA:aa@bofh.astro.ex.ac.uk:2000:0002',
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk' );
             
# build a score request
my $status = $message2->score_observation(
             Target => 'Test Target',
             RA     => '09 00 00',
             Dec    => '+60 00 00', 
             Snr    => '3.0',
             Flux   => '12.0' );

# check some tag information
ok( $message2->port(), 2000 );
ok( $message2->id(), 'IA:aa@bofh.astro.ex.ac.uk:2000:0002' );
ok( $message2->ra(), '09 00 00' );
ok( $message2->dec(), '+60 00 00' );
ok( $message2->snr(), '3.0' );
ok( $message2->flux(), '12.0' );

# dump out the request
my $doc2 = $message2->dump_rtml();
print $doc2;

# Create an RTML object
my $message3 = new eSTAR::RTML::Build( 
             Port        => '2000',
             ID          => 'IA:aa@bofh.astro.ex.ac.uk:2000:0003',
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk' );
             
# build a score request
my $status = $message3->request_observation(
             Target => 'Test Target',
             RA     => '09 00 00',
             Dec    => '+60 00 00', 
             Snr    => '3.0',
             Flux   => '12.0' );

# check some tag information
ok( $message3->port(), 2000 );
ok( $message3->id(), 'IA:aa@bofh.astro.ex.ac.uk:2000:0003' );
ok( $message3->ra(), '09 00 00' );
ok( $message3->dec(), '+60 00 00' );
ok( $message3->snr(), '3.0' );
ok( $message3->flux(), '12.0' );

# dump out the request
my $doc3 = $message3->dump_rtml();
print $doc3;
