package Astro::FITS::HdrTrans::UKIRTDB;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::UKIRTDB

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    UKIRTDB database

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id: UKIRTDB.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

#  Copyright:
#     Copyright (C) 2002 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::UKIRTDB - Translate FITS headers into generic
headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in UKIRTDB FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;
use Data::Dumper;
use Time::Piece;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id: UKIRTDB.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing UKIRTDB headers into a hash containing
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

=item B<to_INST-DHS>

Sets the INST-DHS header.

=cut

sub to_INST_DHS {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{DHSVER} ) ) {
    $FITS_headers->{DHSVER} =~ /^(\w+)/;
    my $dhs = uc($1);
    $return = $FITS_headers->{TEMP_INST} . "_$dhs";
  } else {
    my $dhs = "UKDHS";
    $return = $FITS_headers->{TEMP_INST} . "_$dhs";
  }

  return $return;

}

=item B<to_EXPOSURE_TIME>

Converts either the C<EXPOSED> or C<DEXPTIME> FITS header into
the C<EXPOSURE_TIME> generic header.

=cut

sub to_EXPOSURE_TIME {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'EXPOSED'} ) && defined( $FITS_headers->{'EXPOSED'} ) ) {
    $return = $FITS_headers->{'EXPOSED'};
  } elsif( exists( $FITS_headers->{'DEXPTIME'} ) && defined( $FITS_headers->{'DEXPTIME'} ) ) {
    $return = $FITS_headers->{'DEXPTIME'};
  } elsif( exists( $FITS_headers->{'EXP_TIME'} ) && defined( $FITS_headers->{'EXP_TIME'} ) ) {
    $return = $FITS_headers->{'EXP_TIME'};
  }
  return $return;
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

=item B<to_GRATING_NAME>

=cut

sub to_GRATING_NAME {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{GRATING})) {
    $return = $FITS_headers->{GRATING};
  } elsif(exists($FITS_headers->{GRISM})) {
    $return = $FITS_headers->{GRISM};
  }
  return $return;
}

=item B<to_GRATING_WAVELENGTH>

=cut

sub to_GRATING_WAVELENGTH {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{GLAMBDA})) {
    $return = $FITS_headers->{GLAMBDA};
  } elsif(exists($FITS_headers->{CENWAVL})) {
    $return = $FITS_headers->{CENWAVL};
  }
  return $return;
}

=item B<to_SLIT_ANGLE>

Converts either the C<SANGLE> or the C<SLIT_PA> header into the C<SLIT_ANGLE>
generic header.

=cut

sub to_SLIT_ANGLE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'SANGLE'})) {
    $return = $FITS_headers->{'SANGLE'};
  } elsif(exists($FITS_headers->{'SLIT_PA'} )) {
    $return = $FITS_headers->{'SLIT_PA'};
  }
  return $return;

}

=item B<to_SLIT_NAME>

Converts either the C<SLIT> or the C<SLITNAME> header into the C<SLIT_NAME>
generic header.

=cut

sub to_SLIT_NAME {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'SLIT'})) {
    $return = $FITS_headers->{'SLIT'};
  } elsif(exists($FITS_headers->{'SLITNAME'} )) {
    $return = $FITS_headers->{'SLITNAME'};
  }
  return $return;

}

=item B<to_SPEED_GAIN>

=cut

sub to_SPEED_GAIN {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'SPD_GAIN'} ) ) {
    $return = $FITS_headers->{'SPD_GAIN'};
  } elsif( exists( $FITS_headers->{'WAVEFORM'} ) ) {
    if( $FITS_headers->{'WAVEFORM'} =~ /^thermal/i ) {
      $return = 'thermal';
    } else {
      $return = 'normal';
    }
  }
  return $return;
}

=item B<to_STANDARD>

Converts either the C<STANDARD> header (if it exists) or uses the
C<OBJECT> or C<RECIPE> headers to determine if an observation is of a
standard.  If the C<OBJECT> header starts with either B<BS> or B<FS>,
I<or> the DR recipe contains the word STANDARD, it is assumed to be a
standard.

=cut

