
BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use eSTAR::LDAP::Search;
$loaded = 1;
print "ok 1\n";

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
   my @atts = $entry->attributes;
   print "\n\n";
   foreach(@atts) { 
      print "$_="; my $val = $entry->get_value($_); 
      print "$val\n"; 
   }
}

exit;
