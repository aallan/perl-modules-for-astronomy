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
#     $Id: Star.pm,v 1.1 2002/01/10 03:40:42 aa Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::Star - A generic star object in a stellar catalogue.

=head1 SYNOPSIS

  $star = new Astro::Catalog::Star( ID       => $id, 
                                    RA       => $ra,
                                    Dec      => $dec,
                                    Bmag     => $b_magnitude,
                                    DeltaB   => $b_error,
                                    Vmag     => $v_magnitude,
                                    DeltaV   => $v_error,
                                    Rmag     => $r_magnitude,
                                    DeltaR   => $r_error,
                                    BminusR  => $b_minus_r,
                                    DeltaBMR => $b_minus_r_error,
                                    Quality  => $quality_flag,
                                    Field    => $field,
                                    GSC      => $in_gsc,
                                    Distance => $distance_to_centre,
                                    PosAngle => $position_angle );

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

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Star.pm,v 1.1 2002/01/10 03:40:42 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options


  $star = new Astro::Catalog::Star( ID       => $id, 
                                    RA       => $ra,
                                    Dec      => $dec,
                                    Bmag     => $b_magnitude,
                                    DeltaB   => $b_error,
                                    Vmag     => $v_magnitude,
                                    DeltaV   => $v_error,
                                    Rmag     => $r_magnitude,
                                    DeltaR   => $r_error,
                                    BminusR  => $b_minus_r,
                                    DeltaBMR => $b_minus_r_error,
                                    Quality  => $quality_flag,
                                    Field    => $field,
                                    GSC      => $in_gsc,
                                    Distance => $distance_to_centre,
                                    PosAngle => $position_angle );

returns a reference to an Astro::Catalog::Star object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { ID       => undef,
                      RA       => undef,
                      DEC      => undef, 
                      BMAG     => undef,
                      DELTAB   => undef,
                      VMAG     => undef,
                      DELTAV   => undef,
                      RMAG     => undef, 
                      DELTAR   => undef,
                      BMINUSR  => undef,
                      DELTABMR => undef, 
                      QUALITY  => undef,
                      FIELD    => undef, 
                      GSC      => undef, 
                      DISTANCE => undef, 
                      POSANGLE => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------


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
  for my $key (qw / ID RA Dec Bmag DeltaB Vmag DeltaV Rmag DeltaR BminusR
                    DeltaBMR Quality Field GSC Distance PosAngle  /) {
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
