# Astro::ADS::Query test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 23 };

# load modules
use Astro::ADS::Query;
use Astro::ADS::Result;

# debugging
#use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# list of authors
my ( @authors, @new_authors );
$authors[0] = "Allan, Alasdair";
$authors[1] = "Naylor, Tim";
$authors[2] = "Harries, T.J.";
$authors[3] = "Bate, M.";

# Check the configuration of the Query object
my $query = new Astro::ADS::Query( Authors => \@authors );

# AUTHORS
# -------

# check its got all the authors
my @ret_authors = $query->authors();
for my $i (0 .. $#authors) {
   ok( $ret_authors[$i], $authors[$i] );
}

# check scalar context
my $first_author = $query->authors();
ok( $first_author, $authors[0] );

# delete two authors and check again
$new_authors[0] = $authors[0];
$new_authors[1] = $authors[1];
my @next_authors = $query->authors(\@new_authors);

# check its got all the authors
for my $i (0 .. $#new_authors) {
   ok( $next_authors[$i], $new_authors[$i] );
}

# check scalar context
my $new_first_author = $query->authors();
ok( $new_first_author, $new_authors[0] );

# change author logic
my $author_logic = $query->authorlogic("AND");

# check logic okay
ok( $author_logic, "AND" );

# for verbose=1
print "# Connecting to ADS\n";

# query ADS
my $result = $query->querydb();
# print Dumper($result);
print "# Continuing Tests\n";

# grab the comparison from the DATA block
my @data = <DATA>;
chomp @data;

# change author logic
$author_logic = $query->authorlogic("OR");

# check logic okay
ok( $author_logic, "OR" );

# list of objects
my ( @objects );
$objects[0] = "U Gem";
$objects[1] = "SS Cyg";

# Check the configuration of the Query object
my $query2 = new Astro::ADS::Query( Objects => \@objects );

my @ret_obj = $query2->objects();
for my $i (0 .. $#objects) {
   ok( $ret_obj[$i], $objects[$i] );
}

# change author logic
my $obj_logic = $query2->objectlogic("AND");

# check logic okay
ok( $obj_logic, "AND" );

# for verbose=1
print "# Connecting to ADS\n";

# query ADS
my $other_result = $query2->querydb();
#print Dumper($other_result);

print "# Continuing Tests\n";

# check the number of papers returned, right now(!) it should be 304,
# but by default we should get the first 100 abstracts only...
ok( 100,  $other_result->sizeof());

# add some more objects
$objects[2] = "M31";
$objects[3] = "M32";

my $query3 = new Astro::ADS::Query( Objects => \@objects );
$query3->objectlogic("AND");

# Set the object query
$query3->objects( \@objects );

# for verbose=1
print "# Connecting to ADS\n";

# query ADS
my $next_result = $query3->querydb();

print "# Continuing Tests\n";

#my %hash = $query2->_dump_options();
#for my $key ( keys %hash ) {
#   print "$key\t\t\t= $hash{$key}\n";
#} 

# should (hopefully) be 0
ok( $next_result->sizeof(), 0);

# set and check the proxy
$query2->proxy('http://wwwcache.ex.ac.uk:8080/');
my $proxy_url = $query2->proxy();

ok( $proxy_url , 'http://wwwcache.ex.ac.uk:8080/');

# set and check the proxy
$query2->timeout(60);
my $time = $query2->timeout();

ok( $time , 60 );

# test bibcode query for Tim Jenness
my $query4 = new Astro::ADS::Query( Bibcode => "1996PhDT........42J" );

# query ADS
print "# Connecting to ADS\n";
my $bibcode_result = $query4->querydb();
#print Dumper($bibcode_result);
print "# Continuing Tests\n";

# check we have the right object
my $timj_thesis = $bibcode_result->paperbyindex( 0 );
my @timj_abstract = $timj_thesis->abstract();

# should have 32 lines of text!
ok( @timj_abstract, 32 );

# test the user agent tag
print "# User Agent: " . $query4->agent() . "\n";

# Test the start/end year and month options
$query4->startmonth( "01" );
ok( $query4->startmonth(), "01" );

$query4->endmonth( "12" );
ok( $query4->endmonth(), "12" );

$query4->startyear( "2001" );
ok( $query4->startyear(), "2001" );

$query4->endyear( "2002" );
ok( $query4->endyear(), "2002" );

exit;

# D A T A   B L O C K  ----------------------------------------------------

__DATA__
Query Results from the Astronomy Database


Retrieved 1 abstracts, starting with number 1.  Total number selected: 1.

%R 1999MNRAS.310..407W
%T A spatially resolved `inside-out' outburst of IP Pegasi
%A Webb, N. A.; Naylor, T.; Ioannou, Z.; Worraker, W. J.; Stull, J.; Allan, A.;
Fried, R.; James, N. D.; Strange, D.
%F AA(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AB(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AC(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AD(65 Wantage Road, Didcot, Oxfordshire OX11 0AE), AE(Stull Observatory, 
Alfred University, Alfred, NY 14802, USA), AF(Department of Physics, Keele 
University, Keele, Staffordshire ST5 5BG), AG(Braeside Observatory, PO Box 
906 Flagstaff, AZ 86002, USA), AH(11 Tavistock Road, Chelmsford, Essex CM1 
6JL), AI(Worth Hill Observatory, Worth Matravers, Dorset)
%J Monthly Notices, Volume 310, Issue 2, pp. 407-413.
%D 12/1999
%L 413
%K ACCRETION, ACCRETION DISCS, BINARIES: ECLIPSING, STARS: INDIVIDUAL: IP PEG, 
NOVAE, CATACLYSMIC VARIABLES, WHITE DWARFS, INFRARED: STARS
%G MNRAS
%C (c) 1999 The Royal Astronomical Society
%I ABSTRACT: Abstract;
   EJOURNAL: Electronic On-line Article;
   ARTICLE: Full Printable Article;
   REFERENCES: References in the Article;
   CITATIONS: Citations to the Article;
   SIMBAD: SIMBAD Objects;
%U http://cdsads.u-strasbg.fr/cgi-bin/nph-bib_query?bibcode=1999MNRAS.310..407W&db_key=AST 
%S  1.000
%B We present a comprehensive photometric data set taken over the entire 
outburst of the eclipsing dwarf nova IP Peg in 1997 September/October. 
Analysis of the light curves taken over the long rise to the 
peak-of-outburst shows conclusively that the outburst started near the 
centre of the disc and moved outwards. This is the first data set that 
spatially resolves such an outburst. The data set is consistent with the 
idea that long rise times are indicative of such `inside-out' outbursts. 
We show how the thickness and the radius of the disc, along with the 
mass transfer rate, change over the whole outburst. In addition, we show 
evidence of the secondary and the irradiation thereof. We discuss the 
possibility of spiral shocks in the disc; however, we find no conclusive 
evidence of their existence in this data set. 
