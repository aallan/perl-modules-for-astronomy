package Astro::Catalog::GSC::Query;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Catalog::GSC::Query

#  Purposes:
#    Perl wrapper for the GSC Catalog

#  Language:
#    Perl module

#  Description:
#    This module wraps the GSC Catalogonline database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.1 2002/01/14 10:05:33 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::GSC::Query - A query request to the GSC Catalog

=head1 SYNOPSIS

  $usno = new Astro::Catalog::GSC::Query( RA        => $ra,
                                             Dec       => $dec,
                                             Radius    => $radius,
                                             Bright    => $magbright,
                                             Faint     => $magfaint,
                                             Sort      => $sort_type,
                                             Nout      => $number_out );
      
  my $catalog = $usno->querydb();

=head1 DESCRIPTION

Stores information about an prospective GSC query and allows the query to
be made, returning an Astro::Catalog::GSC::Catalog object.

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Math::Libm qw(:all);
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.1 2002/01/14 10:05:33 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $usno = new Astro::Catalog::GSC::Query( RA        => $ra,
                                             Dec       => $dec,
                                             Radius    => $radius,
                                             Bright    => $magbright,
                                             Faint     => $magfaint,
                                             Sort      => $sort_type,
                                             Nout      => $number_out );
      

returns a reference to an GSC query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      URL       => undef,
                      QUERY     => undef,
                      USERAGENT => undef,
                      BUFFER    => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<querydb>

Returns an Astro::Catalog::GSC::Catalog object from a GSC query.

   $catalog = $usno->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual USNO query
  $self->_make_query();

  # check for failed connect
  return undef unless defined $self->{BUFFER};

  # return catalog
  return $self->_parse_query();

}

=item B<proxy>

Return (or set) the current proxy for the GSC request.

   $usno->proxy( 'http://wwwcache.ex.ac.uk:8080/' );
   $proxy_url = $usno->proxy();

=cut

sub proxy {
   my $self = shift;

   # grab local reference to user agent
   my $ua = $self->{USERAGENT};

   if (@_) {
      my $proxy_url = shift;
      $ua->proxy('http', $proxy_url );
   }

   # return the current proxy
   return $ua->proxy('http');

}

=item B<timeout>

Return (or set) the current timeout in seconds for the GSC request.

   $usno->timeout( 30 );
   $proxy_timeout = $usno->timeout();

=cut

sub timeout {
   my $self = shift;

   # grab local reference to user agent
   my $ua = $self->{USERAGENT};

   if (@_) {
      my $time = shift;
      $ua->timeout( $time );
   }

   # return the current timeout
   return $ua->timeout();

}

=item B<url>

Return (or set) the current base URL for the GSC query.

   $url = $usno->url();
   $usno->url( "archive.eso.org" );

if not defined the default URL is archive.eso.org

=cut

sub url {
  my $self = shift;

  # SETTING URL
  if (@_) { 

    # set the url option 
    my $base_url = shift; 
    $self->{URL} = $base_url;
    if( defined $base_url ) {
       $self->{QUERY} = "http://$base_url/skycat/servers/usnoa_res?";
    }
  }

  # RETURNING URL
  return $self->{URL};
}

=item B<agent>

Returns the user agent tag sent by the module to the GSC server.

   $agent_tag = $usno->agent();

=cut

sub agent {
  my $self = shift;
  return $self->{USERAGENT}->agent();
}

# O T H E R   M E T H O D S ------------------------------------------------


=item B<RA>

Return (or set) the current target R.A. defined for the GSC query

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

Return (or set) the current target Declination defined for the GSC query

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

Instead of querying GSC by R.A. and Dec., you may also query it by object
name. Return (or set) the current target object defined for the GSC query,
will query SIMBAD for object name resolution.

   $ident = $usno->target();
   $usno->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
GSC using this identifier rather than any currently set co-ordinates.

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

Set (or query) the faint magnitude limit for inclusion on the GSC results

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

Set (or query) the bright magnitude limit for inclusion on the GSC results

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

=item B<Nout>

The number of objects to return, defaults to 20,000 which should hopefully
be sufficent to return all objects of interest. This value should be increased
if a (very) large sample radius is requested.

   $num = $query->nout();
   $query->nout( 100 );

=cut

sub nout {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"nout"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"nout"};
}

=item B<Nout>

Whether to return multiple identifications

   $multi = $query->multi();
   $query->multi( 'no' );

valid responses are 'yes' and 'no', the default is yes.

=cut

sub multi {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"multi"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"multi"};
}

