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
use Astro::Catalog::Star::Morphology;
use Astro::Coords;
use Astro::SLA;

use base qw/ Astro::Catalog::IO::ASCII /;

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
currently only supports reading information from the following output
parameters:

=item NUMBER - Astro::Catalog::Star id

=item X_IMAGE - Astro::Catalog::Star x

=item Y_IMAGE - Astro::Catalog::Star y

=item X2_IMAGE

=item Y2_IMAGE

=item ERRX2_IMAGE

=item ERRY2_IMAGE

=item ALPHA_J2000 - Astro::Catalog::Star coords

=item DELTA_J2000 - Astro::Catalog::Star coords

=item MAG_ISO - Astro::Catalog::Star magnitudes

=item MAGERR_ISO - Astro::Catalog::Star magerr

=item FLUX_ISO

=item FLUXERR_ISO

=item ELLIPTICITY - Astro::Catalog::Star morphology

=item THETA_IMAGE - Astro::Catalog::Star morphology

=item THETA_WORLD - Astro::Catalog::Star morphology

=item A_IMAGE - Astro::Catalog::Star morphology

=item B_IMAGE - Astro::Catalog::Star morphology

=item A_WORLD - Astro::Catalog::Star morphology

=item B_WORLD - Astro::Catalog::Star morphology

