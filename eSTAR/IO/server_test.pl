#!/home/globus/Perl/bin/perl -W

# eSTAR::IO::Server test harness

use lib "blib/arch";
use lib "blib/lib";

# strict
use strict;

# load test
use Test;
use Test::Harness qw(&runtests $verbose);
$verbose=1;

BEGIN { plan tests => 5 };

# load modules
use eSTAR::IO qw / :all /;
use eSTAR::IO::Server;

# debugging
use Data::Dumper;


# ----------------------------------------------------------------------------

# test the test system
ok( 1 );

# status variable
my ( $status, $callback, $reply);

# hardwire the test port
my $port = "2001";

# connection callback --------------------------------------------------------

$callback = sub {
   my $handle = shift;

   print "# " . $handle . "\n#\n";
   print "# Reading Message\n";

   # READ MESSAGE FROM CLIENT
   $reply = read_message( $handle );

   unless ( defined $reply ) {
      report_error();
      print "# Shutting down sever on port $port\n#\n";
      $status = stop_server( );
      print "# Deactvating modules\n#\n";
      $status = module_deactivate();
      exit;
   } else { ok ( 1 ); }
   print "# Returned message '" . @{$reply}[0] . "'\n#\n";

   # REPLY TO CLIENT
   my $message = "ok";

   print "# Sending Message: $message\n";
   $status = write_message( $handle, $message );

   if( $status == GLOBUS_FALSE) {
      report_error();
      print "# Shutting down sever on port $port\n#\n";
      $status = stop_server( );
      print "# Deactvating modules\n#\n";
      $status = module_deactivate();
      exit;
   }
   ok( $status, GLOBUS_TRUE );
   print "# Returned $status (should be 1)\n#\n";

   # SHUTDOWN IF ASKED
   if( @{$reply}[0] eq "shutdown" ) {
      print "# Message passed from client requested shutdown\n";
      print "# Shutting down sever on port $port\n#\n";
      $status = stop_server( );;
   };

   return GLOBUS_TRUE

};

# activate modules ----------------------------------------------------------

print "# Activating GLOBUS modules\n";
$status = module_activate();
if( $status == GLOBUS_FALSE) {
   report_error();
   print "# Shutting down sever on port $port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

# start server --------------------------------------------------------------

print "# Starting Server on port $port\n";
start_server( $port, $callback );

# shutdown server ------------------------------------------------------------

#print "# Shutting down sever on port $port\n";
#$status = stop_server( );
#if( $status == GLOBUS_FALSE) {
#   report_error();
#   exit;
#}

# deactivate modules --------------------------------------------------------

print "# Deactivating GLOBUS modules\n";
$status = module_deactivate();
if( $status == GLOBUS_FALSE) {
   report_error();
   exit;
}


# ----------------------------------------------------------------------------

exit;
