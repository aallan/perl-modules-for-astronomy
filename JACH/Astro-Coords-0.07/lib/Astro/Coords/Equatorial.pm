package Astro::Coords::Equatorial;

=head1 NAME

Astro::Coords::Equatorial - Manipulate equatorial coordinates

=head1 SYNOPSIS

  $c = new Astro::Coords::Equatorial( name => 'blah',
				      ra   => '05:22:56',
				      dec  => '-26:20:40.4',
				      type => 'B1950'
				      units=> 'sexagesimal');

  $c = new Astro::Coords::Equatorial( name => 'Vega',
                                      ra => ,
                                      dec => ,
                                      type => 'J2000',
                                      units => 'sex',
                                      pm => [ 0.202, 0.286],
                                      parallax => 0.13,
                                      epoch => 2004.529,
                                      );


=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
specified in a fixed astronomical coordinate frame.

You are not expected to use this class directly, the C<Astro::Coords>
class should be used for all access (the C<Astro::Coords> constructor 
is treated as a factory constructor).

If proper motions and parallax information are supplied with a
coordinate it is assumed that the RA/Dec supplied is correct
for the given epoch. An equinox can be specified through the 'type'
constructor, where a 'type' of 'J1950' would be Julian epoch 1950.0.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

our $VERSION = '0.03';

use Astro::SLA ();
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Equatorial(
			  name =>
                          ra =>
                          dec =>
			  long =>
			  lat =>
                          pm =>
                          parallax =>
			  type =>
			  units =>
                          epoch =>
                         );

C<ra> and C<dec> are used for HMSDeg systems (eg type=J2000). Long and
Lat are used for degdeg systems (eg where type=galactic). C<type> can
be "galactic", "j2000", "b1950", and "supergalactic".  The C<units>
can be specified as "sexagesimal" (when using colon or space-separated
strings), "degrees" or "radians". The default is determined from
context. The name is just a string you can associate with the sky
position.

All coordinates are converted to FK5 J2000 [epoch 2000.0] internally.

Units of parallax are arcsec. Units of proper motion are arcsec/year
(no correction for declination; tropical year for B1950, Julian year
for J2000).  If proper motions are supplied they must both be supplied
in a reference to an array:

  pm => [ 0.13, 0.45 ],

If parallax and proper motions are given, the ra/dec coordinates are
assumed to be correct for the specified EQUINOX (Epoch = 2000.0 for
J2000, epoch = 1950.0 for B1950) unless an explicit epoch is
specified.  If the epoch is supplied it is assumed to be a Besselian
epoch for FK4 coordinates and Julian epoch for all others.

