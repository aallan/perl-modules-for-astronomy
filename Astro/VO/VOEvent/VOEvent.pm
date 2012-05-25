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

'$Revision: 1.6 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: VOEvent.pm,v 1.6 2005/11/02 01:17:49 aa Exp $

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

  $xml = $object->build( Type        => $string,
                         Role        => $string,
                         ID          => $url,
                         Description => $string,
                         Citations   => [ { ID   => $strig,
                                            Cite => $string },
                                              .
                                              .
                                              .
                                          { ID   => $string,
                                            Cite => $string }],
                         Who        => { Publisher => $url,
                                          Contact => { Name      => $string,
                                                       Institution => $string,
                                                       Address   => $string,
                                                       Telephone => $string,
                                                       Email     => $string, },
                                          Date    => $string },
                         WhereWhen   => { RA    => $ra,
                                          Dec   => $dec,
                                          Error => $error,
                                          Time  => $time },
                         How         => { Name     => $string,
                                          Location => $string,
                                          RTML     => $url ),
                         What        => [ { Name  => $strig,
                                            UCD   => $string,
                                            Value => $string },
                                              .
                                              .
                                              .
                                          { Name  => $string,
                                            UCD   => $string,
                                            Value => $string } ],
                         Hypothesis  => { Classification => {
                                                   Probability  => $string,
                                                   Type         => $string,
                                                   Description  => string },
                                                       .
                                                       .
                                                       .
                                          Identification => {
                                                   Type        => $string,
                                                   Description => string } }
                       );


this will create a document from the options passed to the method, most
of the hash keys are optional and if missed out the relevant keywords will
be blank or missing entirely from the built document. Type, Role, ID and
either Reference or WhereWhen (and their sub-tags) are mandatory.

The <Group> tag can be utilised from within the <What> tag as follows

                         What => [ Group => [ { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string },
                                                  .
                                                  .
                                                  .
                                              { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string } ],
                                  Group => [ { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string },
                                                  .
                                                  .
                                                  .
                                              { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string } ],
                                  { Name  => $string,
                                    UCD   => $string,
                                    Value => $string,
                                    Units => $string },
                                      .
                                      .
                                      .
                                  { Name  => $string,
                                    UCD   => $string,
                                    Value => $string,
                                    Units => $string } ],

this will probably NOT be the final API for the build() method, as it is
overly complex. It is probably one or more convenience methods will be
put ontop of this routine to make it easier to use. See the t/2_simple.t
file in the test suite for an example which makes use of the complex form
of the What tag above.

NB: This is the low level interface to build a message, this is subject
to change without notice as higher level "easier to use" accessor methods
are added to the module. It may eventually be reclassified as a PRIVATE
method.

=cut