# C O N F I G U R E -------------------------------------------------------

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

  # define the default base URL
  $self->{URL} = "archive.eso.org";
  
  # define the query URLs
  my $default_url = $self->{URL};
  $self->{QUERY} = "http://$default_url/gsc/gsc?";
   
  # Setup the LWP::UserAgent
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  $self->{USERAGENT} = new LWP::UserAgent( timeout => 30 ); 
  $self->{USERAGENT}->agent("Astro::Catalog::GSC/$VERSION ($HOST.$DOMAIN)");

  # Grab Proxy details from local environment
  $self->{USERAGENT}->env_proxy();  
  
  # hidden options
  ${$self->{OPTIONS}}{"catalogue"}   = "gsc";
  ${$self->{OPTIONS}}{"epoch"}       = "2000.0";
  ${$self->{OPTIONS}}{"chart"}       = "1";
  
  # configure the default options
  ${$self->{OPTIONS}}{"ra"}          = undef;
  ${$self->{OPTIONS}}{"dec"}         = undef;
  ${$self->{OPTIONS}}{"object"}      = undef;
  
  ${$self->{OPTIONS}}{"radmax"}      = 5;
  ${$self->{OPTIONS}}{"magbright"}   = 0;
  ${$self->{OPTIONS}}{"magfaint"}    = 100;
  ${$self->{OPTIONS}}{"format"}      = 1;
  ${$self->{OPTIONS}}{"sort"}        = "ra";
  ${$self->{OPTIONS}}{"nout"}        = "20000";
  ${$self->{OPTIONS}}{"multi"}       = "yes";

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Target Radius Bright Faint Sort Number Multi
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

=item B<_make_query>

Private function used to make an GSC query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor method.

=cut

sub _make_query {
   my $self = shift;

   # grab the user agent
   my $ua = $self->{USERAGENT};

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $URL = $self->{QUERY};
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

=item B<_parse_query>

Private function used to parse the results returned in an GSC query.
Should not be called directly. Instead use the querydb() assessor method to 
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;
  
  # get a local copy of the current BUFFER
  my @buffer = split( /\n/,$self->{BUFFER});
  chomp @buffer;

  # create an Astro::Catalog object to hold the search results
  my $catalog = new Astro::Catalog();

  # create a temporary object to hold stars
  my $star;

  my ( $line, $counter );
  my ( $ra, $dec, $radius );
  # loop round the returned buffer and stuff the contents into star objects
  foreach $line ( 0 ... $#buffer ) {
      
     # Parse field centre
     # ------------------ 
      
     # RA
     if( lc($buffer[$line]) =~ "<td>ra:" ) {
        $_ = lc($buffer[$line]);
        ( $ra ) = /^\s*<td>ra:\s+(.*)<\/td>/;
        $catalog->fieldcentre( RA => $ra ); 
     }
     
     # Dec
     if( lc($buffer[$line]) =~ "<td>dec:" ) {
        $_ = lc($buffer[$line]);
        ( $dec ) = /^\s+<td>dec:\s+(.*)<\/td>/;
        $catalog->fieldcentre( Dec => $dec ); 
     }
     
     # Radius
     if( lc($buffer[$line]) =~ "search radius:" ) {
        $_ = lc($buffer[$line+1]);
        ( $radius ) = />\s+(.*)\s\w/;
        $catalog->fieldcentre( Radius => $radius ); 
     }
     
     # Parse list of objects
     # ---------------------
     
     if( lc($buffer[$line]) =~ "<pre>" ) {
     
        # reached the catalog block, loop through until </pre> reached
        $counter = $line+2;
        until ( lc($buffer[$counter+1]) =~ "</pre>" ) {
                      
           # split each line
           my @separated = split( /\s+/, $buffer[$counter] );
           
           # debugging (leave in)
           #foreach my $thing ( 0 .. $#separated ) {
           #   print "   $thing # $separated[$thing] #\n";
           #}
           
           # check that there is something on the line
           if ( defined $separated[0] ) {
              
              # create a temporary place holder object
              $star = new Astro::Catalog::Star(); 

              # ID
              my $id = $separated[2];
              $star->id( $id );
               
              # debugging
              #my $num = $counter - $line -2;
              #print "# ID $id star $num\n";      
              
              # RA
              my $objra = "$separated[3] $separated[4] $separated[5]";
              $star->ra( $objra );
              
              # Dec
              my $objdec = "$separated[6] $separated[7] $separated[8]";
              $star->dec( $objdec );
              
              # B Magnitude
              my %b_mag = ( B => $separated[10] );
              $star->magnitudes( \%b_mag );
              
              # B mag error
              my %mag_errors = ( B => $separated[11] );
              $star->magerr( \%mag_errors );
              
              # Quality
              my $quality = $separated[11];
              $star->quality( $quality );
              
              # Field
              my $field = $separated[12];
              $star->field( $field );
              
              # GSC, obvious!
              $star->gsc( "TRUE" );
              
              # Distance
              my $distance = $separated[16];
              $star->distance( $distance );
              
              # Position Angle
              my $pos_angle = $separated[17];
              $star->posangle( $pos_angle );

           }
             
           # Push the star into the catalog
           # ------------------------------
           $catalog->pushstar( $star );
           
           # increment counter
           # -----------------
           $counter = $counter + 1;
        }
        
        # reset $line to correct place
        $line = $counter;
     }
     
  }

  return $catalog;
}


=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last GSC query made using querydb().

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

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
