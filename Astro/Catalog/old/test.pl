#!/home/perl/bin/perl

use blib;

use Astro::Catalog::Star;
use Astro::Catalog;
use Astro::Catalog::Query::2MASS;
use Astro::Catalog::Query::CMC;
use Astro::Catalog::Query::SuperCOSMOS;
use Astro::Catalog::Query::SkyCat;
use Astro::Catalog::Query::SIMBAD;
use Astro::Catalog::Query::USNOA2;
use Data::Dumper;

my $simbad = new Astro::Catalog::Query::SIMBAD( Target => $ARGV[0] );
my $result = $simbad->querydb();
my $star = $result->popstar();
my $ra = $star->ra();
my $dec = $star->dec();

my $query = new Astro::Catalog::Query::SuperCOSMOS( RA      => $ra, 
                                                    Dec     => $dec,
                                                    Radius  => '1',
                                                    Equinox => 'J2000',
                                                    Colour => 'UKJ',
                                                    Timeout => 60 );
my $file = File::Spec->catfile( '.', 'etc', 'sss.cfg' );
$query->cfg_file( $file );  
     
my $catalog = $query->querydb();

#print Dumper($catalog);

my $buffer;
$catalog->write_catalog( File => \$buffer, Format => 'Cluster' );

print $buffer . "\n";                         
