# Astro::SIMBAD::Query test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 1 };

# load modules

# debugging
use Data::Dumper;
use Astro::SIMBAD::Query;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my $coord_query = new Astro::SIMBAD::Query( RA        => "01 10 12.98",
                                            Dec       => "+60 04 35.9",
                                            Error     => 10,
                                            Units     => "arcsec" );
                                      
print "# Connecting to SIMBAD\n";
my $coord_result = $coord_query->querydb();
print "# Continuing Tests\n";

my $ident_query = new Astro::SIMBAD::Query( Target    => "HT Cas",
                                            Error     => 10,
                                            Units     => "arcsec" );                                      
print "# Connecting to SIMBAD\n";
my $ident_result = $ident_query->querydb();
print "# Continuing Tests\n";

my $multi_query = new Astro::SIMBAD::Query( Target    => "3C273",
                                            Error     => 10,
                                            Units     => "arcsec" ); 
print "# Connecting to SIMBAD\n";
my $multi_result = $multi_query->querydb();
print "# Continuing Tests\n"; 
print Dumper($multi_result);
                                              
