package Astro::Coords::Elements;


=head1 NAME

Astro::Coords::Elements - Specify astronomical coordinates using orbital elements

=head1 SYNOPSIS

  $c = new Astro::Coords::Elements( elements => \%elements );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
specified as orbital elements.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

# Need working slaPlante
use Astro::SLA 0.95 ();
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS


=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Elements( elements => \%elements );

Returns undef on error.

The elements must be specified in a hash containing the following
keys:

suitable for the major planets:

 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC          =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  longitude of perihelion  [$\varpi$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e 
 AORL 		 =  mean longitude L (radians)
 DM 		 =  daily motion n (radians)

suitable for minor planets:


 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e
 AORL 		 =  mean anomaly M (radians)

suitable for comets:


 EPOCH 		 =  epoch of perihelion T (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  perihelion distance q (AU)
 E 		 =  eccentricity e

See the documentation to slaPlante() for more information.
Keys must be upper case.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts = @_;
  return undef unless (exists $opts{elements}
    && ref($opts{elements}) eq "HASH");

  # Sanity check
  for (qw/ EPOCH ORBINC ANODE PERIH AORQ E/) {
    return undef unless exists $opts{elements}->{$_};
  }


  # Copy the elements
  my %el = %{ $opts{elements}};

  bless { elements => \%el }, $class;

}



=back

=head2 Accessor Methods

=over 4

=item B<elements>

Returns the hash containing the elements.

  %el = $c->elements;

=cut

sub elements {
  my $self = shift;
  return %{ $self->{elements}};
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the
string "ELEMENTS", the next two elements as undef and up to 8
following elements containing the orbital elements in the order
presented in the documentation of the constructor.

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  my %el = $self->elements;
  return ( $self->type, undef, undef,
	   $el{EPOCH}, $el{ORBINC}, $el{ANODE}, $el{PERIH}, 
	   $el{AORQ}, $el{E}, $el{AORL}, $el{DM});
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "ELEMENTS";
}

=item B<stringify>

Stringify overload. Returns comma-separated list of 
the elements.

=cut

sub stringify {
  my $self = shift;
  my %el = $self->elements;
  my $str = join(",", values %el);
  return $str;
}

=item B<_apparent>

Return the apparent RA and Dec (in radians) for the current
coordinates and time.

Returns empty list on error.

=cut

sub _apparent {
  my $self = shift;
  my $tel = $self->telescope;
  my $long = (defined $tel ? $tel->long : 0.0 );
  my $lat = (defined $tel ? $tel->lat : 0.0 );
  my %el = $self->elements;
  my $jform;
  if (exists $el{DM} and defined $el{DM}) {
    $jform = 1;
  } elsif (exists $el{AORL} and defined $el{AORL}) {
    $jform = 2;
    $el{DM} = 0;
  } else {
    $jform = 3;
    $el{DM} = 0;
    $el{AORL} = 0;
  }

  Astro::SLA::slaPlante($self->datetime->mjd, $long, $lat, $jform,
			$el{EPOCH}, $el{ORBINC}, $el{ANODE}, $el{PERIH}, 
			$el{AORQ}, $el{E}, $el{AORL}, $el{DM}, 
			my $ra, my $dec, my $dist, my $j);

  return () if $j != 0;
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
