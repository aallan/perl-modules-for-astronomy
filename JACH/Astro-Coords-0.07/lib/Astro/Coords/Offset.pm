package Astro::Coords::Offset;

=head1 NAME

Astro::Coords::Offset - Represent an offset from a base position

=head1 SYNOPSIS

  use Astro::Coords::Offset;

  my $offset = new Astro::Coords::Offset( 10, 20, 
                                          system => 'J2000',
                                          projection => "TAN" );

=head1 DESCRIPTION

Sometimes, it is necessary for a position to be specified that is
offset from the base tracking system. This class provides a means of
specifying an offset in a particular coordinate system and using a
specified projection.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use vars qw/ @PROJ  @SYSTEMS /;

our $VERSION = '0.01';

# Allowed projections
@PROJ = qw| SIN TAN ARC |;

# Allowed coordinate systems
@SYSTEMS = qw|
	      TRACKING
	      GAL
	      ICRS
	      ICRF
	      J2000
	      B1950
	      APP
	      HADEC
	      AZEL
	      MOUNT
	      OBS
	      FPLANE
	      |;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new Offset object. The first two arguments must be the offsets
in arcseconds. The projection and tracking system can be specified
as optional hash arguments (defaulting to TAN and J2000 respectively).

  my $off = new Astro::Coords::Offset( 10, -20 );

  my $off = new Astro::Coords::Offset( @off, system => "AZEL", 
                                             projection => "SIN");

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $dc1 = shift;
  my $dc2 = shift;

  croak "Offsets must be supplied to constructor"
    if (!defined $dc1 || !defined $dc2);

  my %options = @_;

  my $system = (exists $options{system} ? $options{system} : "J2000" );
  my $proj = (exists $options{projection} ? $options{projection} : "TAN" );

  # Create the object
  my $off = bless {
		   OFFSETS => [ $dc1, $dc2 ],
		   PROJECTION => undef,
		   SYSTEM       => undef,
		   TRACKING_SYSTEM => undef,
		  }, $class;

  # Use accessor to set so that we get validation
  $off->projection( $proj );
  $off->system( $system );
  $off->tracking_system( $options{tracking_system} )
    if exists $options{tracking_system};

  return $off;
}

=back

=head2 Accessor Methods

=over 4

=item B<offsets>

Return the X and Y offsets.

  @offsets = $self->offsets;

=cut

sub offsets {
  my $self = shift;
  return @{$self->{OFFSETS}};
}

=item B<system>

Coordinate system of this offset. Can be different to the coordinate
system of the base position.

Allowed values are J2000, B1950, AZEL plus others specified by the
JAC TCS XML (see L<"SEE ALSO"> section at end). TRACKING is special
since it can change, depending on which output coordinate frame is
in use. See the C<tracking_system> attribute for more details.

=cut

sub system {
  my $self = shift;
  if (@_) { 
    my $p = shift;
    $p = uc($p);
    my $match = join("|",@SYSTEMS);
    croak "Unknown system '$p'"
      unless $p =~ /^$match$/;
    $self->{SYSTEM} = $p;
  }
  return $self->{SYSTEM};
}

=item B<projection>

Return (or set) the projection that should be used for this offset.
Defaults to tangent plane. Allowed options are TAN, SIN or ARC.

=cut

sub projection {
  my $self = shift;
  if (@_) { 
    my $p = shift;
    $p = uc($p);
    my $match = join("|",@PROJ);
    croak "Unknown projection '$p'"
      unless $p =~ /^$match$/;
    $self->{PROJECTION} = $p; 
  }
  return $self->{PROJECTION};
}



#  From the TCS:
#   if (otype == direct)
#     {
#        *dc1 = t1 - b1;
#        *dc2 = t2 - b2;
#     }
#   else if (otype == tan_offset)
#     {
#        slaDs2tp(t1,t2,b1,b2,dc1,dc2,&jstat);
#     }
#   else if (otype == sin_offset)
#     {
#        da = t1 - b1;
#        cd = cos(t2);
#        *dc1 = cd * sin(da);
#        *dc2 = sin(t2)*cos(b2) - cd * sin(b2) * cos(da);
#     }
#   else if (otype == arc_offset)
#     {
#        da = t1 - b1;
#        cd = cos(t2);
#        sd = sin(t2);
#        cd0 = cos(b2);
#        sd0 = sin(b2);
#        cda = cos(da);
#        theta = acos(sd*sd0 + cd*cd0*cda);
#        to = theta/(sin(theta));
#        *dc1 = to*cd*sin(da);
#        *dc2 = to*(sd*cd0 - cd*sd0*cda);
#     }

=item B<tracking_system>

In some cases, the offset can be specified to be relative to the
system that the telescope is currently using to track the source.
This does not necessarily have to be the same as the coordinate
frame that was originally used to specify the target. For example,
it is perfectly acceptable to ask a telescope to go to a certain
Az/El and then ask it to track in RA/Dec.

This method allows the tracking system to be specified
independenttly of the offset coordinate system. It will only
be used if the offset is specified to use "TRACKING" (but it allows
the system to disambiguate an offset that was defined as "TRACKING B1950"
from an offset that is simply "B1950".

The allowed types are the same as for C<system> except that "TRACKING"
is not permitted.

=cut

sub tracking_system {
  my $self = shift;
  if (@_) { 
    my $p = shift;
    $p = uc($p);
    croak "Tracking System can not itself be 'TRACKING'"
      if $p eq 'TRACKING';
    my $match = join("|",@SYSTEMS);
    croak "Unknown system '$p'"
      unless $p =~ /^$match$/;
    $self->{TRACKING_SYSTEM} = $p;
  }
  return $self->{TRACKING_SYSTEM};
}

=head1 SEE ALSO

The allowed offset types are designed to match the specification used
by the Portable Telescope Control System configuration XML.
See L<http://www.jach.hawaii.edu/JACdocs/JCMT/OCS/ICD/006> for more
on this.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

Copyright 2002-2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
