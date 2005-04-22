package Astro::VO::VOEvent;


=head1 NAME

eSTAR::RTML - Object interface to parse and create VOEvent messages

=head1 SYNOPSIS

   $rtml = new Astro::VO::VOEvent();
 

=head1 DESCRIPTION

At moment this module is limited to creation of VOEvent messages as
discussed in the April workshop meeting at Caltech. Functionality is
currently very limited.

Parsing is not really implemented, an XML::Parser document tree will
be returned by the parse() method. This will change when I get a chance
to do something more useful.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

use XML::Parser;
use XML::Writer;
use XML::Writer::String;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;
use Data::Dumper;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: VOEvent.pm,v 1.1 2005/04/22 09:33:59 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $object = new Astro::VO::VOEvent( );

returns a reference to an VOEvent object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { PARSER   => undef,
                      WRITER   => undef,
                      DOCUMENT => undef,
                      BUFFER   => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# A C C E S S O R   M E T H O D S -------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<build>

Build a VOEvent document

  $xml = $object->build( Type       => $string,
                         Role       => $string,
                         ID         => $url,
                         Reference => { URL => $url, Type => $string } );

or 
  
  $xml = $object->build( Type       => $string,
                         Role       => $string,
                         ID         => $url,
                         Curation   => { Publisher => $url,
                                         DateStamp => $string },
                         WhereWhen  => { RA    => $ra,
                                         Dec   => $dec,
                                         Error => $error,
                                         Time  => $time },
                         How        => { Name     => $string,
                                         Location => $string,
                                         RTML     => $url ), 
                         What       => [ { Name  => $strig,
                                           UCD   => $string,
                                           Value => $string },
                                             .
                                             .
                                             .
                                         { Name  => $strig,
                                           UCD   => $string,
                                           Value => $string } ],
                         Hypothesis => [ Class => { Prob        => $string,
                                                    Units       => $string,
                                                    Type        => $string,
                                                    Description => string },
                                                     .
                                                     .
                                                     . 
                                         Ident => { Type        => $string,
                                                    Description => string } ]
                        );
                         
  
this will create a document from the options passed to the method, most
of the hash keys are optional and if missed out the relevant keywords will
be blank or missing entirely from the built document.

MANDATORY TAGS: "Type", "Role", "ID" and either "Reference" or "WhereWhen"

=cut

sub build {
  my $self = shift;
  my %args = @_;

  # mandatory tags
  unless ( exists $args{Type} && exists $args{Role} && exists $args{ID} && 
           ( exists $args{Reference} || $args{WhereWhen} ) ) {
     return undef;
  }         

  # open the document
  $self->{WRITER}->xmlDecl( 'UTF-8' );
   
  # BEGIN DOCUMENT ------------------------------------------------------- 
  $self->{WRITER}->startTag( 'VOEvent', 
          'type' => $args{Type},
          'role' => $args{Role},
          'id'   => $args{ID},
          'xmlns:stc' => 'http://www.ivoa.net/xml/STC/stc-v1.20.xsd',
          'xmlns:crd' => 'http://www.ivoa.net/xml/STC/STCCoords/v1.20',
          'xmlns:xi'  => 'http://www.w3c.org/2001/XInclude',
          'xmlns:xsi'  => 'http://www.w3c.org/2001/XMLSchema-instance',
          'xsi:schemaLocation' => 'http://www.ivoa.net/xml/STC/stc-v1.20'
          );   
                             
  # REFERENCE ONLY -------------------------------------------------------
                             
  if ( exists $args{Reference} ) {
     $self->{WRITER}->emptyTag( 'Ref',
                                'uri' => ${$args{Reference}}{URL},
                                'type' => ${$args{Reference}}{Type} );
  
       
     $self->{WRITER}->endTag( 'VOEvent' );
     $self->{WRITER}->end();
     
     return $self->{BUFFER}->value();
  }

  # SKELETON DOCUMENT ----------------------------------------------------
     
}

=item B<parse>

Parse a VOEvent document

  $document = $object->parse( File => $file_name );
  $document = $object->parse( XML => $scalar );

this parse a VOEvent document.

=cut

sub parse {
  my $self = shift;
  my %args = @_;
  
  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
        $self->{DOCUMENT} = $self->{PARSER}->parsefile( $args{$key} );
        return $self->{DOCUMENT};
        
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
        $self->{DOCUMENT} = $self->{PARSER}->parse( $args{$key} );
        return $self->{DOCUMENT};
        
     } else {
        return undef;
        
     }   
  }
  
 
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
  $self->{PARSER} = new XML::Parser( Style            => 'Tree',
                                     ProtocolEncoding => 'US-ASCII' );

  # BLESS XML WRITER
  # ----------------
  $self->{BUFFER} = new XML::Writer::String();  
  $self->{WRITER} = new XML::Writer( OUTPUT      => $self->{BUFFER},
                                     DATA_MODE   => 1, 
                                     DATA_INDENT => 4 );

  # Nothing to configure...
  return undef;

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
