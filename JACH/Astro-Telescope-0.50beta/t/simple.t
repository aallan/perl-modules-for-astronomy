
# Simple test for Astro::Telescope
# to test constructor

use strict;
use Test;

BEGIN { plan tests => 23 }

use Astro::Telescope;

# Test unknown telescope
my $tel = new Astro::Telescope( "blah" );
ok( $tel, undef);

# Now a known telescope
$tel = new Astro::Telescope( "JCMT" );

# Compare and contrast. This all assumes slaObs is not updated.
ok($tel->name, "JCMT");
ok($tel->fullname, "JCMT 15 metre");
ok($tel->lat("s"), "19 49 22.11");
ok($tel->long("s"), "-155 28 37.20");
ok($tel->alt, 4111);

# Change telescope to something wrong
$tel->name("blah");
ok($tel->name, "JCMT");

# To something valid
$tel->name("JODRELL1");
ok($tel->name, "JODRELL1");

# Full list of telescope names
my @list = Astro::Telescope->telNames;
ok(scalar(@list));

# Check limits of JCMT
$tel->name( 'JCMT' );
my %limits = $tel->limits;

ok( $limits{type}, "AZEL");
ok(exists $limits{el}{max} );
ok(exists $limits{el}{min} );

# Switch telescope
$tel->name( "UKIRT" );
ok( $tel->name, "UKIRT");
ok( $tel->fullname, "UK Infra Red Telescope");

%limits = $tel->limits;
ok( $limits{type}, "HADEC");
ok(exists $limits{ha}{max} );
ok(exists $limits{ha}{min} );
ok(exists $limits{dec}{max} );
ok(exists $limits{dec}{min} );

# test constructor that takes a hash
my $new = new Astro::Telescope( Name => $tel->name,
				Long => $tel->long,
				Lat  => $tel->lat);
ok($new);

ok($new->name, $tel->name);
ok($new->long, $tel->long);
ok($new->lat,  $tel->lat);


exit;
