package Astro::FITS::HdrTrans::IRIS2;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::IRIS2

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    IRIS2 instrument.

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id: IRIS2.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

#  Copyright:
#     Copyright (C) 2002 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::IRIS2 - Translate FITS headers into generic
headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in IRIS2 FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Math::Trig qw/ acos /;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id: IRIS2.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing IRIS2 FITS headers into a hash containing
generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

The C<header_array> argument is used to supply a list of generic
header names.

=back

=cut

sub translate_from_FITS {
  my $FITS_header = shift;
  my $header_array = shift;
  my %generic_header;

  for my $key ( @$header_array ) {

    if(exists($hdr{$key}) ) {
      $generic_header{$key} = $FITS_header->{$hdr{$key}};
    } else {
      my $subname = "to_" . $key;
      if(exists(&$subname) ) {
        no strict 'refs'; # EEP!
        $generic_header{$key} = &$subname($FITS_header);
      }
    }
  }
  return %generic_header;

}

=over 4

=item B<translate_to_FITS>

Converts a hash containing generic headers into a hash containing
FITS headers

  %FITS_headers = translate_to_FITS(\%generic_headers, \@header_array);

The C<header_array> argument is used to supply a list of generic
header names.

=back

=cut

sub translate_to_FITS {
  my $generic_header = shift;
  my $header_array = shift;
  my %FITS_header;

  for my $key ( @$header_array ) {

    if( exists($hdr{$key}) ) {
      $FITS_header{$hdr{$key}} = $generic_header->{$key};
    } else {
      no strict 'refs'; # EEP EEP!
      my $subname = "from_" . $key;
      if(exists(&$subname) ) {
        my %new = &$subname($generic_header);
        for my $newkey ( keys %new ) {
          $FITS_header{$newkey} = $new{$newkey};
        }
      }
    }
  }

  return %FITS_header;

}

=head1 TRANSLATION METHODS

These methods provide many-to-one mappings between FITS headers and
generic headers. An example of a method defined in this section would
be one that converts UT date and UT hour FITS headers into one combined
UT datetime generic header. These mappings can also use calculations,
for example converting a zenith distance to airmass.

These methods are named backwards from the C<translate_from_FITS> and
C<translate_to_FITS> methods in that we are translating to and from
generic headers. As an example, a method to convert to a generic airmass
header would be named C<to_AIRMASS>.

The format of these methods is C<to_HEADER> and C<from_HEADER>.
C<to_> methods accept a hash reference as an argument and return a scalar
value (typically a string). C<from_> methods accept a hash reference
as an argument and return a hash. All UT datetimes should be in
standard ISO 8601 datetime format, which is C<YYYY-MM-DDThh:mm:ss>.
See http://www.cl.cam.ac.uk/~mgk25/iso-time.html for a brief overview
of ISO 8601. Dates should be in YYYY-MM-DD format.

=over 4

=item B<to_AIRMASS_START>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_START {
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if(exists($FITS_headers->{DSTART})) {
    $return = 1 /  cos( $FITS_headers->{DSTART} * $pi / 180 );
  }

  return $return;

}

=item B<from_AIRMASS_START>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_START {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{AIRMASS_START})) {
    $return_hash{DSTART} = acos($generic_headers->{AIRMASS_START});
  }
  return %return_hash;
}

=item B<to_AIRMASS_END>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_END {
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if(exists($FITS_headers->{DEND})) {
    $return = 1 /  cos( $FITS_headers->{DEND} * $pi / 180 );
  }

  return $return;

}

=item B<from_AIRMASS_END>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_END {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{AIRMASS_END})) {
    $return_hash{DEND} = acos($generic_headers->{AIRMASS_END});
  }
  return %return_hash;
}

=item B<to_COORDINATE_TYPE>

Converts the C<EQUINOX> FITS header into B1950 or J2000, depending
on equinox value, and sets the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{EQUINOX})) {
    if($FITS_headers->{EQUINOX} =~ /1950/) {
      $return = "B1950";
    } elsif ($FITS_headers->{EQUINOX} =~ /2000/) {
      $return = "J2000";
    }
  }
  return $return;
}

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "degrees".

=cut

sub to_COORDINATE_UNITS {
  "degrees";
}

=item B<to_UTDATE>

Converts FITS header values into standard UT date value of the form
YYYY-MM-DD.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/;
    $return = $utdate;
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyy-mm-dd> to C<yyyymmdd>.

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    $date =~ s/-/:/g;
    $return_hash{UTDATE} = $date;
  }
  return %return_hash;
}

=item B<to_OBSERVATION_MODE>

Determines the observation mode from the IR2_SLIT FITS header value. If
this value is equal to "OPEN1", then the observation mode is imaging.
Otherwise, the observation mode is spectroscopy.

=cut

sub to_OBSERVATION_MODE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IR2_SLIT})) {
    $return = ($FITS_headers->{IR2_SLIT} eq "OPEN1") ? "imaging" : "spectroscopy";
  }
  return $return;
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into an ISO 8601 formatted date.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTSTART})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTSTART} . "";
  }
  return $return;
}

=item B<from_UTSTART>

Converts an ISO 8601 formatted date into two FITS headers for IRIS2: IDATE
(in the format YYYYMMDD) and RUTSTART (decimal hours).

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{UTDATE} = join ':', $year, $month, $date;
    $return_hash{UTSTART} = join ':', $hour, $minute, $second;
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
an ISO 8601-formatted date.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTEND})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTEND};
  }
  return $return;
}