sub to_STANDARD {
  my $FITS_headers = shift;

  # Set false as default so we do not have to repeat this in the logic
  # below (could just use undef == false)
  my $return = 0; # default false

  if( exists( $FITS_headers->{'STANDARD'} ) &&
      length( $FITS_headers->{'STANDARD'} . "") > 0 ) {

    if($FITS_headers->{'STANDARD'} =~ /^[tf]$/i) {
      # Raw header read from FITS header
      $return = (uc($FITS_headers->{'STANDARD'}) eq 'T');
    } elsif($FITS_headers->{'STANDARD'} =~ /^[01]$/) {
      # Translated header either so a true logical
      $return = $FITS_headers->{'STANDARD'};
    }

  } elsif ( ( exists $FITS_headers->{OBJECT} &&
	      $FITS_headers->{'OBJECT'} =~ /^[bf]s/i ) ||
	    ( exists( $FITS_headers->{'RECIPE'} ) &&
	      $FITS_headers->{'RECIPE'} =~ /^standard/i
	    )) {
    # Either we have an object with name prefix of BS or FS or
    # our recipe looks suspiciously like a standard.
    $return = 1;

  }

  return $return;

}

=item B<to_UTSTART>

Strips the 'Z' from the C<DATE-OBS> header, or if that header does
not exist, combines the C<UT_DATE> and C<RUTSTART> headers into a unified
C<UTSTART> header.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'DATE_OBS'} ) ) {
    ( $return = $FITS_headers->{'DATE_OBS'} ) =~ s/Z//;

  } elsif(exists($FITS_headers->{'UT_DATE'}) && defined($FITS_headers->{'UT_DATE'}) &&
          exists($FITS_headers->{'RUTSTART'}) && defined( $FITS_headers->{'RUTSTART'} ) ) {
    # The UT_DATE is returned in the form "mmm dd yyyy hh:mm(am|pm)"
    my $t = Time::Piece->strptime($FITS_headers->{'UT_DATE'}, "%b %d %Y %I:%M%p");
    my $hour = int($FITS_headers->{'RUTSTART'});
    my $minute = int( ( $FITS_headers->{'RUTSTART'} - $hour ) * 60 );
    my $second = int( ( ( ( $FITS_headers->{'RUTSTART'} - $hour ) * 60) - $minute ) * 60 );
    $return = $t->ymd . "T" . $hour . ":" . $minute . ":" . $second;
  }
  return $return;
}

=item B<from_UTSTART>

Converts the C<UTSTART> generic header into C<UT_DATE>, C<RUTSTART>,
and C<DATE-OBS> database headers.

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $t = _parse_date( $generic_headers->{'UTSTART'} );
    my $month = $t->month;
    $month =~ /^(.{3})/;
    $month = $1;
    $return_hash{'UT_DATE'} = $month . " " . $t->mday . " " . $t->year;
    $return_hash{'RUTSTART'} = $t->hour + ($t->min / 60) + ($t->sec / 3600);
    $return_hash{'DATE_OBS'} = $generic_headers->{'UTSTART'} . "Z";
  }
  return %return_hash;
}

=item B<to_UTEND>

Strips the 'Z' from the C<DATE-END> header, or if that header does
not exist, combines the C<UT_DATE> and C<RUTEND> headers into a unified
C<UTEND> header.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'DATE_END'} ) ) {
    ( $return = $FITS_headers->{'DATE_END'} ) =~ s/Z//;
  } elsif(exists($FITS_headers->{'UT_DATE'}) &&
     exists($FITS_headers->{'RUTEND'}) ) {
    # The UT_DATE is returned in the form "mmm dd yyyy hh:mm(am|pm)"
    my $t = Time::Piece->strptime($FITS_headers->{'UT_DATE'}, "%b %d %Y %I:%M%p");
    my $hour = int($FITS_headers->{'RUTEND'});
    my $minute = int( ( $FITS_headers->{'RUTEND'} - $hour ) * 60 );
    my $second = int( ( ( ( $FITS_headers->{'RUTEND'} - $hour ) * 60) - $minute ) * 60 );
    $return = $t->ymd . "T" . $hour . ":" . $minute . ":" . $second;
  }
  return $return;
}

=item B<from_UTEND>

