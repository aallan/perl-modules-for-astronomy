package Astro::FITS::HdrTrans::SCUBA;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::SCUBA

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    SCUBA instrument.

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id: SCUBA.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

#  Copyright:
#     Copyright (C) 2002 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::SCUBA - Translate FITS headers into generic
headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in SCUBA FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id: SCUBA.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing SCUBA FITS headers into a hash containing
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

=item B<to_INST_DHS>

Sets the INST_DHS header.

=cut

sub to_INST_DHS {

  return "SCUBA_SCUBA";

}


=item B<to_CHOP_COORDINATE_SYSTEM>

Uses the C<CHOP_CRD> FITS header to determine the chopper coordinate
system, and then places that coordinate type in the C<CHOP_COORDINATE_SYSTEM>
generic header.

A FITS header value of 'LO' translates to 'Tracking', 'AZ' translates to
'Alt/Az', and 'NA' translates to 'Focal Plane'. Any other values will return
undef.

=cut

sub to_CHOP_COORDINATE_SYSTEM {
  my $FITS_headers = shift;
  my $return;

  if(exists($FITS_headers->{'CHOP_CRD'})) {
    my $fits_eq = $FITS_headers->{'CHOP_CRD'};
    if( $fits_eq =~ /LO/i ) {
      $return = "Tracking";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "Alt/Az";
    } elsif( $fits_eq =~ /NA/i ) {
      $return = "Focal Plane";
    }
  }
  return $return;
}

=item B<to_COORDINATE_TYPE>

Uses the C<CENT_CRD> FITS header to determine the coordinate type
(galactic, B1950, J2000) and then places that coordinate type in
the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if( $fits_eq =~ /RB/i ) {
      $return = "B1950";
    } elsif( $fits_eq =~ /RJ/i ) {
      $return = "J2000";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "galactic";
    }
  }
  return $return;
}

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "sexagesimal".

=cut

sub to_COORDINATE_UNITS {
  "sexagesimal";
}

=item B<to_EQUINOX>

Translates EQUINOX header into valid equinox value. The following
translation is done:

=over 4

=item * RB => 1950

=item * RJ => 2000

=item * RD => current

=item * AZ => AZ/EL

=back

=cut

sub to_EQUINOX {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if( $fits_eq =~ /RB/i ) {
      $return = "1950";
    } elsif( $fits_eq =~ /RJ/i ) {
      $return = "2000";
    } elsif( $fits_eq =~ /RD/i ) {
      $return = "current";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "AZ/EL";
    }
  }
  return $return;
}

=item B<from_EQUINOX>

Translates generic C<EQUINOX> values into SCUBA FITS
equinox values for the C<CENT_CRD> header.

=cut

sub from_EQUINOX {
  my $generic_headers = shift;
  my %return_hash;
  my $return;
  if(exists($generic_headers->{EQUINOX})) {
    my $equinox = $generic_headers->{EQUINOX};
    if( $equinox =~ /1950/ ) {
      $return = 'RB';
    } elsif( $equinox =~ /2000/ ) {
      $return = 'RJ';
    } elsif( $equinox =~ /current/ ) {
      $return = 'RD';
    } elsif( $equinox =~ /AZ\/EL/ ) {
      $return = 'AZ';
    } else {
      $return = $equinox;
    }
  }
  $return_hash{'CENT_CRD'} = $return;
  return %return_hash;
}

=item B<to_NUMBER_OF_OFFSETS>

Always returns 1.

=cut

sub to_NUMBER_OF_OFFSETS {
  1;
}

=item B<to_OBSERVATION_MODE>

Returns C<photometry> if the FITS header value for C<MODE>
is C<PHOTOM>, otherwise returns C<imaging>.

=cut

sub to_OBSERVATION_MODE {
  my $FITS_headers = shift;
  my $return;
  if($FITS_headers->{'MODE'} =~ /PHOTOM/i) {
    $return = "photometry";
  } else {
    $return = "imaging";
  }
  return $return;
}

=item B<to_OBSERVATION_TYPE>

Converts the observation type. If the FITS header is equal to
C<PHOTOM>, C<MAP>, C<POLPHOT>, or C<POLMAP>, then the generic
header value is C<OBJECT>. Else, the FITS header value is
copied directly to the generic header value.

=cut

sub to_OBSERVATION_TYPE {
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if($mode =~ /PHOTOM|MAP|POLPHOT|POLMAP/i) {
    $return = "OBJECT";
  } else {
    $return = $mode;
  }
  return $return;
}

=item B<to_POLARIMETRY>

