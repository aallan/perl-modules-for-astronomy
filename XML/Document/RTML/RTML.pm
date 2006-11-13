package XML::Document::RTML;
# ---------------------------------------------------------------------------

#+ 
#  Name:
#    XML::Document::RTML

#  Purposes:
#    Perl module to build and parse RTML documents

#  Language:
#    Perl module

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: RTML.pm,v 1.1 2006/11/13 17:56:09 aa Exp $

#  Copyright:
#     Copyright (C) 200s University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

XML::Document::RTML - module which builds and parses RTML documents

=head1 SYNOPSIS

An object instance can be created from an existing RTML document in a 
scalar, or directly from a file on local disk.


   my $object = new XML::Document::RTML( XML => $xml );
   my $object = new XML::Document::RTML( File => $file );
   
or via the build method,

   my $object = new XML::Document::RTML() 
   $document = $object->build( %hash );
   
once instantiated various query methods are supported, e.g.,

   my $object = new XML::Document::RTML( File => $file );
   my $role = $object->role();

=head1 DESCRIPTION

The module can build and parse RTML documents. Currently only version 2.2
of the standard is supported by the module.

=cut
# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

#use XML::Parser;
use XML::Simple;
use XML::Writer;
use XML::Writer::String;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;
use Data::Dumper;
use Class::ISA;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: RTML.pm,v 1.1 2006/11/13 17:56:09 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  my $object = new XML::Document::RTML( %hash );

returns a reference to an message object.

=cut


sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DOCUMENT => undef,
                      WRITER   => undef,
                      BUFFER   => undef,
		      OPTIONS  => {} }, $class;

  # Configure the object
  $block->configure( @_ ); 

  return $block;

}

# A C C E S S O R   M E T H O D S -------------------------------------------

sub build {
  my $self = shift;
  my %args = @_;

  # mandatory tags
  unless ( exists $args{Role} ) {
     return undef;
  }         

  # open the document
  $self->{WRITER}->xmlDecl( 'US_ASCII' );
   
  # BEGIN DOCUMENT ------------------------------------------------------- 
  
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );


  # SKELETON DOCUMENT ----------------------------------------------------

  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  my $xml = $self->{BUFFER}->value();
  $self->_parse( XML => $xml ); # populates the object with a parsed document
  return $xml;  

}  

# GET & SET --------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<type>

Return, or set, the type of the RTML document

  my $type = $object->type();
  $object->type( $type );

=cut

sub role {
  my $self = shift;
  if (@_) {
     ${$self->{OPTIONS}}{TYPE} = shift;
  }
  return $self->{DOCUMENT}->{type};
}

sub type {
  role( @_ );
}

sub determine_type {
  role( @_ );
}

=item B<version>

Return, or set, the version of the RTML specification used

  my $version = $object->version();
  $object->version( $version );

=cut

sub version {
  my $self = shift;
  if (@_) {
     ${$self->{OPTIONS}}{VERSION} = shift;
  }  
  return $self->{DOCUMENT}->{version};
}

sub dtd {
   version( @_ );
}

=item B<group_count>

Return, or set, the group count of the observation

  my $num = $object->group_count();
  $object->group_count( $num );
  
=cut

sub group_count {
  my $self = shift;
  if (@_) {
     ${$self->{OPTIONS}}{GROUPCOUNT} = shift;
  }  
  return $self->{DOCUMENT}->{Observation}->{Schedule}->{Exposure}->{Count};
}

sub groupcount {
  group_count( @_ );
}  


=item B<series_count>

Return, or set, the series count of the observation

  my $num = $object->series_count();
  $object->series_count( $num );
  
=cut

sub series_count {
  my $self = shift;
  if (@_) {
     ${$self->{OPTIONS}}{SERIESCOUNT} = shift;
  }  
  return $self->{DOCUMENT}->{Observation}->{Schedule}->{SeriesConstraint}->{Count};
}

sub seriescount {
  series_count( @_ );
}  

# G E N E R A L ------------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<dump_buffer>

Dumps the contents of the RTML buffer in memory to a scalar, should return
an undefined value if that buffer is empty. This will occur if we haven't
called build() to create a document.

   $string = $object->dump_buffer();

=cut

sub dump_buffer {
  my $self = shift;
  
  if ( defined $self->{BUFFER} ){
     return $self->{BUFFER}->value();
  } else {
     return undef;
  }
}

sub dump_rtml {
  dump_buffer( @_ );
} 

sub buffer {
  dump_buffer( @_ );
}   

=item B<dump_document>

Dumps the contents of the RTML document tree currently held in memory to 
a scalar, should return an undefined value if that tree is empty. This error
will occur if we haven't called build() to create a document, or populated 
the tree using the object creator by calling the XML or File methods to read 
in an existing document.

   $string = $object->dump_document();

=cut

sub dump_document {
  my $self = shift;
  
  if ( defined $self->{DOCUMENT} ){
     return $self->{DOCUMENT};
  } else {
     return undef;
  }
}

sub dump_tree {
  dump_document( @_ );
}  

sub document {
  dump_document( @_ );
}  


# C O N F I G U R E ---------------------------------------------------------

=item B<configure>

Configures the object, takes an options hash as an argument

  $message->configure( %options );

Does nothing if the hash is not supplied. This is called directly from
the constructor during object creation

=cut


sub configure {
  my $self = shift;

  # BLESS XML WRITER
  # ----------------
  $self->{BUFFER} = new XML::Writer::String();  
  $self->{WRITER} = new XML::Writer( OUTPUT      => $self->{BUFFER},
                                     DATA_MODE   => 1, 
                                     DATA_INDENT => 4 );
				     
  # DEFAULTS
  # --------
  
  # use the RTML Namespace as defined by the v2.2 DTD
  ${$self->{OPTIONS}}{DTD} = "http://www.estar.org.uk/documents/rtml2.2.dtd"; 
  
  ${$self->{OPTIONS}}{HOST} = "127.0.0.1";
  ${$self->{OPTIONS}}{PORT} = '8000';
  
  ${$self->{OPTIONS}}{EQUINOX} = 'J2000';
  
  ${$self->{OPTIONS}}{TARGETTYPE} = 'normal';
  ${$self->{OPTIONS}}{TARGETIDENT} = 'SingleExposure';

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;
				        
  # Loop over the keys that mean we're parsing a document
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
        $self->_parse( File => $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
        $self->_parse( XML => $args{$key} );
	last;
	      
     }  
  }	
  
  # Loop over the rest of the keys
  for my $key (qw / Port ID Role User Name Institution Email Host 
  		    Target TargetType TargetIdent RA Dec Equinox 
		    Exposure Snr Flux Filter GroupCount SeriesCount 
		    Interval Tolerance TimeConstraint Score Time 
		    Catalogue Headers ImageURI/ ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }
  
  			     

  # Nothing to configure...
  return undef;

}


# P R I V A T E   M E T H O D S ------------------------------------------

sub _parse {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  my $xs = new XML::Simple( );

  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     }  
  }
  
  #print Dumper( $self->{DOCUMENT} );      
  return;
}

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
