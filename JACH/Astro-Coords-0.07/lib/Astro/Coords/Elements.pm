package Astro::Coords::Elements;


=head1 NAME

Astro::Coords::Elements - Specify astronomical coordinates using orbital elements

=head1 SYNOPSIS

  $c = new Astro::Coords::Elements( elements => \%elements );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
specified as orbital elements.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

# Need working slaPlante
use Astro::SLA 0.95 ();
use Time::Piece qw/ :override /;

use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS


=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Elements( elements => \%elements );

Returns undef on error.

The elements must be specified in a hash containing the following
keys:

suitable for the major planets:

 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC          =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  longitude of perihelion  [$\varpi$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e 
 AORL 		 =  mean longitude L (radians)
 DM 		 =  daily motion n (radians)

suitable for minor planets:


 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e
 AORL 		 =  mean anomaly M (radians)

suitable for comets:


 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  perihelion distance q (AU)
 E 		 =  eccentricity e
 EPOCHPERIH      = epoch of perihelion T (TT MJD)

See the documentation to slaPlante() and slaPertel() for more information.
Keys must be upper case.

For comets if the only one epoch is specified it is assumed that the
epochs are identical. This may cause problems if the epochs are not
really close to each other.

In order to better match normal usage, EPOCH can also be specified
as a string of the form 'YYYY mmm D.frac' (e.g. '1997 Apr 1.567').
(no decimal place after the month).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts = @_;
  return undef unless (exists $opts{elements}
    && ref($opts{elements}) eq "HASH");

  # Sanity check
  for (qw/ ORBINC ANODE PERIH AORQ E/) {
    #return undef unless exists $opts{elements}->{$_};
    croak "Must supply element $_ to constructor"
      unless exists $opts{elements}->{$_};
  }

  # Fix up EPOCHs if it has been specified as a string
  for my $key (qw/ EPOCH EPOCHPERIH / ) {
    next unless exists $opts{elements}->{$key};
    my $epoch = $opts{elements}->{$key};

    # if we are missing one of the EPOCHs that is okay
    # so just skip
    if (! defined $epoch) {
      # and delete it from the hash as if it was never supplied
      # this avoids complications later
      delete $opts{elements}->{$key};
      next;
    }

    if ($epoch =~ /^\d+\.\d+$/ || $epoch =~ /^\d+$/) {
      # an MJD so do not modify
    } elsif ($epoch =~ /\d\d\d\d \w\w\w \d+\.\d+/) {
      # has letters in it so try to parse
      # Split on decimal point
      my ($date, $frac) = split(/\./,$epoch,2);
      $frac = "0.". $frac; # preserve as decimal fraction
      my $format = '%Y %B %d';
      #print "EPOCH : $epoch and $date and $frac\n";
      my $obj = Time::Piece->strptime($date, $format);
      my $tzoffset = $obj->tzoffset;
      $obj = gmtime($obj->epoch() + $tzoffset);

      # get the MJD and add on the fraction
      my $mjd = $obj->mjd() + $frac;
      $opts{elements}->{$key} = $mjd;
      #print "MJD: $mjd\n";

    } else {
      # do not understand the format so return undef
      warn "Unable to recognize format for elements $key [$epoch]";
      return undef;
    }
  }

  # but complain if we do not have one of them
  croak "Must supply one of EPOCH or EPOCHPERIH - both were undefined"
    if (!exists $opts{elements}->{EPOCH} &&
	!exists $opts{elements}->{EPOCHPERIH});

  # Copy the elements
  my %el = %{ $opts{elements}};

  bless { elements => \%el, name => $opts{name} }, $class;

}



=back

=head2 Accessor Methods

=over 4

=item B<elements>

Returns the hash containing the elements.

  %el = $c->elements;

=cut

