package Astro::Catalog::Star;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::Catalog::Star

#  Purposes:
#    Generic star in a catalogue

#  Language:
#    Perl module

#  Description:
#    This module provides a generic star object for the Catalog object

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Star.pm,v 1.19 2004/02/26 01:42:57 cavanagh Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog::Star - A generic star object in a stellar catalogue.

=head1 SYNOPSIS

  $star = new Astro::Catalog::Star( ID           => $id, 
                                    Coords       => new Astro::Coords(),
                                    Magnitudes   => \%magnitudes,
                                    MagErr       => \%mag_errors,
                                    Colours      => \%colours,
                                    ColErr       => \%colour_errors,
                                    Quality      => $quality_flag,
                                    Field        => $field,
                                    GSC          => $in_gsc,
                                    Distance     => $distance_to_centre,
                                    PosAngle     => $position_angle,
                                    X            => $x_pixel_coord,
                                    Y            => $y_pixel_coord,
                                    Comment      => $comment_string
				    SpecType     => $spectral_type,
				    StarType     => $star_type,
				    LongStarType => $long_star_type,
				    MoreInfo     => $url,
                                    InsertDate   => new Time::Piece(),
				  );

=head1 DESCRIPTION

Stores generic meta-data about an individual stellar object from a catalogue.

If the catalogue has a field center the Distance and Position Angle properties
should be used to store the direction to the field center, e.g. a star from the
USNO-A2 catalogue retrieived from the ESO/ST-ECF Archive will have these
properties.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use vars qw/ $VERSION /;
use Carp;
use Astro::Coords;

# Register an Astro::Catalog::Star warning category
use warnings::register;

# Radians to arcseconds
# Copied from Astro::SLA just in case Astro::Coords ever loses Astro::SLA
# dependency. I am not really happy about this - TJ
# This is not meant to part of the documented public interface.
use constant DR2AS => 2.0626480624709635515647335733077861319665970087963e5;

