package Astro::Catalog::IO::FITSTable;

=head1 NAME

Astro::Catalog::IO::FITSTable - Binary FITS table I/O for Astro::Catalog.

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::FITSTable->_read_catalog( $whatever );

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Catalog;
use Astro::Catalog::Star::Morphology;
use Astro::Coords;
use Astro::FITS::CFITSIO qw/ :longnames :constants /;
use File::Temp qw/ tempfile /;

use base qw/ Astro::Catalog::IO::Binary /;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '0.01';
$DEBUG = 0;

=begin __PUBLIC_METHODS__

=head1 PUBLIC METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor, but are available for public use.

=over 4

=item B<input_format>

Returns the requested input format for the FITSTable class, which is
'name', meaning the name of the file to be turned into an C<Astro::Catalog>
object.

  $input_format = Astro::Catalog::IO::FITSTable->input_format;

=cut

sub input_format {
  return "name";
}

=back

=begin __PRIVATE_METHODS__

=head1 PRIVATE METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=item B<_read_catalog>

Parses the binary FITS table and returns a new C<Astro::Catalog> object
containing the catalogue entries.

  $cat = Astro::Catalog::IO::FITSTable->_read_catalog( $whatever );

The current translations from FITS table column names to
C<Astro::Catalog::Star> properties are:

=over 4

=item No. - ID

=item X_coordinate - X

=item Y_coordinate - Y

=item RA & DEC - Coords

=item Isophotal_flux - Magnitudes

=item Ellipticity & Position_angle - Morphology

=back

RA and Dec are assumed to be in J2000 coordinates, and are in units
of radians. The isophotal flux is assumed to be in units of counts,
and is converted into a magnitude through the formula -2.5 * log10( flux ).
The position angle is assumed to be the angle measured counter-
clockwise from the positive x axis, in degrees.

=cut

