package Astro::Catalog::SuperCOSMOS::Query;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Catalog::SuperCOSMOS::Query

#  Purposes:
#    Perl wrapper for the SuperCOSMOS Catalog

#  Language:
#    Perl module

#  Description:
#    This module wraps the SuperCOSMOS Catalog online database using
#    the Astro::Aladin module.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.2 2003/02/24 22:31:09 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::SuperCOSMOS::Query - Query the SuperCOSMOS Catalog

=head1 SYNOPSIS

  $supercos = new Astro::Catalog::SuperCOSMOS::Query( RA        => $ra,
                                                      Dec       => $dec,
                                                      Band      => $waveband,
                                                      Radius    => $radius,
                                                    );
      
  my $catalog = $supercos->querydb();

=head1 DESCRIPTION

Stores information about an prospective SuperCOSMOS Sky Survey query and 
allows the query to be made, returning an Astro::Catalog object.

Since the module uses the Astro::Aladin module to drive the CDS Aladin
application to retrieve the catalogue, its doubtful that it will work
through a proxy (unlike the USNO-A2 and GSC modules). 

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Net::Domain qw(hostname hostdomain);
use File::Spec;

use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

# aladin stuff
use Astro::Aladin;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.2 2003/02/24 22:31:09 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $supercos = new Astro::Catalog::SuperCOSMOS::Query( RA        => $ra,
                                                      Dec       => $dec,
                                                      Band      => $waveband,
                                                      Radius    => $radius
                                                    );

returns a reference to an SuperCOSMOS query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RA        => undef,
                      DEC       => undef,
                      RADIUS    => undef,
                      BAND      => undef,
                      BUFFER    => [] }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<querydb>

Returns an Astro::Catalog object from a SuperCOSMOS query.

   $catalog = $supercos->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual SuperCOSMOS query
  my $status = $self->_make_query();

  # check for failed query
  return undef unless defined $self->{BUFFER};

  # parse the returned page
  my $catalog = $self->_parse_query();
  
  # parse catalog and return an Astro::Catalog object
  return $catalog;
  

}


# O T H E R   M E T H O D S ------------------------------------------------


=item B<RA>

Return (or set) the current target R.A. defined for the SuperCOSMOS query

   $ra = $supercos->ra();
   $supercos->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) { 
     $self->{RA} = shift;
  }
  
  return $self->{RA};
}

=item B<Dec>

Return (or set) the current target Declination defined for the SuperCOSMOS 
query

   $dec = $supercos->dec();
   $supercos->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec { 
  my $self = shift;

  # SETTING DEC
  if (@_) { 
    $self->{DEC} = shift;
  }
  
  return $self->{DEC};
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
    $self->{RADIUS} = shift;
  }
  
  return $self->{RADIUS};

}

=item B<Band>

Set (or query) the Primary survey/waveband, options UKST Blue: -90 < Dec < +2.5, UKST Red: -90 < Dec < +2.5, UKST Infrared: -90 < Dec < +2.5, ESO Red: -90 < Dec < -17.5, POSS I Red: -20.5 < Dec < +2.5.

   $band = $query->band();
   $query->band( "UKST IR" );

valid options are "UKST Blue", "UKST Red", "UKST Infrared", "ESO Red" and 
"POSS-I Red".

=cut

