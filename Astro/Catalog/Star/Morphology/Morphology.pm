package Astro::Catalog::Star::Morphology;

=head1 NAME

Astro::Catalog::Star::Morphology - Information about a star's morphology.

=head1 SYNOPSIS

  $morphology = new Astro::Catalog::Star::Morphology( );

=head1 DESCRIPTION

Stores information about an astronomical object's morphology.

=cut

use 5.006;
use strict;
use warnings;
use vars qw/ $VERSION /;
use Carp;
use Class::Struct;

use warnings::register;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::Catalog::Star::Morphology> object.

$morphology = new Astro::Catalog::Star::Morphology( );

This method returns a reference to an C<Astro::Catalog::Star::Morphology>
object.

=cut

struct ( 'Astro::Catalog::Star::Morphology',
         { ellipticity => '$',
           position_angle_pixel => '$',
           position_angle_world => '$',
           major_axis_pixel => '$',
           minor_axis_pixel => '$',
           major_axis_world => '$',
           minor_axis_world => '$',
           area => '$',
         }
       );

=back

=head2 Accessor Methods

=over 4

=item B<ellipticity>

The ellipticity of the object.

=item B<position_angle_pixel>

Position angle using the pixel frame as a reference. Measured counter-
clockwise from the positive x axis.

=item B<position_angle_world>

Position angle using the world coordinate system as a reference. Measured
east of north.

=item B<major_axis_pixel>

Length of the semi-major axis in units of pixels.

=item B<minor_axis_pixel>

Length of the semi-minor axis in units of pixels.

=item B<major_axis_world>

Length of the semi-major axis in units of degrees.

=item B<minor_axis_world>

Length of the semi-minor axis in units of degrees.

=item B<area>

Area of the object, usually by using isophotal techniques, in square
pixels.

=back

=head1 REVISION

 $Id: Morphology.pm,v 1.2 2004/12/22 01:42:24 cavanagh Exp $

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
