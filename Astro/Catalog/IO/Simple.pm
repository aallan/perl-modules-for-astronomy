package Astro::Catalog::IO::Simple;

=head1 NAME

Astro::Catalog::IO::Simple - Simple Input/Output format

=head1 SYNOPSIS

  $catalog = Astro::Catalog::IO::Simple->_read_catalog( \@lines );
  \@lines = Astro::Catalog::IO::Simple->_write_catalog( $catalog );
  Astro::Catalog::IO::Cluster->_default_file();

=head1 DESCRIPTION

Performs simple IO, reading or writing "id_string hh mm ss.s +dd mm ss.s"
formated strings for each Astro::Catalog::Star object in the catalog.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords;

use Data::Dumper;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Simple.pm,v 1.2 2003/07/27 03:56:25 aa Exp $

=begin __PRIVATE_METHODS__

=head1 Private methods

These methods are for internal use only and are called from the 
Astro::Catalog module. Its not expected that anyone would want to
call them from utside that module.

=over 4

=item B<_read_catalog>

Parses a reference to an array containing a simply formated catalogue

  $catalog = Astro::Catalog::IO::Simple->_read_catalog( \@lines );

=cut

sub _read_catalog {
   croak( 'Usage: _read_catalog( \@lines )' ) unless scalar(@_) >= 1;
   my $class = shift;
   my $arg = shift;
   my @lines = @{$arg};
   
   # create am Astro::Catalog object;
   my $catalog = new Astro::Catalog();

   # loop through lines
   foreach my $i ( 3 .. $#lines ) {

      # Skip commented and blank lines
      return if ($lines[$i] =~ /^\s*[\*\%]/);
      return if ($lines[$i] =~ /^\s*$/);

      # temporary star object
      my $star = new Astro::Catalog::Star();

      # Use a pattern match parser
      my @match = ( $lines[$i] =~ m/^(.*?)  # Target name (non greedy)
		          \s*   # optional trailing space
                          (\d{1,2}) # 1 or 2 digits [RA:h] [greedy]
		          \s+       # separator
		          (\d{1,2}) # 1 or 2 digits [RA:m]
		          \s+       # separator
		          (\d{1,2}(?:\.\d*)?) # 1|2 digits opt .fraction [RA:s]
		                    # no capture on fraction
		          \s+
		          ([+-]?\s*\d{1,2}) # 1|2 digit [dec:d] inc sign
		          \s+
		          (\d{1,2}) # 1|2 digit [dec:m]
		          \s+
		          (\d{1,2}(?:\.\d*)?) # arcsecond (optional fraction)
                                              # no capture on fraction
                          \s*
		          (J2000|B1950|Galactic) # coordinate type
                          
		         # most everything else is optional
		         \s+
                         \#
                         \s+(.*)$                    # comment [13]
		/xi);

      # Abort if we do not have matches for the first 9 fields
      for (0 ... 8) {
         return unless defined $match[$_];
      }

      # Read the values
      my $target = $match[0];
      my $ra = join(":",@match[1..3]);
      my $dec = join(":",@match[4..6]);
      $dec =~ s/\s//g; # remove  space between the sign and number
      my $type = $match[7];
      my $comment = $match[8];      
      
      # push the target id
      $star->id( $target );
      
      # push the comment
      $star->comment( $comment );
      
      # Assume J2000 and create an Astro::Coords object
      my $coords = new Astro::Coords( type  => $type,
				      units => 'sex',
				      ra    => $ra,
				      dec   => $dec,
				      name  => $star->id() );
      
      # and push it into the Astro::Catalog::Star object
      $star->coords( $coords );

      # push it onto the stack
      $catalog->pushstar( $star );

   }
   
   $catalog->origin( 'IO::Simple' );
   return $catalog;

}

=item B<_write_catalog>

Will write the catalogue object to an simple output format 

   \@lines = Astro::Catalog::IO::Simple->_write_catalog( $catalog );

where $catalog is an Astro::Catalog object.

=cut

sub _write_catalog {
  croak ( 'Usage: _write_catalog( $catalog )') unless scalar(@_) >= 1;
  my $class = shift;
  my $catalog = shift;
   
  # write header
  # ------------
  my @output;
  my $output_line;
  
  push (@output, "# Catalog written automatically by class ". __PACKAGE__ ."\n");
  push (@output, "# on date " . gmtime . "UT\n" );
  push (@output, "# Origin of catalogue: ". $catalog->origin ."\n");

  # reference to the $self->{STARS} array in Astro::Catalog
  my $stars = $catalog->stars();
  
  # write body
  # ----------
  
  # loop through all the stars in the catalogue
  foreach my $star ( 0 .. $#$stars ) {

     $output_line = undef;
        
     if ( defined ${$stars}[$star]->id() ) {
        $output_line = ${$stars}[$star]->id() . "  ";
     } else {
        $output_line = $star . " ";
     }   
     $output_line = $output_line . ${$stars}[$star]->ra() . "  ";
     $output_line = $output_line . ${$stars}[$star]->dec() . "   ";
     $output_line = $output_line . "J2000  ";
     
     $output_line = $output_line . "# " . ${$stars}[$star]->comment();
     
     # next star
     $output_line = $output_line . "\n";
     push (@output, $output_line );

  }

  # clean up
  return \@output;

}

=item B<_default_file>

If Astro::Catalog is created with a Format but no Filename or other data
source it checked this routine to see whether there is a default file
that should be read. This is mainly for Astro::Catalo::IO::JCMT and the
JAC, but might prive useful elsewhere.

=cut

sub _default_file {
 
   # returns an empty list
   return;
}  

=back

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modificiations Copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This module was written as part of the eSTAR project in collaboration
with the Joint Astronomy Centre (JAC) in Hawaii and is free software; 
you can redistribute it and/or modify it under the terms of the GNU 
Public License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