sub band {
  my $self = shift;
  
  if (@_) {
    $self->{BAND} = shift;
  } 

  return $self->{BAND};  
  
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

  # CONFIFGURE FROM DEFAULTS
  # ------------------------
  
  $self->{RA}     = undef;
  $self->{DEC}    = undef;
  $self->{BAND}   = "UKST Blue";
  $self->{RADIUS} = 10;


  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Radius Band / ) {
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

Private function used to make an SuperCOSMOS query. Should not be called
directly, since it does not parse the results. Instead use the querydb() 
assessor method.

=cut

sub _make_query {
   my $self = shift;

   # clean out the buffer
   $self->{BUFFER} = [""];
   
   # generate a (hopefully) unique ID
   my $unique_id = $ENV{"USER"} . "@" . hostname() . "." . hostdomain();

   my $ra_string = $self->{RA};
   $ra_string =~ s/\s+//g;
   
   my $dec_string = $self->{DEC};
   $dec_string =~ s/^\s//;
   $dec_string = "+" . $dec_string unless $dec_string =~ "-";
   $dec_string =~ s/\s+//g; 

   my $filename = $unique_id . "_" . $ra_string . $dec_string . ".cat";
               
   my $file = File::Spec->catfile( File::Spec->tmpdir() , $filename );
   
   # make query
   
   my $aladin = new Astro::Aladin();
   my $status = $aladin->supercos_catalog( RA     => $self->{RA},
                                           Dec    => $self->{DEC},
                                           Radius => $self->{RADIUS},
                                           Band   => $self->{BAND},
                                           File   => $file );
   
   # read file back in again (booh!)
   unless ( open( TMPCAT, $status ) ) {
       croak("SuperCOSMOS - Can't find catalogue $status");
   } 
   
   # read from file   
   @{$self->{BUFFER}} = <TMPCAT>;
   chomp( @{$self->{BUFFER}} );
   close(TMPCAT); 
   
   # read it in, now lets clean up
   #unlink( $status);     
   
   return $status;                                      
   
}

=item B<_parse_query>

Private function used to parse the results returned in an SuperCOSMOS query.
Should not be called directly. Instead use the querydb() assessor method to 
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;
  
  # get a local copy of the current BUFFER
  my @buffer = @{$self->{BUFFER}};

  # create an Astro::Catalog object to hold the search results
  my $catalog = new Astro::Catalog();
  $catalog->fieldcentre( RA => $self->{RA}, Dec => $self->{Dec}, 
                         Radius => $self->{RADIUS} );

  # create a temporary object to hold stars
  my $star;

  # loop round the returned buffer and stuff the contents into star 
  # objects, skip the first two lines, they're just headers 
  foreach my $i ( 2 ... $#buffer ) {
    
     # break the line down into bits
     my @line = split( /\t+/,$buffer[$i]);
              
     # create a temporary place holder object
     $star = new Astro::Catalog::Star(); 
       
     # ID
     $star->id( $line[2] );
     
     # RA & Dec - Need to convert to sextuplets
     my $ra_deg = $line[0];
     $ra_deg = $ra_deg/15.0;  # should this be cos(delta) here?
     
     #print "1: $ra_deg\n";
     
     my $period = index( $ra_deg, ".");
     my $length = length( $ra_deg );
     my $ra_min = substr( $ra_deg, -($length-$period-1));
     $ra_min = "0." . $ra_min;
     $ra_min = $ra_min*60.0;

     #print "2: $ra_deg $ra_min\n";
     
     $ra_deg = substr( $ra_deg, 0, $period);
     $period = index( $ra_min, ".");
     $length = length( $ra_min );

     #print "3: $ra_deg $ra_min\n";
     
     my $ra_sec = substr( $ra_min, -($length-$period-1));
     $ra_sec = "0." . $ra_sec;
     $ra_sec = $ra_sec*60.0;
     $ra_min = substr( $ra_min, 0, $period);

     #print "4: $ra_deg $ra_min $ra_sec\n";
     
     my $dec_deg = $line[1];

     #print "1: $dec_deg\n";
     
     my $sign = "pos";
     if ( $dec_deg =~ "-" ) {
        $dec_deg =~ s/-//;
        $sign = "neg";
     }   

     #print "2: $dec_deg\n";
     
     my $period = index( $dec_deg, ".");
     my $length = length( $dec_deg );
     my $dec_min = substr( $dec_deg, -($length-$period-1));
     $dec_min = "0." . $dec_min;
     $dec_min = $dec_min*60.0;

     #print "3: $dec_deg $dec_min\n";
     
     $dec_deg = substr( $dec_deg, 0, $period);
     $period = index( $dec_min, ".");
     $length = length( $dec_min );

     #print "4: $dec_deg $dec_min\n";
     
     my $dec_sec = substr( $dec_min, -($length-$period-1));
     $dec_sec = "0." . $dec_sec;
     $dec_sec = $dec_sec*60.0;
     $dec_min = substr( $dec_min, 0, $period);     

     #print "5: $dec_deg $dec_min $dec_sec\n";
     
     if( $sign == "neg" ) {
        $dec_deg = "-" . $dec_deg;
     }
     
     #print "6: $dec_deg $dec_min $dec_sec\n\n";
     
     
     $star->ra( "$ra_deg $ra_min $ra_sec" );
     $star->dec( "$dec_deg $dec_min $dec_sec" );
     
     # Magnitudes
     $star->magnitudes( {Bj => $line[10]} );
     $star->magnitudes( {R2 => $line[12]} );
     $star->magnitudes( {I  => $line[13]} );
     $star->magnitudes( {R1 => $line[11]} );
     
     # Field
     $star->field( $line[22] );
   
     # Quality flag
     if( $line[18] == 2.0 ) {
        $star->quality( 0 );
     } else {
        $star->quality( 1 );
     }
     
     # calulate the errors
     $star->magerr( {Bj => 0.04} ) if( $star->get_magnitude( "Bj" ) > 15.0 );
     $star->magerr( {Bj => 0.05} ) if( $star->get_magnitude( "Bj" ) > 17.0 );
     $star->magerr( {Bj => 0.06} ) if( $star->get_magnitude( "Bj" ) > 19.0 );
     $star->magerr( {Bj => 0.07} ) if( $star->get_magnitude( "Bj" ) > 20.0 );
     $star->magerr( {Bj => 0.12} ) if( $star->get_magnitude( "Bj" ) > 21.0 );
     $star->magerr( {Bj => 0.08} ) if( $star->get_magnitude( "Bj" ) > 22.0 );

     $star->magerr( {R1 => 0.06} ) if( $star->get_magnitude( "R1" ) > 11.0 );
     $star->magerr( {R1 => 0.03} ) if( $star->get_magnitude( "R1" ) > 12.0 );
     $star->magerr( {R1 => 0.09} ) if( $star->get_magnitude( "R1" ) > 13.0 );
     $star->magerr( {R1 => 0.10} ) if( $star->get_magnitude( "R1" ) > 14.0 );
     $star->magerr( {R1 => 0.12} ) if( $star->get_magnitude( "R1" ) > 18.0 );
     $star->magerr( {R1 => 0.18} ) if( $star->get_magnitude( "R1" ) > 19.0 );
         
     $star->magerr( {R2 => 0.02} ) if( $star->get_magnitude( "R2" ) > 12.0 );
     $star->magerr( {R2 => 0.03} ) if( $star->get_magnitude( "R2" ) > 13.0 );
     $star->magerr( {R2 => 0.04} ) if( $star->get_magnitude( "R2" ) > 15.0 );
     $star->magerr( {R2 => 0.05} ) if( $star->get_magnitude( "R2" ) > 17.0 );
     $star->magerr( {R2 => 0.06} ) if( $star->get_magnitude( "R2" ) > 18.0 );
     $star->magerr( {R2 => 0.11} ) if( $star->get_magnitude( "R2" ) > 19.0 );     
     $star->magerr( {R2 => 0.16} ) if( $star->get_magnitude( "R2" ) > 20.0 );     

     $star->magerr( {I => 0.05} ) if( $star->get_magnitude( "I" ) > 15.0 );
     $star->magerr( {I => 0.06} ) if( $star->get_magnitude( "I" ) > 16.0 );
     $star->magerr( {I => 0.09} ) if( $star->get_magnitude( "I" ) > 17.0 );
     $star->magerr( {I => 0.16} ) if( $star->get_magnitude( "I" ) > 18.0 );

     # calculate colours UKST Bj - UKST R, UKST Bj - UKST I
     $star->colours( {"Bj-R2" => (   $star->get_magnitude( "Bj" )
                                  - $star->get_magnitude( "R2" ) )} );
     $star->colours( {"Bj-I" => (   $star->get_magnitude( "Bj" )
                                 - $star->get_magnitude( "I" ) )} );
                                        
     # calculate colour errors
     my $delta_bjmr = ( ( $star->get_errors( "Bj" ) )**2.0 +
                        ( $star->get_errors( "R2" ) )**2.0     )** (1/2);
     
     my $delta_bjmi = ( ( $star->get_errors( "Bj" ) )**2.0 +
                        ( $star->get_errors( "I" ) )**2.0     )** (1/2);
     
     $star->colerr( {"Bj-R2" => $delta_bjmr} );
     $star->colerr( {"Bj-I"  => $delta_bjmi} );
      
     # push star onto catalog                               
     $catalog->pushstar( $star );
                                  
                                        
  }

  return $catalog;
}


=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last SuperCOSMOS query made using querydb().

=cut

sub _dump_raw {
   my $self = shift;
   return @{$self->{BUFFER}};
}

=back

=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2003 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

;
