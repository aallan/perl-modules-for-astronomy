package Astro::Catalog;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::Catalog

#  Purposes:
#    Generic catalogue object

#  Language:
#    Perl module

#  Description:
#    This module provides a generic astronomical catalogue object

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Catalog.pm,v 1.2 2002/01/14 07:32:13 aa Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog - A generic stellar catalogue object.

=head1 SYNOPSIS

  $catalog = new Astro::Catalog( Stars   => \@array );
  $catalog = new Astro::Catalog( Cluster => $file_name );

=head1 DESCRIPTION

Stores generic meta-data about an astronomical catalogue. Takes a hash 
with an array refernce as an arguement. The array should contain a list 
of Astro::Catalog::Star objects. Alternatively it takes a file name of
an ARK Cluster format catalogue.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Catalog.pm,v 1.2 2002/01/14 07:32:13 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options 

  $catalog = new Astro::Catalog( Stars   => \@array );
  $catalog = new Astro::Catalog( Cluster => $file_name );

returns a reference to an C<Astro::Catalog> object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { STARS  => [],
                      RA     => undef,
                      DEC    => undef,
                      RADIUS => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# O U P T U T  ------------------------------------------------------------

=back

=head2 Output Methods

=over 4

=item B<write_catalog>

Will write the catalogue object to an standard ARK Cluster format file

   $status = $catalog->write_catalog( $file_name );

returns zero on sucess and non-zero if the write failed. 

=cut

sub write_catalog {
  my $self = shift;

  # croak unless we have arguments
  croak ("Astro::Catalog write_catalog() - No filename provided" ) unless @_;
 
  # grab file name and open file for writing
  my $file_name = shift;
  unless ( open( FH, ">$file_name" ) ) {
     croak("Astro::Catalog write_catalog() - Cannont open file $file_name");
  } 
  
  # number of stars in catalogue
  my $number = $#{$self->{STARS}};
 
  # how many filters do we have?
  my $num_filters = ${$self->{STARS}}[0]->what_filters();
  my @filters = ${$self->{STARS}}[0]->what_filters();
  
  # how many colours do we have?
  my $num_colours = ${$self->{STARS}}[0]->what_colours();
  my @colours = ${$self->{STARS}}[0]->what_colours();

  # write header
  my $total = $num_filters + $num_colours;
  print FH "$total colours were created\n";
  print FH "@filters @colours\n";
  print FH "A sub-set of USNO-A2: Field centre at RA " . $self->get_ra() .
           ", Dec " . $self->get_dec() . ", Search Radius " . 
           $self->get_radius() . " arcminutes \n";
           
  # loop through all the stars in the catalogue
  foreach my $star ( 0 .. $#{$self->{STARS}} ) {
  
     # field, number, ra, dec and x&y position
     print FH ${$self->{STARS}}[$star]->field() . "  ";
     print FH $star . "  ";
     print FH ${$self->{STARS}}[$star]->ra() . "  ";
     print FH ${$self->{STARS}}[$star]->dec() . "  ";
     print FH "0.000  0.000  ";
     
     # magnitudes
     foreach my $i ( 0 .. $num_filters-1 ) {
        print FH ${$self->{STARS}}[$star]->get_magnitude( $filters[$i] ) . "  ";
        print FH ${$self->{STARS}}[$star]->get_errors( $filters[$i] ) . "  ";
        print FH ${$self->{STARS}}[$star]->quality() . "  ";
     }
     
     # colours
     foreach my $j ( 0 .. $num_colours-1 ) {
        print FH ${$self->{STARS}}[$star]->get_colour( $colours[$j] ) . "  ";
        print FH ${$self->{STARS}}[$star]->get_colourerr( $colours[$j] ) . "  ";
        print FH ${$self->{STARS}}[$star]->quality() . "  ";
     } 
     
     # next star      
     print FH "\n";

  }
  
  # clean up
  close ( FH );      

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<sizeof>

Return the number of stars in the catalogue.

   $num = $catalog->sizeof();

=cut

sub sizeof {
  my $self = shift;
  return scalar( @{$self->{STARS}} );
}


=item B<pushstar>

Push a new star onto the end of the C<Astro::Catalog> object

   $catalog->pushstar( $star );

returns the number of stars now in the Catalog object.

=cut

sub pushstar {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  my $star = shift;

  # push the new item onto the stack 
  return push( @{$self->{STARS}}, $star );
}

=item B<popstar>

Pop a star from the end of the C<Astro::Catalog> object

   $star = $catalog->popstar();

the method deletes the star and returns the deleted C<Astro::Catalog::Star> 
object.

=cut

sub popstar {
  my $self = shift;

  # pop the star out of the stack
  return pop( @{$self->{STARS}} );
}

=item B<stars>

Return a list of all the C<Astro::Catalog::Star> objects
stored in the results object.

  @stars = $catalog->stars();

=cut

sub stars {
  my $self = shift;
  return @{ $self->{STARS} };
}

=item B<starbyindex>

Return the C<Astro::Catalog::Star> object at index $index

   $star = $catalog->starbyindex( $index );

the first star is at index 0 (not 1). Returns undef if no arguements 
are provided.

=cut

sub starbyindex {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  my $index = shift;

  return ${$self->{STARS}}[$index];
}

=item B<fieldcentre>

Set the field centre and radius of the catalogue (if appropriate)

     $catalog->fieldcentre( RA     => $ra,
                            Dec    => $dec,
                            Radius => $radius );

=cut

sub fieldcentre {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;
  
  # set RA
  if ( defined $args{RA} ) {
     $self->{RA} = $args{RA};
  } 
   
  # set Dec
  if ( defined $args{Dec} ) {
     $self->{DEC} = $args{Dec};
  }  
  
  # set field radius
  if ( defined $args{Radius} ) {
     $self->{RADIUS} = $args{Radius};
  }
  
}

=item B<get_ra>

Return the RA of the catalogue field centre

   $ra = $catalog->get_ra();

=cut

sub get_ra {
  my $self = shift;
  return $self->{RA};
}

=item B<get_dec>

Return the Dec of the catalogue field centre

   $dec = $catalog->get_dec();

=cut

sub get_dec {
  my $self = shift;
  return $self->{DEC};
}

=item B<get_radius>

Return the radius of the catalogue from the field centre

   $radius = $catalog->get_radius();

=cut

sub get_radius {
  my $self = shift;
  return $self->{RADIUS};
}


# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $catalog->configure( %options );

Takes a hash as argument with the list of keywords.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Define the actual catalogue
  # ---------------------------
  
  if ( defined $args{Stars} ) {
  
    # grab the array reference and stuff it into the object
    @{$self->{STARS}} = @{$args{Stars}};
    
  } elsif ( defined $args{Cluster} ) {
  
    # build from Cluster file
    my $file_name = $args{Cluster};
    unless ( open( FH, "$file_name" ) ) {
       croak("Astro::Catalog - Cannont open ARK Cluster file $file_name");
    } 
    @{$self->{STARS}} = _read_cluster( $file_name );    
    close(FH);
    
  } else {
  
     # no build arguements
     croak("Astro::Catalog - Bad constructor, no arguements supplied");
  }   
  
  # Define the field centre if provided
  # -----------------------------------
  
  # set RA
  if ( defined $args{RA} ) {
     $self->{RA} = $args{RA};
  } 
   
  # set Dec
  if ( defined $args{Dec} ) {
     $self->{DEC} = $args{Dec};
  }  
  
  # set field radius
  if ( defined $args{Radius} ) {
     $self->{RADIUS} = $args{Radius};
  }
  
}

# H A N D L E   C L U S T E R   F I L E S ------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=itemB<_read_cluster>

Reads and parses an ARK Format Cluster file into the object.

=cut

sub _read_cluster {
   my $self = shift;

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

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