package Astro::FITS::HdrTrans;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans

#  Purposes:
#    Translates FITS headers into and from generic headers

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id: HdrTrans.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

#  Copyright:
#     Copyright (C) 2002 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans - Translate FITS headers into generic headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers);

  %FITS_headers = translate_to_FITS(\%generic_headers);

=head1 DESCRIPTION

Converts information contained in instrument-specific FITS headers to
and from generic headers. A list of generic headers are given at the end
of the module documentation.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;

use Switch;
use Data::Dumper;
use Carp;

our $VERSION;
'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

require Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw( translate_from_FITS translate_to_FITS @generic_headers );
our %EXPORT_TAGS = (
                    'all' => [ qw( @EXPORT ) ],
                    'variables' => [ qw( @generic_headers ) ]
                    );

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id: HdrTrans.pm,v 1.1 2003/07/21 19:59:39 aa Exp $

=head2 B<Variables>

The following variables may be exported, but are not by default.

=over 4

=item B<@generic_headers>

Provides a list of generic headers that may or may not be available in the
generic header hash, depending on if translations were set up for these
headers in the instrument-specific subclasses.

=cut

our @generic_headers = qw( AIRMASS_START
                       AIRMASS_END
                       ALTITUDE_START
                       ALTITUDE_END
                       AZIMUTH_START
                       AZIMUTH_END
                       BACKEND
                       BOLOMETERS
                       CAMERA
                       CHOP_ANGLE
                       CHOP_COORDINATE_SYSTEM
                       CHOP_THROW
                       CONFIGURATION_INDEX
                       COORDINATE_UNITS
                       COORDINATE_TYPE
                       CYCLE_LENGTH
                       DEC_BASE
                       DEC_SCALE
                       DEC_TELESCOPE_OFFSET
                       DETECTOR_BIAS
                       DETECTOR_INDEX
                       DETECTOR_READ_TYPE
                       DR_GROUP
                       DR_RECIPE
                       EQUINOX
                       EXPOSURE_TIME
                       FILENAME
                       FILTER
                       GAIN
                       GRATING_DISPERSION
                       GRATING_NAME
                       GRATING_ORDER
                       GRATING_WAVELENGTH
                       INSTRUMENT
                       INST_DHS
                       LATITUDE
                       LONGITUDE
                       MSBID
                       NSCAN_POSITIONS
                       NUMBER_OF_COADDS
                       NUMBER_OF_CYCLES
                       NUMBER_OF_DETECTORS
                       NUMBER_OF_EXPOSURES
                       NUMBER_OF_OFFSETS
                       NUMBER_OF_READS
                       NUMBER_OF_SUBFRAMES
                       OBJECT
                       OBSERVATION_MODE
                       OBSERVATION_NUMBER
                       OBSERVATION_TYPE
                       POLARIMETRY
                       PROJECT
                       RA_BASE
                       RA_SCALE
                       RA_TELESCOPE_OFFSET
                       REST_FREQUENCY
                       ROTATION
                       SAMPLING
                       SCAN_INCREMENT
                       SEEING
                       SLIT_ANGLE
                       SLIT_NAME
                       SLIT_WIDTH
                       SPEED_GAIN
                       STANDARD
                       SYSTEM_VELOCITY
                       TAU
                       TELESCOPE
                       UTDATE
                       UTEND
                       UTSTART
                       VELOCITY
                       VELSYS
                       WAVEPLATE_ANGLE
                       X_BASE
                       Y_BASE
                       X_OFFSET
                       Y_OFFSET
                       X_SCALE
                       Y_SCALE
                       X_DIM
                       Y_DIM
                       X_LOWER_BOUND
                       X_UPPER_BOUND
                       Y_LOWER_BOUND
                       Y_UPPER_BOUND
                     );

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing instrument-specific FITS headers into a hash
containing generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers);

=cut

sub translate_from_FITS {
  my $FITS_header = shift;

  my $instrument;
  my %generic_header;

  # Determine the instrument name so we can use the appropriate subclass
  # for header translations. We're going to apply a little bit of logic
  # in this determination set, since we're not entirely sure at this
  # point which header is going to contain the instrument name.

  # Start out looking at a header named INSTRUME
  if ( ( defined( $FITS_header->{INSTRUME} ) &&
         length( $FITS_header->{INSTRUME} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{INSTRUME};
  } elsif ( ( defined( $FITS_header->{INST} ) &&
              length( $FITS_header->{INST} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{INST};
  } elsif ( ( defined( $FITS_header->{C1BKE} ) &&
              length( $FITS_header->{C1BKE} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{C1BKE};
  } elsif ( ( defined( $FITS_header->{BACKEND} ) &&
              length( $FITS_header->{BACKEND} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{BACKEND};
  } else {

    # We couldn't find an instrument header, so we can't do header
    # translations. Alas.
    croak "Could not find instrument header in FITS headers.\n";

  }

  # Special instrument-handling (can't really put this elsewhere)
  if( $instrument =~ /ircam/i ) { $instrument = "IRCAM"; }
  if( $instrument =~ /das|cbe|ifd/i ) { $instrument = "JCMT_GSD"; }

  # Untaint
  if ($instrument =~ /^(\w+)$/) {
    $instrument = uc($1);
  } else {
    croak "Instrument name looks a bit strange to me: $instrument\n";
  }

  # Do the translation.
  my $class = "Astro::FITS::HdrTrans::" . uc( $instrument );
  eval "require $class";
  if( $@ ) { croak "Could not load module $class"; }
  {
    no strict 'refs';
    %generic_header = &{$class."::translate_from_FITS"}( $FITS_header, \@generic_headers);
  }

  return %generic_header;

}

=item B<translate_to_FITS>

Converts a hash containing generic headers into one containing
instrument-specific FITS headers.

  %FITS_headers = translate_to_FITS(\%generic_headers);

=cut

sub translate_to_FITS {
  my $generic_header = shift;

  my $instrument;
  my %FITS_header;

  if( ( defined( $generic_header->{BACKEND} ) ) &&
      ( length( $generic_header->{BACKEND} . "" ) != 0 ) &&
      $generic_header->{BACKEND} =~ /CBE|DAS|IFD/i ) {

    $instrument = "JCMT_GSD";

  } elsif( ( defined( $generic_header->{INSTRUMENT} ) ) &&
      ( length( $generic_header->{INSTRUMENT} . "" ) != 0 ) ) {

    $instrument = $generic_header->{INSTRUMENT};
  } else {
    croak "Instrument not found in header.\n";
  }

  # Untaint
  if ($instrument =~ /^(\w+)$/) {
    $instrument = $1;
  } else {
    croak "Instrument name looks a bit strange to me: $instrument\n";
  }

  # Do the translation.
  my $class = "Astro::FITS::HdrTrans::" . uc( $instrument );
  eval "require $class";
  if( $@ ) { croak "Could not load module $class: $@"; }
  {
    no strict 'refs';
    %FITS_header = &{$class."::translate_to_FITS"}( $generic_header, \@generic_headers);
  }

  return %FITS_header;

}

=back


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
