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
#     $Id: Query.pm,v 1.3 2003/07/25 00:45:43 timj Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::GSC::Query - A query request to the GSC Catalog

=head1 SYNOPSIS

  $gsc = new Astro::Catalog::GSC::Query( RA        => $ra,
					 Dec       => $dec,
					 Radius    => $radius,
					 Bright    => $magbright,
					 Faint     => $magfaint,
					 Sort      => $sort_type,
					 Nout      => $number_out );
      
  my $catalog = $gsc->querydb();

=head1 DESCRIPTION

Stores information about an prospective GSC query and allows the query to
be made, returning an Astro::Catalog::GSC::Catalog object.

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::BaseQuery /;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: Query.pm,v 1.3 2003/07/25 00:45:43 timj Exp $

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

=cut

sub _default_remote_host {
  return "archive.eso.org";
}

=item B<_default_url_path>

=cut

sub _default_url_path {
  return "gsc/gsc?";
}

=item B<_set_default_options>

=cut

sub _set_default_options {
  my $self = shift;

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