=item ISOAREA_IMAGE - Astro::Catalog::Star morphology

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;
  my %args = @_;

  if( ref( $lines ) ne 'ARRAY' ) {
    croak "Must supply catalogue contents as a reference to an array";
  }

  if( defined( $args{'Filter'} ) &&
      ! UNIVERSAL::isa( $args{'Filter'}, "Astro::WaveBand" ) ) {
    croak "Filter as passed to SExtractor->_read_catalog must be an Astro::WaveBand object";
  }

  my $filter;
  if( defined( $args{'Filter'} ) ) {
    $filter = $args{'Filter'}->natural;
  } else {
    $filter = 'unknown';
  }

  my @lines = @$lines; # Dereference, make own copy.

  # Create an Astro::Catalog object;
  my $catalog = new Astro::Catalog();

  # Set up columns.
  my $id_column = -1;
  my $x_column = -1;
  my $xvar_column = -1;
  my $y_column = -1;
  my $yvar_column = -1;
  my $xvarerr_column = -1;
  my $yvarerr_column = -1;
  my $ra_column = -1;
  my $dec_column = -1;
  my $mag_column = -1;
  my $magerr_column = -1;
  my $flux_column = -1;
  my $fluxerr_column = -1;
  my $ell_column = -1;
  my $posang_pixel_column = -1;
  my $posang_world_column = -1;
  my $minor_pixel_column = -1;
  my $major_pixel_column = -1;
  my $minor_world_column = -1;
  my $major_world_column = -1;
  my $area_column = -1;

  # Loop through the lines.
  for ( @lines ) {
    my $line = $_;

    # If we're on a column line that starts with a #, check to see
    # if it's describing where the X, Y, RA, or Dec position is in
    # the table, or the object number, or the flux, or the error in
    # flux.
    if( $line =~ /^#/ ) {
      my @column = split( /\s+/, $line );
      if( $column[2] =~ /^NUMBER/ ) {
        $id_column = $column[1] - 1;
        print "ID column is $id_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^X_IMAGE/ ) {
        $x_column = $column[1] - 1;
        print "X column is $x_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^Y_IMAGE/ ) {
        $y_column = $column[1] - 1;
        print "Y column is $y_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^X2_IMAGE/ ) {
        $xvar_column = $column[1] - 1;
        print "X VARIANCE column is $xvar_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^Y2_IMAGE/ ) {
        $yvar_column = $column[1] - 1;
        print "Y VARIANCE column is $yvar_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^ERRX2_IMAGE/ ) {
        $xvarerr_column = $column[1] - 1;
        print "X VARIANCE ERROR column is $xvarerr_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^ERRY2_IMAGE/ ) {
        $yvarerr_column = $column[1] - 1;
        print "Y VARIANCE ERROR column is $yvarerr_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^ALPHA_J2000/ ) {
        $ra_column = $column[1] - 1;
        print "RA column is $ra_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^DELTA_J2000/ ) {
        $dec_column = $column[1] - 1;
        print "DEC column is $dec_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^MAG_ISOCOR/ ) {
        $mag_column = $column[1] - 1;
        print "MAG column is $mag_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^MAGERR_ISOCOR/ ) {
        $magerr_column = $column[1] - 1;
        print "MAG ERROR column is $magerr_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^FLUX_ISO/ ) {
        $flux_column = $column[1] - 1;
        print "FLUX_ISO column is $flux_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^FLUXERR_ISO/ ) {
        $fluxerr_column = $column[1] - 1;
        print "FLUXERR_ISO column is $fluxerr_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^ELLIPTICITY/ ) {
        $ell_column = $column[1] - 1;
        print "ELLIPTICITY column is $ell_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^THETA_IMAGE/ ) {
        $posang_pixel_column = $column[1] - 1;
        print "POSITION ANGLE (PIXELS) column is $posang_pixel_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^THETA_WORLD/ ) {
        $posang_world_column = $column[1] - 1;
        print "POSITION ANGLE (WORLD) column is $posang_world_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^B_IMAGE/ ) {
        $minor_pixel_column = $column[1] - 1;
        print "MINOR AXIS (PIXELS) column is $minor_pixel_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^A_IMAGE/ ) {
        $major_pixel_column = $column[1] - 1;
        print "MAJOR AXIS (PIXELS) column is $major_pixel_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^B_WORLD/ ) {
        $minor_world_column = $column[1] - 1;
        print "MINOR AXIS (WORLD) column is $minor_world_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^A_WORLD/ ) {
        $major_world_column = $column[1] - 1;
        print "MAJOR AXIS (WORLD) column is $major_world_column\n" if $DEBUG;
      } elsif( $column[2] =~ /^ISOAREA_IMAGE/ ) {
        $area_column = $column[1] - 1;
        print "AREA column is $area_column\n" if $DEBUG;
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
                                    ra => ( $ra_column != -1 ? $fields[$ra_column] : undef ),
                                    dec => ( $dec_column != -1 ? $fields[$dec_column] : undef ),
                                    name => ( $id_column != -1 ? $fields[$id_column] : undef ),
                                    units => 'degrees',
                                  );

    $star->coords( $coords );
    $star->quality( 0 );

    # Set the magnitude and the magnitude error. Set the filter
    # to 'unknown' because SExtractor doesn't know about such things.
    if( $mag_column != -1 ) {
      my %mags = ( $filter => $fields[$mag_column] );
      $star->magnitudes( \%mags );
    }
    if( $magerr_column != -1 ) {
      my %magerrs = ( $filter => $fields[$magerr_column] );
      $star->magerr( \%magerrs );
    }

    # Set the x and y coordinates.
    $star->x( ( $x_column != -1 ? $fields[$x_column] : undef ) );
    $star->y( ( $y_column != -1 ? $fields[$y_column] : undef ) );

    # Set up the star's morphology.
    my $morphology = new Astro::Catalog::Star::Morphology( ellipticity => ( $ell_column != -1 ? $fields[$ell_column] : undef ),
                                                           position_angle_pixel => ( $posang_pixel_column != -1 ? $fields[$posang_pixel_column] : undef ),
                                                           position_angle_world => ( $posang_world_column != -1 ? $fields[$posang_world_column] : undef ),
                                                           major_axis_pixel => ( $major_pixel_column != -1 ? $fields[$major_pixel_column] : undef ),
                                                           minor_axis_pixel => ( $minor_pixel_column != -1 ? $fields[$minor_pixel_column] : undef ),
                                                           major_axis_world => ( $major_world_column != -1 ? $fields[$major_world_column] : undef ),
                                                           minor_axis_world => ( $minor_world_column != -1 ? $fields[$minor_world_column] : undef ),
                                                           area => ( $area_column != -1 ? $fields[$area_column] : undef ),
                                                         );
    $star->morphology( $morphology );

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

  $Id: SExtractor.pm,v 1.8 2005/06/08 03:29:25 aa Exp $

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
