package Astro::Catalog::IO::Astrom;

=head1 NAME

Astro::Catalog::IO::Astrom - Starlink Astrom catalogue I/O for
Astro::Catalog.

=head1 SYNOPSIS

  \@lines = Astro::Catalog::IO::Astrom->_write_catalog( $catalog );

=head1 DESCRIPTION

This class provides a write method for catalogues to be used as
import to Starlink Astrom. The method is not public and should,
in general, only be called from the C<Astro::Catalog> C<write_catalog>
method.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

# Bring in the Astro:: modules.
use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '0.01';
$DEBUG = 0;

=begin __PRIVATE_METHODS__

=head1 PRIVATE METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Not currently implemented for Astro::Catalog::IO::Astrom.

=cut

sub _read_catalog {
  croak "Not yet implemented.";
}

=item B<_write_catalog>

Writes the catalogue object to a file in a format that Starlink ASTROM
can understand.

  \@lines = Astro::Catalog::IO::Astrom->_write_catalog( $catalog );

where $catalog is an C<Astro::Catalog> object.

=cut

sub _write_catalog {
  croak ( 'Usage: _write_catalog( $catalog ) ') unless scalar( @_ ) >= 1;
  my $class = shift;
  my $catalog = shift;

# Get the number of stars, since if we have fewer than N we cannot
# do a fit without the field centre.
  my $nstars = $catalog->sizeof();

  if ( ! defined( $catalog->get_coords ) ) {
    croak "Need catalogue field centre to do astrometry correction";
  }

# Set up some variables for output.
  my @output;
  my $output_line;

# Write the approximate field centre.
  my $ra_cen = $catalog->get_coords->ra( format => 's' );
  my $dec_cen = $catalog->get_coords->dec( format => 's' );

# Strip out colons or dms/hms and replace them with spaces.
  $ra_cen =~ s/[:dhms]/ /g;
  $dec_cen =~ s/[:dhms]/ /g;

  push @output, "~ $ra_cen $dec_cen J2000 2000.0";

# For each star, write the RA, Dec, epoch, X and Y coordinates.
  foreach my $star ( $catalog->stars ) {

    next if ( ! defined( $star->ra ) ||
              ! defined( $star->dec ) ||
              ! defined( $star->x ) ||
              ! defined( $star->y ) );

    my $coords = $star->coords;
    my $ra = $coords->ra( format => 's' );
    my $dec = $coords->dec( format => 's' );

# Strip out colons or dms/hms and replace them with spaces.
    $ra =~ s/[:dhms]/ /g;
    $dec =~ s/[:dhms]/ /g;

    $output_line = "$ra $dec J2000 2000.0";
    push @output, $output_line;

    my $x = $star->x;
    my $y = $star->y;
    $output_line = "$x $y";
    push @output, $output_line;

  }

  return \@output;
}

=back

=head1 REVISION

 $Id: Astrom.pm,v 1.2 2005/02/02 20:07:52 cavanagh Exp $

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>

Starlink User Note 5 (http://www.starlink.ac.uk/star/docs/sun5.htx/sun5.html)

=head1 COYPRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
