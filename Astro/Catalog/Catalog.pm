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
#     $Id: Catalog.pm,v 1.9 2003/06/10 23:17:42 aa Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog - A generic stellar catalogue object.

=head1 SYNOPSIS

  $catalog = new Astro::Catalog( Stars   => \@array );
  $catalog = new Astro::Catalog( Cluster => $file_name );
  $catalog = new Astro::Catalog( Scalar      => $scalar );

=head1 DESCRIPTION

Stores generic meta-data about an astronomical catalogue. Takes a hash 
with an array refernce as an arguement. The array should contain a list 
of Astro::Catalog::Star objects. Alternatively it takes a file name of
an ARK Cluster format catalogue.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::Catalog::Star;
use Carp;

'$Revision: 1.9 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Catalog.pm,v 1.9 2003/06/10 23:17:42 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options 

  $catalog = new Astro::Catalog( Stars       => \@array );
  $catalog = new Astro::Catalog( Cluster     => $file_name );
  $catalog = new Astro::Catalog( Scalar      => $scalar );

returns a reference to an C<Astro::Catalog> object. Where $scalar is a scalar
holding a string representing an ARK Cluster Format file.

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

   $status = $catalog->write_catalog( $file_name, \@mags, \@colour );

returns zero on sucess and non-zero if the write failed. Only magnitudes 
and colours passed in the array will be written to the file, e.g.

   my @mags = ( 'R' );
   my @colour = ( 'B-R', 'B-V' );
   $status = $catalog->write_catalog( $file_name, \@mags, \@colour );

will write a catalogue with R, B-R and B-V.   

=cut

sub write_catalog {
  my $self = shift;

  # croak unless we have arguments
  croak ("Astro::Catalog write_catalog() - No filename provided" ) unless @_;
 
  # grab file name and open file for writing
  my $file_name = shift;
  unless ( open( FILE, ">$file_name" ) ) {
     croak("Astro::Catalog write_catalog() - Can not open file $file_name");
  } 
 
  # number of stars in catalogue
  my $number = $#{$self->{STARS}};
 
  # how many filters do we have?
  my $num_filters = ${$self->{STARS}}[0]->what_filters();
  my @filters = ${$self->{STARS}}[0]->what_filters();
  
  # how many colours do we have?
  my $num_colours = ${$self->{STARS}}[0]->what_colours();
  my @colours = ${$self->{STARS}}[0]->what_colours();

  # grab the filters and colours to be output to the file
  my ( $output_mags, $output_cols );
  if ( @_ ) {
    $output_mags = shift;
    $output_cols = shift;
  } else {
    $output_mags = \@filters;
    $output_cols = \@colours;
  }   

  # define varaibles for output filters and colours
  my ( @out_filters, @out_colours );
        
  # if we want fewer magnitudes than we have in the object
  # to be written to the cluster file
  foreach my $m ( 0 .. $#{$output_mags} ) {
     foreach my $n ( 0 .. $#filters ) {
        if ( ${$output_mags}[$m] eq $filters[$n] ) {
           push( @out_filters, ${$output_mags}[$m]);
        }
     }   
  }
  
  # same for colours
  foreach my $m ( 0 .. $#{$output_cols} ) {
     foreach my $n ( 0 .. $#colours ) {
        if ( ${$output_cols}[$m] eq $colours[$n] ) {
           push( @out_colours, ${$output_cols}[$m]);
        }   
     }
  }  
        
  # write header
  
  # check to see if we're outputing all the filters and colours
  my $total = scalar(@out_filters) + scalar(@out_colours);
   
  print FILE "$total colours were created\n";
  print FILE "@out_filters @out_colours\n";
  print FILE "A sub-set of USNO-A2: Field centre at RA " . $self->get_ra() .
           ", Dec " . $self->get_dec() . ", Search Radius " . 
           $self->get_radius() . " arcminutes \n";
           
  # loop through all the stars in the catalogue
  foreach my $star ( 0 .. $#{$self->{STARS}} ) {
  
     # field, number, ra, dec and x&y position
     print FILE ${$self->{STARS}}[$star]->field() . "  ";
     print FILE $star . "  ";
     print FILE ${$self->{STARS}}[$star]->ra() . "  ";
     print FILE ${$self->{STARS}}[$star]->dec() . "  ";
     print FILE "0.000  0.000  ";
     
     # magnitudes
     foreach my $i ( 0 .. $num_filters-1 ) {
     
        my $doit = 0;
        
        # if we want fewer magnitudes than we have in the object
        # to be written to the cluster file
        if ( defined ${$output_mags}[0] ) { 

           $doit = -1;
           # check to see if we have a valid filter
           foreach my $m ( 0 .. $#{$output_mags} ) {
              $doit = 1 if ( ${$output_mags}[$m] eq $filters[$i] );
           }
        }
           
        # so long as $doit isn't -1 then we have a valid filter 
        if( $doit != -1 ) {   
          print FILE ${$self->{STARS}}[$star]->get_magnitude($filters[$i]) . "  ";
          print FILE ${$self->{STARS}}[$star]->get_errors($filters[$i]) . "  ";
          print FILE ${$self->{STARS}}[$star]->quality() . "  ";
        } 
     }
     
     # colours
     foreach my $j ( 0 .. $num_colours-1 ) {
     
        my $doit = 0;
        
        # if we want fewer magnitudes than we have in the object
        # to be written to the cluster file
        if ( defined ${$output_cols}[0] ) { 

           $doit = -1;
           # check to see if we have a valid filter
           foreach my $m ( 0 .. $#{$output_cols} ) {
              $doit = 1 if ( ${$output_cols}[$m] eq $colours[$j] );
           }
        }
           
        # so long as $doit isn't -1 then we have a valid filter 
        if( $doit != -1 ) {   
           print FILE ${$self->{STARS}}[$star]->get_colour( $colours[$j] ) . "  ";
           print FILE ${$self->{STARS}}[$star]->get_colourerr($colours[$j]) ."  ";
           print FILE ${$self->{STARS}}[$star]->quality() . "  ";
        }
     } 
     
     # next star      
     print FILE "\n";

  }
  
  # clean up
  close ( FILE );      

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
    unless ( open( CAT, $file_name ) ) {
       croak("Astro::Catalog - Cannont open ARK Cluster file $file_name");
    }     
    # read from file   
    $/ = "\n";
    my @catalog = <CAT>;
    close(CAT);
    chomp @catalog;
   
    #print "File is $file_name\n";
   
    #print "Grabbed " . $#catalog . " lines of cluster catalog\n";
    #foreach my $loop ( 0 ... $#catalog ) {
    #   print "$loop# " . $catalog[$loop] . "\n";
    #}
    
    # read catalogue
     _read_cluster( $self, @catalog ); 
        
  } elsif ( defined $args{Scalar} ) {
  
    # Split the catalog out from its single scalar
    my @catalog = split( /\n/, $args{Scalar} );

    # read catalogue from file
     _read_cluster( $self, @catalog );    
        
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

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'Astro::Catalog';
}

