package eSTAR::RTML;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    eSTAR::RTML

#  Purposes:
#    Perl module to deal with RTML messages

#  Language:
#    Perl module

#  Description:
#    This module deals with RTML for the intelligent agent

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: RTML.pm,v 1.2 2002/03/15 05:26:13 aa Exp $

#  Copyright:
#     Copyright (C) 200s University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

eSTAR::RTML - module handling RTML for the intelligetn agent

=head1 SYNOPSIS

   $rtml = new eSTAR::RTML();
 

=head1 DESCRIPTION

The module handles RTML for the intelligent agent 

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

use XML::Parser;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;
use Data::Dumper;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: RTML.pm,v 1.2 2002/03/15 05:26:13 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $rtml = new eSTAR::RTML( File => $rtml_file );

returns a reference to an RTML object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { XML      => undef,
                      DOCUMENT => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# L O A D I N G  M E T H O D S ----------------------------------------------

=back

=head2 Methods

=over 4

=item B<file>

Loads the RTML file into the

   $dtd = $rtml->file( $rtml_file );

=cut

sub file {
  my $self = shift;
  if (@_) { 
     my $file = shift;
     $self->{DOCUMENT} = $self->{XML}->parsefile( $file );
  }
  return ;
}

# A C C E S S O R   M E T H O D S -------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<determine_type>

Return the type of the RTML document

  $type = $rtml->determine_type();

=cut

sub determine_type {
  my $self = shift;
  return ${${${$self->{DOCUMENT}}[1]}[0]}{'type'};
}

=item B<return_tree>

Returnd the RTML document tree

  $type = $rtml->return_tree();

used internally in the eSTAR::RTML::Parse module to pull the RTML document
from the object. While public, its unlikely that anyone would actually want
to do this outside this module.

=cut

sub return_tree {
  my $self = shift;
  
  my $reference = $self->{DOCUMENT};
  return $reference;
}

# C O N F I G U R E ---------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $rtml->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # SELF REFERENCE
  # --------------
  $SELF = $self;

  # BLESS XML PARSER
  # ----------------
  $self->{XML} = new XML::Parser( Style            => 'Tree',
                                  ProtocolEncoding => 'US-ASCII' );


  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / File / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------
   
=head1 COPYRIGHT

Copyright (C) 2002 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
