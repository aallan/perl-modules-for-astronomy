# Astro::Catalog::SuperCOSMOS::Query test harness

# strict
use strict;

#load test
use Test;

use Data::Dumper;
BEGIN { plan tests => 1 };

# Load Astro::Catalog;
use Astro::Catalog;
use Astro::Catalog::Star;
eval "use Astro::Catalog::SuperCOSMOS::Query";
if ($@) {
  for (1..1) {
    skip("Skip Astro::Aladin module not available", 1);
  }
  exit;
}

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my $sss = new Astro::Catalog::SuperCOSMOS::Query( RA     => "15 16 06.9",
                                                  Dec    => "-60 57 26.1",
                                                  Radius => "1" );

                                                  
print "# Connecting to ROE\n";
my $catalog = $sss->querydb();
print "\n# file = $catalog\n#\n\n";

print Dumper( $catalog );
#print "# BUFFER\n#\n\n";
#$sss->_dump_raw();
#my @buffer = $sss->_dump_raw();
#print @buffer;
