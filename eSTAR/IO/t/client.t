# eSTAR::IO::Client test harness

# strict
use strict;

# load test
use Test;
BEGIN { plan tests => 5 };

# load modules
use eSTAR::Globus qw / :all /;
use eSTAR::IO;
use eSTAR::IO::Client;

# debugging
use Data::Dumper;


# ---------------------------------------------------------------------------- 

# test the test system
ok( 1 );


# status variable
my ( $status, $handle, $write_status, $close_status );

# hardwire the test port and hostname
my $port = "2000";
my $host = "bofh";

# open the client ----------------------------------------------------------

print "# Opening Client Connection\n";
$handle = open_client( $host, $port );

unless( defined $handle ) {
   report_error();
   $status = eSTAR::Globus::deactivate_all();
   exit;
} else { ok( 1 ); }
print "# globus_io_handle_t * " . Dumper($handle) . "#\n";

# write a message ----------------------------------------------------------

my $message = "abort";

print "# Sending Message: $message\n";
$write_status = write_message( $handle, $message );

if( $write_status == GLOBUS_FALSE) {
   report_error();
   $status = eSTAR::Globus::deactivate_all();
   exit;
}
ok( $write_status, GLOBUS_TRUE );
print "# Returned $write_status (should be 1)\n#\n";

# read a message ------------------------------------------------------------

print "# Reading Message\n";

my $reply = read_message( $handle );

unless ( defined $reply ) {
   report_error();
   $status = eSTAR::Globus::deactivate_all();
   exit;
} else { ok ( 1 ); }

print "# Returned message '" . @{$reply}[0] . "'\n#\n";

# close the client ----------------------------------------------------------

print "# Closing Client Connection\n";
$close_status = close_client( $handle );

if( $close_status == GLOBUS_FALSE) {
   report_error();
   $status = eSTAR::Globus::deactivate_all();
   exit;
}
ok( $close_status, GLOBUS_TRUE );
print "# Returned $close_status (should be 1)\n#\n";

exit;

# ---------------------------------------------------------------------------- 
