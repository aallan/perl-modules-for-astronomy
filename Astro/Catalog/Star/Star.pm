package Astro::Catalog::Star;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::Catalog::Star

#  Purposes:
#    Generic star in a catalogue

#  Language:
#    Perl module

#  Description:
#    This module provides a generic star object for the Catalog object

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Star.pm,v 1.2 2002/01/11 22:57:01 aa Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::Star - A generic star object in a stellar catalogue.

=head1 SYNOPSIS

  $star = new Astro::Catalog::Star( ID         => $id, 
                                    RA         => $ra,
                                    Dec        => $dec,
                                    Magnitudes => \%magnitudes,
                                    MagErr     => \%mag_errors,
                                    Colours    => \%colours,
                                    ColErr     => \%colour_errors,
                                    Quality    => $quality_flag,
                                    Field      => $field,
                                    GSC        => $in_gsc,
                                    Distance   => $distance_to_centre,
                                    PosAngle   => $position_angle );

=head1 DESCRIPTION

Stores generic meta-data about an individual stellar object from a catalogue.

If the catalogue has a field center the Distance and Position Angle propertie
should be used to store the direction to the field center, e.g. a star from the
USNO-A2 catalogue retrieived from the ESO/ST-ECF Archive will have these
properties.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Star.pm,v 1.2 2002/01/11 22:57:01 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options


  $star = new Astro::Catalog::Star( ID         => $id, 
                                    RA         => $ra,
                                    Dec        => $dec,
                                    Magnitudes => \%magnitudes,
                                    MagErr     => \%mag_errors,
                                    Colours    => \%colours,
                                    ColErr     => \%colour_errors,
                                    Quality    => $quality_flag,
                                    Field      => $field,
                                    GSC        => $in_gsc,
                                    Distance   => $distance_to_centre,
                                    PosAngle   => $position_angle );