sub build {
  my $self = shift;
  my %args = @_;

  # mandatory tags
  unless ( exists $args{Role} && exists $args{ID} &&
           ( exists $args{Reference} || $args{WhereWhen} ) ) {
     return undef;
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'UTF-8' );

  # BEGIN DOCUMENT -------------------------------------------------------
  if ( exists $args{UseSTC} ) {
     $self->{WRITER}->startTag( 'VOEvent',
          #'type' => $args{Type},
          'role' => $args{Role},
          'id'   => $args{ID},
	  'version' => '0.1',
          'xmlns:stc' => 'http://www.ivoa.net/xml/STC/stc-v1.20.xsd',
          'xmlns:crd' => 'http://www.ivoa.net/xml/STC/STCCoords/v1.20',
          'xmlns:xi'  => 'http://www.w3c.org/2001/XInclude',
          'xmlns:xsi'  => 'http://www.w3c.org/2001/XMLSchema-instance',
          'xsi:schemaLocation' => 'http://www.ivoa.net/xml/STC/stc-v1.20'
	  );
  } else {
     $self->{WRITER}->startTag( 'VOEvent',
          #'type' => $args{Type},
          'role' => $args{Role},
          'id'   => $args{ID},
	  'version' => 'HTN/0.1' );
  }

  # REFERENCE ONLY -------------------------------------------------------

  if ( exists $args{Reference} ) {
     if ( exists $args{Description} ) {
        $self->{WRITER}->startTag( 'Description' );
        $self->{WRITER}->characters( $args{Description} );
        $self->{WRITER}->endTag( 'Description' );
     }

     $self->{WRITER}->emptyTag( 'Reference',
                                'uri' => ${$args{Reference}}{URL},
                                'type' => ${$args{Reference}}{Type} );


     $self->{WRITER}->endTag( 'VOEvent' );
     $self->{WRITER}->end();

     return $self->{BUFFER}->value();
  }

  # SKELETON DOCUMENT ----------------------------------------------------

  # DESCRIPTION
  if ( exists $args{Description} ) {
     $self->{WRITER}->startTag( 'Description' );
     $self->{WRITER}->characters( $args{Description} );
     $self->{WRITER}->endTag( 'Description' );
  }

  # WHO
  if ( exists $args{Who} ) {
     $self->{WRITER}->startTag( 'Who' );

     if ( exists ${$args{Who}}{Publisher} ) {
       $self->{WRITER}->startTag( 'Publisher' );
       $self->{WRITER}->characters( ${$args{Who}}{Publisher} );
       $self->{WRITER}->endTag( 'Publisher' );
     }
     if ( exists ${$args{Who}}{Contact} ) {
       $self->{WRITER}->startTag( 'Contact' );
       if ( exists ${${$args{Who}}{Contact}}{Name} ) {
          $self->{WRITER}->startTag( 'Name' );
          $self->{WRITER}->characters(
                             ${${$args{Who}}{Contact}}{Name} );
          $self->{WRITER}->endTag( 'Name' );
       }
       if ( exists ${${$args{Who}}{Contact}}{Institution} ) {
          $self->{WRITER}->startTag( 'Institution' );
          $self->{WRITER}->characters(
                             ${${$args{Who}}{Contact}}{Institution} );
          $self->{WRITER}->endTag( 'Institution' );
       }
       if ( exists ${${$args{Who}}{Contact}}{Address} ) {
          $self->{WRITER}->startTag( 'Address' );
          $self->{WRITER}->characters(
                             ${${$args{Who}}{Contact}}{Address} );
          $self->{WRITER}->endTag( 'Address' );
       }
       if ( exists ${${$args{Who}}{Contact}}{Telephone} ) {
          $self->{WRITER}->startTag( 'Telephone' );
          $self->{WRITER}->characters(
                             ${${$args{Who}}{Contact}}{Telephone} );
          $self->{WRITER}->endTag( 'Telephone' );
       }
       if ( exists ${${$args{Who}}{Contact}}{Email} ) {
          $self->{WRITER}->startTag( 'Email' );
          $self->{WRITER}->characters(
                             ${${$args{Who}}{Contact}}{Email} );
          $self->{WRITER}->endTag( 'Email' );
       }
       $self->{WRITER}->endTag( 'Contact' );
     }
     if ( exists ${$args{Who}}{Date} ) {
       $self->{WRITER}->startTag( 'Date' );
       $self->{WRITER}->characters( ${$args{Who}}{Date} );
       $self->{WRITER}->endTag( 'Date' );
     }

     $self->{WRITER}->endTag( 'Who' );
  }

  # CITATIONS
  if ( exists $args{Citations} ) {
     $self->{WRITER}->startTag( 'Citations' );

     my @array = @{$args{Citations}};
     foreach my $i ( 0 ... $#array ) {
        $self->{WRITER}->startTag( 'EventID','cite' => ${$array[$i]}{Cite} );
	$self->{WRITER}->characters( ${$array[$i]}{ID} );
	$self->{WRITER}->endTag( 'EventID' );
     }
     $self->{WRITER}->endTag( 'Citations' );
  }

  # WHERE & WHEN
  if ( exists $args{UseSTC} ) {
      $self->{WRITER}->startTag( 'WhereWhen',
                                 'type' => 'stc', );
      $self->{WRITER}->startTag( 'stc:ObservationLocation' );
      $self->{WRITER}->startTag( 'crd:AstroCoords',
        		      'coord_system_id' => 'FK5-UTC' );
      $self->{WRITER}->startTag( 'crd:Time', 'unit' => 's' );
      $self->{WRITER}->startTag( 'crd:TimeInstant' );
      $self->{WRITER}->startTag( 'crd:TimeScale' );
      $self->{WRITER}->characters( 'UTC' );
      $self->{WRITER}->endTag( 'crd:TimeScale' );
      $self->{WRITER}->startTag( 'crd:ISOTime' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Time} );
      $self->{WRITER}->endTag( 'crd:ISOTime' );
      $self->{WRITER}->endTag( 'crd:TimeInstant' );
      $self->{WRITER}->endTag( 'crd:Time' );
      $self->{WRITER}->startTag( 'crd:Position2D', 'unit' => 'deg' );
      $self->{WRITER}->startTag( 'crd:Value2');
      my $position = ${$args{WhereWhen}}{RA} . " " . ${$args{WhereWhen}}{Dec};
      $self->{WRITER}->characters( $position );
      $self->{WRITER}->endTag( 'crd:Value2' );
      $self->{WRITER}->startTag( 'crd:Error1Circle' );
      $self->{WRITER}->startTag( 'crd:Size' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Error} );
      $self->{WRITER}->endTag( 'crd:Size' );
      $self->{WRITER}->endTag( 'crd:Error1Circle' );
      $self->{WRITER}->endTag( 'crd:Position2D' );
      $self->{WRITER}->endTag( 'crd:AstroCoords' );
      $self->{WRITER}->endTag( 'stc:ObservationLocation' );
  } else {
      $self->{WRITER}->startTag( 'WhereWhen',
                                 'type' => 'simple', );
      $self->{WRITER}->startTag( 'RA', units => 'deg' );
      $self->{WRITER}->startTag( 'Coord' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{RA} );
      $self->{WRITER}->endTag( 'Coord' );
      $self->{WRITER}->emptyTag( 'Error',
                            value => ${$args{WhereWhen}}{Error},
			    units => "arcmin" );
      $self->{WRITER}->endTag( 'RA' );
      $self->{WRITER}->startTag( 'Dec', units => 'deg' );
      $self->{WRITER}->startTag( 'Coord' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Dec} );
      $self->{WRITER}->endTag( 'Coord' );
      $self->{WRITER}->emptyTag( 'Error',
                            value => ${$args{WhereWhen}}{Error},
			    units => "arcmin" );
      $self->{WRITER}->endTag( 'Dec' );
      $self->{WRITER}->emptyTag( 'Epoch', value => "J2000.0" );
      $self->{WRITER}->emptyTag( 'Equinox', value => "2000.0" );

      $self->{WRITER}->startTag( 'Time' );
      $self->{WRITER}->startTag( 'Value' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Time} );
      $self->{WRITER}->endTag( 'Value' );
      if ( exists ${$args{WhereWhen}}{TimeError} ) {
         $self->{WRITER}->emptyTag( 'Error',
                            value => ${$args{WhereWhen}}{TimeError},
			    units => "s" );
      }
      $self->{WRITER}->endTag( 'Time' );

  }
  $self->{WRITER}->endTag( 'WhereWhen' );

  # HOW
  if ( exists $args{How} ) {
     $self->{WRITER}->startTag( 'How' );
     $self->{WRITER}->startTag( 'Instrument' );

     if ( exists ${$args{How}}{Name} ) {
       $self->{WRITER}->startTag( 'Name' );
       $self->{WRITER}->characters( ${$args{How}}{Name} );
       $self->{WRITER}->endTag( 'Name' );
     }

     if ( exists ${$args{How}}{Location} ) {
       $self->{WRITER}->startTag( 'Location' );
       $self->{WRITER}->characters( ${$args{How}}{Location} );
       $self->{WRITER}->endTag( 'Location' );
     }
     if ( exists ${$args{How}}{RTML} ) {
       $self->{WRITER}->emptyTag( 'Reference' ,
                                   uri => ${$args{How}}{RTML},
                                   type => 'rtml' );
     }

     $self->{WRITER}->endTag( 'Instrument' );
     $self->{WRITER}->endTag( 'How' );
  }

  # WHAT
  if ( exists $args{What} ) {
     $self->{WRITER}->startTag( 'What' );

     my @array = @{$args{What}};
     foreach my $i ( 0 ... $#array ) {

        my %hash = %{${$args{What}}[$i]};

        if ( exists $hash{Group} ) {
           $self->{WRITER}->startTag( 'Group' );

           my @subarray = @{$hash{Group}};
           foreach my $i ( 0 ... $#subarray ) {

              # Only UNITS is optional for Param tags
              if ( exists ${$subarray[$i]}{Units} ) {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value},
                                          'units' => ${$subarray[$i]}{Units} );
              } else {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value},
                                          'units' => ${$subarray[$i]}{Units} );
              }
           }

           $self->{WRITER}->endTag( 'Group' );

        } else {
           # Only UNITS is optional for Param tags
           if ( exists $hash{Units} ) {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value},
                                        'units' => $hash{Units} );
           } else {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value} );
           }
        }
     }

     $self->{WRITER}->endTag( 'What' );
  }

  # WHY
  if ( exists $args{Why} ) {
     $self->{WRITER}->startTag( 'Why' );

     if ( exists ${$args{Why}}{Classification} ) {
        if ( exists ${${$args{Why}}{Classification}}{Probability} ) {
          $self->{WRITER}->startTag( 'Classification',
          'probability' => ${${$args{Why}}{Classification}}{Probability},
          'units'       => 'percent',
          'type'        => ${${$args{Why}}{Classification}}{Type});
          $self->{WRITER}->characters(
                        ${${$args{Why}}{Classification}}{Description} );
          $self->{WRITER}->endTag( 'Classification' );
        } else {
          $self->{WRITER}->startTag( 'Classification',
                   'type' => ${${$args{Why}}{Classification}}{Type});
          $self->{WRITER}->characters(
                        ${${$args{Why}}{Classification}}{Description} );
          $self->{WRITER}->endTag( 'Classification' );
        }
     }

     if ( exists ${$args{Why}}{Identification} ) {
       $self->{WRITER}->startTag( 'Identification',
             'type'   => ${${$args{Why}}{Identification}}{Type});
       $self->{WRITER}->characters(
                        ${${$args{Why}}{Identification}}{Description} );
       $self->{WRITER}->endTag( 'Identification' );
     }


     $self->{WRITER}->endTag( 'Why' );
  }

  # END DOCUMENT ---------------------------------------------------------
  $self->{WRITER}->endTag( 'VOEvent' );
  $self->{WRITER}->end();

  return $self->{BUFFER}->value();


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

     }
  }
  return undef;


}

=item B<determine_id>

Return the id of the VOEvent document

  $id = $object->determine_id( File => $file_name );
  $id = $object->determine_id( XML => $scalar );

this is the only information about the document available via this module.

=cut

sub determine_id {
  my $self = shift;
  my %args = @_;

  $self->parse( %args );
  return ${${${$self->{DOCUMENT}}[1]}[0]}{'id'};
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
