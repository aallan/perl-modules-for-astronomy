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
use Proc::Simple;
use Net::Domain qw(hostname hostdomain);

# file paths
use File::Spec qw / tmpdir /;
$ENV{"ESTAR_DATA"} = File::Spec->tmpdir();

# debugging
use Data::Dumper;

# CVS revision tag
'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# T E S T   H A R N E S S ---------------------------------------------------

# test the test system
ok(1);

# hardwire the test port
my $server_port = "2000";

# options handling -----------------------------------------------------------

my ( %opt );
 
my $status = GetOptions( "ra=s"       => \$opt{"ra"},
                         "dec=s"      => \$opt{"dec"},
                         "host=s"     => \$opt{"dn_host"},
                         "port=s"     => \$opt{"dn_port"},
                         "request=s"  => \$opt{"number"},
                         "exposure=s" => \$opt{"exposure"} );

# connection options defaults
$opt{"dn_host"} = "dn1.ex.ac.uk" unless defined $opt{"dn_host"};
$opt{"dn_port"} = "2220" unless defined $opt{"dn_port"};

# check we have an RA and Dec
unless ( defined $opt{"ra"} && defined $opt{"dec"} ) {
   croak("eSTAR: No observing co-ordinates");
}

# check we have a Request Number
unless ( defined $opt{"number"} ) {
   croak("eSTAR: No unique observing rquest number provided");
} 
                       
# rollout --------------------------------------------------------------------

print "# Observation Script ($VERSION)\n#\n";
print "# Node is $opt{dn_host}:$opt{dn_port}\n";
print "# R.A. = $opt{ra}  Dec. = $opt{dec}\n";
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
   print "#\n# Leaving Callback\n";
      
   return GLOBUS_TRUE 
};      

# create an RTML object -----------------------------------------------------

print "# Test connection to $opt{dn_host}:$opt{dn_port}\n#\n";
print "# Building SCORE request\n#\n";

my $hostname = hostname() . "." . hostdomain();

my $message = new eSTAR::RTML::Build( 
             Port        => $server_port,
             Host        => $hostname,
             ID          => "IA:aa\@$hostname:$opt{server_port}:$opt{number}",
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk'
             
             );
             
my $status = $message->score_observation(
             Target => 'Test Target',
             RA     => $opt{"ra"},
             Dec    => $opt{"dec"},
             Exposure => $opt{"exposure"}
             );

# grab RTML -----------------------------------------------------------------

print "# Dumping request to scalar\n";
my $rtml = $message->dump_rtml();

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

# wait for response RTML demo discovery node
#print "# Starting Server process on port $server_port\n";
#my $server_process = threads->create("start_server", $server_port, $callback );
#my $server_process = new Proc::Simple();
#$server_process->start( File::Spec->catfile( 
#                             File::Spec->curdir() . "server.pl" ) );

# SLEEP ---------------------------------------------------------------------

print "# Sleeping for 5 seconds\n#\n";
sleep(5);

# client thread -------------------------------------------------------------

print "# Opening connection to $opt{dn_host}:$opt{dn_port}\n";
my $client_handle = open_client( $opt{"dn_host"}, $opt{"dn_port"} );

unless( defined $client_handle ) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

print "# Sending message\n";
$status = write_message( $client_handle, $rtml );

if( $status == GLOBUS_FALSE) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

print "# write_message() returned $status (1)\n#\n";

# read a message ------------------------------------------------------------

print "# Reading message\n";

my $reply = read_message( $client_handle );

unless ( defined $reply ) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
} 
print "# read_message returned $status (1)\n#\n";
print "# Returned message '" . @{$reply}[0] . "'\n#\n";
  
# write to file -------------------------------------------------------------

print "# Writing RTML to $ENV{ESTAR_DATA}/client_message.xml\n";
my $file = File::Spec->catfile( $ENV{"ESTAR_DATA"}, "client_message.xml" );
unless ( open ( FILE, "+>$file" )) {
  croak("eSTAR: Cannont open output file $file");
}   

print FILE @{$reply}[0];
close( FILE );

print "# File closed\n";

# parse the returned XML ----------------------------------------------------

print "# Parsing XML from file\n";

my $ers_obs = new eSTAR::RTML( File => File::Spec->catfile( $ENV{"ESTAR_DATA"},
                                                 "client_message.xml" )  );

my $type = $ers_obs->determine_type();
print "# Got a ' " . $type . " ' RTML file from ERS server at $opt{dn_host}\n";
ok( $type, 'score' );

my $ers_score = new eSTAR::RTML::Parse( RTML => $ers_obs );
my $score = $ers_score->score();
my $completion_time = $ers_score->time();

print "#    Score = $score\n";
print "#    Time = $completion_time\n";

# SLEEP ---------------------------------------------------------------------

print "# Sleeping for 5 seconds\n#\n";
sleep(5);

# build RTML ----------------------------------------------------------------

print "# Building REQUEST request\n#\n";
my $message2 = new eSTAR::RTML::Build( 
             Port        => $server_port,
             Host        => $hostname,
             ID          => "IA:aa\@$hostname:$opt{server_port}:$opt{number}",
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk'
                       
             
             );
             
$status = $message2->request_observation(
             Target   => 'Test Target',
             RA       => $opt{"ra"},
             Dec      => $opt{"dec"},
             Score    => $score,
             Time     => $completion_time,
             Exposure => $opt{"exposure"}
             );  
             

# grab RTML -----------------------------------------------------------------

print "# Dumping request to scalar\n";
my $rtml2 = $message2->dump_rtml();

# client thread -------------------------------------------------------------

print "# Opening connection to $opt{dn_host}:$opt{dn_port}\n";
my $client_handle = open_client( $opt{"dn_host"}, $opt{"dn_port"} );

unless( defined $client_handle ) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

print "# Sending Message\n";
$status = write_message( $client_handle, $rtml2 );

if( $status == GLOBUS_FALSE) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

print "# write_message returned $status (1)\n#\n";

# read a message ------------------------------------------------------------

print "# Reading Message\n";

my $reply2 = read_message( $client_handle );

unless ( defined $reply2 ) {
   report_error();
   print "# Shutting down sever on port $server_port\n#\n";
   $status = stop_server( );
   print "# Deactvating modules\n#\n";
   $status = module_deactivate();
   exit;
}

print "# read_message returned $status (1)\n#\n";
print "# Returned message '" . @{$reply2}[0] . "'\n#\n";   
    
# --------------------------------------------------------------------------

#print "# Entering Mainloop()\n#\n";

# mainloop
#while () {}

exit;
