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
#     $Id: RTML.pm,v 1.4 2003/06/03 21:24:50 aa Exp $

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

'$Revision: 1.4 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: RTML.pm,v 1.4 2003/06/03 21:24:50 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $rtml_object = new eSTAR::RTML( File => $rtml_file );
  $rtml_object = new eSTAR::RTML( Source => $rtml_document );

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

# A C C E S S O R   M E T H O D S -------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<determine_type>

Return the type of the RTML document

  $type = $rtml->determine_type();

this is the only information about the document available via this module,
to fully parse the RTML the C<eSTAR::RTML> objet should be passed to an
L<eSTAR::RTML::Parse> object.

=cut

sub determine_type {
  my $self = shift;
  return ${${${$self->{DOCUMENT}}[1]}[0]}{'type'};
}

=item B<return_tree>

Returnd the RTML document tree

  $type = $rtml->return_tree();

used by the C<eSTAR::RTML::Parse> module to pull the C<XML::Parse> document
tree from the C<eSTAR::RTML> object. While a public method, its hard to see
why you would want to do this unles the output is going to be parsed by a
module that understands such trees. In which case it might be better to call
C<XML::Parse> directly rather than deal with the C<eSTAR::RTML> infrastructure.

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

does nothing if the hash is not supplied.

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
  for my $key (qw / File Source / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# M E T H O D S -------------------------------------------------------------

=item B<file>

Populates the object from a file returning the version number of the DTD.

   $dtd = $rtml->file( $rtml_file );

This method is called directly from configure() is the C<File> key and value is passed into to teh object in the %options hash.

=cut

sub file {
  my $self = shift;
  if (@_) { 
     my $file = shift;
     $self->{DOCUMENT} = $self->{XML}->parsefile( $file );
  }
  return ${${${$self->{DOCUMENT}}[1]}[0]}{'dtd'};
}

=item B<source>

Populates the object from a scalar returning the version number of the DTD.

   $dtd = $rtml->source( $rtml );

This method is called directly from configure() is the C<Document> key and 
value is passed into to teh object in the %options hash.

=cut

sub source {
  my $self = shift;
  if (@_) { 
     my $rtml = shift;
     $self->{DOCUMENT} = $self->{XML}->parse( $rtml );
  }
  return ${${${$self->{DOCUMENT}}[1]}[0]}{'dtd'};
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

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