returns a reference to an Astro::Catalog::Star object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { ID         => undef,
                      RA         => undef,
                      DEC        => undef, 
                      MAGNITUDES => {}, 
                      MAGERR     => {},
                      COLOURS    => {},
                      COLERR     => {}, 
                      QUALITY    => undef,
                      FIELD      => undef, 
                      GSC        => undef, 
                      DISTANCE   => undef, 
                      POSANGLE   => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<id>

Return (or set) the ID of the star

   $id = $star->id();
   $star->id( $id );

=cut

sub id {
  my $self = shift;
  if (@_) {
    $self->{ID} = shift;
  }
  return $self->{ID};
}



=item B<RA>

Return (or set) the current object R.A. 

   $ra = $star->ra();
   $star->ra( $ra );

=cut

sub ra {
  my $self = shift;
  if (@_) {
    $self->{RA} = shift;
  }
  return $self->{RA};
}

=item B<Dec>

Return (or set) the current target Declination defined for the DSS query

   $dec = $dss->dec();
   $dss->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec { 
  my $self = shift;
  if (@_) {
    $self->{DEC} = shift;
  }
  return $self->{DEC};
}

=item B<Magnitudes>

Set the UBVRIHK magnitudes of the object, takes a reference to a hash of 
magnitude values

    my %mags = ( B => '16.5', V => '15.4', R => '14.3' );
    $star->magnitudes( \%mags );

additional calls to magnitudes() will append, not replace, additional 
magnitude values, magnitudes for filters already existing will be over-written.

=cut

sub magnitudes { 
  my $self = shift;
  if (@_) {
    my $mags = shift;
    %{$self->{MAGNITUDES}} = ( %{$self->{MAGNITUDES}}, %{$mags} );
  }
}

=item B<MagErr>

Set the error in UBVRIHK magnitudes of the object, takes a reference to a
hash of error values

    my %mag_errors = ( B => '0.3', V => '0.1', R => '0.4' );
    $star->magnitudes( \%mag_errors );

additional calls to magerr() will append, not replace, additional error values,
errors for filters already existing will be over-written.

=cut

sub magerr { 
  my $self = shift;
  if (@_) {
    my $magerr = shift;
    %{$self->{MAGERR}} = ( %{$self->{MAGERR}}, %{$magerr} );
  }
}

=item B<Colours>

Set the colour values for the object, takes a reference to a hash of colours

    my %cols = ( 'B-V' => '0.5', 'B-R' => '0.4' );
    $star->colours( \%cols );

additional calls to colours() will append, not replace, colour values,
altough for colours which already have defined values, these values will
be over-written.

=cut

sub colours { 
  my $self = shift;
  if (@_) {
    my $cols = shift;
    %{$self->{COLOURS}} = ( %{$self->{COLOURS}}, %{$cols} );
  }
}

=item B<ColErr>

Set the colour error values for the object, takes a reference to a hash of
colour errors

    my %col_errors = ( 'B-V' => '0.02', 'B-R' => '0.05' );
    $star->colerr( \%col_errors );

additional calls to colerr() will append, not replace, colour error values,
altough for errors which already have defined values, these values will
be over-written.

=cut

sub colerr { 
  my $self = shift;
  if (@_) {
    my $col_err = shift;
    %{$self->{COLERR}} = ( %{$self->{COLERR}}, %{$col_err} );
  }
}


=item B<what_filters>

Returns a list of the filters for which the object has defined values.

   @filters = $star->what_filters();
   $num = $star->what_filters();

if called in a scalar context it will return the number of filters which
have defined magnitudes in the object.

=cut

sub what_filters {
  my $self = shift;
  
  # define output array
  my @mags;
  
  foreach my $key (sort keys %{$self->{MAGNITUDES}}) {
      # push the filters onto the output array
      push ( @mags, $key );
  }
  
  # return array of filters or number if called in scalar context
  return wantarray ? @mags : $#mags;
}    

=item B<what_colours>

Returns a list of the colours for which the object has defined values.

   @colours = $star->what_colours();
   $num = $star->what_colours();

if called in a scalar context it will return the number of colours which
have defined values in the object.

=cut

sub what_colours {
  my $self = shift;
  
  # define output array
  my @cols;
  
  foreach my $key (sort keys %{$self->{COLOURS}}) {
      # push the colours onto the output array
      push ( @cols, $key );
  }
  
  # return array of colours or number if called in scalar context
  return wantarray ? @cols : $#cols;
}  
  
=item B<get_magnitude>

Returns the magnitude for the supplied filter if available

   $magnitude = $star->get_magnitude( 'B' );

=cut

sub get_magnitude {
  my $self = shift;
  
  my $magnitude;
  if (@_) {  
  
     # grab passed filter
     my $filter = shift;
     foreach my $key (sort keys %{$self->{MAGNITUDES}}) {
         
         # grab magnitude for filter
         if( $key eq $filter ) {
            $magnitude = ${$self->{MAGNITUDES}}{$key};
         }   
     }
  }
  return $magnitude;
}  
    
=item B<get_errors>

Returns the error in the magnitude value for the supplied filter if available

   $mag_errors = $star->get_errors( 'B' );

=cut

sub get_errors {
  my $self = shift;
  
  my $mag_error;
  if (@_) {  
  
     # grab passed filter
     my $filter = shift;
     foreach my $key (sort keys %{$self->{MAGERR}}) {
         
         # grab magnitude for filter
         if( $key eq $filter ) {
            $mag_error = ${$self->{MAGERR}}{$key};
         }   
     }
  }
  return $mag_error;
}  

=item B<get_colour>

Returns the value of the supplied colour if available

   $colour = $star->get_colour( 'B-V' );

=cut

sub get_colour {
  my $self = shift;
  
  my $value;
  if (@_) {  
  
     # grab passed colour
     my $colour = shift;
     foreach my $key (sort keys %{$self->{COLOURS}}) {
         
         # grab magnitude for colour
         if( $key eq $colour ) {
            $value = ${$self->{COLOURS}}{$key};
         }   
     }
  }
  return $value;
}  

=item B<get_colourerror>

Returns the error in the colour value for the supplied colour if available

   $col_errors = $star->get_colourerr( 'B-V' );

=cut

sub get_colourerr {
  my $self = shift;
  
  my $col_error;
  if (@_) {  
  
     # grab passed colour
     my $colour = shift;
     foreach my $key (sort keys %{$self->{COLERR}}) {
         
         # grab values for the colour
         if( $key eq $colour ) {
            $col_error = ${$self->{COLERR}}{$key};
         }   
     }
  }
  return $col_error;
}  
   
=item B<quality>

Return (or set) the quality flag of the star

   $quality = $star->quailty();
   $star->quality( 0 );

for example for the USNO-A2 caltalogue, 0 denotes good quality, and 1 denotes
a possible problem object. In the generic case any flag value, including a boolean, could be used.

=cut

sub quality {
  my $self = shift;
  if (@_) {
    $self->{QUALITY} = shift;
  }
  return $self->{QUALITY};
}  

sub field {}
sub gsc {}
sub distance {}
sub posangle {} 

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $star->configure( %options );

Takes a hash as argument with the list of keywords.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys storing the values
  # in the object if they exist
  for my $key (qw / ID RA Dec Magnitudes MagErr Colours ColErr
                    Quality Field GSC Distance PosAngle  /) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.


=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;      
