package Astro::Coords::Fixed;

=head1 NAME

Astro::Coords::Fixed - Manipulate coordinates that are fixed on the sky

=head1 SYNOPSIS

  $c = new Astro::Coords::Fixed( az => 180,
                                 el => 45,
				 units => 'degrees');

  $c = new Astro::Coords::Fixed( ha => '02:30:00.0',
				 dec => '45:30:03',
				 units => 'sexagesimal',
				 tel => $telescope,
			       );

=head1 DESCRIPTION

This subclass of C<Astro::Coords> allows for the manipulation
of coordinates that are fixed on the sky. Sometimes a telescope
should be commanded to go to a fixed location (eg for a calibration)
and this class puts those coordinates (Azimuth and elevation for telescopes
such as JCMT and Gemini and Hour Angle and Declination for equatorial
telescopes such as UKIRT) on the same footing as astronomical coordinates.

Note that Azimuth and elevation do not require the telescope latitude
whereas Hour Angle and declination does.

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Astro::SLA ();
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Constructor. Recognizes hash keys "ha", "dec" and "az", "el".

  $c = new Astro::Coords::Fixed( az => 35, el => 30 );

  $c = new Astro::Coords::Fixed( ha => $ha, dec => $dec, tel => $tel);

Usually called via C<Astro::Coords> rather than directly.

Note that the declination is equivalent to "Apparent Dec" used
elsewhere in these classes.

Azimuth and Elevation is the internal format. Currently there is no
caching (so there is always overhead converting to apparent 
RA and Dec) since there is no cache flushing when the telescope
is changed.

In principal a name can be associated with this position.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  # We will always calculate ha, dec, az and el
  my ($az, $el);

  # Create a new object
  my $c = bless { }, $class;

  # Store the telescope if we have one
  $c->telescope( $args{tel} ) if exists $args{tel};

  if (exists $args{ha} && exists $args{dec} and exists $args{tel}
     and UNIVERSAL::isa($args{tel}, "Astro::Telescope")) {
    # HA and Dec

    # Convert input args to radians
    my $ha = $class->_cvt_torad($args{units}, $args{ha}, 1);
    my $dec = $class->_cvt_torad($args{units}, $args{dec}, 0);

    # Convert to "native" format
    my $lat = $args{tel}->lat;
    Astro::SLA::slaDe2h( $ha, $dec, $lat, $az, $el);

  } elsif (exists $args{az} and exists $args{el}) {
    # Az and El

    # Convert input args to radians
    $az = $class->_cvt_torad($args{units}, $args{az}, 0);
    $el = $class->_cvt_torad($args{units}, $args{el}, 0);

  } else {
    return undef;
  }

  # Store the name
  $c->name( $args{name} ) if exists $args{name};

  # Store it in the object
  $c->_azel( $az, $el );

  return $c;
}


=back

=head2 Accessor Methods

=over 4

=item B<_azel>

Return azimuth and elevation (in radians)

 ($az, $el) = $c->_azel;

Can also be used to store the azimuth and elevation
(in radians).

  $c->_azel( $az, $el);

=cut

sub _azel {
  my $self = shift;
  if (@_) {
    $self->{Az} = shift;
    $self->{El} = shift;
  }
  return ($self->{Az}, $self->{El});
}

=back

=head2 General Methods

=over 4

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "FIXED".

This is used to aid construction of summary tables when using
mixed coordinates.

=cut

sub type {
  return "FIXED";
}

=item B<stringify>

Returns a string representation of the object. Returns
Azimth and Elevation in degrees.

=cut

sub stringify {
  my $self = shift;
  my $az = $self->az( format => "degrees" );
  my $el = $self->el( format => "degrees" );
  return "$az $el";
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
  return sprintf("%-16s  %-12s  %-13s   AZEL",$name,
		 $self->az(format=>"s"),
		 $self->el(format =>"s"));
}

=item B<array>

Array summarizing the object. Retuns 
Return back 11 element array with first 3 elements being the
coordinate type (FIXED) and the az/el coordinates
(radians).

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  return ( $self->type, $self->az, $self->el,
	   undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<ha>

Get the hour angle for the currently stored LST. Default units are in
radians.

  $ha = $c->ha;
  $ha = $c->ha( format => "deg" );

=cut

sub ha {
  my $self = shift;
  my %opt = @_;
  $opt{format} = "radians" unless defined $opt{format};
  my $ha = ($self->_hadec)[0];
  # Convert to hours if we are using a string or hour format
  $ha = $self->_cvt_tohrs( \$opt{format}, $ha);
  return $self->_cvt_fromrad( $ha, $opt{format});
}

=item B<_apparent>

Return the apparent RA and Dec (in radians)
for the current time [note that the apparent declination
is fixed and the apparent RA changes].

If no telescope is present the equator is used.

=cut

sub _apparent {
  my $self = shift;

  my ($ha, $dec_app) = $self->_hadec;
  my $ra_app = $self->_lst - $ha;

  return( $ra_app, $dec_app);
}

=item B<_hadec>

Return the Hour angle and apparent declination (in radians).
If no telescope is present the equator is used.

 ($ha, $dec) = $c->_hadec;

=cut

sub _hadec {
  my $self = shift;
  my $az = $self->az;
  my $el = $self->el;
  my $tel = $self->telescope;
  my $lat = ( defined $tel ? $tel->lat : 0.0);

  # First need to get the hour angle and declination from the Az and El
  Astro::SLA::slaDh2e($az, $el, $lat, my $ha, my $dec_app);

  return ($ha, $dec_app);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::SLA> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