sub _read_catalog {
  my $class = shift;
  my %args = @_;

  if( ! defined( $args{'filename'} ) ) {
    croak "Must supply a filename to read";
  }
  my $filename = $args{'filename'};

  # A lookup table for column name mappings.
  my %column_name = ( 'ID' => 'No.',
                      'X' => 'X_coordinate',
                      'Y' => 'Y_coordinate',
                      'RA' => 'RA',
                      'Dec' => 'DEC',
                      'flux' => 'Isophotal_flux',
                      'ellipticity' => 'Ellipticity',
                      'position_angle' => 'Position_angle',
                    );

  # The new Astro::Catalog object.
  my $catalog = new Astro::Catalog;

  # CFITSIO status variable.
  my $status = 0;

  # Open the file using CFITSIO.
  my $fptr = Astro::FITS::CFITSIO::open_file( $filename,
                                              Astro::FITS::CFITSIO::READONLY(),
                                              $status );
  if( $status != 0 ) {
    Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
    croak "Error opening FITS file: $status $text";
  }

  # Get the number of HDUs in the FITS file.
  $fptr->get_num_hdus( my $num_hdus, $status );
  if( $status != 0 ) {
    Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
    croak "Error retrieving number of HDUs from FITS file: $status $text";
  }

  $fptr->get_hdu_num( my $hdu_pos );

  while( $hdu_pos <= $num_hdus ) {

    # Get the type of HDU for the one we're at.
    $fptr->get_hdu_type( my $hdutype, $status );
    if( $status != 0 ) {
      Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
      croak "Error retrieving HDU type from FITS file: $status $text";
    }

    if( $hdutype == BINARY_TBL ) {

      # Get the number of rows in this table.
      $fptr->get_num_rows( my $nrows, $status );
      if( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error retrieving number of rows from HDU $hdu_pos from FITS file: $status $text";
      }

      # Grab all the information we can from this HDU.
      # First, get the column numbers for the ID, RA, Dec, flux,
      # ellipticity, position angle, and x and y position.
      $fptr->get_colnum( CASEINSEN, $column_name{'ID'}, my $id_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding ID column: $status $text";
      }
      if( $id_column == 0 ) { $id_column = -1; }
      print "ID column: $id_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'RA'}, my $ra_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding RA column: $status $text";
      }
      if( $ra_column == 0 ) { $ra_column = -1; }
      print "RA column: $ra_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'Dec'}, my $dec_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding Dec column: $status $text";
      }
      if( $dec_column == 0 ) { $dec_column = -1; }
      print "Dec column: $dec_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'flux'}, my $flux_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding flux column: $status $text";
      }
      if( $flux_column == 0 ) { $flux_column = -1; }
      print "Flux column: $flux_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'ellipticity'}, my $ell_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding ellipticity column: $status $text";
      }
      if( $ell_column == 0 ) { $ell_column = -1; }
      print "Ellipticity column: $ell_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'position_angle'}, my $posang_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding position angle column: $status $text";
      }
      if( $posang_column == 0 ) { $posang_column = -1; }
      print "Position angle column: $posang_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'X'}, my $x_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding x-coordinate column: $status $text";
      }
      if( $x_column == 0 ) { $x_column = -1; }
      print "X-coordinate column: $x_column\n" if $DEBUG;

      $fptr->get_colnum( CASEINSEN, $column_name{'Y'}, my $y_column, $status );
      if( $status == COL_NOT_FOUND ) {
        $status = 0;
        $id_column = -1;
      } elsif( $status != 0 ) {
        Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
        croak "Error in finding y-coordinate column: $status $text";
      }
      if( $y_column == 0 ) { $y_column = -1; }
      print "Y-coordinate column: $y_column\n" if $DEBUG;

      # Now that we've got all the columns defined, we need to grab each column
      # in one big array, then take those arrays and stuff the information into
      # Astro::Catalog::Star objects
      my $id;
      my $ra;
      my $dec;
      my $flux;
      my $ell;
      my $posang;
      my $x_pos;
      my $y_pos;
      if( $id_column != -1 ) {
        $fptr->read_col( TFLOAT, $id_column, 1, 1, $nrows, undef, $id, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for ID column: $status $text";
        }
      }
      if( $ra_column != -1 ) {
        $fptr->read_col( TFLOAT, $ra_column, 1, 1, $nrows, undef, $ra, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for RA column: $status $text";
        }
      }
      if( $dec_column != -1 ) {
        $fptr->read_col( TFLOAT, $dec_column, 1, 1, $nrows, undef, $dec, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for Dec column: $status $text";
        }
      }
      if( $flux_column != -1 ) {
        $fptr->read_col( TFLOAT, $flux_column, 1, 1, $nrows, undef, $flux, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for flux column: $status $text";
        }
      }
      if( $ell_column != -1 ) {
        $fptr->read_col( TFLOAT, $ell_column, 1, 1, $nrows, undef, $ell, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for ellipticity column: $status $text";
        }
      }
      if( $posang_column != -1 ) {
        $fptr->read_col( TFLOAT, $posang_column, 1, 1, $nrows, undef, $posang, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for position angle column: $status $text";
        }
      }
      if( $x_column != -1 ) {
        $fptr->read_col( TFLOAT, $x_column, 1, 1, $nrows, undef, $x_pos, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for x-coordinate column: $status $text";
        }
      }
      if( $y_column != -1 ) {
        $fptr->read_col( TFLOAT, $y_column, 1, 1, $nrows, undef, $y_pos, undef, $status );
        if( $status != 0 ) {
          Astro::FITS::CFITSIO::fits_get_errstatus( $status, my $text );
          croak "Error in retrieving data for y-coordinate column: $status $text";
        }
      }

      # Go through each array, grabbing the information and creating a
      # new Astro::Catalog::Star object each time through.
      for( my $i = 0; $i < $nrows; $i++ ) {
        my $id_value;
        if( defined( $id ) ) {
          $id_value = $id->[$i];
        }
        my $ra_value;
        if( defined( $ra ) ) {
          $ra_value = $ra->[$i];
        }
        my $dec_value;
        if( defined( $dec ) ) {
          $dec_value = $dec->[$i];
        }
        my $flux_value;
        if( defined( $flux ) ) {
          $flux_value = $flux->[$i];
        }
        my $ell_value;
        if( defined( $ell ) ) {
          $ell_value = $ell->[$i];
        }
        my $posang_value;
        if( defined( $posang ) ) {
          $posang_value = $posang->[$i];
        }
        my $x_pos_value;
        if( defined( $x_pos ) ) {
          $x_pos_value = $x_pos->[$i];
        }
        my $y_pos_value;
        if( defined( $y_pos ) ) {
          $y_pos_value = $y_pos->[$i];
        }

        # Set up the Astro::Coords object, assuming our RA and Dec are in units
        # of radians.
        my $coords;
        if( defined( $ra_value ) && defined( $dec_value ) ) {
          $coords = new Astro::Coords( ra => $ra_value,
                                       dec => $dec_value,
                                       units => 'radians',
                                       type => 'J2000',
                                     );
        }

        # Calculate the magnitude.
        my %mag;
        if( defined( $flux_value ) ) {
          $mag{'unknown'} = -2.5 * log( $flux_value );
        }

        # And set up the Astro::Catalog::Star::Morphology object.
        my $morphology = new Astro::Catalog::Star::Morphology( ellipticity => $ell_value,
                                                               position_angle_pixel => $posang_value,
                                                             );

        # And create the Astro::Catalog::Star object from this conglomoration of data.
        my $star = new Astro::Catalog::Star( ID => $id_value,
                                             Magnitudes => \%mag,
                                             Coords => $coords,
                                             X => $x_pos_value,
                                             Y => $y_pos_value,
                                             Morphology => $morphology );

        # Push it onto the Astro::Catalog object.
        $catalog->pushstar( $star );
      }

    }
    $status = 0;

    # Move to the next one.
    $fptr->movrel_hdu( 1, $hdutype, $status );
    last if ( $status == END_OF_FILE );

    # And set $hdu_pos.
    $fptr->get_hdu_num( $hdu_pos );

  }

  # Set the origin.
  $catalog->origin( 'IO::FITSTable' );

  # And return.
  return $catalog;

}

=item B<_write_catalog>

Create an output catalog as a binary FITS table.

  $ref = Astro::Catalog::IO::FITSTable->_write_catalog( $catalog );

Argument is an C<Astro::Catalog> object.

This method is not yet implemented.

=cut

sub _write_catalog {
  croak "Not yet implemented.";
}

=back

=head1 REVISION

  $Id: FITSTable.pm,v 1.1 2005/03/31 01:26:42 cavanagh Exp $

=head1 SEE ALSO

L<Astro::Catalog>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
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

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