Usually called via C<Astro::Coords>.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  return undef unless exists $args{type};

  # make sure we are upper cased.
  $args{type} = uc($args{type});

  # Convert input args to radians
  $args{ra} = $class->_cvt_torad($args{units}, $args{ra}, 1)
    if exists $args{ra};
  $args{dec} = $class->_cvt_torad($args{units}, $args{dec}, 0)
    if exists $args{dec};
  $args{long} = $class->_cvt_torad($args{units}, $args{long}, 0)
    if exists $args{long};
  $args{lat} = $class->_cvt_torad($args{units}, $args{lat}, 0)
    if exists $args{lat};

  # Default values for parallax and proper motions
  my( $pm, $parallax );
  if( exists( $args{parallax} ) ) {
    $parallax = $args{parallax};
  } else {
    $parallax = 0;
  }
  if( exists( $args{pm} ) ) {
    $pm = $args{pm};
  } else {
    $pm = [0,0];
  }

  # Try to sort out what we have been given. We need to convert
  # everything to FK5 J2000
  croak "Proper motions are supplied but not as a ref to array"
    unless ref($pm) eq 'ARRAY';

  # Extract the proper motions into convenience variables
  my $pm1 = $pm->[0];
  my $pm2 = $pm->[1];

  my ($ra, $dec);

  if ($args{type} =~ /^j([0-9\.]+)/i) {
    return undef unless exists $args{ra} and exists $args{dec};
    return undef unless defined $args{ra} and defined $args{dec};

    $ra = $args{ra};
    $dec = $args{dec};

# The equinox is everything after the J.
    my $equinox = $1;

# Wind the RA/Dec to J2000 if the equinox isn't 2000.
    if( $equinox != 2000 ) {
      Astro::SLA::slaPreces( 'FK5', $equinox, '2000.0', $ra, $dec );
    }

# Get the epoch. If it's not given (in $args{epoch}) then it's
# the same as the equinox.
    my $epoch = ( ( exists( $args{epoch} ) && defined( $args{epoch} ) ) ?
                  $args{epoch} :
                  $equinox );

# Wind the RA/Dec to epoch 2000.0 if the epoch isn't 2000.0,
# taking the proper motion and parallax into account.
    if( $epoch != 2000 &&
        ( $pm1 != 0 || $pm2 != 0 || $parallax != 0 ) ) {
      my ( $ra0, $dec0 );
      Astro::SLA::slaPm( $ra, $dec,
                         Astro::SLA::DAS2R * $pm1,
                         Astro::SLA::DAS2R * $pm2,
                         $parallax,
                         0.0, # radial velocity
                         $epoch,
                         2000.0,
                         $ra0,
                         $dec0 );
      $ra = $ra0;
      $dec = $dec0;
    }

  } elsif ($args{type} =~ /^b([0-9\.]+)/i) {
    return undef unless exists $args{ra} and exists $args{dec};
    return undef unless defined $args{ra} and defined $args{dec};

    $ra = $args{ra};
    $dec = $args{dec};

# The equinox is everything after the B.
    my $equinox = $1;

# Get the epoch. If it's not given (in $args{epoch}) then it's
# the same as the equinox.
    my $epoch = ( ( exists( $args{epoch} ) && defined( $args{epoch} ) ) ?
                  $args{epoch} :
                  $equinox );

    my ( $ra0, $dec0 );

# For the implementation details, see section 4.1 of SUN/67.
    if( $pm1 != 0 || $pm2 != 0 || $parallax != 0 ) {
      Astro::SLA::slaPm( $ra, $dec,
                         Astro::SLA::DAS2R * $pm1,
                         Astro::SLA::DAS2R * $pm2,
                         $parallax,
                         0.0,
                         $epoch,
                         2000.0,
                         $ra0,
                         $dec0 );
      $ra = $ra0;
      $dec = $dec0;
    }

    if( $equinox != 1950 ) {

# Remove the E-terms.
      my ( $ra0, $dec0 );
      Astro::SLA::slaSubet( $ra, $dec, $equinox, $ra0, $dec0 );
      $ra = $ra0;
      $dec = $dec0;

# Wind the RA/Dec to B1950 if the equinox isn't 1950.
      Astro::SLA::slaPreces( 'FK4', $equinox, 1950.0, $ra, $dec );

# Add the E-terms back in.
      Astro::SLA::slaAddet( $ra, $dec, 1950.0, $ra0, $dec0 );
      $ra = $ra0;
      $dec = $dec0;
    }

# Convert to J2000, no proper motion. We need the epoch at which the
# coordinate was valid
    Astro::SLA::slaFk45z($ra, $dec,
			 $epoch,
                         $ra0, $dec0
                        );
    $ra = $ra0;
    $dec = $dec0;

  } elsif ($args{type} eq "GALACTIC") {
    return undef unless exists $args{long} and exists $args{lat};
    return undef unless defined $args{long} and defined $args{lat};

    Astro::SLA::slaGaleq( $args{long}, $args{lat}, $ra, $dec);

  } elsif ($args{type} eq "SUPERGALACTIC") {
    return undef unless exists $args{long} and exists $args{lat};
    return undef unless defined $args{long} and defined $args{lat};

    Astro::SLA::slaSupgal( $args{long}, $args{lat}, my $glong, my $glat);
    Astro::SLA::slaGaleq( $glong, $glat, $ra, $dec);

  } else {
    my $type = (defined $args{type} ? $args{type} : "<undef>");
    croak "Supplied coordinate type [$type] not recognized";
  }

  # Now the actual object
  bless { ra2000 => $ra, dec2000 => $dec, name => $args{name},
	  pm => $args{pm}, parallax => $args{parallax}
	}, $class;


}


