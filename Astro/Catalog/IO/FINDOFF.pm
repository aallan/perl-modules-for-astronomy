package Astro::Catalog::IO::FINDOFF;

=head1 NAME

Astro::Catalog::IO::FINDOFF - Catalogue I/O for Astro::Catalog for Starlink
FINDOFF.

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::FINDOFF->_read_catalog( \@lines );
  $arrref = Astro::Catalog::IO::FINDOFF->_write_catalog( $cat, %options );

=head1 DESCRIPTION

This class provides read and write methods for catalogues in the Starlink
FINDOFF input and output file format. The methods are not public and should,
in general only be called from the C<Astro::Catalog> C<write_catalog> and
C<read_catalog> methods.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Catalog;
use Astro::Catalog::Star;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '0.01';
$DEBUG = 0;

=head1 METHODS

=head2 Private Methods

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog>
object containing the catalog entries.

  $cat = Astro::Catalog::IO::FINDOFF->_read_catalog( \@lines, %options );

There are currently no supported options.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  croak "Must supply catalogue contents as a reference to an array"
    unless ref( $lines ) eq 'ARRAY';

  # Create the Astro::Catalog object.
  my $catalog = new Astro::Catalog();

  # Chew up the lines. For position list files in FINDOFF, the first
  # three columns are ID, X, and Y. Any columns after that could be
  # anything, really, so put them in the Star's comment string.
  my @lines = @$lines; # Dereference, make own copy.
  for ( @lines ) {
    my $line = $_;
    next unless $line =~ /^\s*([\w.]+)\s+([\w.]+)\s+([\w.]+)(?:\s+(.+))*$/;
    my $id = $1;
    my $x = $2;
    my $y = $3;
    my $comment = $4;

    # Create the Astro::Catalog::Star object.
    my $star = new Astro::Catalog::Star( ID => $id,
                                         X => $x,
                                         Y => $y,
                                         Comment => $comment );

    # And push the star onto the catalogue.
    $catalog->pushstar( $star );
  }

  # Set the catalogue's origin.
  $catalog->origin( 'IO::FINDOFF' );

  # And return;
  return $catalog;
}

=item B<_write_catalog>

Create an output catalogue in the Starlink FINDOFF format and return
the lines in an array.

  $ref = Astro::Catalog::IO::FINDOFF->_write_catalog( $catalog );

The sole mandatory argument is an C<Astro::Catalog> object.

As the Starlink FINDOFF is ID in column 1, X position in column 2,
Y position in column 3, and miscellaneous information in the remaining
columns that gets carried through to the output file, this method
writes the ID, X, and Y in the first three columns followed by
the ID, X, Y, RA, and Dec (latter two in colon-separated sexagesimal
and in J2000).

=cut

sub _write_catalog {
  my $class = shift;
  my $catalog = shift;

  croak "Must supply catalogue contents as a reference to an array"
    unless UNIVERSAL::isa( $catalog, "Astro::Catalog" );

  # Set up variables for output.
  my @output;
  my $output_line;

  # Loop through the stars.
  foreach my $star ( $catalog->stars ) {

    # We need at a bare minimum the X, Y, and ID.
    next if ( ! defined( $star->x ) ||
              ! defined( $star->y ) ||
              ! defined( $star->id ) );

    # Start off the output string.
    $output_line = join( ' ', $star->id, $star->x, $star->y, $star->id, $star->x, $star->y );

    # And append the RA/Dec, if we have them.
    if( defined( $star->coords ) ) {
      my $coords = $star->coords;
      my $ra = $coords->ra2000;
      my $dec = $coords->dec2000;
      $ra->str_delim(':');
      $dec->str_delim(':');
      $output_line .= " $ra $dec";
    }

    # And push this string to the output array.
    push @output, $output_line;

  }

  # All done looping through the stars, so return the array reference.
  return \@output;
}

=back

=head1 REVISION

 $Id: FINDOFF.pm,v 1.1 2005/01/15 01:35:52 cavanagh Exp $

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>

Starlink User Note 139 (http://www.starlink.ac.uk/star/docs/sun139.htx/sun139.html)

=head1 COYPRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