'$Revision: 1.19 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# Internal lookup table for Simbad star types
my %STAR_TYPE_LOOKUP = (
          'vid' => 'Underdense region of the Universe',
          'Er*' => 'Eruptive variable Star',
          'Rad' => 'Radio-source',
          'Q?' => 'Possible Quasar',
          'IR' => 'Infra-Red source',
          'SB*' => 'Spectrocopic binary',
          'C*' => 'Carbon Star',
          'Gl?' => 'Possible Globular Cluster',
          'DNe' => 'Dark Nebula',
          'GlC' => 'Globular Cluster',
          'No*' => 'Nova',
          'V*?' => 'Star suspected of Variability',
          'LeG' => 'Gravitationnaly Lensed Image of a Galaxy',
          'mAL' => 'metallic Absorption Line system',
          'LeI' => 'Gravitationnaly Lensed Image',
          'WU*' => 'Eclipsing binary of W UMa type',
          'Be*' => 'Be Star',
          'PaG' => 'Pair of Galaxies',
          'Mas' => 'Maser',
          'LeQ' => 'Gravitationnaly Lensed Image of a Quasar',
          'mul' => 'Composite object',
          'SBG' => 'Starburst Galaxy',
          '*' => 'Star',
          'gam' => 'gamma-ray source',
          'bL*' => 'Eclipsing binary of beta Lyr type',
          'S*' => 'S Star',
          'El*' => 'Elliptical variable Star',
          'GNe' => 'Galactic Nebula',
          'DQ*' => 'Cataclysmic Var. DQ Her type',
          '?' => 'Object of unknown nature',
          'WV*' => 'Variable Star of W Vir type',
          'SR?' => 'SuperNova Remnant Candidate',
          'Bla' => 'Blazar',
          'G' => 'Galaxy',
          'SCG' => 'Supercluster of Galaxies',
          'OH*' => 'Star with envelope of OH/IR type',
          'Lev' => '(Micro)Lensing Event',
          'BNe' => 'Bright Nebula',
          'RV*' => 'Variable Star of RV Tau type',
          'IR0' => 'IR source at lambda < 10 microns',
          'OVV' => 'Optically Violently Variable object',
          'a2*' => 'Variable Star of alpha2 CVn type',
          'IR1' => 'IR source at lambda > 10 microns',
          'Em*' => 'Emission-line Star',
          'PM*' => 'High proper-motion Star',
          'X' => 'X-ray source',
          'HzG' => 'Galaxy with high redshift',
          'Sy*' => 'Symbiotic Star',
          'LXB' => 'Low Mass X-ray Binary',
          '*i*' => 'Star in double system',
          'Sy1' => 'Seyfert 1 Galaxy',
          'Sy2' => 'Seyfert 2 Galaxy',
          'LIN' => 'LINER-type Active Galaxy Nucleus',
          'rG' => 'Radio Galaxy',
          'Cl*' => 'Cluster of Stars',
          'NL*' => 'Nova-like Star',
          'HV*' => 'High-velocity Star',
          'EmG' => 'Emission-line galaxy',
          '*iA' => 'Star in Association',
          'grv' => 'Gravitational Source',
          '*iC' => 'Star in Cluster',
          'SyG' => 'Seyfert Galaxy',
          'RNe' => 'Reflection Nebula',
          'EmO' => 'Emission Object',
          'Ce*' => 'Classical Cepheid variable Star',
          'CV*' => 'Cataclysmic Variable Star',
          '*iN' => 'Star in Nebula',
          'BY*' => 'Variable of BY Dra type',
          'Pe*' => 'Peculiar Star',
          'AM*' => 'Cataclysmic Var. AM Her type',
          'FU*' => 'Variable Star of FU Ori type',
          'HVC' => 'High-velocity Cloud',
          'ClG' => 'Cluster of Galaxies',
          'Ir*' => 'Variable Star of irregular type',
          'PN?' => 'Possible Planetary Nebula',
          'ALS' => 'Absorption Line system',
          'cm' => 'centimetric Radio-source',
          'As*' => 'Association of Stars',
          'V*' => 'Variable Star',
          'Fl*' => 'Flare Star',
          'EB*' => 'Eclipsing binary',
          'CGG' => 'Compact Group of Galaxies',
          'UV' => 'UV-emission source',
          'Ro*' => 'Rotationally variable Star',
          'SN*' => 'SuperNova',
          'pr*' => 'Pre-main sequence Star',
          'CH*' => 'Star with envelope of CH type',
          'Al*' => 'Eclipsing binary of Algol type',
          'Pu*' => 'Pulsating variable Star',
          'Cld' => 'Cloud of unknown nature',
          'QSO' => 'Quasar',
          'Psr' => 'Pulsars',
          'GiC' => 'Galaxy in Cluster of Galaxies',
          'V* RI*' => 'Variable Star with rapid variations',
          'sh' => 'HI shell',
          'GiG' => 'Galaxy in Group of Galaxies',
          'OpC' => 'Open (galactic) Cluster',
          'WR*' => 'Wolf-Rayet Star',
          'BCG' => 'Blue compact Galaxy',
          'blu' => 'Blue object',
          'GiP' => 'Galaxy in Pair of Galaxies',
          'LyA' => 'Ly alpha Absorption Line system',
          'CGb' => 'Cometary Globule',
          '**' => 'Double or multiple star',
          'H2G' => 'HII Galaxy',
          'RR*' => 'Variable Star of RR Lyr type',
          'HB*' => 'Horizontal Branch Star',
          'RC*' => 'Variable Star of R CrB type',
          'SNR' => 'SuperNova Remnant',
          'MoC' => 'Molecular Cloud',
          'HXB' => 'High Mass X-ray Binary',
          'mR' => 'metric Radio-source',
          'TT*' => 'T Tau-type Star',
          'DN*' => 'Dwarf Nova',
          'eg sr*' => 'Semi-regular pulsating Star',
          'HII' => 'HII (ionized) region',
          'HH' => 'Herbig-Haro Object',
          'HI' => 'HI (neutral) region',
          'WD*' => 'White Dwarf',
          'Or*' => 'Variable Star in Orion Nebula',
          'dS*' => 'Variable Star of delta Sct type',
          'DLy' => 'Dumped Ly alpha Absorption Line system',
          'AGN' => 'Active Galaxy Nucleus',
          'GrG' => 'Group of Galaxies',
          'Mi*' => 'Variable Star of Mira Cet type',
          'RS*' => 'Variable of RS CVn type',
          'mm' => 'millimetric Radio-source',
          'red' => 'Very red source',
          'BLL' => 'BL Lac - type object',
          'reg' => 'Region defined in the sky',
          'PN' => 'Planetary Nebula',
          'ZZ*' => 'Variable White Dwarf of ZZ Cet type',
          'gB' => 'gamma-ray Burster',
          'PoC' => 'Part of Cloud',
          'XB*' => 'X-ray Binary',
          'PoG' => 'Part of a Galaxy',
          'Neb' => 'Nebula of unknown nature'
        );


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Star.pm,v 1.19 2004/02/26 01:42:57 cavanagh Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options


  $star = new Astro::Catalog::Star( ID           => $id, 
                                    Coords       => new Astro::Coords(),
                                    Magnitudes   => \%magnitudes,
                                    MagErr       => \%mag_errors,
                                    Colours      => \%colours,
                                    ColErr       => \%colour_errors,
                                    Quality      => $quality_flag,
                                    Field        => $field,
                                    GSC          => $in_gsc,
                                    Distance     => $distance_to_centre,
                                    PosAngle     => $position_angle,
                                    X            => $x_pixel_coord,
                                    Y            => $y_pixel_coord,
                                    Comment      => $comment_string
				    SpecType     => $spectral_type,
				    StarType     => $star_type,
				    LongStarType => $long_star_type,
				    MoreInfo     => $url,
                                    InsertDate   => new Time::Piece(),
				  );