=back

=head2 Accessor Methods

=over 4

=item B<ra>

Retrieve the Right Ascension (FK5 J2000) for the date stored in the
C<datetime> method. Defaults to current date if no time is stored
in the object.

  $ra = $c->ra( format => 's' );

For J2000 coordinates without proper motions or parallax, this will
return the same values as returned from the C<ra2000> method.

=cut

sub ra {
  my $self = shift;

  # If we have proper motions we need to take them into account
  # Do this using slaPm rather than via the base class since it
  # must be more efficient than going through apparent 
  my @pm = $self->pm;
  my $par = $self->parallax;

  # Fix PM array and parallax if none-defined
  @pm = (0,0) unless @pm;
  $par = 0 unless defined $par;

  my $ra;
  $ra = $self->ra2000();

  if ($pm[0] != 0 || $pm[1] != 0 || $par != 0) {

    # We have proper motions
    my $dec = $self->dec2000();

    Astro::SLA::slaPm( $ra, $dec, Astro::SLA::DAS2R * $pm[0],
		       Astro::SLA::DAS2R * $pm[1], $par, 0, 2000.0,
		       Astro::SLA::slaEpj($self->_mjd_tt), $ra, $dec );

# Take care of parallax.
    if( $par != 0 ) {
      my ( @w, @eb );
      Astro::SLA::slaEvp( $self->_mjd_tt, 2000.0,
                          @w, @eb, @w, @w );

      my @v;
      Astro::SLA::slaDcs2c( $ra, $dec, @v );
      for ( 0..2 ) {
        $v[$_] -= $par * Astro::SLA::DAS2R * $eb[$_];
      }
      Astro::SLA::slaDcc2s( @v, $ra, $dec );

      $ra = Astro::SLA::slaDranrm( $ra );
    }
  }

  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};

  # Convert to hours if we are using a string or hour format
  $ra = $self->_cvt_tohrs( \$opt{format}, $ra);
  my $retval = $self->_cvt_fromrad( $ra, $opt{format});

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;

}

=item B<dec>

Retrieve the Declination (FK5 J2000) for the date stored in the
C<datetime> method. Defaults to current date if no time is stored
in the object.

  $dec = $c->dec( format => 's' );

For J2000 coordinates without proper motions or parallax, this will
return the same values as returned from the C<dec2000> method.

=cut

sub dec {
  my $self = shift;

  # If we have proper motions we need to take them into account
  # Do this using slaPm rather than via the base class since it
  # must be more efficient than going through apparent 
  my @pm = $self->pm;
  my $par = $self->parallax;

  # Fix PM array and parallax if none-defined
  @pm = (0,0) unless @pm;
  $par = 0 unless defined $par;

  my $dec = $self->dec2000();
  if ($pm[0] != 0 || $pm[1] != 0 || $par != 0) {
    # We have proper motions
    my $ra = $self->ra2000();

    Astro::SLA::slaPm( $ra, $dec, Astro::SLA::DAS2R * $pm[0], 
		       Astro::SLA::DAS2R * $pm[1], $par, 0, 2000.0,
		       Astro::SLA::slaEpj($self->_mjd_tt), $ra, $dec );

# Take care of parallax.
    if( $par != 0 ) {
      my ( @w, @eb );
      Astro::SLA::slaEvp( $self->_mjd_tt, 2000.0,
                          @w, @eb, @w, @w );

      my @v;
      Astro::SLA::slaDcs2c( $ra, $dec, @v );
      for ( 0..2 ) {
        $v[$_] -= $par * Astro::SLA::DAS2R * $eb[$_];
      }
      Astro::SLA::slaDcc2s( @v, $ra, $dec );
    }
  }

  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( $dec, $opt{format});

}