# H A N D L E   C L U S T E R   F I L E S ------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=itemB<_read_cluster>

Reads and parses a scalar containing an ARK Format Cluster file into the object.

=cut

sub _read_cluster {
   my $self = shift;
   my @catalog = @_;

   # loop through catalog
   foreach my $i ( 3 .. $#catalog ) {
 
      # remove leading spaces
      $catalog[$i] =~ s/^\s+//;

      # split each line
      my @separated = split( /\s+/, $catalog[$i] );
 
      # debugging (leave in)
      #print "$i # id $separated[1]\n";
      #foreach my $thing ( 0 .. $#separated ) {
      #   print "   $thing # $separated[$thing] #\n";
      #}
                        
      # temporary star object
      my $star = new Astro::Catalog::Star();
      
      # field
      $star->field( $separated[0] );
      
      # id
      $star->id( $separated[1] );
      
      # ra
      my $objra = "$separated[2] $separated[3] $separated[4]";
      $star->ra( $objra );
       
      # dec
      my $objdec = "$separated[5] $separated[6] $separated[7]";
      $star->dec( $objdec );
      
      # x & y
      $star->x( $separated[8] );
      $star->y( $separated[9] );
      
      # number of magnitudes and colours
      $catalog[1] =~ s/^\s+//;
      my @colours = split( /\s+/, $catalog[1] );
      
      my @quality;
      foreach my $j ( 0 .. $#colours ) {
      
         # colours have minus signs
         if( lc($colours[$j]) =~ "-" ) {
         
            # colours
            my %colours = ( $colours[$j] => $separated[3*$j+10] );
            $star->colours( \%colours );
            
            # errors
            my %col_errors = ( $colours[$j] => $separated[3*$j+11] );
            $star->colerr( \%col_errors );
            
            # quality flags
            $quality[$j] = $separated[3*$j+12];
            
         } else {
         
            # mags
            my %magnitudes = ( $colours[$j] => $separated[3*$j+10] );
            $star->magnitudes( \%magnitudes );
            
            # errors
            my %mag_errors = ( $colours[$j] => $separated[3*$j+11] );
            $star->magerr( \%mag_errors );
            
            # quality flags
            $quality[$j] = $separated[3*$j+12];
            
            # increment counter
            $j = $j + 2;
            
         }
            
      }
            
      # set default "good" quality
      $star->quality( 0 );
      
      # check and set quality flag
      foreach my $k( 0 .. $#colours ) {
      
         # if quality not good then set bad flag
         if( $quality[$k] != 0 ) {
            $star->quality( 1 );
         }         
      }
      
      # push it onto the stack
      push ( @{$self->{STARS}}, $star );
   
      
   
   }
   
   
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
