#!/home/globus/Perl/bin/perl

# Test Harness for
#
# eSTAR::RTML::Parse 
# eSTAR::RTML::Build 
# eSTAR::IO
# eSTAR::Server
# eSTAR::Client

# libraries
use lib "blib/arch";
use lib "blib/lib";

# process control
use strict;
use threads;
use threads::shared;

use vars qw/ $VERSION $SELF /;

# load test
use Test;
use Test::Harness qw(&runtests $verbose); 
$verbose=1;

BEGIN { plan tests => 1 };

# load modules
use eSTAR::RTML;
use eSTAR::RTML::Parse;
use eSTAR::RTML::Build;
use eSTAR::IO qw / :all /;
use eSTAR::IO::Server;
use eSTAR::IO::Client;

use Carp;
use Getopt::Long;
use Net::Domain qw(hostname hostdomain);

# file paths
use File::Spec qw / tmpdir /;
$ENV{"ESTAR_DATA"} = File::Spec->tmpdir();

# debugging
use Data::Dumper;

# CVS revision tag
'$Revision: 1.4 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# hardwire the test port
my $server_port = "2000";
my $server_host = hostname() . "." . hostdomain();

# options handling -----------------------------------------------------------

my ( %opt );

my $status = GetOptions( );
             
# rollout --------------------------------------------------------------------

print "# Server Script ($VERSION)\n#\n";
print "# Node is $server_host:$server_port\n";
print "# Temporary Directory: \$ESTAR_DATA = $ENV{ESTAR_DATA}\n";

# connection callback --------------------------------------------------------

my $callback = sub { 
   my $handle = shift;
   
   my ( $status );
   
   print "# Server Callback ( " . $handle . " )\n#\n";
   print "# Reading RTML\n#\n";

   # READ MESSAGE FROM DISCOVERY NODE
   my $reply = read_message( $handle );

   unless ( defined $reply ) {
      report_error();
      print "# Shutting down sever on port $server_port\n#\n";
      $status = stop_server( );
      print "# Deactvating modules\n#\n";
      $status = module_deactivate();
      exit;
   }  
   
   # print out message
   print "# Writing RTML to $ENV{ESTAR_DATA}/server_message.xml\n";
   my $file = File::Spec->catfile( $ENV{"ESTAR_DATA"}, "server_message.xml" );
   unless ( open ( FILE, "+>$file" )) {
     croak("eSTAR: Cannont open output file $file");
   }   

   print FILE @{$reply}[0];
   close(FILE);
   print "# Closing $ENV{ESTAR_DATA}/server_message.xml\n"; 
   
   print "# Re-opening $ENV{ESTAR_DATA}/server_message.xml\n";

   my $obs = new eSTAR::RTML( File => File::Spec->catfile( $ENV{"ESTAR_DATA"},
                                                 "server_message.xml" )  );

   my $type = $obs->determine_type();
   print "# Got a '" . $type . "' RTML file from ERS server at $opt{dn_host}\n";

   my $parsed = new eSTAR::RTML::Parse( RTML => $obs );   
   
   print Dumper( $parsed );
   
   print "#\n# Leaving Callback\n";
      
   return GLOBUS_TRUE 
};      

# activate modules ----------------------------------------------------------

print "# Activating GLOBUS modules\n";
$status = module_activate();
if( $status == GLOBUS_FALSE) {
   report_error();
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
} 

# start server --------------------------------------------------------------

# wait for response RTML from dn1.ex.ac.uk
print "# Starting server process on port $server_port\n";
$status = start_server( $server_port, $callback );
if( $status == GLOBUS_FALSE) {
   report_error();
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
} 
# --------------------------------------------------------------------------

exit;
