package Astro::FITS::HdrTrans::HETERODYNE;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::HETERODYNE

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    Heterodyne instruments at JCMT.

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id: HETERODYNE.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

#  Copyright:
#     Copyright (C) 2003 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::HETERODYNE - Translantes FITS headers into
generic headers and back again.

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in JCMT heterodyne instrument headers
to and from generic headers. See Astro::FITS::HdrTrans for a list of
generic headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;
our %to_file_headers;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id: HETERODYNE.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing heterodyne FITS headers into a hash containing
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
  my %db_headers;

  if( exists($FITS_header->{C4EL}) ) {
    %db_headers = pretranslate_file_headers( $FITS_header );
  } else {
    %db_headers = %{$FITS_header};
  }
  for my $key ( @$header_array ) {
    if(exists($hdr{$key}) ) {
      $generic_header{$key} = $db_headers{$hdr{$key}};
    } else {
      my $subname = "to_" . $key;
      if(exists(&$subname) ) {
        no strict 'refs'; # EEP!
        $generic_header{$key} = &$subname(\%db_headers);
      }
    }
  }
#use Data::Dumper;
#print Dumper \%generic_header;
#exit;
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

=over 4

=item B<pretranslate_file_headers>

=item B<pretranslate_db_headers>

Do a pre-translation of headers from files into headers from the database and
vice-versa.

  %dbheaders = pretranslate_file_headers( \%fileheaders );
  %fileheaders = pretranslate_db_headers( \%dbheaders );

This step is necessary so that it will not be necessary to translate
both database headers and file headers individually. Since there is
a one-to-one mapping between database headers and file headers, we do
this pretranslation to simplify matters.

These methods take as input a hash reference and return a hash.

=back

=cut

sub pretranslate_file_headers {
  my $fileheaders = shift;

  my %dbheaders;
  my %to_db_headers = reverse %to_file_headers;

  foreach my $filehdr (keys %to_db_headers) {
    $dbheaders{$to_db_headers{$filehdr}} = $fileheaders->{$filehdr};
  }
  return %dbheaders;

}

sub pretranslate_db_headers {
  my $dbheaders = shift;

  my %fileheaders;

  foreach my $dbhdr (keys %to_file_headers) {
    $fileheaders{$to_file_headers{$dbhdr}} = $dbheaders->{$dbhdr};
  }

  return %fileheaders;

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

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "decimal".

=cut

sub to_COORDINATE_UNITS {
  "decimal";
}

=item B<to_EQUINOX>

Sets the C<EQUINOX> generic header to "current".

=cut

sub to_EQUINOX {
  "current";
}

=item B<to_TELESCOPE>

Sets the C<TELESCOPE> generic header to "JCMT".

=cut

sub to_TELESCOPE {
  "JCMT";
}

=item B<to_UTDATE>

Translates the C<UT> or C<C3DAT> header into a standard YYYY-MM-DD format.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'UT'}) && defined( $FITS_headers->{'UT'} ) ) {
    my $t = Time::Piece->strptime($FITS_headers->{'UT'},
                                  "%b%t%d%t%Y%t%I:%M%p",);
    $return = $t->ymd;
  } elsif( exists( $FITS_headers->{'C3DAT'} ) ) {
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $return = "$1-$2-$day";
  }
  return $return;
}

=item B<to_UTSTART>

Translates the C<UT> header (for database lookups) or the C<C3DAT> and C<C3UT>
headers (for file headers) into standard ISO 8601 format.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;

  my $return;
  if( exists( $FITS_headers->{'LONGDATE'}) && defined( $FITS_headers->{'LONGDATE'} ) ) {
    my $date = $FITS_headers->{'LONGDATE'};
    $date =~ s/(:)\d\d\d(AM|PM)\s+/$2/i;
    my $t = Time::Piece->strptime($date, "%b%n%d%n%Y%n%I:%M:%S%p",);
    $return = $t->datetime;
  } elsif ( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
            exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $return = sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ) ;
  }
  return $return;

}

=item B<to_UTEND>

Translates the C<UT> and C<SAMPRAT> headers (for database lookups) or the
C<C3DAT>, C<C3UT>, C<C3NIS>, C<C3CL>, C<C3NCP>, and C<C3NCI> (from file
headers) into standard ISO 8601 format.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my ($return, $t, $expt);
  if( exists( $FITS_headers->{'LONGDATE'}) && defined( $FITS_headers->{'LONGDATE'} ) ) {
    my $date = $FITS_headers->{'LONGDATE'};
    $date =~ s/(:)\d\d\d(AM|PM)\s+/$2/i;
    $t = Time::Piece->strptime($date, "%b%t%d%t%Y%t%I:%M:%S%p");
  } elsif( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
           exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $t = Time::Piece->strptime(sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ),
                              "%Y-%m-%dT%T");
  }

  $expt = to_EXPOSURE_TIME( $FITS_headers );

  $t += $expt;
  $return = $t->datetime;

  return $return;

}