returns a reference to an Astro::Catalog::Star object.

The coordinates can also be specified as individual RA and Dec values
(sexagesimal format) if they are known to be J2000.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { ID         => undef,
                      MAGNITUDES => {},
                      MAGERR     => {},
                      COLOURS    => {},
                      COLERR     => {},
                      QUALITY    => undef,
                      FIELD      => undef,
                      GSC        => undef,
                      DISTANCE   => undef,
                      POSANGLE   => undef,
		      COORDS     => undef,
                      X          => undef,
                      Y          => undef,
                      COMMENT    => undef,
		      SPECTYPE   => undef,
		      STARTYPE   => undef,
		      LONGTYPE   => undef,
		      MOREINFO   => undef,
                      INSERTDATE => undef,
		    }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<id>

Return (or set) the ID of the star

   $id = $star->id();
   $star->id( $id );

If an Astro::Coords object is associated with the Star, the name
field is set in the underlying Astro::Coords object as well as in
the current Star object.

=cut

sub id {
  my $self = shift;
  if (@_) {
    $self->{ID} = shift;

    my $c = $self->coords;
    $c->name( $self->{ID} ) if defined $c;
  }
  return $self->{ID};
}

=item B<coords>

Return or set the coordinates of the star as an C<Astro::Coords>
object.

  $c = $star->coords();
  $star->coords( $c );

The object returned by this method is the actual object stored
inside this Star object and not a clone. If the coordinates
are changed through this object the coordinate of the star is
also changed.

Currently, if you modify the RA or Dec through the ra() 
or dec() methods of Star, the internal object associated with
the Star will change.

Returns undef if the coordinates have never been specified.

If the name() field is defined in the Astro::Coords object
the id() field is set in the current Star object. Similarly for
the comment field.

