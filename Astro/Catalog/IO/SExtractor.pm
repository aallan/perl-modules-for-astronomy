package Astro::Catalog::IO::SExtractor;

=head1 NAME

Astro::Catalog::IO::SExtractor - SExtractor output catalogue I/O for
Astro::Catalog.

=head1 SYNOPSIS

$cat = Astro::Catalog::IO::SExtractor->_read_catalog( \@lines );

=head1 DESCRIPTION

This class provides a read method for catalogues written by SExtractor,
as long as they were written in ASCII_HEAD format. The method is not
public and should, in general, only be called from the C<Astro::Catalog>
C<write_catalog> method.

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
use Astro::SLA;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '0.01';
$DEBUG = 0;

=begin __PRIVATE_METHODS__

=head1 PRIVATE METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog> object
containing the catalogue entries.

$cat = Astro::Catalog::IO::SExtractor->_read_catalog( \@lines );

The catalogue lines must include column definitions as written using
the 'ASCII_HEAD' catalogue type from SExtractor. This implementation
currently only supports reading information from the NUMBER, X_IMAGE,
Y_IMAGE, ALPHA_J2000, DELTA_J2000, MAG_ISOCOR, and MAGERR_ISOCOR output
parameters.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  if( ref( $lines ) ne 'ARRAY' ) {
    croak "Must supply catalogue contents as a reference to an array";
  }

  my @lines = @$lines; # Dereference, make own copy.

  # Create an Astro::Catalog object;
  my $catalog = new Astro::Catalog();

  # Set up columns.
  my $id_column = -1;
  my $x_column = -1;
  my $y_column = -1;
  my $ra_column = -1;
  my $dec_column = -1;
  my $mag_column = -1;
  my $magerr_column = -1;

  # Loop through the lines.
  for ( @lines ) {
    my $line = $_;

    # If we're on a column line that starts with a #, check to see
    # if it's describing where the X, Y, RA, or Dec position is in
    # the table, or the object number, or the flux, or the error in
    # flux.
    if( $line =~ /^#/ ) {
      my @column = split( /\s+/, $line );
      if( $column[2] =~ /NUMBER/ ) {
        $id_column = $column[1] - 1;
      } elsif( $column[2] =~ /X_IMAGE/ ) {
        $x_column = $column[1] - 1;
      } elsif( $column[2] =~ /Y_IMAGE/ ) {
        $y_column = $column[1] - 1;
      } elsif( $column[2] =~ /ALPHA_J2000/ ) {
        $ra_column = $column[1] - 1;
      } elsif( $column[2] =~ /DELTA_J2000/ ) {
        $dec_column = $column[1] - 1;
      } elsif( $column[2] =~ /MAG_ISOCOR/ ) {
        $mag_column = $column[1] - 1;
      } elsif( $column[2] =~ /MAGERR_ISOCOR/ ) {
        $magerr_column = $column[1] - 1;
      }
      next;
    }

    # Remove leading whitespace and go to the next line if the
    # current one is blank.
    $line =~ s/^\s+//;
    next if length( $line ) == 0;

    # Form an array of the fields in the catalogue.
    my @fields = split( /\s+/, $line );

    # Create a temporary Astro::Catalog::Star object.
    my $star = new Astro::Catalog::Star();

    # Grab the coordinates, forming an Astro::Coords object.
    my $coords = new Astro::Coords( type => 'J2000',
                                    ra => $fields[$ra_column],
                                    dec => $fields[$dec_column],
                                    name => $fields[$id_column],
                                    units => 'degrees',
                                  );

    $star->coords( $coords );
    $star->quality( 0 );

    # Set the magnitude and the magnitude error. Set the filter
    # to 'unknown' because SExtractor doesn't know about such things.
    my %mags = ( 'unknown' => $fields[$mag_column] );
    $star->magnitudes( \%mags );
    my %magerrs = ( 'unknown' => $fields[$magerr_column] );
    $star->magerr( \%magerrs );

    # Push the star onto the catalog.
    $catalog->pushstar( $star );
  }

  $catalog->origin( 'IO::SExtractor' );
  return $catalog;
}

=item B<_write_catalog>

Create an output catalogue in the SExtractor ASCII_HEAD format and
return the lines in an array.

  $ref = Astro::Catalog::IO::SExtractor->_write_catalog( $catalog );

Argument is an C<Astro::Catalog> object.

This method is not yet implemented.

=cut

sub _write_catalog {
  croak "Not yet implemented.";
}

=back

=head1 REVISION

  $Id: SExtractor.pm,v 1.1 2004/11/23 01:17:26 cavanagh Exp $

=head1 FORMAT

The SExtractor ASCII_HEAD format consists of a header block and a
data block. The header block is made up of comments denoted by a
# as the first character. These comments describe the column number,
output parameter name, description of the output paramter, and units
of the output parameter enclosed in square brackets. The data block
is space-delimited.

=head1 SEE ALSO

L<Astro::Catalog>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
