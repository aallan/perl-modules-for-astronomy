
use Test;
BEGIN { plan tests => 94 }

use Astro::WaveBand;
use warnings;
use strict;

ok(1);

print "# ====== Test constructor ======\n";

# First test that we can not construct a bad object
my $w = new Astro::WaveBand( Wavelength => 850,
			     Instrument => 'SCUBA');

ok($w);

# These will return undef and raise an warning
{
  no warnings 'Astro::WaveBand';
  $w = new Astro::WaveBand( Wavelength => 850, Frequency => 345E9);
  ok($w, undef);

  $w = new Astro::WaveBand();
  ok($w, undef);

  $w = new Astro::WaveBand( Instrument => 'UFTI');
  ok($w, undef);
}


# Set up the tests
my @tests = (
	     { 
	      _init => { Wavelength => '1.635',
			 Instrument => 'UFTI'
		       },
	      filter => 'H98',
	      wavelength => '1.635',
	      natural => 'H98',
	      waveband => 'infrared',
	     },
	     { 
	      _init => { Wavelength => '1.634999999',
			 Instrument => 'UFTI'
		       },
	      filter => 'H98',
	      wavelength => '1.635',
	      natural => 'H98',
	      waveband => 'infrared',
	     },
	     { 
	      _init => { Filter => 'BrG', 
			 Instrument => 'IRCAM'
		       },
	      filter => 'BrG',
	      wavelength => '2.0',
	      natural => 'BrG',
	      waveband => 'infrared',
	     },
	     {
	      _init => { Wavelength => 2.226,
			 Instrument => 'IRCAM'
		       },
	      filter => undef,
	      wavelength => 2.226,
	      natural => 2.226,
	      waveband => 'infrared',
	     },
	     {
	      _init => { Filter => '450W',
			 Instrument => 'SCUBA'
		       },
	      filter => '450W',
	      wavelength => '443',
	      frequency => 676732410835.214,
	      natural => '450W',
	      waveband => 'submm',
	     },
	     {
	      _init => { Frequency => 22E9,
		       },
	      filter => undef,
	      wavelength => 13626.9299090909,
	      frequency => 22E9,
	      natural => 13626.9299090909,
	      waveband => 'radio',
	     },
	     {
	      _init => { Filter => 'I',
		       },
	      filter => 'I',
	      wavelength => 0.90,
	      wavenumber => 11111.1111111111,
	      natural => 'I',
	      waveband => 'optical',
	     },
	     {
	      _init => { Filter => 'U',
		       },
	      filter => 'U',
	      wavelength => 0.365,
	      wavenumber => 27397.2602739726,
	      natural => 'U',
	      waveband => 'optical',
	     },
	     {
	      _init => { Wavenumber => 1500,
		       },
	      filter => undef,
	      wavelength => 6.66666666666667,
	      wavenumber => 1500,
	      natural => 6.66666666666667,
	      waveband => 'infrared',
	     },
	     {
	      _init => { Filter => "F79B10",
			 Instrument => 'MICHELLE',
		       },
	      filter => "F79B10",
	      wavelength => 7.9,
	      wavenumber => 1265.82278481013,
	      natural => "F79B10",
	      waveband => 'infrared',
	     },
	     {
	      _init => { Filter => "F79B10",
			 Instrument => 'MICHELLE',
		       },
	      filter => "F79B10",
	      wavelength => 7.9,
	      wavenumber => 1265.82278481013,
	      natural => "F79B10",
	      waveband => 'infrared',
	     },
	     {
	      _init => { Wavelength => 3.367,
			 Instrument => 'CGS4',
		       },
	      filter => undef,
	      wavelength => 3.367,
	      wavenumber => 2970.00297000297,
	      frequency => 89038449064449.1,
	      natural => 3.367,
	      waveband => 'infrared',
	     },
	     {
	      _init => { Wavelength => 7.9,
			 Instrument => 'MICHELLE',
		       },
	      filter => "F79B10",
	      wavelength => 7.9,
	      wavenumber => 1265.82278481013,
	      natural => "F79B10",
	      waveband => 'infrared',
	     },
	     {
	      _init => {Frequency => 345.0E9,
			Instrument => 'RXA3',
		       },
	      filter => undef,
	      wavelength => 868.9636,
	      waveband => 'submm',
	      natural => 345E9,
	     }
	    );

print "# ====== Test behaviour ======\n";

for my $test (@tests) {
  my $obj = new Astro::WaveBand( %{ $test->{_init} });
  print "# Object creation\n";
  ok($obj);

  for my $key (keys %$test) {
    next if $key eq '_init';
    unless (defined $obj) {
      skip("skip Object could not be instantiated so no point trying",1);
      next;
    }

    # Correct for significant figures since we have problems
    # with precision. The problem is that natural can be either
    # number or string. Hope there is no problem with 5.5E257 
    # matching as a string...
    my $correct = $test->{$key};
    $correct = sprintf("%7e", $correct) 
      if (defined $correct and $correct !~ /[A-Za-z]/);

    my $fromobj = $obj->$key;
    $fromobj = sprintf("%7e", $fromobj) 
      if (defined $fromobj and $fromobj !~ /[A-Za-z]/);

    # print $obj->$key,"\n";
    print "# $key: ",( defined $correct ? $correct : "<UNDEF>" ) , "\n";

    ok($fromobj, $correct);
  }

}

print "# ====== Test Alasdair's Modifications ======\n";

# static methods Astro::WaveBand

ok( Astro::WaveBand::has_filter( UIST => 'J98') );
ok( !Astro::WaveBand::has_filter( UIST => 'Kprime') );
ok(Astro::WaveBand::has_filter( UIST => 'J98', IRCAM => 'K98'));
ok(!Astro::WaveBand::has_filter( UIST => 'H98', IRCAM => 'K97'));

ok( Astro::WaveBand::has_instrument( UKIRT => 'UIST' ) );
ok( !Astro::WaveBand::has_instrument( UKIRT => 'SCUBA' ) );

ok( Astro::WaveBand::is_observable( UKIRT => 'Kprime' ) );
ok( !Astro::WaveBand::is_observable( UKIRT => '850N' ) );
ok( Astro::WaveBand::is_observable( JCMT => '850N' ) );

exit;