=cut

sub coords {
  my $self = shift;
  if (@_) {
    my $c = shift;
    croak "Coordinates must be an Astro::Coords object"
      unless UNIVERSAL::isa($c, "Astro::Coords");

    # force the ID and comment to match
    $self->id( $c->name ) if defined $c->name;
    $self->comment( $c->comment ) if $c->comment;

    # Store the new coordinate object
    # Storing it late stops looping from the id and comment methods
    $self->{COORDS} = $c;

  }
  return $self->{COORDS};
}

=item B<ra>

Return (or set) the current object R.A. (J2000).

   $ra = $star->ra();

If the Star is associated with a moving object such as a planet,
comet or asteroid this method will return the J2000 RA associated
with the time and observer position associated with the coordinate
object itself (by default current time, longitude of 0 degrees).
Returns undef if no coordinate has been associated with this star.

   $star->ra( $ra );

The RA can be changed using this method but only if the coordinate
object is associated with a fixed position. Attempting to change the
J2000 RA of a moving object will fail. If an attempt is made to
change the RA when no coordinate is associated with this object then
a new Astro::Coords object will be created (with a
Dec of 0.0).

RA accepted by this method must be in sexagesimal format, space or
colon-separated. Returns a space-separated sexagesimal number.


=cut

sub ra {
  my $self = shift;
  if (@_) {
    my $ra = shift;

    # Issue a warning specifically for this call
    my @info = caller();
    warnings::warnif("deprecated","Use of ra() method for setting RA now deprecated. Please use the coords() method instead, at $info[1] line $info[2]");


    # Get the coordinate object
    my $c = $self->coords;
    if (defined $c) {
      # Need to tweak RA?
      croak "Can only adjust RA with Astro::Coords::Equatorial coordinates"
	unless $c->isa("Astro::Coords::Equatorial");

      # For now need to kluge since Astro::Coords does not allow
      # you to change the position (it is an immutable object)
      $c = $c->new( type => 'J2000',
		    dec => $c->dec(format => 's'),
		    ra => $ra,
		  );

    } else {
      $c = new Astro::Coords( type => 'J2000',
			      ra => $ra,
			      dec => '0',
			    );
    }

    # Update the object
    $self->coords($c);
  }

  my $outc = $self->coords;
  return unless defined $outc;

  # Astro::Coords inserts colons by default
  my $outra = $outc->ra(format => 's');

  # Tidy for backwards compatibility
  $outra =~ s/:/ /g;
  $outra =~ s/^\s*//;

  return $outra;
}

=item B<dec>

Return (or set) the current object Dec (J2000).

   $dec = $star->dec();

If the Star is associated with a moving object such as a planet,
comet or asteroid this method will return the J2000 Dec associated
with the time and observer position associated with the coordinate
object itself (by default current time, longitude of 0 degrees).
Returns undef if no coordinate has been associated with this star.

   $star->dec( $dec );

The Dec can be changed using this method but only if the coordinate
object is associated with a fixed position. Attempting to change the
J2000 Dec of a moving object will fail. If an attempt is made to
change the Dec when no coordinate is associated with this object then
a new Astro::Coords object will be created (with a
Dec of 0.0).

Dec accepted by this method must be in sexagesimal format, space or
colon-separated. Returns a space-separated sexagesimal number
with a leading sign.

=cut

