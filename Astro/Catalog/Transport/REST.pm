package Astro::Catalog::Transport::REST;

=head1 NAME

Astro::Catalog::Transport::REST - A base class for REST query modules

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::Transport::REST /;


=head1 DESCRIPTION

This class forms a base class for all the REST based query classes provided
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::Query::GSC>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::Query /;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: REST.pm,v 1.3 2003/07/29 20:15:12 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $q = new Astro::Catalog::Transport::REST( Coords    => new Astro::Coords(),
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
                      URL       => undef,
                      QUERY     => undef,
                      USERAGENT => undef,
                      BUFFER    => undef }, $class;

  # Configure the object [even if there are no args]
  $block->configure( @_ );

  return $block;

}

=over 4

=item B<useragent>

The LWP user agent mediating the web transaction.

=cut

sub useragent {
  my $self = shift;
  if (@_) {
     my $ua = shift;
     croak "Must be a LWP::UserAgent"
       unless UNIVERSAL::isa($ua, "LWP::UserAgent");
     $self->{USERAGENT} = $ua;
  }
  return $self->{USERAGENT};
}

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

   # grab local reference to user agent
   my $ua = $self->useragent;

   if (@_) {
      my $proxy_url = shift;
      $ua->proxy('http', $proxy_url );
   }

   # return the current proxy
   return $ua->proxy('http');

}

=item B<timeout>

Return (or set) the current timeout in seconds for the request.

   $usno->timeout( 30 );
   $proxy_timeout = $usno->timeout();

Default is 30 seconds.

=cut

sub timeout {
   my $self = shift;

   # grab local reference to user agent
   my $ua = $self->useragent;

   if (@_) {
      my $time = shift;
      $ua->timeout( $time );
   }

   # return the current timeout
   return $ua->timeout();

}

=item B<query_url>

The URL formed to build up a query. Made up of a root host name
(that can be set using the C<url> method) and a fixed suffix that
specifies the path to the service (CGI or otherwise). This query URL
does not include the arguments to the CGI script (but will include
the question mark if appropriate).

  $query_url = $q->query();
  $q->query_url( 'http://www.blah.org/cgi-bin/xxx.pl?');

Care must be taken when setting this value.

The argument is not validated. There may also need to be a new method
that returns the full URL including arguments.

If no value has been supplied, a default will be returned.

=cut

sub query_url {
  my $self = shift;
  if (@_) {
    $self->{QUERY} = shift;
  }
  if (defined $self->{QUERY}) {
    return $self->{QUERY};
  } else {
    return "http://". $self->url .
      "/" . $self->_default_url_path;
  }

  return $self->{QUERY};
}

=item B<url>

Return the current remote host for the query (the full URL 
can be returned using the C<query_url> method).

   $host = $q->url();

Can also be used to set the root host for the URL (ie the
machine name but no path component)

   $q->url( "archive.eso.org" );

if not defined the default URL is used (specified in the sub class).
This method should really be called C<remote_host>.

Returns the default host name specified by the particular subclass
if a value has not been defined.

=cut

sub url {
  my $self = shift;

  # SETTING URL
  if (@_) { 

    # set the url option
    my $base_url = shift;
    $self->{URL} = $base_url;
    if( defined $base_url ) {
       $self->query_url("http://$base_url/" .
			$self->_default_url_path );
    }
  }

  # RETURNING remote host
  if (defined $self->{URL}) {
    return $self->{URL};
  } else {
    return $self->_default_remote_host();
  }
}

=item B<agent>

Returns the user agent tag sent by the module to the server.

   $agent_tag = $q->agent();

The user agent tag can not be set by this method.

=cut

sub agent {
  my $self = shift;
  return $self->useragent->agent();
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

  # CONFIGURE DEFAULTS
  # ------------------

  # Setup the LWP::UserAgent
  my $ua = new LWP::UserAgent( timeout => 30 );

  $self->useragent( $ua );
  $ua->agent( $self->_default_useragent_id );

  # Grab Proxy details from local environment
  $ua->env_proxy();

  # pass control back to the SUPER class
  $self->SUPER::configure( @_ );

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

The default host name to use to build up the full URL.
Must be specified in a sub-class.

  $host = $q->_default_remote_host();

=cut

sub _default_remote_host {
  croak "default remote host must be specified in subclass\n";
}

=item B<_default_url_path>

The path information after the host in the remote URL.
Must be overridden in a subclass.

=cut

sub _default_url_path {
  croak "default url path information must be subclassed\n";
}

=item B<_default_useragent_id>

Default user agent ID used to declare the agent to the remote server.
Default format is

  __PACKAGE__/$VERSION ($HOST.$DOMAIN)

This can be overridden in a subclass if necessary.

=cut

sub _default_useragent_id {
  my $self = shift;
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  my $package = ref($self);
  my $pack_version;
  {
    # Need a symbolic reference
    no strict 'refs';
    $pack_version = ${ $package."::VERSION" };
  }
  $pack_version = 'UNKNOWN' unless defined $pack_version;
  return "Astro::Catalog::USNOA2/$pack_version ($HOST.$DOMAIN)";
}


=item B<_make_query>

Private function used to make an query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor 
method.

=cut

sub _make_query {
   my $self = shift;

   # grab the user agent
   my $ua = $self->useragent;

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $URL = $self->query_url;
   my $options = "";

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
