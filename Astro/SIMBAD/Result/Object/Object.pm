package Astro::SIMBAD::Result::Object;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::SIMBAD::Result:Object

#  Purposes:
#    Perl wrapper for the SIMBAD database

#  Language:
#    Perl module

#  Description:
#    This module wraps the SIMBAD online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Object.pm,v 1.2 2001/11/28 01:06:10 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::SIMBAD::Result::Object - A individual astronomical object 

=head1 SYNOPSIS

  $object = new Astro::SIMBAD::Result::Object( Name   => $object_name,
                                               Type   => $object_type,
                                               Long   => $long_type,
                                               Frame => \@coord_frame,
                                               RA     => $ra,
                                               Dec    => $declination,
                                               Spec   => $spectral_type,
                                               URL    => $url );

=head1 DESCRIPTION

Stores meta-data about an individual astronomical object in the
Astro::SIMBAD::Result object returned by an Astro::SIMBAD::Query object.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Object.pm,v 1.2 2001/11/28 01:06:10 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $paper = new Astro::SIMBAD::Result::Object(  );

returns a reference to an SIMBAD astronomical object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { NAME    => undef,
                      TYPE    => undef,
                      LONG    => undef,
                      FRAME   => [],
                      RA      => undef,
                      DEC     => undef,
                      SPEC    => undef,
                      URL     => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<name>

Return (or set) the name of the object

   $name = $object->name();
   $object->name( $name );

=cut

sub name {
  my $self = shift;
  if (@_) {
    $self->{NAME} = shift;
  }
  return $self->{NAME};
}

=item B<type>

Return (or set) the (short) type of the object

   $type = $object->type();
   $object->type( $type );

=cut

sub type {
  my $self = shift;
  if (@_) {
    $self->{TYPE} = shift;
  }
  return $self->{TYPE};
}

=item B<long>

Return (or set) the (long) type of the object

   $long_type = $object->long();
   $object->long( $long_type );

=cut

sub long {
  my $self = shift;
  if (@_) {
    $self->{LONG} = shift;
  }
  return $self->{LONG};
}

=item B<frame>

Return (or set) the system the R.A. and DEC stored in the object are
defined in, e.g. Co-ordinate Frame FK5, Epoch 1950 and Equinox 2000

   @system = $object->system();
   $object->system( \@system );

where @system would be [ "FK5", 1950.0, 2000.0 ]. If called in a scalar
context will return a string of the form "FK5 1950/2000" to

=cut

sub frame {
  my $self = shift;

  if (@_) {
    # take a local copy to avoid "copy of copy" problems
    my $frame = shift;
    @{$self->{FRAME}} = @{$frame};
  }
   
  my $stringify = 
     "${$self->{FRAME}}[0] ${$self->{FRAME}}[1]/${$self->{FRAME}}[2]";
     
  return wantarray ? @{$self->{FRAME}} : $stringify;
}

=item B<ra>

Return (or set) the R.A. of the object

   $ra = $object->ra();
   $object->ra( $ra );

=cut

sub ra {
  my $self = shift;
  if (@_) {
    $self->{RA} = shift;
  }
  return $self->{RA};
}

=item B<dec>

Return (or set) the Declination of the object

   $dec = $object->dec();
   $object->dec( $dec );

=cut

sub dec {
  my $self = shift;
  if (@_) {
    $self->{DEC} = shift;
  }
  return $self->{DEC};
}

=item B<spec>

Return (or set) the Spectral Type of the object

   $spec_type = $object->spec();
   $object->spec( $spec_type );

=cut

sub spec {
  my $self = shift;
  if (@_) {
    $self->{SPEC} = shift;
  }
  return $self->{SPEC};
}

=item B<url>

Return (or set) the followup URL for the object where more information
can be found via SIMBAD, including pointers to reduced data.

   $url = $object->url();
   $object->url( $url );

=cut

sub url {
  my $self = shift;
  if (@_) {
    $self->{URL} = shift;
  }
  return $self->{URL};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $object->configure( %options );

Takes a hash as argument with the following keywords:

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys storing the values
  # in the object if they exist
  for my $key (qw / Name Type Long Frame RA Dec Spec URL /) {
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