sub dec {
  my $self = shift;
  if (@_) {
    my $dec = shift;

    # Issue a warning specifically for this call
    my @info = caller();
    warnings::warnif("deprecated","Use of ra() method for setting RA now deprecated. Please use the coords() method instead, at $info[1] line $info[2]");

    # Get the coordinate object
    my $c = $self->coords;
    if (defined $c) {
      # Need to tweak RA?
      croak "Can only adjust Dec with Astro::Coords::Equatorial coordinates"
	unless $c->isa("Astro::Coords::Equatorial");

      # For now need to kluge since Astro::Coords does not allow
      # you to change the position (it is an immutable object)
      $c = $c->new( type => 'J2000',
		    ra => $c->ra(format => 's'),
		    dec => $dec,
		  );

    } else {
      $c = new Astro::Coords( type => 'J2000',
			      dec => $dec,
			      ra => 0,
			    );
    }

    # Update the object
    $self->coords($c);
  }

  my $outc = $self->coords;
  return unless defined $outc;

  # Astro::Coords inserts colons by default
  my $outdec = $outc->dec(format => 's');
  $outdec =~ s/:/ /g;
  $outdec =~ s/^\s*//;

  # require leading sign for backwards compatibility
  # Sign will be there for negative
  $outdec = (substr($outdec,0,1) eq '-' ? '' : '+' ) . $outdec;

  return $outdec;
}

=item B<magnitudes>

Set the UBVRIHK magnitudes of the object, takes a reference to a hash of 
magnitude values

    my %mags = ( B => '16.5', V => '15.4', R => '14.3' );
    $star->magnitudes( \%mags );

additional calls to magnitudes() will append, not replace, additional 
magnitude values, magnitudes for filters already existing will be over-written.

=cut

sub magnitudes {
  my $self = shift;
  if (@_) {
    my $mags = shift;
    %{$self->{MAGNITUDES}} = ( %{$self->{MAGNITUDES}}, %{$mags} );
  }
}

=item B<magerr>

Set the error in UBVRIHK magnitudes of the object, takes a reference to a
hash of error values

    my %mag_errors = ( B => '0.3', V => '0.1', R => '0.4' );
    $star->magerr( \%mag_errors );

additional calls to magerr() will append, not replace, additional error values,
errors for filters already existing will be over-written.

=cut

sub magerr {
  my $self = shift;
  if (@_) {
    my $magerr = shift;
    %{$self->{MAGERR}} = ( %{$self->{MAGERR}}, %{$magerr} );
  }
}

=item B<Colours>

Set the colour values for the object, takes a reference to a hash of colours

    my %cols = ( 'B-V' => '0.5', 'B-R' => '0.4' );
    $star->colours( \%cols );

additional calls to colours() will append, not replace, colour values,
altough for colours which already have defined values, these values will
be over-written.

=cut

sub colours {
  my $self = shift;
  if (@_) {
    my $cols = shift;
    %{$self->{COLOURS}} = ( %{$self->{COLOURS}}, %{$cols} );
  }
}

=item B<ColErr>

Set the colour error values for the object, takes a reference to a hash of
colour errors

    my %col_errors = ( 'B-V' => '0.02', 'B-R' => '0.05' );
    $star->colerr( \%col_errors );

additional calls to colerr() will append, not replace, colour error values,
altough for errors which already have defined values, these values will
be over-written.

=cut

sub colerr {
  my $self = shift;
  if (@_) {
    my $col_err = shift;
    %{$self->{COLERR}} = ( %{$self->{COLERR}}, %{$col_err} );
  }
}


=item B<what_filters>

Returns a list of the filters for which the object has defined values.

   @filters = $star->what_filters();
   $num = $star->what_filters();

if called in a scalar context it will return the number of filters which
have defined magnitudes in the object.

=cut

sub what_filters {
  my $self = shift;

  # define output array
  my @mags;

  foreach my $key (sort keys %{$self->{MAGNITUDES}}) {
      # push the filters onto the output array
      push ( @mags, $key );
  }

  # return array of filters or number if called in scalar context
  return wantarray ? @mags : scalar( @mags );
}

=item B<what_colours>

Returns a list of the colours for which the object has defined values.

   @colours = $star->what_colours();
   $num = $star->what_colours();

if called in a scalar context it will return the number of colours which
have defined values in the object.

=cut

