package Astro::Coords::Planet;


=head1 NAME

Astro::Coords::Planet - coordinates relating to planetary motion

=head1 SYNOPSIS

  $c = new Astro::Coords::Planet( 'uranus' );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
for planets..

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Astro::SLA ();
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

our @PLANETS = qw/ sun mercury venus moon mars jupiter saturn
  uranus neptune pluto /;

# invert the planet for lookup
my $i = 0;
our %PLANET = map { $_, $i++  } @PLANETS;

=head1 METHODS


=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Planet( 'mars' );

Returns undef on error.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $planet = lc(shift);

  return undef unless defined $planet;

  # Check that we have a valid planet
  return undef unless exists $PLANET{$planet};

  bless { planet => $planet }, $class;

}



=back

=head2 Accessor Methods

=over 4

=item B<planet>

Returns the name of the planet.

=cut

sub planet {
  my $self = shift;
  return $self->{planet};
}

=item B<name>

For planets, the name is always just the planet name.

=cut

sub name {
  my $self = shift;
  return $self->planet;
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the planet
name.

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  return ($self->planet, undef, undef,
	  undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "PLANET";
}

=item B<stringify>

Stringify overload. Simple returns the name of the planet
in capitals.

=cut

sub stringify {
  my $self = shift;
  return uc($self->planet());
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
  return sprintf("%-16s  %-12s  %-13s PLANET",$name,'','');
}

=item B<_apparent>

Return the apparent RA and Dec (in radians) for the current
coordinates and time.

=cut

sub _apparent {
  my $self = shift;
  my $tel = $self->telescope;
  my $long = (defined $tel ? $tel->long : 0.0 );
  my $lat = (defined $tel ? $tel->lat : 0.0 );

  Astro::SLA::slaRdplan($self->_mjd_tt, $PLANET{$self->planet},
			$long, $lat, my $ra, my $dec, my $diam);
  return($ra, $dec);
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