=item B<ra2000>

Retrieve the Right Ascension (FK5 J2000, epoch 2000.0). Default
is to return it in radians.

The coordinates returned by this method are B<not> adjusted for proper
motion or parallax. Use the C<ra> method if you want J2000, reference epoch.

  $ra = $c->ra2000( format => "s" );

The optional hash arguments can have the following keys:

=over 4

=item format

The required formatting for the declination:

  radians     - (the default)
  degrees     - decimal
  sexagesimal - a string (hours/minutes/seconds)
  hours       - decimal hours
  array       - a ref to an array containing hour/min/sec

=back

=cut

sub ra2000 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  my $ra = $self->{ra2000};
  # Convert to hours if we are using a string or hour format
  $ra = $self->_cvt_tohrs( \$opt{format}, $ra);
  my $retval = $self->_cvt_fromrad( $ra, $opt{format});

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec2000>

Retrieve the declination (FK5 J2000, epoch 2000.0). Default
is to return it in radians.

  $dec = $c->dec( format => "sexagesimal" );

The coordinates returned by this method are B<not> adjusted for proper
motion or parallax. Use the C<ra> method if you want J2000, reference epoch.

The optional hash arguments can have the following keys:

=over 4

=item format

The required formatting for the declination:

  radians     - (the default)
  degrees     - decimal
  sexagesimal - a string (degrees/minutes/seconds)
  array       - a ref to an array containing sign/degrees/min/sec

=back

=cut

sub dec2000 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( $self->{dec2000}, $opt{format});
}


=item B<parallax>

Retrieve (or set) the parallax of the target. Units should be
given in arcseconds. There is no default.

  $par = $c->parallax();
  $c->parallax( 0.13 );

=cut

sub parallax {
  my $self = shift;
  if (@_) {
    $self->{parallax} = shift;
  }
  return $self->{parallax};
}

=item B<pm>

Proper motions in units of arcsec / Julian year (not corrected for
declination).

  @pm = $self->pm();
  $self->pm( $pm1, $pm2);

If the proper motions are not defined, an empty list will be returned.

=cut

sub pm {
  my $self = shift;
  if (@_) {
    my $pm1 = shift;
    my $pm2 = shift;
    if (!defined $pm1) {
      warnings::warnif("Proper motion 1 not defined. Using 0.0 arcsec/year");
      $pm1 = 0.0;
    }
    if (!defined $pm2) {
      warnings::warnif("Proper motion 2 not defined. Using 0.0 arcsec/year");
      $pm2 = 0.0;
    }
    $self->{pm} = [ $pm1, $pm2 ];
  }
  if( !defined( $self->{pm} ) ) { $self->{pm} = []; }
  return @{ $self->{pm} };
}

=back

=head2 General Methods

=over 4

=item B<array>

Return back 11 element array with first 3 elements being the
coordinate type (RADEC) and the ra/dec coordinates in J2000
(radians).

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  return ( $self->type, $self->ra, $self->dec,
	   undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<glong>

Return Galactic longitude. Arguments are similar to those specified
for "dec".

  $glong = $c->glong( format => "s" );

=cut

sub glong {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_glonglat)[0], $opt{format});
}

=item B<glat>

Return Galactic latitude. Arguments are similar to those specified
for "dec".

  $glat = $c->glat( format => "s" );

=cut

sub glat {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_glonglat)[1], $opt{format});
}

=item B<sglong>