sub what_colours {
  my $self = shift;

  # define output array
  my @cols;

  foreach my $key (sort keys %{$self->{COLOURS}}) {
      # push the colours onto the output array
      push ( @cols, $key );
  }

  # return array of colours or number if called in scalar context
  return wantarray ? @cols : scalar( @cols );
}

=item B<get_magnitude>

Returns the magnitude for the supplied filter if available

   $magnitude = $star->get_magnitude( 'B' );

=cut

sub get_magnitude {
  my $self = shift;

  my $magnitude;
  if (@_) {

     # grab passed filter
     my $filter = shift;
     foreach my $key (sort keys %{$self->{MAGNITUDES}}) {

         # grab magnitude for filter
         if( $key eq $filter ) {
            $magnitude = ${$self->{MAGNITUDES}}{$key};
         }
     }
  }
  return $magnitude;
}

=item B<get_errors>

Returns the error in the magnitude value for the supplied filter if available

   $mag_errors = $star->get_errors( 'B' );

=cut

sub get_errors {
  my $self = shift;

  my $mag_error;
  if (@_) {

     # grab passed filter
     my $filter = shift;
     foreach my $key (sort keys %{$self->{MAGERR}}) {

         # grab magnitude for filter
         if( $key eq $filter ) {
            $mag_error = ${$self->{MAGERR}}{$key};
         }
     }
  }
  return $mag_error;
}

=item B<get_colour>

Returns the value of the supplied colour if available

   $colour = $star->get_colour( 'B-V' );

=cut

sub get_colour {
  my $self = shift;

  my $value;
  if (@_) {

     # grab passed colour
     my $colour = shift;
     foreach my $key (sort keys %{$self->{COLOURS}}) {

         # grab magnitude for colour
         if( $key eq $colour ) {
            $value = ${$self->{COLOURS}}{$key};
         }
     }
  }
  return $value;
}

=item B<get_colourerror>

Returns the error in the colour value for the supplied colour if available

   $col_errors = $star->get_colourerr( 'B-V' );

=cut

sub get_colourerr {
  my $self = shift;

  my $col_error;
  if (@_) {

     # grab passed colour
     my $colour = shift;
     foreach my $key (sort keys %{$self->{COLERR}}) {

         # grab values for the colour
         if( $key eq $colour ) {
            $col_error = ${$self->{COLERR}}{$key};
         }
     }
  }
  return $col_error;
}

=item B<quality>

Return (or set) the quality flag of the star

   $quality = $star->quailty();
   $star->quality( 0 );

for example for the USNO-A2 catalogue, 0 denotes good quality, and 1
denotes a possible problem object. In the generic case any flag value,
including a boolean, could be used.

These quality flags are standardised sybolically across catalogues and
have the following definitions:

  STARGOOD
  STARBAD

TBD. Need to provide quality constants and mapping to and from these
constants on catalog I/O.

=cut

sub quality {
  my $self = shift;
  if (@_) {
  
    # 2MASS hack
    # ----------
    # quick, dirty and ultimately icky hack. The entire quality flag
    # code is going to have to be rewritten so it works like mag errors,
    # and gets assocaited with a magnitude. For now, if the JHK QFlag
    # for 2MASS is A,B or C then the internal quality flag is 0 (good),
    # otherwise it gets set to 1 (bad). This pretty much sucks.
    
    # Yes Tim, I know I'm doing this in the wrong place. I'm panicing 
    # I'll fix it later. I've moved the Cluster specific hack about the
    # star ID's out of Astro::Catalog::query::USNOA2 and into the Cluster
    # IO module and used Scalar::Util to figure out whether I've got a
    # number (neat solution) before blowing it away.
    
    # Anyway...
    my $quality = shift;
    if ( $quality =~ /^[A-Z][A-Z][A-Z]$/ ) {
       
       $_ = $quality;
       m/^([A-Z])([A-Z])([A-Z])$/;
       
       my $j_quality = $1;
       my $h_quality = $2;
       my $k_quality = $3;
       
       if ( ($j_quality eq 'A' || $j_quality eq 'B' || $j_quality eq 'C') &&
            ($h_quality eq 'A' || $h_quality eq 'B' || $h_quality eq 'C') ) {
       
          # good quality
          $self->{QUALITY} = 0;
          
       } else { 
          # bad quality  
          $self->{QUALITY} = 1;
       }
       
    } else {
    
       $self->{QUALITY} = $quality;
    }
          
  }
  return $self->{QUALITY};
}

