use strict;
use Test;

BEGIN { plan tests => 67 }

use Astro::Coords;
use Astro::Telescope;
use Time::Piece ':override';

# Simulataneously test negative zero dec and B1950 to J2000 conversion
my $c = new Astro::Coords( ra => "15:22:33.3",
	                   dec => "-0:13:4.5",
			   type => "B1950");

print "#J2000: $c\n";
# Compare with J2000 values
ok("15:25:7.35", $c->ra(format=>'s'));
ok("-0:23:35.76", $c->dec(format=>'s'));

# Set telescope
my $tel = new Astro::Telescope('JCMT');
my $ukirt = new Astro::Telescope('UKIRT');

# Date/Time
# Something we know
# Approx Fri Sep 14 02:57 2001
my $date = gmtime(1000436215);

# Configure the object
$c->telescope( $tel );
$c->datetime( $date);

# Test Az/El
ok( int($c->el(format=>"d")), 67.0 );
ok( int($c->az(format=>"d")), 208.0 );

# Get the summary
my @result = ("RADEC",4.03660853577072,-0.00686380910209873,undef,
	      undef,undef,undef,undef,undef,undef,undef);
my @summary = $c->array;
test_array_elem(\@summary,\@result);

# observability
ok( $c->isObservable );

# Change telescope and try again
$c->telescope( $ukirt );
ok( $c->isObservable );

# Now for a planet
$c = new Astro::Coords( planet => "mars" );
$c->telescope( $tel );
$c->datetime( $date);

print "# $c\n";
# Test stringify
ok("$c", "MARS");

# Test Az/El
ok( int($c->el(format=>"d")),  34 );
ok( int($c->az(format=>"d")), 145 );

# And apparent ra/dec
ok( int($c->ra_app(format=>"h")), 18);
ok( int($c->dec_app(format=>"d")), -26);

# Get the summary
@result = ("mars",undef,undef,undef,undef,undef,undef,undef,undef,
	      undef,undef);
@summary = $c->array;
test_array_elem(\@summary,\@result);

# observability
ok( $c->isObservable );


# No tests for elements yet

# Test Fixed on Earth coordinate frames
# and compare with the previous values for Mars

my $fc = new Astro::Coords( az => $c->az, el => $c->el );
$fc->telescope( $tel );
$fc->datetime( $date);

print "# FIXED: $fc\n";

ok($fc->type, "FIXED");

# Test Az/El
ok( int($fc->el(format=>"d")),  34 );
ok( int($fc->az(format=>"d")), 145 );

# And apparent ra/dec
ok( int($fc->ra_app(format=>"h")), 18);
ok( int($fc->dec_app(format=>"d")), -26);

# Get the summary
@result = ("FIXED",$fc->az,$fc->el,undef,undef,undef,undef,undef,undef,
	      undef,undef);
@summary = $fc->array;
test_array_elem(\@summary,\@result);

# observability
ok( $fc->isObservable );


# Calibration
print "# CAL\n";
my $cal = new Astro::Coords();

ok( $cal->type, "CAL");

# observability
ok( $cal->isObservable );


# Now come up with some coordinates that are not 
# always observable

print "# Observability\n";

$c = new Astro::Coords( ra => "15:22:33.3",
			dec => "-0:13:4.5",
			type => "J2000");

$c->telescope( $tel );
$c->datetime( $date ); # approximately transit
ok( $c->isObservable );

# Change the date by 12 hours
# Approx Fri Sep 14 14:57 2001
my $ndate = gmtime(1000436215 + ( 12*3600) );
$c->datetime( $ndate );
ok(! $c->isObservable );

# switch to UKIRT (shouldn't be observable either)
$c->telescope( $ukirt );
ok( ! $c->isObservable );

# Now use coordinates which can be observed with JCMT
# but not with UKIRT
$c = new Astro::Coords( ra => "15:22:33.3",
			dec => "72:13:4.5",
			type => "J2000");

$c->telescope( $tel );
$c->datetime( $date );

ok( $c->isObservable );
$c->telescope( $ukirt );
ok( !$c->isObservable );


# Some random comparisons with SCUBA headers
print "# Compare with SCUBA observations\n";


$c = new Astro::Coords( planet => 'mars');
$c->telescope( $tel );

my $time = _gmstrptime("2002-03-21T03:16:36");
$c->datetime( $time);
print "#LST " . ($c->_lst * Astro::SLA::DR2H). "\n";
ok(sprintf("%.1f",$c->az(format => 'd')), '268.5');
ok(sprintf("%.1f",$c->el(format => 'd')), '60.3');

$c = new Astro::Coords( ra => '04:42:53.60',
			type => 'J2000',
			dec => '36:06:53.65',
			units => 'sexagesimal',
		      );
$c->telescope( $tel );

# Time is in UT not localtime
$time = _gmstrptime("2002-03-21T06:23:36");
$c->datetime( $time );
print "#LST " . ($c->_lst * Astro::SLA::DR2H). "\n";

ok(sprintf("%.1f",$c->az(format => 'd')), '301.7');
ok(sprintf("%.1f",$c->el(format => 'd')), '44.9');

# Comet Hale Bopp
$c = new Astro::Coords( elements => {
				     # Original
				     EPOCH => 50520.5,
				     ORBINC => 89.4300* Astro::SLA::DD2R,
				     ANODE =>  282.4707* Astro::SLA::DD2R,
				     PERIH =>  130.5887* Astro::SLA::DD2R,
				     AORQ => 0.914142,
				     E => 0.995068,
				    });
$c->telescope( $tel );

# Time is in UT not localtime
$time = _gmstrptime("1997-10-24T16:58:32");
#$time = _gmstrptime("1997-10-24T15:00:00");

$c->datetime( $time );
print "# MJD: " . $c->datetime->mjd ."\n";
print "# LST " . ($c->_lst * Astro::SLA::DR2H). "\n";

# Answer actually stored in the headers is 187.4az and 22.2el
# We get a slightly different answer. This is probably because
# the elements are slightly different. Need to test properly
# with a known position. 2 degrees in elevation is quite a lot!
ok(sprintf("%.1f",$c->az(format => 'd')), '187.6');
ok(sprintf("%.1f",$c->el(format => 'd')), '19.9');
print "# RA: " . $c->ra_app(format => 's') . "\n";
print "# Dec: " . $c->dec_app(format => 's') . "\n";


exit;

sub test_array_elem {
  my $ansref  = shift;  # The answer you got
  my $testref = shift;  # The answer you should have got

  # Compare sizes
  ok($#$ansref, $#$testref);

  for my $i (0..$#$testref) {
    ok($ansref->[$i], $testref->[$i]);
  }

}

sub _gmstrptime {
  # parse ISO date as UT
  my $input = shift;
  my $isoformat = "%Y-%m-%dT%T";
  my $time = Time::Piece->strptime($input, $isoformat);
  my $tzoffset = $date->tzoffset;
  return scalar(gmtime($time->epoch() + $tzoffset));
}
