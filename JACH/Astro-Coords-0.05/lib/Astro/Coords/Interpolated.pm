package Astro::Coords::Interpolated;


=head1 NAME

Astro::Coords::Interpolated - Specify astronomical coordinates using two reference positions

=head1 SYNOPSIS

  $c = new Astro::Coords::Elements( elements => \%elements );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
for moving sources specified as two coordinates at two epochs.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Interpolated( ra1 => '05:22:56',
					dec1 => '-26:20:44.4',
					mjd1 => 52440.5,
					ra2 => '05:23:56',
					dec2 => '-26:20:50.4',
					mjd2 => 52441.5,
					units =>
				      );

Returns undef on error. The positions are assumed to be apparent
RA/Dec. Units are optional (see C<Astro::Coords::Equatorial>).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts = @_;

  # Sanity check
  for (qw/ ra1 dec1 mjd1 ra2 dec2 mjd2 /) {
    return undef unless exists $opts{$_};
  }

  # Convert input args to radians
  $opts{ra1} = $class->_cvt_torad($opts{units}, $opts{ra1}, 1);
  $opts{dec1} = $class->_cvt_torad($opts{units}, $opts{dec1}, 0);
  $opts{ra2} = $class->_cvt_torad($opts{units}, $opts{ra2}, 1);
  $opts{dec2} = $class->_cvt_torad($opts{units}, $opts{dec2}, 0);

  bless \%opts, $class;

}


=back

=head2 Accessor Methods

=over 4

=item B<ra1>

Apparent Right Ascension of first reference position. Defaults to radians.

  $ra = $c->ra1( %opts );

Type of returned value is controlled with the same options
as defined in C<Astro::Coords::Equatorial>.

=cut

sub ra1 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  my $ra = $self->{ra1};
  # Convert to hours if we are using a string or hour format
  $ra = $self->_cvt_tohrs( \$opt{format}, $ra);
  my $retval = $self->_cvt_fromrad( $ra, $opt{format});

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec1>

Apparent declination of first reference position. Default
is to return it in radians.

  $dec = $c->dec1( format => "sexagesimal" );

=cut

sub dec1 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( $self->{dec1}, $opt{format});
}

=item B<mjd1>

Time (MJD) when the first reference position was valid.

=cut

sub mjd1 {
  my $self = shift;
  return $self->{mjd1};
}

=item B<ra2>

Apparent Right Ascension of second reference position. Defaults to radians.

  $ra = $c->ra2( %opts );

Type of returned value is controlled with the same options
as defined in C<Astro::Coords::Equatorial>.

=cut

sub ra2 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  my $ra = $self->{ra2};
  # Convert to hours if we are using a string or hour format
  $ra = $self->_cvt_tohrs( \$opt{format}, $ra);
  my $retval = $self->_cvt_fromrad( $ra, $opt{format});

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec2>

Apparent declination of second reference position. Default
is to return it in radians.

  $dec = $c->dec2( format => "sexagesimal" );

=cut

sub dec2 {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  return $self->_cvt_fromrad( $self->{dec2}, $opt{format});
}

=item B<mjd2>

Time (MJD) when the second reference position was valid.

=cut

sub mjd2 {
  my $self = shift;
  return $self->{mjd2};
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the
string "INTERP", the next ten elements as undef.

This method returns a standardised set of elements across all
types of coordinates.

The original design did not contain this type of coordinate specification
and so the array returned can not yet include it. Needs more work to integrate
into the other coordinate systems.

=cut

sub array {
  my $self = shift;
  my %el = $self->elements;
  return ( $self->type, undef, undef,
	   undef,undef,undef,undef,undef,undef,undef,undef);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "INTERP".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "INTERP";
}

=item B<stringify>

Stringify overload. Just returns the type.

=cut

sub stringify {
  my $self = shift;
  return $self->type;
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
  return sprintf("%-16s  %-12s  %-13s INTERP",$name,'','');
}

=item B<_apparent>

Return the apparent RA and Dec (in radians) for the current
coordinates and time.

  ($ra,$dec) = $c->_apparent();

Returns empty list on error.

Apparent RA/Dec is obtained by linear interpolation from the reference
positions. If the requested time lies outside the reference times
the position will be extrapolated.


=cut

sub _apparent {
  my $self = shift;
  my $tel = $self->telescope;
  my $long = (defined $tel ? $tel->long : 0.0 );
  my $lat = (defined $tel ? $tel->lat : 0.0 );

  my $mjd = $self->datetime->mjd;
  my $mjd1 = $self->mjd1;
  my $mjd2 = $self->mjd2;
  my $ra1  = $self->ra1;
  my $ra2  = $self->ra2;
  my $dec1 = $self->dec1;
  my $dec2 = $self->dec2;

  my ($ra,$dec);
  if ($self->mjd1 == $self->mjd2) {
    # special case when times are identical
    $ra = $self->ra1;
    $dec = $self->dec1;
  } else {
    # else linear interpolation
    $ra = $ra1  + ( $ra2  - $ra1  ) * ( $mjd - $mjd1 ) / ( $mjd2 - $mjd1 );
    $dec= $dec1 + ( $dec2 - $dec1 ) * ( $mjd - $mjd1 ) / ( $mjd2 - $mjd1 );
  }

  return($ra, $dec);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>. This is the coordinate style
used by SCUBA instead of using orbital elements.

Apparent RA/Decs suitable for use in this class can be obtained
from http://ssd.jpl.nasa.gov/.

=head1 SEE ALSO

L<Astro::Coords::Elements>

=head1 REQUIREMENTS

Does not use any external SLALIB routines.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