=item B<field>

Return (or set) the field parameter for the star

   $field = $star->field();
   $star->field( '0080' );

=cut

sub field {
  my $self = shift;
  if (@_) {
    $self->{FIELD} = shift;
  }
  return $self->{FIELD};
}

=item B<gsc>

Return (or set) the GSC flag for the object

   $gsc = $star->gsc();
   $star->gsc( 'TRUE' );

the flag is TRUE if the object is known to be in the Guide Star Catalogue, 
and FALSE otherwise.

=cut

sub gsc {
  my $self = shift;
  if (@_) {
    $self->{GSC} = shift;
  }
  return $self->{GSC};
}

=item B<distance>

Return (or set) the distance from the field centre

   $distance = $star->distance();
   $star->distance( '0.009' );

e.g. for the USNO-A2 catalogue.

=cut

sub distance {
  my $self = shift;
  if (@_) {
    $self->{DISTANCE} = shift;
  }
  return $self->{DISTANCE};
}

=item B<posangle>

Return (or set) the position angle from the field centre

   $position_angle = $star->posangle();
   $star->posangle( '50.761' );

e.g. for the USNO-A2 catalogue.

=cut

sub posangle {
  my $self = shift;
  if (@_) {
    $self->{POSANGLE} = shift;
  }
  return $self->{POSANGLE};
}

=item B<x>

Return (or set) the X pixel co-ordinate of the star

   $x = $star->x();
   $star->id( $x );

=cut

sub x {
  my $self = shift;
  if (@_) {
    $self->{X} = shift;
  }
  return $self->{X};
}

=item B<y>

Return (or set) the Y pixel co-ordinate of the star

   $y = $star->y();
   $star->id( $y );

=cut

sub y {
  my $self = shift;
  if (@_) {
    $self->{Y} = shift;
  }
  return $self->{Y};
}


=item B<comment>

Return (or set) a comment associated with the star

   $comment = $star->comment();
   $star->comment( $comment_string );

The comment is propogated to the underlying coordinate
object (if one is present) if the comment is updated.

=cut

sub comment {
  my $self = shift;
  if (@_) {
    $self->{COMMENT} = shift;

    my $c = $self->coords;
    $c->comment( $self->{COMMENT} ) if defined $c;
  }
  return $self->{COMMENT};
}

=item B<spectype>

The spectral type of the Star.

  $spec = $star->spectype;

=cut

sub spectype {
  my $self = shift;
  if (@_) {
    $self->{SPECTYPE} = shift;
  }
  return $self->{SPECTYPE};
}

=item B<startype>

The type of star. Usually uses the Simbad abbreviation.
eg. '*' for a star, 'rG' for a Radio Galaxy.

  $type = $star->startype;

See also C<longstartype> for the expanded version of this type.

=cut

sub startype {
  my $self = shift;
  if (@_) {
    $self->{STARTYPE} = shift;
  }
  return $self->{STARTYPE};
}

=item B<longstartype>

The full description of the type of star. Usually uses the Simbad text.
If no text has been provided, a lookup will be performed using the
abbreviated C<startype>.

  $long = $star->longstartype;
  $star->longstartype( "A variable star" );

See also C<longstartype> for the expanded version of this type.

=cut

