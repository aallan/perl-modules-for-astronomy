package Astro::Catalog::Query::Sesame;

=head1 NAME

Astro::Catalog::Query::Sesame - Object name resolution via SIMBAD

=head1 SYNOPSIS

  my $sesame = new Astro::Catalog::Query::Sesame( Target => "EX Hya" );
  my $catalog = $sesame->querydb();

=head1 DESCRIPTION

Simple wrapper object for the CDS SIMBAD Name Resolver serbice (Sesame), see
http://cdsweb.u-strasbg.fr/cdsws.gml for details of the service. 

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use base qw/ Astro::Catalog::Transport::WebService /;
use vars qw/ $VERSION /;

use Carp;
use Math::Libm ':all';

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: Sesame.pm,v 1.2 2003/07/30 03:35:04 aa Exp $

=head1 METHODS

=head2 Constructor

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::Catalog::Query::WebService( Object => $target );

returns a reference to an query object.
=cut

# base class 

=item B<querydb>

Returns an Astro::Catalog object resulting from the specific query.

   $catalog = $query->querydb();

=cut

sub querydb {
  my $self = shift;
  
  # clean out buffer
  $self->_set_raw("");
  
  my $endpoint = $self->endpoint();
  my %options = $self->_translate_options();
  
  # return unless we haev a target, set it otherwise
  return undef unless $self->query_options("object");

  # make sesame query
  my $service = SOAP::Lite->service( $self->endpoint() );   
  
  my $ident = $self->query_options("object");
  $ident =~ s/\+/ /g;
  
  my $buffer; 
  eval { $buffer = $service->Sesame( $ident ); };
  if ( $@ ) {
     my $status = $service->transport()->status();
     croak("Error: $status");
     return;
  }
 
  # parse results & return
  $self->_set_raw( $buffer );
  my $catalog = $self->_parse_query();
  return $catalog; 
}

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_endpoint>

=cut

sub _default_endpoint {
  return "http://cdsws.u-strasbg.fr/axis/Sesame.jws?wsdl";
}

=item B<_default_urn>

=cut

sub _default_urn {
  return undef;
}

=item B<_is_service>

=cut

sub _is_service {
  return 1;
}  

=item B<_get_allowed_options>

Returns a hash with keys, being the internal options supported
by this subclass, and values being the key name actually required
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
	  object => 'object'
	 );
}

=item B<_get_supported_init>

Uses base class options.

=cut

# base class

=item B<_set_default_options>

Set the default query state.

=cut

sub _set_default_options {
  my $self = shift;

  my %defaults = (
		  object => undef,
		 );

  $self->_set_query_options( %defaults );
  return;
}


=item B<_get_supported_init>

Return the list of initialization methods supported by this catalogue.
This is not the same as the allowed options since some methods are
not related to options and other methods that are related to options
use different names.

=cut

sub _get_supported_init {
  return (qw/ Target URN Endpoint Proxy /);
}

=item B<_parse_query>

Private function used to parse the results returned in an USNO-A2.0 query.
Should not be called directly. Instead use the querydb() assessor method to 
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;

  # create an Astro::Catalog object to hold the search results
  my $catalog = new Astro::Catalog();

  # create a temporary object to hold stars
  my $star = new Astro::Catalog::Star();

  # get a local copy of the current BUFFER
  my @result = $self->_dump_raw();
  chomp @result;
  
  #use Data::Dumper; print Dumper( @result );
  
  # Grab Coordinates
  # ----------------
  #use Data::Dumper;
  #print Dumper( @result );
  
  # grab line from return result
  my $line = $result[3];
  
  # split it on \s+
  my @coords = split( /\s+/,$line);

  # GRAB DEC
  # --------

  # grab Dec
  my $dec = $coords[2];  
  #print "dec $dec\n";
  
  my $decdot = index $dec, ".";
  my $deg = substr $dec, 0, $decdot;
  #print "deg $deg\n";
  
  my $min = substr $dec, $decdot+1, length($dec);
  $min = "0." . $min;
  $min = $min * 60.0;  

  my $secdot = index $min, ".";
  my $sec = substr $min, $secdot+1, length($min);
  $min = substr $min, 0, $secdot;
  $sec = "0." . $sec;
  $sec = Math::Libm::ceil($sec * 60.0);  
  
  if ( $sec == 60 ) {
     $sec = 0;
     $min = $min+1;
  }   
  #print "min $min\n";
  #print "sec $sec\n";
  
  my $objdec = "$deg $min $sec";  
  
  # GRAB RA
  # -------
  
  # grab RA
  my $ra = $coords[1];
  $ra = $ra/15.0;
  #print "ra $ra\n";
  
  my $radot = index $ra, ".";
  my $hours = substr $ra, 0, $radot;
  #print "hours $hours\n";
  
  $min = substr $ra, $radot+1, length($ra);
  $min = "0." . $min;
  $min = $min * 60.0;  

  $secdot = index $min, ".";
  $sec = substr $min, $secdot+1, length($min);
  $min = substr $min, 0, $secdot;
  $sec = "0." . $sec;
  $sec = Math::Libm::ceil($sec * 60.0);  
  
  if ( $sec == 60 ) {
     $sec = 0;
     $min = $min+1;
  }   
  #print "min $min\n";
  #print "sec $sec\n";
  
  my $objra = "$hours $min $sec";  


  $star->coords( new Astro::Coords(ra => $objra,
                                   dec => $objdec,
                                   units => 'sex',
                                   type => 'J2000',
                                   name => $self->query_options("object"),
                                   ) );


  # Push the star into the catalog
  $catalog->pushstar( $star );
  
  # return
  return $catalog;

}

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
