package Astro::ADS::Query;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::SIMBAD::Query

#  Purposes:
#    Perl wrapper for the SIMBAD database

#  Language:
#    Perl module

#  Description:
#    This module wraps the SIMBAD online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.1 2001/11/27 18:09:42 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::SIMBAD::Query - Object definining an prospective SIMBAD query.

=head1 SYNOPSIS

  $query = new Astro::SIMBAD::Query( );

  my $results = $query->querydb();

=head1 DESCRIPTION

Stores information about an prospective SIMBAD query and allows the query to
be made, returning an Astro::SIMBAD::Result object. 

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Carp;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.1 2001/11/27 18:09:42 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::SIMBAD::Query(  );

returns a reference to an SIMBAD query object.

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

Returns an Astro::SIMBAD::Result object for an inital SIMBAD query

   $results = $query->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual SIMBAD query
  $self->_make_query();

  # check for failed connect
  return undef unless defined $self->{BUFFER};

  # return an Astro::SIMBAD::Result object
  return $self->_parse_query();

}

=item B<proxy>

Return (or set) the current proxy for the SIMBAD request.

   $query->proxy( 'http://wwwcache.ex.ac.uk:8080/' );
   $proxy_url = $query->proxy();

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

Return (or set) the current timeout in seconds for the SIMBAD request.

   $query->timeout( 30 );
   $proxy_timeout = $query->timeout();

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

# O T H E R   M E T H O D S ------------------------------------------------

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $query->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # CONFIGURE DEFAULTS
  # ------------------

  # define the default base URLs
  $self->{URL} = "";
  $self->{QUERY} = "";

  # Setup the LWP::UserAgent
  $self->{USERAGENT} = new LWP::UserAgent( timeout => 30 ); 

  # Grab Proxy details from local environment
  $self->{USERAGENT}->env_proxy();

  # configure the default options


  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw /  / ) {
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

Private function used to make an SIMBAD query. Should not be called directly,
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
      $options = $options . "&$key=${$self->{OPTIONS}}{$key}";
   }

   # build final query URL
   $URL = $URL . $options;

   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   if ( ${$reply}{"_rc"} eq 200 ) {
      # stuff the page contents into the buffer
      $self->{BUFFER} = ${$reply}{"_content"};
   } else {
      $self->{BUFFER} = undef;
      croak("Error ${$reply}{_rc}: Failed to establish network connection");
   }
}

=item B<_parse_query>

Private function used to parse the results returned in an SIMBAD query. Should 
not be called directly. Instead use the querydb() assessor method to make and
parse the results.

=cut

sub _parse_query {
  my $self = shift;

  # get a local copy of the current BUFFER
  my @buffer = split( /\n/,$self->{BUFFER});
  chomp @buffer;

  # create an Astro::ADS::Result object to hold the search results
  my $result = new Astro::SIMBAD::Result();

  # create a temporary object to hold papers
  my $object;

  # loop round the returned buffer and stuff the contents into Paper objects
  my ( $line );
  foreach $line ( 0 ... $#buffer ) {

    
   }

   # return an Astro::SIMBAD::Result object, or undef if no abstracts returned
   return $result;

}

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last SIMBAD query made using querydb().

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


# D A T A   B L O C K  ----------------------------------------------------