=item B<to_EXPOSURE_TIME>

=cut

sub to_EXPOSURE_TIME {
  my $FITS_headers = shift;
  my $expt;

  if( exists( $FITS_headers->{'OBSMODE'} ) && defined( $FITS_headers->{'OBSMODE'} ) &&
      exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
      exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) &&
      exists( $FITS_headers->{'NOCYCPTS'} ) && defined( $FITS_headers->{'NOCYCPTS'} ) &&
      exists( $FITS_headers->{'NOCYCLES'} ) && defined( $FITS_headers->{'NOCYCLES'} ) &&
      exists( $FITS_headers->{'NCYCPTS'} ) && defined( $FITS_headers->{'NCYCPTS'} ) ) {

    my $obsmode = uc( $FITS_headers->{'OBSMODE'} );
    my $nscan = uc( $FITS_headers->{'NSCAN'} );
    my $cycllen = uc( $FITS_headers->{'CYCLLEN'} );
    my $nocycpts = uc( $FITS_headers->{'NOCYCPTS'} );
    my $nocycles = uc( $FITS_headers->{'NOCYCLES'} );
    my $ncycpts = uc( $FITS_headers->{'NCYCPTS'} );
    if( $obsmode eq 'RASTER' ) {
      $expt = $nscan * $cycllen / $nocycpts * ( $nocycpts + sqrt( $nocycpts ) );
    } elsif ( ( $obsmode eq 'FIVEPOINT' ) || ( $obsmode eq 'FOCUS' ) ) {
      $expt = $nscan * $cycllen * $nocycles;
    } elsif ( ( $obsmode eq 'SAMPLE' ) ) {
      $expt = $ncycpts * $cycllen * $nscan / 2;
    } else {
      # This supports pattern and grid
      $expt = $nocycles * $cycllen * $nscan;
    }
  }

  return $expt;

}

=item B<to_VELSYS>

Translate the C<VREF> and C<VDEF> headers into one combined header.

=cut

sub to_VELSYS {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'VREF'} ) && defined( $FITS_headers->{'VREF'} ) &&
      exists( $FITS_headers->{'VDEF'} ) && defined( $FITS_headers->{'VDEF'} ) ) {
    $return = substr( $FITS_headers->{'VDEF'}, 0, 3 ) . substr( $FITS_headers->{'VREF'}, 0, 3 );
  }
  return $return;
}

=back

=head1 VARIABLES

=over 4

=item B<%to_file_headers>

Contains one-to-one mappings between database headers and file headers.
Keys are database headers, values are file headers.

=cut

%to_file_headers = (
                    AZ => "C4AZ",
                    MAPUNIT => "C4ODCO",
                    OBSMODE => "C6ST",
                    BACKEND => "C1BKE",
                    BACKTYPE => "C1BTYP",
                    PROJID => "C1PID",
                    AFOCUSH => "C4Y",
                    PHASE => "C7PHASE",
                    AFOCUSR => "C4Z",
                    AFOCUSV => "C4X",
                    LST => "C3LST",
                    COORDCD => "C4CSC",
                    BACKEND => "C1BKE",
                    FRAME => "C4LSC",
                    UT1C => "C3UT1C",
                    RADATE => "C4RADATE",
                    FRONTEND => "C1RCV",
                    FRONTYPE => "C1FTYP",
                    OBJECT => "C1SNA1",
                    EL => "C4EL",
                    SCAN => "C1SNO",
                    VELOCITY => "C7VR",
                    VDEF => "C12VDEF",
                    VREF => "C12VREF",
                    SAMPRAT => "C3SRT",
                    NOCYCLES => "C3NCI",
                    NSCAN => "C3NSAMPL",
                    CYCLLEN => "C3CL",
                    NOCYCPTS => "C3NCP",
                    NCYCPTS => "C6NP",
                    RESTFRQ1 => "C12RF",
                    C3DAT => "C3DAT",
                    C3UT => "C3UT",
                   );

=item B<%hdr>

Contains one-to-one mappings between FITS headers and generic headers.
Keys are generic headers, values are FITS headers.

=cut

%hdr = (
        ALTITUDE_START => "EL",
        AZIMUTH_START => "AZ",
        BACKEND => "BACKEND",
        COORDINATE_TYPE => "FRAME",
        CYCLE_LENGTH => "CYCLLEN",
        DEC_BASE => "DECDATE",
        FILENAME => "GSDFILE",
        INSTRUMENT => "FRONTEND",
        NUMBER_OF_CYCLES => "NOCYCLES",
        OBJECT => "OBJECT",
        OBSERVATION_MODE => "OBSMODE",
        OBSERVATION_NUMBER => "SCAN",
        PROJECT => "PROJID",
        RA_BASE => "RADATE",
        REST_FREQUENCY => "RESTFRQ1",
        VELOCITY => "VELOCITY",
       );

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