Return SuperGalactic longitude. Arguments are similar to those specified
for "dec".

  $sglong = $c->sglong( format => "s" );

=cut

sub sglong {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_sglonglat)[0], $opt{format});
}

=item B<sglat>

Return SuperGalactic latitude. Arguments are similar to those specified
for "dec".

  $glat = $c->sglat( format => "s" );

=cut

sub sglat {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_sglonglat)[1], $opt{format});
}

=item B<ecllong>

Return Ecliptic longitude. Arguments are similar to those specified
for "dec".

  $eclong = $c->ecllong( format => "s" );

=cut

sub ecllong {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_ecllonglat)[0], $opt{format});
}

=item B<ecllat>

Return ecliptic latitude. Arguments are similar to those specified
for "dec".

  $eclat = $c->ecllat( format => "s" );

=cut

sub ecllat {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( ($self->_ecllonglat)[1], $opt{format});
}


=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

=cut

sub type {
  return "RADEC";
}

=item B<stringify>

A string representation of the object.

Returns RA and Dec (J2000) in string format.

=cut

sub stringify {
  my $self = shift;
  return $self->ra(format=>"s") . " " . $self->dec(format =>"s");
}

=item B<summary>

Return a one line summary of the coordinates.
In the future will accept arguments to control output.

  $summary = $c->summary();

=cut

sub summary {
  my $self = shift;
  my $name = $self->name;
  $name = '' unless defined $name;
  return sprintf("%-16s  %-12s  %-13s  J2000",$name,
		 $self->ra(format=>"s"),
		 $self->dec(format =>"s"));
}


=back

=head2 Private Methods

=over 4

=item B<_glonglat>

Calculate Galactic longitude and latitude.

 ($long, $lat) = $c->_glonglat;

=cut

sub _glonglat {
  my $self = shift;
  my $ra = $self->ra;
  my $dec = $self->dec;
  # Really need to cache this
  slaEqgal( $ra, $dec, my $long, my $lat );
  return ($long, $lat);
}

=item B<_sglonglat>

Calculate Super Galactic longitude and latitude.

 ($slong, $slat) = $c->_sglonglat;

=cut

sub _sglonglat {
  my $self = shift;
  my ($glong, $glat) = $self->_glonglat();
  slaGalsup( $glong, $glat, my $sglong, my $sglat);
  return ($sglong, $sglat);
}

=item B<_ecllonglat>

Calculate the ecliptic longitude and latitude for the epoch stored
in the object.

 ($long, $lat) = $c->_ecllonglat();

=cut

sub _ecllonglat {
  my $self = shift;
  my $ra = $self->ra;
  my $dec = $self->dec;
  # Really need to cache this
  Astro::SLA::slaEqecl( $ra, $dec, $self->_mjd_tt, my $long, my $lat );
  return ($long, $lat);
}

=item B<_apparent>

Return the apparent RA and Dec (in radians) for the current
coordinates and time.

=cut

sub _apparent {
  my $self = shift;
  my $ra = $self->ra2000;
  my $dec = $self->dec2000;
  my $mjd = $self->_mjd_tt;
  my $par = $self->parallax;
  my @pm = $self->pm;

  @pm = (0,0) unless @pm;
  $par = 0.0 unless defined $par;

  Astro::SLA::slaMap( $ra, $dec,
		      Astro::SLA::DAS2R * $pm[0],
		      Astro::SLA::DAS2R * $pm[1], $par, 0.0, 2000.0, $mjd,
		      my $ra_app, my $dec_app);

  # Convert from observed to apparent place
#  Astro::SLA::slaOap("r", $ra_app, $dec_app, $mjd, 0.0, $long, $lat,
#                     0.0,0.0,0.0,
#                     0.0,0.0,0.0,0.0,0.0,$ra, $dec);


  return ($ra_app, $dec_app);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::SLA> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2003 Particle Physics and Astronomy Research Council.
All Rights Reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