__DATA__
?       Object of unknown nature
Rad     Radio-source
mR      metric Radio-source
cm      centimetric Radio-source
mm      millimetric Radio-source
Mas     Maser
IR      Infra-Red source
IR1     IR source at lambda > 10 microns
IR0     IR source at lambda < 10 microns
red     Very red source
blu     Blue object
UV      UV-emission source
X       X-ray source
gam     gamma-ray source
gB      gamma-ray Burster
grv     Gravitational Source
Lev     (Micro)Lensing Event
mul     Composite object
reg     Region defined in the sky
vid     Underdense region of the Universe
SCG     Supercluster of Galaxies
ClG     Cluster of Galaxies
GrG     Group of Galaxies
CGG     Compact Group of Galaxies
PaG     Pair of Galaxies
Gl?     Possible Globular Cluster
Cl*     Cluster of Stars
GlC     Globular Cluster
OpC     Open (galactic) Cluster
As*     Association of Stars
**      Double or multiple star
EB*     Eclipsing binary
Al*     Eclipsing binary of Algol type
bL*     Eclipsing binary of beta Lyr type
WU*     Eclipsing binary of W UMa type
SB*     Spectrocopic binary
CV*     Cataclysmic Variable Star
DQ*     Cataclysmic Var. DQ Her type
AM*     Cataclysmic Var. AM Her type
NL*     Nova-like Star
No*     Nova
DN*     Dwarf Nova
XB*     X-ray Binary
LXB     Low Mass X-ray Binary
HXB     High Mass X-ray Binary
Neb     Nebula of unknown nature
PoC     Part of Cloud
PN?     Possible Planetary Nebula
CGb     Cometary Globule
EmO     Emission Object
HH      Herbig-Haro Object
Cld     Cloud of unknown nature
GNe     Galactic Nebula
BNe     Bright Nebula
DNe     Dark Nebula
RNe     Reflection Nebula
HI      HI (neutral) region
MoC     Molecular Cloud
HVC     High-velocity Cloud
HII     HII (ionized) region
PN      Planetary Nebula
sh      HI shell
SR?     SuperNova Remnant Candidate
SNR     SuperNova Remnant
*       Star
*iC     Star in Cluster
*iN     Star in Nebula
*iA     Star in Association
*i*     Star in double system
V*?     Star suspected of Variability
Pe*     Peculiar Star
HB*     Horizontal Branch Star
Em*     Emission-line Star
Be*     Be Star
WD*     White Dwarf
ZZ*     Variable White Dwarf of ZZ Cet type
C*      Carbon Star
S*      S Star
OH*     Star with envelope of OH/IR type
CH*     Star with envelope of CH type
pr*     Pre-main sequence Star
TT*     T Tau-type Star
WR*     Wolf-Rayet Star
PM*     High proper-motion Star
HV*     High-velocity Star
V*      Variable Star
Ir*     Variable Star of irregular type
Or*     Variable Star in Orion Nebula
V* RI*  Variable Star with rapid variations
Er*     Eruptive variable Star
Fl*     Flare Star
FU*     Variable Star of FU Ori type
RC*     Variable Star of R CrB type
Ro*     Rotationally variable Star
 a2*    Variable Star of alpha2 CVn type
El*     Elliptical variable Star
Psr     Pulsars
BY*     Variable of BY Dra type
RS*     Variable of RS CVn type
Pu*     Pulsating variable Star
Mi*     Variable Star of Mira Cet type
RR*     Variable Star of RR Lyr type
Ce*     Classical Cepheid variable Star
eg sr*  Semi-regular pulsating Star
 dS*    Variable Star of delta Sct type
RV*     Variable Star of RV Tau type
WV*     Variable Star of W Vir type
SN*     SuperNova
Sy*     Symbiotic Star
G       Galaxy
PoG     Part of a Galaxy
GiC     Galaxy in Cluster of Galaxies
GiG     Galaxy in Group of Galaxies
GiP     Galaxy in Pair of Galaxies
HzG     Galaxy with high redshift
ALS     Absorption Line system
LyA     Ly alpha Absorption Line system
DLy     Dumped Ly alpha Absorption Line system
mAL     metallic Absorption Line system
rG      Radio Galaxy
H2G     HII Galaxy
Q?      Possible Quasar
EmG     Emission-line galaxy
SBG     Starburst Galaxy
BCG     Blue compact Galaxy
LeI     Gravitationnaly Lensed Image
LeG     Gravitationnaly Lensed Image of a Galaxy
LeQ     Gravitationnaly Lensed Image of a Quasar
AGN     Active Galaxy Nucleus
LIN     LINER-type Active Galaxy Nucleus
SyG     Seyfert Galaxy
Sy1     Seyfert 1 Galaxy
Sy2     Seyfert 2 Galaxy
Bla     Blazar
BLL     BL Lac - type object
OVV     Optically Violently Variable object
QSO     Quasar  
# declare the lookup hash
  my %lookup;
  
  # build the data table
  my @data = <DATA>;
  chomp @data;
  
  # build the lookup hash
  for my $i ( 0 .. $#data ) {
     my @pair = split( /\s+/, $data[$i] );
     $lookup{$pair[0]} = $pair[1];
  }