sub longstartype {
  my $self = shift;
  if (@_) {
    $self->{LONGTYPE} = shift;
  }
  # if we have nothing, attempt a look up
  if (!defined $self->{LONGTYPE} && defined $self->startype
     && exists $STAR_TYPE_LOOKUP{$self->startype}) {
    return $STAR_TYPE_LOOKUP{$self->startype};
  } else {
    return $self->{STARTYPE};
  }
}

=item B<moreinfo>

A link (URL) to more information on the star in question. For example
this might provide a direct link to the full Simbad description.

  $url = $star->moreinfo;

=cut

sub moreinfo {
  my $self = shift;
  if (@_) {
    $self->{MOREINFO} = shift;
  }
  return $self->{MOREINFO};
}

=item B<insertdate>

The time the information for the star in question was gathered. This
is different from the time of observation of the star.

  $insertdate = $star->insertdate;

This is a C<Time::Piece> object.

=cut

sub insertdate {
  my $self = shift;
  if( @_ ) {
    $self->{INSERTDATE} = shift;
  }
  return $self->{INSERTDATE};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $star->configure( %options );

Takes a hash as argument with the list of keywords.
The keys are not case-sensitive and map to accessor methods.

Note that RA and Dec keys are allowed. The values should be
sexagesimal.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return unless @_;

  # grab the argument list
  my %args = @_;

  # First check for duplicate keys (case insensitive) with different
  # values and store the unique lower-cased keys
  my %check;
  for my $key (keys %args) {
    my $lckey = lc($key);
    if (exists $check{$lckey} && $check{$lckey} ne $args{$key}) {
      warnings::warnif("Duplicated key in constructor [$lckey] with differing values ".
	" '$check{$lckey}' and '$args{$key}'\n");
    }
    $check{$lckey} = $args{$key};
  }

  # Now that we have lower cased keys we can look to see if we have
  # ra & dec as well as coords and also verify that they are actually
  # the same if we have them
  if (exists $check{coords} && (exists $check{ra} || exists $check{dec})) {
    # coords + one of ra or dec is a mistake
    if (exists $check{ra} && exists $check{dec}) {
      # Create a new coords object - assume J2000
      my $c = new Astro::Coords( type => 'J2000',
				 ra => $check{ra},
				 dec => $check{dec},
#				 units => 'sex',
			       );

      # Make sure we have the same reference place and time
      $c->datetime( $check{coords}->datetime ) 
	if $check{coords}->has_datetime;
      $c->telescope( $check{coords}->telescope ) 
	if defined $check{coords}->telescope;


      # Check the distance
      my $d = $c->distance( $check{coords} );

      # Raise warn if the error is more than 1 arcsecond
      my $arcsec = $d * DR2AS;
      warnings::warnif( "Coords and RA/Dec were specified and they differ by more than 1 arcsec [$arcsec sec]. Ignoring RA/Dec keys.\n")
	if $arcsec > 1;

    } elsif (!exists $check{ra}) {
      warnings::warnif("Dec specified in addition to Coords but without RA. Ignoring it.");
    } elsif (!exists $check{dec}) {
      warnings::warnif("RA specified in addition to Coords but without Dec. Ignoring it.");
    }

    # Whatever happens we do not want ra and dec here
    delete $check{dec};
    delete $check{ra};
  } elsif (exists $check{ra} || $check{dec}) {
    # Generate a Astro::Coords object here in one go rather than
    # relying on the old ra() dec() methods individually
    my $ra = $check{ra} || 0.0;
    my $dec = $check{dec} || 0.0;
    $check{coords} = new Astro::Coords( type => 'J2000',
					ra => $ra,
					dec => $dec );
    delete $check{ra};
    delete $check{dec};
  }

  # Loop over the allowed keys storing the values
  # in the object if they exist. Case insensitive.
  for my $key (keys %check) {
    my $method = lc($key);
    $self->$method( $check{$key} ) if $self->can( $method );
  }
  return;
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modification are Copyright (C) 2003 Particle Physics and
Astronomy Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.


=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;

