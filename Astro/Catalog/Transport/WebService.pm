package Astro::Catalog::Transport::WebService;

=head1 NAME

Astro::Catalog::Transport::WebService - A base class for WebService querys

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::Transport::WebService /;

=head1 DESCRIPTION

This class forms a base class for all the WebService based query classes 
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::Query::Sesame>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::BaseQuery /;
use vars qw/ $VERSION /;

use SOAP::Lite;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: WebService.pm,v 1.1 2003/07/29 04:11:57 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $q = new Astro::Catalog::Transport::WebService( 
                                            Coords    => new Astro::Coords(),
				            Radius    => $radius,
				            Bright    => $magbright,
				            Faint     => $magfaint,
				            Sort      => $sort_type,
				            Number    => $number_out );

returns a reference to an query object. Must only called from
sub-classed constructors.

RA and Dec are also allowed but are deprecated (since with only
RA/Dec the coordinates must always be supplied as J2000 space-separated
sexagesimal format).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
		      COORDS    => undef,
                      URN       => undef,
                      ENDPOINT  => undef,
                      SERVICE   => undef,
                      QUERY     => undef,
                      BUFFER    => undef }, $class;

  # Configure the object [even if there are no args]
  $block->configure( @_ );

  return $block;

}

=over 4

=item B<querydb>

Returns an Astro::Catalog object resulting from the specific query.

   $catalog = $q->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual query
  $self->_make_query();

  # check for failed connect
  return undef unless defined $self->{BUFFER};

  # return catalog
  return $self->_parse_query();

}

=item B<proxy>

Return (or set) the current proxy for the catalog request.

   $usno->proxy( 'http://wwwcache.ex.ac.uk:8080/' );
   $proxy_url = $usno->proxy();

=cut

sub proxy {
   my $self = shift;
   
   # SOAP::Lite respects the HTTP_proxy environment variable

   if (@_) {
      my $proxy_url = shift;
      $ENV{HTTP_proxy} = $proxy_url;
      $ENV{HTTP_PROXY} = $proxy_url;
   }

   # return the current proxy
   return $ENV{HTTP_proxy};

}

=item B<urn>

Return the current remote urn for the query 

   $host = $q->urn();

Can also be used to set the urn.

=cut

sub urn {
  my $self = shift;

  # SETTING URL
  if (@_) { 

    # set the url option
    my $urn = shift;
    $self->{URN} = $urn;
  }

  return $self->{URN};
  
}

=item B<endpoint>

Return the current endpoint for the query 

   $host = $q->endpoint();
   $q->endpoint( 'http://www.blah.org:8080' ););

Can also be used to set the endpoint. If the endpoint is a wsdl file
the SOAP::Lite object will automagically be configured to use the
correct URN, e.g.

   $q->endpoint( 'http://cdsws.u-strasbg.fr/axis/Sesame.jws?wsdl' );

=cut

sub endpoint {
  my $self = shift;

  # SETTING ENDPOINT
  if (@_) { 

    # set the url option
    my $endpoint = shift;
    
    if( $endpoint =~ /wsdl$/ ) {
      $self->{SERVICE} = 1;
    }  
    $self->{ENDPOINT} = $endpoint;
    
  }

  return $self->{ENDPOINT};
  
}

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $dss->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;
  $self->SUPER::configure( @_ );
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_urn>

The default URN for the hostname. Must be specified in a sub-class.

  $host = $q->_default_urn();

=cut

sub _default_urn {
  croak "default URN must be specified in subclass\n";
}

=item B<_default_endpoint>

The default endpoint. Must be specified in a sub-class.

  $host = $q->_default_endpoint();

=cut

sub _default_endpoint {
  croak "default endpoint must be specified in subclass\n";
}


=item B<_make_query>

Private function used to make an query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor 
method.

=cut

sub _make_query {
   my $self = shift;

   # grab the soaplite object
   my $soap = $self->soaplite();

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $endpoint = $self->endpoint();

   # loop round all the options keys and build the query
   my %allow = $self->_get_allowed_options;
   foreach my $key ( keys %allow ) {
     # Need to translate them...
     my $cvtmethod = "_from_" . $key;
     my ($outkey, $outvalue);
     if ($self->can($cvtmethod)) {
       ($outkey, $outvalue) = $self->$cvtmethod();
     } else {
       # Currently assume everything is one to one
       warnings::warnif("Unable to find translation for key $key. Assuming 1 to 1 mapping");
       $outkey = $key;
       $outvalue = $self->query_options($key);
     }

     $options .= "&$outkey=". $outvalue
       if defined $outvalue;
   }

   # build final query URL
   $URL = $URL . $options;

   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   # declare file name
   my $file_name;

   if ( ${$reply}{"_rc"} eq 200 ) {
      # stuff the page contents into the buffer
      $self->{BUFFER} = ${$reply}{"_content"};
   } else {
      croak("Error ${$reply}{_rc}: Failed to establish network connection");
   }
}


=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