Sets the C<POLARIMETRY> generic header to 'true' if the
value for the FITS header C<MODE> is 'POLMAP' or 'POLPHOT',
otherwise sets it to 'false'.

=cut

sub to_POLARIMETRY {
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if($mode =~ /POLMAP|POLPHOT/i) {
    $return = 1;
  } else {
    $return = 0;
  }
  return $return;
}

=item B<to_ROTATION>

Always returns 0.

=cut

sub to_ROTATION {
  0;
}

=item B<to_SLIT_ANGLE>

Always returns 0.

=cut

sub to_SLIT_ANGLE {
  0;
}

=item B<to_SPEED_GAIN>

Always returns C<normal>.

=cut

sub to_SPEED_GAIN {
  "normal";
}

=item B<to_TELESCOPE>

Always returns C<JCMT>.

=cut

sub to_TELESCOPE {
  "JCMT";
}

=item B<to_INSTRUMENT>

Always returns C<SCUBA>.

=cut

sub to_INSTRUMENT {
  "SCUBA";
}

=item B<to_UTDATE>

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  my $utdate = $FITS_headers->{'UTDATE'};
  my ($year, $month, $day) = split /:/, $utdate;
  $return = sprintf("%04d-%02d-%02d", $year, $month, $day);
  return $return;
}

=item B<from_UTDATE>

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE})) {
    my ($year, $month, $day) = split /:/, $generic_headers->{UTDATE};
    $return_hash{'UTDATE'} = join ':', int($year), int($month), int($day);
  }
  return %return_hash;
}

=item B<to_UTSTART>

Combines C<UTDATE> and C<UTSTART> into a unified C<UTSTART>
generic header.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;
  my $utdate = $FITS_headers->{'UTDATE'};
  my $utstart = $FITS_headers->{'UTSTART'};
  my ($year, $month, $day) = split /:/, $utdate;
  my ($hour, $minute, $second) = split /:/, $utstart;
  $return = sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $year, $month, $day, $hour, $minute, $second);
  return $return;
}

=item B<from_UTSTART>

Converts the unified C<UTSTART> generic header into C<UTDATE>
and C<UTSTART> FITS headers of the form C<YYYY:MM:DD> (but
without leading zeroes) and C<HH:MM:SS> (but with leading
zeroes for all but the hours).

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    $generic_headers->{UTSTART} =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    $return_hash{'UTDATE'} = join ':', int($1), int($2), int($3);
    $return_hash{'UTSTART'} = join ':', int($4), $5, $6;
  }
  return %return_hash;
}

=item B<to_UTEND>

Removes the 'Z' from the end of the ending observation time.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;

  my $utdate = $FITS_headers->{'UTDATE'};
  my $utend = $FITS_headers->{'UTEND'};
  my ($year, $month, $day) = split /:/, $utdate;
  my ($hour, $minute, $second) = split /:/, $utend;
  $return = sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $year, $month, $day, $hour, $minute, $second);

  return $return;
}

=item B<from_UTEND>

Adds a 'Z' to the end of the ending observation time.

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {

    $generic_headers->{UTEND} =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    $return_hash{'UTDATE'} = join ':', int($1), int($2), int($3);
    $return_hash{'UTEND'} = join ':', int($4), $5, $6;

  }
  return %return_hash;
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
            BOLOMETERS           => "BOLOMS",
            CHOP_ANGLE           => "CHOP_PA",
            CHOP_THROW           => "CHOP_THR",
            DEC_BASE             => "LAT",
            DEC_TELESCOPE_OFFSET => "MAP_Y",
            DETECTOR_READ_TYPE   => "MODE",
            DR_RECIPE            => "DRRECIPE",
            FILENAME             => "SDFFILE",
            FILTER               => "FILTER",
            GAIN                 => "GAIN",
            MSBID                => "MSBID",
            NUMBER_OF_EXPOSURES  => "EXP_NO",
            OBJECT               => "OBJECT",
            OBSERVATION_NUMBER   => "RUN",
            OBSERVATION_TYPE     => "OBSTYPE",
            PROJECT              => "PROJ_ID",
            RA_TELESCOPE_OFFSET  => "MAP_X",
            SCAN_INCREMENT       => "SAMPLE_DX",
            SEEING               => "SEEING",
            STANDARD             => "STANDARD",
            TAU                  => "TAU_225",
            X_BASE               => "LONG",
            Y_BASE               => "LAT",
            X_OFFSET             => "MAP_X",
            Y_OFFSET             => "MAP_Y"
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
