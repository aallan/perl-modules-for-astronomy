package Astro::ADS::Result;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::ADS::Result

#  Purposes:
#    Perl wrapper for the ADS database

#  Language:
#    Perl module

#  Description:
#    This module wraps the ADS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Result.pm,v 1.8 2001/11/02 01:32:28 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::ADS::Result - Results from an ADS Query

=head1 SYNOPSIS

  $result = new Astro::ADS::Result( Papers => \@papers );

=head1 DESCRIPTION

Stores the results returned from an ADS search as a hash of
Astro::ADS::Result::Paper objects, with the papers being indexed
by bibcode.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::ADS::Result::Paper;

'$Revision: 1.8 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Result.pm,v 1.8 2001/11/02 01:32:28 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $result = new Astro::ADS::Result( Papers => \@papers );

returns a reference to an ADS Result object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RESULTS => [] }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<sizeof>

Return the number of papers in the Astro::ADS::Result objec.

   $paper = $result->sizeof();

=cut

sub sizeof {
  my $self = shift;

  return scalar( @{$self->{RESULTS}} );
}

=item B<pushpaper>

Push a new paper onto the end of the Astro::ADS::Result object

   $result->pushpaper( $paper );

returns the number of papers now in the Result object.

=cut

sub pushpaper {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;  
  
  my $paper = shift;
  my $bibcode = $paper->bibcode();

  # push the new hash item onto the stack 
  return push( @{$self->{RESULTS}}, $paper );
}

=item B<poppaper>

Pop a paper from the end of the Astro::ADS::Result object

   $paper = $result->poppaper();

the method deletes the paper and returns the deleted paper object.

=cut

sub poppaper {
  my $self = shift;
  my $bibcode = shift;

  # pop the paper out of the stack
  return pop( @{$self->{RESULTS}} );
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as argument

  $result->configure( %options );

Takes a hash as argument with the following keywords:

=over 4

=item B<Papers>

An reference to an array of Astro::ADS::Result::Paper objects.


=back

Does nothing if these keys are not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  if (defined $args{Papers}) {
   
     # Go through each of the supplied paper objects
     for my $i ( 0 ...$#{$args{Papers}} ) {
        ${$self->{RESULTS}}[$i] = ${$args{Papers}}[$i];
     }
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Public License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