=item B<from_UTEND>

Converts an ISO 8601 formatted date into two FITS headers for IRIS2: IDATE
(in the format YYYYMMDD) and RUTEND (decimal hours).

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{UTDATE} = join ':', $year, $month, $date;
    $return_hash{UTEND} = join ':', $hour, $minute, $second;
  }
  return %return_hash;
}

=item B<to_X_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<X_BASE>.

=cut

sub to_X_BASE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_X_BASE>

Converts the decimal degrees in the generic header C<X_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_X_BASE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{X_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{X_BASE} / 15;
  }
  return %return_hash;
}

=item B<to_RA_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<RA_BASE>.

=cut

sub to_RA_BASE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_RA_BASE>

Converts the decimal degrees in the generic header C<RA_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_RA_BASE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{RA_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
  }
  return %return_hash;
}

=item B<to_ROTATION>

Converts a linear transformation matrix into a single rotation angle. This angle
is measured counter-clockwise from the positive x-axis.

=cut

# ROTATION, X_SCALE, and Y_SCALE conversions courtesy Micah Johnson, from
# the cdelrot.pl script supplied for use with XIMAGE.

sub to_ROTATION {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_1}) &&
     exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_1}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd11 = $FITS_headers->{CD1_1};
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd21 = $FITS_headers->{CD2_1};
    my $cd22 = $FITS_headers->{CD2_2};
    my $sgn;
    if( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) { $sgn = -1; } else { $sgn = 1; }
    my $cdelt1 = $sgn * sqrt( $cd11**2 + $cd21**2 );
    my $sgn2;
    if( $cdelt1 < 0 ) { $sgn2 = -1; } else { $sgn2 = 1; }
    my $rad = 57.2957795131;
    $return = $rad * atan2( -$cd21 / $rad, $sgn2 * $cd11 / $rad );
  }
  return $return;
}

=item B<to_Y_SCALE>

Converts a linear transformation matrix into a pixel scale in the declination
axis. Results are in arcseconds per pixel.

=cut

sub to_Y_SCALE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_1}) &&
     exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_1}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd11 = $FITS_headers->{CD1_1};
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd21 = $FITS_headers->{CD2_1};
    my $cd22 = $FITS_headers->{CD2_2};
    my $sgn;
    if( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) { $sgn = -1; } else { $sgn = 1; }
    $return = $sgn * sqrt( $cd11**2 + $cd21**2 ) * 3600;
  }
  return $return;
}

=item B<to_X_SCALE>

Converts a linear transformation matrix into a pixel scale in the right
ascension axis. Results are in arcseconds per pixel.

=cut

sub to_X_SCALE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd22 = $FITS_headers->{CD2_2};
    $return = sqrt( $cd12**2 + $cd22**2 ) * 3600;
  }
  return $return;
}

=back

=head1 VARIABLES

=over 4

=item B<%hdr>

Contains one-to-one mappings between FITS headers and generic headers.
Keys are generic headers, values are FITS headers.

=cut

%hdr = (
            AIRMASS_START        => "AMSTART",
            AIRMASS_END          => "AMEND",
            CONFIGURATION_INDEX  => "CNFINDEX",
            DEC_BASE             => "DECBASE",
            DEC_TELESCOPE_OFFSET => "DECOFF",
            DETECTOR_INDEX       => "DINDEX",
            DETECTOR_READ_TYPE   => "DETMODE",
            DR_GROUP             => "GRPNUM",
            DR_RECIPE            => "RECIPE",
            EQUINOX              => "EQUINOX",
            EXPOSURE_TIME        => "DEXPTIME",
            FILTER               => "FILTER",
            GAIN                 => "DEPERDN",
            GRATING_DISPERSION   => "GDISP",
            GRATING_NAME         => "GRATING",
            GRATING_ORDER        => "GORD",
            GRATING_WAVELENGTH   => "GLAMBDA",
            INSTRUMENT           => "INSTRUME",
            NSCAN_POSITIONS      => "DETNINCR",
            NUMBER_OF_EXPOSURES  => "NEXP",
            NUMBER_OF_OFFSETS    => "NOFFSETS",
            OBJECT               => "OBJECT",
            OBSERVATION_NUMBER   => "OBSNUM",
            OBSERVATION_TYPE     => "OBSTYPE",
            RA_TELESCOPE_OFFSET  => "RAOFF",
            ROTATION             => "CROTA2",
            SCAN_INCREMENT       => "DETINCR",
            SLIT_ANGLE           => "SANGLE",
            SLIT_NAME            => "SLIT",
            SPEED_GAIN           => "SPD_GAIN",
            STANDARD             => "STANDARD",
            TELESCOPE            => "TELESCOP",
            WAVEPLATE_ANGLE      => "WPLANGLE",
            Y_BASE               => "DECBASE",
            X_OFFSET             => "RAOFF",
            Y_OFFSET             => "DECOFF",
            X_DIM                => "DCOLUMNS",
            Y_DIM                => "DROWS",
            X_LOWER_BOUND        => "RDOUT_X1",
            X_UPPER_BOUND        => "RDOUT_X2",
            Y_LOWER_BOUND        => "RDOUT_Y1",
            Y_LOWER_BOUND        => "RDOUT_Y2"
          );

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
