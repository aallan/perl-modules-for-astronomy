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
#     $Id: Catalog.pm,v 1.14 2003/07/26 23:30:43 timj Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog - A generic API for stellar catalogues

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

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;

use Astro::Coords;
use Astro::Catalog::Star;
use Carp;

'$Revision: 1.14 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Catalog.pm,v 1.14 2003/07/26 23:30:43 timj Exp $

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
		      ORIGIN => '<UNKNOWN>',
		      COORDS => undef,
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
  my $FH;
  unless ( open( $FH, ">$file_name" ) ) {
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

  print $FH "$total colours were created\n";
  print $FH "@out_filters @out_colours\n";
  print $FH "A sub-set of USNO-A2: Field centre at RA " . $self->get_ra() .
           ", Dec " . $self->get_dec() . ", Search Radius " .
           $self->get_radius() . " arcminutes \n";

  # loop through all the stars in the catalogue
  foreach my $star ( 0 .. $#{$self->{STARS}} ) {

     # field, number, ra, dec and x&y position
     print $FH ${$self->{STARS}}[$star]->field() . "  ";
     print $FH $star . "  ";
     print $FH ${$self->{STARS}}[$star]->ra() . "  ";
     print $FH ${$self->{STARS}}[$star]->dec() . "  ";
     print $FH "0.000  0.000  ";

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
          print $FH ${$self->{STARS}}[$star]->get_magnitude($filters[$i]) . "  ";
          print $FH ${$self->{STARS}}[$star]->get_errors($filters[$i]) . "  ";
          print $FH ${$self->{STARS}}[$star]->quality() . "  ";
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
           print $FH ${$self->{STARS}}[$star]->get_colour( $colours[$j] ) . "  ";
           print $FH ${$self->{STARS}}[$star]->get_colourerr($colours[$j]) ."  ";
           print $FH ${$self->{STARS}}[$star]->quality() . "  ";
        }
     }

     # next star
     print $FH "\n";

  }

  # clean up
  close ( $FH );

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<origin>

Return (or set) the origin of the data. For example, USNOA2, GSC
for catalogue queries, or 'JCMT' for the JCMT pointing catalogue.
No constraint is placed on the content of this parameter.

  $catalog->origin( 'JCMT' );
  $origin = $catalog->origing;

=cut

sub origin {
  my $self = shift;
  if (@_) {
    $self->{ORIGIN} = shift;
  }
  return $self->{ORIGIN};
}

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

=item B<popstarbyid>

Return C<Astro::Catalog::Star> objects that have the given ID.

  @stars = $catalog->starbyid( $id );

The method deletes the stars and returns the deleted C<Astro::Catalog::Star>
objects. If no star exists with the given ID, the method returns undef.

If called in scalar context this method returns an array reference, and if
called in list context returns an array of C<Astro::Catalog::Star> objects.

=cut

sub popstarbyid {
  my $self = shift;

  # Return undef if they didn't pass an ID.
  return undef unless @_;

  my $id = shift;

  my @match = grep { $_->id == $id } @{ $self->{STARS} };
  my @unmatched = grep { $_->id != $id } @{ $self->{STARS} };

  $self->{STARS} = \@unmatched;

  return ( wantarray ? @match : \@match );

}

=item B<stars>

Return a list of all the C<Astro::Catalog::Star> objects

  @stars = $catalog->stars();

in list context the copy of the array is returned, while in scalar
context a reference to the array is retrun.

=cut

sub stars {
  my $self = shift;
  return wantarray ? @{ $self->{STARS} } : $self->{STARS};
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
                            Radius => $radius,
                            Coords => new Astro::Coords() 
                           );

RA and Dec must be given together or as Coords.
Coords (an Astro::Coords object) supercedes RA/Dec.

=cut

sub fieldcentre {
  my $self = shift;

  # return unless we have arguments
  return () unless @_;

  # grab the argument list
  my %args = @_;

  if (defined $args{Coords}) {
    $self->{COORDS} = $args{Coords};
  } elsif ( defined $args{RA} && defined $args{Dec}) {
    my $c = new Astro::Coords( type => 'J2000',
			       ra => $args{RA},
			       dec => $args{Dec},
			     );
    $self->{COORDS} = $c;
  }

  # set field radius
  if ( defined $args{Radius} ) {
     $self->{RADIUS} = $args{Radius};
  }

}

=item B<get_coords>

Return the C<Astro::Coords> object associated with the field centre.

  $c = $catalog->get_coords();

=cut

sub get_coords {
  my $self = shift;
  return $self->{COORDS};
}

=item B<get_ra>

Return the RA of the catalogue field centre in sexagesimal,
space-separated format. Returns undef if no coordinate supplied.

   $ra = $catalog->get_ra();

=cut

sub get_ra {
  my $self = shift;
  my $c = $self->get_coords;
  return unless defined $c;
  my $ra = $c->ra(format => 'sex');
  $ra =~ s/:/ /g;
  $ra =~ s/^\s*//;
  return $ra;
}

=item B<get_dec>

Return the Dec of the catalogue field centre in sexagesimal
space-separated format with leading sign.

   $dec = $catalog->get_dec();

=cut

sub get_dec {
  my $self = shift;
  my $c = $self->get_coords;
  return unless defined $c;
  my $dec = $c->dec(format => 'sex');
  $dec =~ s/:/ /g;
  $dec =~ s/^\s*//;
  # prepend sign if there is no sign
  $dec = (substr($dec,0,1) eq '-' ? '' : '+' ) . $dec;
  return $dec;
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
    my $CAT;
    unless ( open( $CAT, $file_name ) ) {
       croak("Astro::Catalog - Cannont open ARK Cluster file $file_name");
    }
    # read from file
    $/ = "\n";
    my @catalog = <$CAT>;
    close($CAT);
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
  $self->fieldcentre( %args );

  return;
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

=item B<_read_cluster>

Reads and parses a scalar containing an ARK Format Cluster file into
the object.

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

      # dec
      my $objdec = "$separated[5] $separated[6] $separated[7]";

      # Assume J2000
      $star->coords( new Astro::Coords(type => 'J2000',
				       units => 'sex',
				       ra => $objra,
				       dec => $objdec,
				       name => $star->id)
		   );

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
Some modificiations Copyright (C) 2003 Particle Physics and Astronomy
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
