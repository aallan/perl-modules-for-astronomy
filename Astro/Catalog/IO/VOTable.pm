package Astro::Catalog::IO::VOTable;

=head1 NAME

Astro::Catalog::IO::VOTable - VOTable Input/Output format

=head1 SYNOPSIS

  $catalog = Astro::Catalog::IO::VOTable->_read_catalog( \@lines );
  \@lines = Astro::Catalog::IO::VOTable->_write_catalog( $catalog );
  Astro::Catalog::IO::VOTable->_default_file();

=head1 DESCRIPTION

Performs simple IO, reading or writing a VOTable.

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

use VOTable::Document;

use Data::Dumper;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: VOTable.pm,v 1.3 2003/10/14 10:06:41 aa Exp $

=begin __PRIVATE_METHODS__

=head1 Private methods

These methods are for internal use only and are called from the 
Astro::Catalog module. It is not expected that anyone would want to
call them from outside that module.

=over 4

=item B<_read_catalog>

Parses a reference to an array containing a simply formatted catalogue

  $catalog = Astro::Catalog::IO::VOTable->_read_catalog( \@lines );

=cut

sub _read_catalog {
   croak( 'Usage: _read_catalog( \@lines )' ) unless scalar(@_) >= 1;
   my $class = shift;
   my $arg = shift;
   my @lines = @{$arg};

   # create an Astro::Catalog object;
   #my $catalog = new Astro::Catalog();
 
   # make the array a string
   #my $string = "";
   #foreach my $i ( 0 ... $#lines ) {
   #  $string = $string . chomp( $lines[$i] );
   #}

   # create a VOTable object from the string.
   #my $doc = VOTable::Document->new_from_string($string);
   
   
   # return the catalogue
   #$catalog->origin( 'IO::VOTable' );
   #return $catalog;

   croak( 'Astro::IO::VOTable, _read_catalog() - Function not implemented' );
}

=item B<_write_catalog>

Will write the catalogue object to an simple output format 

   \@lines = Astro::Catalog::IO::VOTable->_write_catalog( $catalog );

where $catalog is an Astro::Catalog object.

=cut

sub _write_catalog {
  croak ( 'Usage: _write_catalog( $catalog )') unless scalar(@_) >= 1;
  my $class = shift;
  my $catalog = shift;
  
  # debugging, drop the catalogue to disk as it flys right by...
  #use Data::Dumper;
  #print "Dumping Catalogue to disk 'catalog_dump.cat'\n";
  #my $status = open my $fh, ">catalog_dump.cat";
  #if (!$status) {
  #    print "Error: cannot open dump file catalog_dump.cat\n";
  #    return;
  #}
  #print $fh Dumper($catalog);
  #close( $fh );

  # real list of filters and colours in the catalogue
  my @mags = $catalog->starbyindex(0)->what_filters();
  my @cols = $catalog->starbyindex(0)->what_colours();

  # number of stars in catalogue
  my $number = $catalog->sizeof();
  
  # number of filters & colours
  my $num_mags = $catalog->starbyindex(0)->what_filters();
  my $num_cols = $catalog->starbyindex(0)->what_colours();

  # reference to the $self->{STARS} array in Astro::Catalog
  my $stars = $catalog->stars();

  # generate the field headers
  # --------------------------
  my @field_names;
  push @field_names, "ID_MAIN";
  push @field_names, "POS_EQ_RA_MAIN";
  push @field_names, "POS_EQ_DEC_MAIN";
  foreach my $i ( 0 .. $#mags ) {
    push @field_names, "PHOT_MAG_" . $mags[$i];
    push @field_names, "PHOT_MAG_" . $mags[$i] . "_ERROR";
  }
  foreach my $i ( 0 .. $#cols ) {
    push @field_names, "PHOT_CI_" . $cols[$i];
    push @field_names, "PHOT_CI_" . $cols[$i] . "_ERROR";
  } 
  push @field_names, "CODE_QUALITY"; 
 
  # generate the data table
  # -----------------------
  my @data;
  
  foreach my $star ( 0 .. $#$stars ) {
     my @row;
     
     # id
     if ( defined ${$stars}[$star]->id() ) {
        push @row, ${$stars}[$star]->id();
     } else {
        push @row, $star;
     } 

     # ra & dec 
     push @row,  ${$stars}[$star]->ra();
     push @row,  ${$stars}[$star]->dec();
 
     # magnitudes
     foreach my $i ( 0 .. $#mags ) {
        
        if ( defined ${$stars}[$star]->get_magnitude($mags[$i]) ) {
           push @row, ${$stars}[$star]->get_magnitude($mags[$i]);
        } else {
           push @row, "0.000";
        } 
        if ( defined ${$stars}[$star]->get_errors($mags[$i]) ) {
           push @row, ${$stars}[$star]->get_errors($mags[$i]);
        } else {
           push @row, "0.000";
        }
                 
     }     
 
     # colours
     foreach my $i ( 0 .. $#cols ) {
        
        if ( defined ${$stars}[$star]->get_colour($cols[$i]) ) {
           push @row, ${$stars}[$star]->get_colour($cols[$i]);
        } else {
           push @row, "0.000";
        } 
        if ( defined ${$stars}[$star]->get_colourerr($cols[$i]) ) {
           push @row, ${$stars}[$star]->get_colourerr($cols[$i]);
        } else {
           push @row, "0.000";
        }
                         
     }        

     # quality
     if ( defined ${$stars}[$star]->quality() ) {
        push @row, ${$stars}[$star]->quality();
     } else {
        push @row, "0";
     }
     
     # push a reference to the row into the data                     
     push @data, \@row;
     
  } # end of loop around the stars array
  

  # Create the VOTABLE document.
  my $doc = new VOTable::Document();

  # Get the VOTABLE element. 
  my $votable = ($doc->get_VOTABLE)[0];

  # Create the RESOURCE element and add it to the VOTABLE.
  my $resource = new VOTable::RESOURCE();
  $votable->set_RESOURCE($resource);

  # Create the DESCRIPTION element and its contents, and add it to the
  # RESOURCE.
  my $description = new VOTable::DESCRIPTION();
  $description->set('Created using Astro::Catalog::IO::VOTable');

  # Create the TABLE element and add it to the RESOURCE.
  my $table = new VOTable::TABLE();
  $resource->set_TABLE($table);

  # Create and add the FIELD elements to the TABLE.
  my($i);
  my($field);
  for ($i = 0; $i < @field_names; $i++) {
      $field = new VOTable::FIELD();
      $field->set_name($field_names[$i]);
      $table->append_FIELD($field);
  }

  # Create and append the DATA element.
  my $data = new VOTable::DATA();
  $table->set_DATA($data);

  # Create and append the TABLEDATA element.
  my $tabledata = new VOTable::TABLEDATA();
  $data->set_TABLEDATA($tabledata);

  # Create and append each TR element, and each TD element.
  my($tr, $td);
  my($j);
  for ($i = 0; $i < @data; $i++) {
    $tr = new VOTable::TR();
    for ($j = 0; $j < @field_names; $j++) {
	$td = new VOTable::TD();
	$td->set($data[$i][$j]);
	$tr->append_TD($td);
    }
    $tabledata->append_TR($tr);
  }

  # Print the finished document.
  my $output_string = $doc->toString(1);  
  my @output = split("\n", $output_string );
  
  #print $output_string;
  #use Data::Dumper; print Dumper(@output);
  
  # return a reference to an array
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

=end __PRIVATE_METHODS__

=head1 FORMAT

This class implements an interface to VOTable documents. This uses the
GSFC VOTable class which inherits from XML::LibXML:Document.

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
