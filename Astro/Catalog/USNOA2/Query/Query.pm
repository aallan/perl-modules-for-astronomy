package Astro::Catalog::USNOA2::Query;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::Catalog::USNOA2::Query

#  Purposes:
#    Perl wrapper for the USNO-A2.0 Catalog

#  Language:
#    Perl module

#  Description:
#    This module wraps the USNO-A2.0 Catalogonline database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.8 2003/07/25 02:01:32 timj Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::USNOA2::Query - A query request to the USNO-A2.0 Catalog

=head1 SYNOPSIS

  $usno = new Astro::Catalog::USNOA2::Query( Coords    => new Astro::Coords(),
                                             Radius    => $radius,
                                             Bright    => $magbright,
                                             Faint     => $magfaint,
                                             Sort      => $sort_type,
                                             Number    => $number_out );
      
  my $catalog = $usno->querydb();

=head1 DESCRIPTION

Stores information about an prospective USNO-A2.0 query and allows the query to
be made, returning an Astro::Catalog::USNOA2::Catalog object.

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use base qw/ Astro::Catalog::BaseQuery /;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.8 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: Query.pm,v 1.8 2003/07/25 02:01:32 timj Exp $

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
  return "skycat/servers/usnoa_res?";
}

=item B<_get_allowed_options>

Returns a hash with keys, being the internal options supported
by this subclass, and values being the key name actually required
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
	  ra => 'ra',
	  dec => 'dec',
	  object => 'object',
	  radmax => 'radmax',
	  magbright => 'magbright',
	  magfaint => 'magfaint',
	  sort => 'sort',
	  nout => 'nout',
	  format => 'format',
	 );
}

=item B<_set_default_options>

Set the default query state.

=cut

sub _set_default_options {
  my $self = shift;

  my %defaults = (
		  ra => undef,
		  dec => undef,
		  object => undef,

		  radmax => 5,
		  magbright => 0,
		  magfaint => 100,
		  format => 1,
		  sort => 'ra',
		  nout => 2000,
		 );

  $self->_set_query_options( %defaults );
  return;
}

=item B<_parse_query>

Private function used to parse the results returned in an USNO-A2.0 query.
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
            
           # hack for first line, remove </b>
           if ( lc($buffer[$counter]) =~ "</b>" ) {
              $buffer[$counter] = substr( $buffer[$counter], 5);
           }
           
           # remove leading spaces
           $buffer[$counter] =~ s/^\s+//; 
                      
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
              my $id = $separated[1];
              $star->id( $id );
               
              # debugging
              #my $num = $counter - $line -2;
              #print "# ID $id star $num\n";      
              
              # RA
              my $objra = "$separated[2] $separated[3] $separated[4]";
              $star->ra( $objra );
              
              # Dec
              my $objdec = "$separated[5] $separated[6] $separated[7]";
              $star->dec( $objdec );
              
              # R Magnitude
              my %r_mag = ( R => $separated[8] );
              $star->magnitudes( \%r_mag );
              
              # B Magnitude
              my %b_mag = ( B => $separated[9] );
              $star->magnitudes( \%b_mag );
              
              # Quality
              my $quality = $separated[10];
              $star->quality( $quality );
              
              # Field
              my $field = $separated[11];
              $star->field( $field );
              
              # GSC
              my $gsc = $separated[12];
              if ( $gsc eq "+" ) {
                 $star->gsc( "TRUE" );
              } else {
                 $star->gsc( "FALSE" );
              }
              
              # Distance
              my $distance = $separated[13];
              $star->distance( $distance );
              
              # Position Angle
              my $pos_angle = $separated[14];
              $star->posangle( $pos_angle );

           }
             
           # Push the star into the catalog
           # ------------------------------
           $catalog->pushstar( $star );
           
           
           # Calculate error
           # ---------------
           
           # Error are calculated as follows
           #
           #   Delta.R = 0.15*sqrt( 1 + 10**(0.8*(R-19)) )
           #   Delta.B = 0.15*sqrt( 1 + 10**(0.8*(B-19)) )
           #
           
           my ( $power, $delta_r, $delta_b );
                      
           # delta.R
           $power = 0.8*( $star->get_magnitude( 'R' ) - 19.0 );
           $delta_r = 0.15* (( 1.0 + ( 10.0 ** $power ) ) ** (1.0/2.0));
           
           # delta.B
           $power = 0.8*( $star->get_magnitude( 'B' ) - 19.0 );
           $delta_b = 0.15* (( 1.0 + ( 10.0 ** $power ) ) ** (1.0/2.0));
           
           # mag errors
           my %mag_errors = ( B => $delta_b,  R => $delta_r );
           $star->magerr( \%mag_errors );
           
           # calcuate B-R colour and error
           # -----------------------------
           
           # Error is calculated as follows
           # 
           #   Delta.(B-R) = sqrt( Delta.R**2 + Delta.B**2 )
           #
           
           my $b_minus_r = $star->get_magnitude( 'B' ) - 
                           $star->get_magnitude( 'R' );
                           
           my %colours = ( 'B-R' => $b_minus_r );
           $star->colours( \%colours );
           
           # delta.(B-R)
           my $delta_bmr = ( ( $delta_r ** 2.0 ) + ( $delta_b ** 2.0 ) ) ** (1.0/2.0);
           
           # col errors
           my %col_errors = ( 'B-R' => $delta_bmr );
           $star->colerr( \%col_errors );
           
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

=head1 SEE ALSO

L<Astro::Catalog::BaseQuery>, L<Astro::Catalog::GSC::Query>

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
