package Astro::Coords::Angle::Hour;

=head1 NAME

Astro::Coords::Angle::Hour - Representation of an angle in units of hours

=head1 SYNOPSIS

  use Astro::Coords::Angle::Hour;

  $ha = new Astro::Coords::Angle::Hour( "12h30m22.4s", units => 'sex');
  $ha = new Astro::Coords::Angle::Hour( 12.53, units => 'hour);

=head1 DESCRIPTION

Class similar to C<Astro::Coords::Angle> but representing the angle
as a time. Suitable for use as hour angle or Right Ascension.
Inherits from C<Astro::Coords::Angle>.

For hour angle a range of "PI" is suitable, for Right Ascension use "2PI".
Default range is none at all.

=cut


use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::SLA;

use base qw/ Astro::Coords::Angle /;

# Package Global variables
use vars qw/ $VERSION /;

$VERSION = '0.01';

=head1 METHODS

=head2 Accessor Methods

=over 4

=item B<hours>

Return the angle in decimal hours.

 $deg = $ang->hours;

=cut

sub hours {
  my $self = shift;
  my $rad = $self->radians;
  return $rad * Astro::SLA::DR2H;
}

=back

=head2 Class Methods

The following methods control the default behaviour of the class.

=over 4

=item B<NDP>

As for the base class except that the default number of decimal places
is 1.

This method has no effect on the base class.

=cut

{
  my $DEFAULT_NDP = 1;
  my $NDP = $DEFAULT_NDP;
  sub NDP {
    my $class = shift;
    if (@_) { 
      my $arg = shift;
      if (defined $arg) {
	$NDP = $arg;
      } else {
	$NDP = $DEFAULT_NDP;
      }
    }
    return $NDP;
  }
}

=item B<DELIM>

As for the base class, except that the default is "hms".
The global value in this class does not have any effect on the base
class.

=cut

{
  my $DEFAULT_DELIM = "hms";
  my $DELIM = $DEFAULT_DELIM;
  sub DELIM {
    my $class = shift;
    if (@_) { 
      my $arg = shift;
      if (defined $arg) {
	$DELIM = $arg;
      } else {
	$DELIM = $DEFAULT_DELIM;
      }
    }
    return $DELIM;
  }
}


=back


=begin __PRIVATE_METHODS__

=head2 Private Methods

These methods are not part of the API and should not be called directly.
They are documented for completeness.

=over 4

=item B<_cvt_torad>

Same as the base class, except that if the units are hours
or sexagesimal, the resulting number is multiplied by 15 before being
passed up to the constructor (since 24 hours is equivalent to 360 degrees).

=cut

sub _cvt_torad {
  my $self = shift;
  my $input = shift;
  my $units = shift;

  # if units are hours, tell the base class we have degrees
  my $unt = $units;
  if (defined $units && $units =~ /^h/) {
    $unt = 'deg';
  } elsif (!defined $units) {
    $unt = $self->_guess_uniuts( $input );
  }

  # Do the conversion
  my $rad = $self->SUPER::_cvt_torad( $input, $unt );

  # scale if we had sexagesimal or hour as units
  if ($unt =~ /^[sh]/) {
    $rad *= 15;
  }

  return $rad;
}

=item B<_r2f>

Routine to convert angle in radians to a formatted array
of numbers in order of sign, hour, min, sec, frac.

  @retval = $ang->_r2f( $ndp );

Note that the number of decimal places is an argument.

=cut

sub _r2f {
  my $self = shift;
  my $res = shift;
  my @dmsf;
  Astro::SLA::slaDr2tf($res, $self->radians, my $sign, @dmsf);
  return ($sign, @dmsf);
}

=end __PRIVATE_METHODS__

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

Copyright (C) 2004 Tim Jenness. All Rights Reserved.

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
