package Astro::Catalog::BaseQuery;

=head1 NAME

Astro::Catalog::BaseQuery - Base class for Astro::Catalog query objects

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::BaseQuery /;


=head1 DESCRIPTION

This class forms a base class for all the query classes provided
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::GSC::Query>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);
use File::Spec;

use Carp;

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;
'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: BaseQuery.pm,v 1.1 2003/07/25 00:45:43 timj Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $q = new Astro::Catalog::BaseQuery( Coords    => new Astro::Coords(),
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



=back

=head2 Accessor Methods

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

=item B<RA>

Return (or set) the current target R.A. defined for the query

   $ra = $usno->ra();
   $usno->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) { 
    
    # grab the new R.A.
    my $ra = shift;
    
    # mutilate it and stuff it and the current $self->{RA} 
    $ra =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"ra"} = $ra;
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $ra = ${$self->{OPTIONS}}{"ra"};
  $ra =~ s/\+/ /g;
  return $ra;
}

=item B<Dec>

Return (or set) the current target Declination defined for the query

   $dec = $usno->dec();
   $usno->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec { 
  my $self = shift;

  # SETTING DEC
  if (@_) { 

    # grab the new Dec
    my $dec = shift;
    
    # mutilate it and stuff it and the current $self->{DEC} 
    $dec =~ s/\+/%2B/g;
    $dec =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"dec"} = $dec;
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $dec = ${$self->{OPTIONS}}{"dec"};
  $dec =~ s/\+/ /g;
  $dec =~ s/%2B/\+/g;
  return $dec;

}


=item B<Target>

Instead of querying by R.A. and Dec., you may also query it
by object name. Return (or set) the current target object defined for
the USNO-A2.0 query, will query SIMBAD for object name resolution.

   $ident = $usno->target();
   $usno->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
using this identifier rather than any currently set co-ordinates.

=cut

sub target {
  my $self = shift;

  # SETTING IDENTIFIER
  if (@_) { 

    # grab the new object name
    my $ident = shift;
    
    # mutilate it and stuff it into ${$self->{OPTIONS}}{object}
    $ident =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"object"} = $ident;
    ${$self->{OPTIONS}}{"ra"} = undef;
    ${$self->{OPTIONS}}{"dec"} = undef;
  }
  
  return ${$self->{OPTIONS}}{"object"};

}

=item B<Radius>

The radius to be searched for objects around the target R.A. and Dec in
arc minutes, the radius defaults to 5 arc minutes.

   $radius = $query->radius();
   $query->radius( 20 );

=cut

sub radius {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"radmax"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"radmax"};

}

=item B<Faint>

Set (or query) the faint magnitude limit for inclusion on the results

   $faint = $query->faint();
   $query->faint( 50 );

=cut

sub faint {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"magfaint"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"magfaint"};

}

=item B<Bright>

Set (or query) the bright magnitude limit for inclusion on the results

   $faint = $query->bright();
   $query->bright( 2 );

=cut

sub bright {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"magbright"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"magbright"};

}

=item B<Sort>

Set or query the order in which the stars are listed in the catalogue

   $sort = $query->sort();
   $query->sort( 'RA' );

valid options are RA, DEC, RMAG, BMAG, DIST (distance to centre of the 
requested field) and POS (the position angle to the centre of the field).  

=cut

sub sort {
  my $self = shift;

  if (@_) {
     
    my $option = shift;
     
    # pick an option
    if( $option eq "RA" ) {
    
       # sort by RA
       ${$self->{OPTIONS}}{"sort"} = "ra";
       
    } elsif ( $option eq "DEC" ) {
    
       # sort by Dec
       ${$self->{OPTIONS}}{"sort"} = "dec";
       
    } elsif ( $option eq "RMAG" ) {
    
       # sort by R magnitude
       ${$self->{OPTIONS}}{"sort"} = "mr";
       
    } elsif ( $option eq "BMAG" ) {
    
       # sort by B magnitude
       ${$self->{OPTIONS}}{"sort"} = "mb";
       
    } elsif ( $option eq "DIST" ) {
    
       # sort by distance from field centre
       ${$self->{OPTIONS}}{"sort"} = "d";
       
    } elsif ( $option eq "POS" ) {
    
       # sort by position angle to field centre
       ${$self->{OPTIONS}}{"sort"} = "pos";
       
    } else {
    
       # in case there are no valid options sort by RA
       ${$self->{OPTIONS}}{"sort"} = "ra";
    }   
  }
  
  # return the sort option
  return ${$self->{OPTIONS}}{"sort"};

}

=item B<Number>

The number of objects to return, defaults to 2000 which should hopefully
be sufficent to return all objects of interest. This value should be increased
if a (very) large sample radius is requested.

   $num = $query->number();
   $query->nout( 100 );

=cut

sub number {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"nout"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"nout"};
}

sub nout {
  my $self = shift;
  warnings::warnif("deprecated","The nout() method is deprecated. Please us number()");
  return $self->number( @_ );
}

=item B<multi>

Whether to return multiple identifications

   $multi = $query->multi();
   $query->multi( 'no' );

valid responses are 'yes' and 'no', the default is yes.

SHOULD ALLOW BOOLEAN

=cut

sub multi {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"multi"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"multi"};
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

  # configure the default options
  $self->_set_default_options();


  # CONFIGURE FROM ARGUMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Target Radius Bright Faint Sort Number
                    URL Timeout Proxy / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

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

=item B<_set_default_options>

Each catalogue requires different default settings for the
URL parameters. They should be specified in a subclass.

=cut

sub _set_default_options {
  croak "default options are specified in subclass\n";
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

Private function used to make an USNO-A2.0 query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor method.

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
   foreach my $key ( keys %{$self->{OPTIONS}} ) {
      $options = $options . 
        "&$key=${$self->{OPTIONS}}{$key}" if defined ${$self->{OPTIONS}}{$key};
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

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last USNO-A2.0 query made using querydb().

=cut

sub _dump_raw {
   my $self = shift;
   
   # split the BUFFER into an array
   my @portable = split( /\n/,$self->{BUFFER});
   chomp @portable;

   return @portable;
}

=item B<_dump_options>

Private function for debugging and other testing purposes. It will return
the current query options as a hash.

=cut

sub _dump_options {
   my $self = shift;

   return %{$self->{OPTIONS}};
}

=back

=end __PRIVATE_METHODS__

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