sub elements {
  my $self = shift;
  return %{ $self->{elements}};
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the
string "ELEMENTS", the next two elements as undef and up to 8
following elements containing the orbital elements in the order
presented in the documentation of the constructor.

This method returns a standardised set of elements across all
types of coordinates.

Note that EPOCHPERIH is I<not> returned yet as a separate element.
If EPOCHPERIH is present it overrides the EPOCH of the elements.
This is not very accurate but is usually good enough to determine
whether the target is up.

=cut

sub array {
  my $self = shift;
  my %el = $self->elements;
  my $epoch = $el{EPOCHPERIH}; # use EPOCHPERIH preferentially
  $epoch = $el{EPOCH} unless $epoch;

  return ( $self->type, undef, undef,
	   $epoch, $el{ORBINC}, $el{ANODE}, $el{PERIH}, 
	   $el{AORQ}, $el{E}, $el{AORL}, $el{DM});
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "ELEMENTS";
}

=item B<stringify>

Stringify overload. Returns comma-separated list of 
the elements.

=cut

sub stringify {
  my $self = shift;
  my %el = $self->elements;
  my $str = join(",", map { (defined $_ ? $_ : 'UNDEF' ) } values %el);
  return $str;
}

=item B<summary>

Return a one line summary of the coordinates.
In the future will accept arguments to control output.

  $summary = $c->summary();

=cut

sub summary {
  my $self = shift;
  my $name = $self->name;
  $name = '' unless defined $name;
  return sprintf("%-16s  %-12s  %-11s ELEMENTS",$name,'','');
}

=item B<_apparent>

Return the apparent RA and Dec (in radians) for the current
coordinates and time. Includes perterbation corrections to convert
the elements to the required epoch.

Returns empty list on error.

=cut

sub _apparent {
  my $self = shift;
  my $tel = $self->telescope;
  my $long = (defined $tel ? $tel->long : 0.0 );
  my $lat = (defined $tel ? $tel->lat : 0.0 );
  my %el = $self->elements;
  my $jform;
  if (exists $el{DM} and defined $el{DM}) {
    # major planets
    $jform = 1;
  } elsif (exists $el{AORL} and defined $el{AORL}) {
    # minor planets
    $jform = 2;
    $el{DM} = 0;
  } else {
    # comets
    $jform = 3;
    $el{DM} = 0;
    $el{AORL} = 0;
  }

  # synch epoch if need be
  if (!exists $el{EPOCH} || !exists $el{EPOCHPERIH}) {
    if (exists $el{EPOCH}) {
      $el{EPOCHPERIH} = $el{EPOCH};
    } else {
      $el{EPOCH} = $el{EPOCHPERIH};
    }
  }

  # First have to perturb the elements to the current epoch
  # if we have a minor planet or comet
  if (1) {
  if ( $jform == 2 || $jform == 3) {
    # for now we do not have enough information for jform=3
    # so just assume the EPOCH is the same
    #use Data::Dumper;
    #print "Before perturbing: ". Dumper(\%el);
    #print "MJD ref : " . $self->_mjd_tt . " and jform = $jform\n";
    Astro::SLA::slaPertel($jform,$el{EPOCH},$self->_mjd_tt,
			  $el{EPOCHPERIH},$el{ORBINC},$el{ANODE},
			  $el{PERIH},$el{AORQ},$el{E},$el{AORL},
			  $el{EPOCH},$el{ORBINC}, $el{ANODE},
			  $el{PERIH},$el{AORQ},$el{E},$el{AORL},
			  my $jstat);
    #print "After perturbing: " .Dumper(\%el);
    croak "Error perturbing elements [status=$jstat]" if $jstat != 0;
  }
}

  # Print out the values
  #print "EPOCH:  $el{EPOCH}\n";
  #print "ORBINC: ". ($el{ORBINC}*Astro::SLA::DR2D) . "\n";
  #print "ANODE:  ". ($el{ANODE}*Astro::SLA::DR2D) . "\n";
  #print "PERIH : ". ($el{PERIH}*Astro::SLA::DR2D) . "\n";
  #print "AORQ:   $el{AORQ}\n";
  #print "E:      $el{E}\n";

  Astro::SLA::slaPlante($self->_mjd_tt, $long, $lat, $jform,
			$el{EPOCH}, $el{ORBINC}, $el{ANODE}, $el{PERIH}, 
			$el{AORQ}, $el{E}, $el{AORL}, $el{DM}, 
			my $ra, my $dec, my $dist, my $j);

  croak "Error determining apparent RA/Dec [status=$j]" if $j != 0;

  # Convert from observed to apparent place
  Astro::SLA::slaOap("r", $ra, $dec, $self->_mjd_tt, 0.0, $long, $lat, 
		     0.0,0.0,0.0,
		     0.0,0.0,0.0,0.0,0.0,$ra, $dec);

  return($ra, $dec);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 LINKS

Useful sources of orbital elements can be found at
http://ssd.jpl.nasa.gov and http://cfa-www.harvard.edu/iau/Ephemerides/

=head1 REQUIREMENTS

C<Astro::SLA> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