Converts the C<UTEND> generic header into C<UT_DATE>, C<RUTEND>
and C<DATE-END> database headers.

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $t = _parse_date( $generic_headers->{'UTEND'} );
    my $month = $t->month;
    $month =~ /^(.{3})/;
    $month = $1;
    $return_hash{'UT_DATE'} = $month . " " . $t->mday . " " . $t->year;
    $return_hash{'RUTEND'} = $t->hour + ($t->min / 60) + ($t->sec / 3600);
    $return_hash{'DATE_END'} = $generic_headers->{'UTEND'} . "Z";
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
            CAMERA               => "CAMLENS",
            CONFIGURATION_INDEX  => "CNFINDEX",
            DEC_BASE             => "DECBASE",
            DEC_SCALE            => "PIXELSIZ",
            DEC_TELESCOPE_OFFSET => "DECOFF",
            DETECTOR_READ_TYPE   => "MODE",
            DR_GROUP             => "GRPNUM",
            DR_RECIPE            => "RECIPE",
            EQUINOX              => "EQUINOX",
            FILTER               => "FILTER",
            GAIN                 => "DEPERDN",
            GRATING_DISPERSION   => "GDISP",
            GRATING_ORDER        => "GORDER",
            INSTRUMENT           => "INSTRUME",
            MSBID                => "MSBID",
            NUMBER_OF_EXPOSURES  => "NEXP",
            OBJECT               => "OBJECT",
            OBSERVATION_MODE     => "INSTMODE",
            OBSERVATION_NUMBER   => "RUN",
            OBSERVATION_TYPE     => "OBSTYPE",
            PROJECT              => "PROJECT",
            RA_SCALE             => "PIXELSIZ",
            RA_TELESCOPE_OFFSET  => "RAOFF",
            TELESCOPE            => "TELESCOP",
            UTDATE               => "UT_DATE",
            WAVEPLATE_ANGLE      => "WPLANGLE",
            Y_BASE               => "DECBASE",
            X_DIM                => "DCOLUMNS",
            Y_DIM                => "DROWS",
            X_OFFSET             => "RAOFF",
            Y_OFFSET             => "DECOFF",
            X_SCALE              => "PIXELSIZ",
            Y_SCALE              => "PIXELSIZ",
            X_LOWER_BOUND        => "RDOUT_X1",
            X_UPPER_BOUND        => "RDOUT_X2",
            Y_LOWER_BOUND        => "RDOUT_Y1",
            Y_LOWER_BOUND        => "RDOUT_Y2"
          );

=back

=head1 INTERNAL METHODS

=item B<_parse_date>

Parses a string as a date. Returns a C<Time::Piece> object.

  $time = _parse_date( $date );

Returns C<undef> if the time could not be parsed.
Returns the object unchanged if the argument is already a C<Time::Piece>.

It will also recognize a Sybase style date: 'Mar 15 2002  7:04AM'
and a simple YYYYMMDD.

The date is assumed to be in UT.

=cut

sub _parse_date {
  my $self = shift;
  my $date = shift;

  # If we already have a Time::Piece return
  return bless $date, "Time::Piece"
    if UNIVERSAL::isa( $date, "Time::Piece");

  # We can use Time::Piece->strptime but it requires an exact
  # format rather than working it out from context (and we don't
  # want an additional requirement on Date::Manip or something
  # since Time::Piece is exactly what we want for Astro::Coords)
  # Need to fudge a little

  my $format;

  # Need to disambiguate ISO date from Sybase date
  if ($date =~ /\d\d\d\d-\d\d-\d\d/) {
    # ISO

    # All arguments should have a day, month and year
    $format = "%Y-%m-%d";

    # Now check for time
    if ($date =~ /T/) {
      # Date and time
      # Now format depends on the number of colons
      my $n = ( $date =~ tr/:/:/ );
      $format .= "T" . ($n == 2 ? "%T" : "%R");
    }
  } elsif ($date =~ /^\d\d\d\d\d\d\d\d\b/) {
    # YYYYMMDD format
    $format = "%Y%m%d";
  } else {
    # Assume Sybase date
    # Mar 15 2002  7:04AM
    $format = "%b%t%d%t%Y%t%I:%M%p";

  }

  # Now parse
  # Note that this time is treated as "local" rather than "gm"
  my $time = eval { Time::Piece->strptime( $date, $format ); };
  if ($@) {
    return undef;
  } else {
    # Note that the above constructor actually assumes the date
    # to be parsed is a local time not UTC. To switch to UTC
    # simply get the epoch seconds and the timezone offset
    # and run gmtime
    # Sometime around v1.07 of Time::Piece the behaviour changed
    # to return UTC rather than localtime from strptime!
    # The joys of backwards compatibility.
    if ($time->[Time::Piece::c_islocal]) {
      my $tzoffset = $time->tzoffset;
      my $epoch = $time->epoch;
      $time = gmtime( $epoch + $tzoffset->seconds );
    }

  }

}

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
