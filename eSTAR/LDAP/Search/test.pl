#!/home/globus/Perl/bin/perl -W 

use lib "blib/arch";
use lib "blib/lib";

# strict
use strict;

# load test
use Test;
use Test::Harness qw(&runtests $verbose); 
$verbose=1;

BEGIN { plan tests => 2 };

use eSTAR::LDAP::Search;
use Data::Dumper;

# ---------------------------------------------------------------------------- 

# test the test system
ok( 1 );

my $timeout = 120;
my $host    = 'dn1.ex.ac.uk';
my $port    = 2135;
my $branch  = "o=eSTAR";
my $filter  = "(objectclass=*)";


my $newgis = new eSTAR::LDAP::Search( host    => $host,
                                      port    => $port,
                                      filter  => $filter,
                                      branch  => $branch,
                                      timeout => $timeout );
                                      
my @entries = $newgis->execute();

print "\@entires = " . $#entries ."\n";
print $newgis->get_error() ."\n";

my $entry;
foreach $entry (@entries) {
   my @atts = $entry->attributes();
   print "\n\n";
   
   foreach(@atts) { 
      print "$_="; my $val = $entry->get_value($_); 
      print "$val\n"; 
   }
}

exit;
