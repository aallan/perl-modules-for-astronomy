package Astro::Catalog::Query;

=head1 NAME

Astro::Catalog::Query - Base class for Astro::Catalog query objects

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::Query /;

=head1 DESCRIPTION

This class forms a base class for all the query classes provided
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::GSC::Query>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;
'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.2 2003/07/30 00:23:39 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $q = new Astro::Catalog::Query( Coords    => new Astro::Coords(),
				  Radius    => $radius,
				  Bright    => $magbright,
				  Faint     => $magfaint,
				  Sort      => $sort_type,
				  Number    => $number_out );

returns a reference to an query object. Must only called from
sub-classed constructors.

RA and Dec are also allowed but are deprecated (since with only
RA/Dec the coordinates must always be supplied as J2000 space-separated
sexagesimal format).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      BUFFER    => undef }, $class;

  # Configure the object [even if there are no args]
  $block->configure( @_ );

  return $block;

}

=back

=head2 Accessor Methods

=over 4

=item B<query_options>

Hash representing the query options to be used to query the catalog
server. This keys in this hash are restricted by the subclass. Some
keys are not usable by all catalogues.

Returns a copy of the options hash when.

  %options = $q->query_options();

Note that the hash keys included here are not necessarily the keys
used to form a remote query.

If an argument is supplied, the value for that option is returned
I<if> the option is supported.

  $ra = $q->query_options( "ra" );

Values can not  be set directly. Please use the provided accessor methods.

=cut

sub query_options {
  my $self = shift;
  if (@_) {
    my $opt = lc(shift);
    my %allow = $self->_get_allowed_options;

    #print "\$opt = $opt\n";
    #print "\$allow{\$opt} = $allow{$opt}\n";
    if (!exists $allow{$opt}) {
      warnings::warnif("Option $opt not supported by this cataloge");
      return;
    }
    return $self->{OPTIONS}->{$opt};
  }
  return %{ $self->{OPTIONS} };
}


=item B<RA>

Return (or set) the current target R.A. defined for the query

   $ra = $usno->ra();
   $usno->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) {
    # grab the new R.A.
    my $ra = shift;
    $self->_set_query_options( ra => $ra );
  }
  # Return it
  return $self->query_options("ra");
}

=item B<Dec>

Return (or set) the current target Declination defined for the query

   $dec = $q->dec();
   $q->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec {
  my $self = shift;

  # SETTING DEC
  if (@_) {
    # grab the new Dec
    my $dec = shift;
    $self->_set_query_options( dec => $dec );
  }

  return $self->query_options("dec");
}


=item B<Target>

Instead of querying by R.A. and Dec., you may also query it
by object name. Return (or set) the current target object defined for
the USNO-A2.0 query, will query SIMBAD for object name resolution.

   $ident = $usno->target();
   $usno->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
using this identifier rather than any currently set co-ordinates.

=cut

sub target {
  my $self = shift;

  # SETTING IDENTIFIER
  if (@_) { 

    # grab the new object name
    my $ident = shift;

    # mutilate it and stuff it into ${$self->{OPTIONS}}{object}
    $ident =~ s/\s/\+/g;
    $self->_set_query_options(
			      object => $ident,
			      dec => undef,
			      ra => undef,
			     );
  }
  return $self->query_options("object");
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
    $self->_set_query_options( radmax => shift );
  }

  return $self->query_options("radmax");
}

=item B<Faint>

Set (or query) the faint magnitude limit for inclusion on the results

   $faint = $query->faint();
   $query->faint( 50 );

=cut

sub faint {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( magfaint => shift );
  }

  return $self->query_options("magfaint");
}

=item B<Bright>

Set (or query) the bright magnitude limit for inclusion on the results

   $faint = $query->bright();
   $query->bright( 2 );

=cut

sub bright {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( magbright => shift );
  }

  return $self->query_options("magbright");
}

=item B<Sort>

Set or query the order in which the stars are listed in the catalogue

   $sort = $query->sort();
   $query->sort( 'RA' );

valid options are RA, DEC, RMAG, BMAG, DIST (distance to centre of the 
requested field) and POS (the position angle to the centre of the field).  

=cut

sub sort {
  my $self = shift;

  if (@_) {

    my $option = shift;
    my $sort;
    # pick an option
    if( $option eq "RA" ) {
      # sort by RA
      $sort = "ra";
    } elsif ( $option eq "DEC" ) {
      # sort by Dec
      $sort = "dec";
    } elsif ( $option eq "RMAG" ) {
      # sort by R magnitude
      $sort = "mr";
    } elsif ( $option eq "BMAG" ) {
      # sort by B magnitude
      $sort = "mb";
    } elsif ( $option eq "DIST" ) {
      # sort by distance from field centre
      $sort = "d";
    } elsif ( $option eq "POS" ) {
      # sort by position angle to field centre
      $sort = "pos";
    } else {
      # in case there are no valid options sort by RA
      warnings::warnif("Unknown sort type: using ra");
      $sort = "ra";
    }
    $self->_set_query_options( sort => $sort );
  }

  # return the sort option
  return $self->query_options("sort");

}

=item B<Number>

The number of objects to return, defaults to 2000 which should hopefully
be sufficent to return all objects of interest. This value should be increased
if a (very) large sample radius is requested.

   $num = $query->number();
   $query->nout( 100 );

=cut

sub number {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( nout => shift );
  }

  return $self->query_options("nout");
}

sub nout {
  my $self = shift;
  warnings::warnif("deprecated","The nout() method is deprecated. Please use number()");
  return $self->number( @_ );
}

=item B<multi>

Whether to return multiple identifications

   $multi = $query->multi();
   $query->multi( 'no' );

valid responses are 'yes' and 'no', the default is yes.

=cut

sub multi {
  my $self = shift;

  if (@_) { 
    $self->_set_query_options( multi => shift );
  }

  return $self->query_options("multi");
}



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

  # CONFIGURE DEFAULTS
  # ------------------

  # configure the default options
  $self->_set_default_options();


  # CONFIGURE FROM ARGUMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key ($self->_get_supported_init) {
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

=item B<_get_supported_init>

Return the list of initialization methods supported by this catalogue.
This is not the same as the allowed options since some methods are
not related to options and other methods that are related to options
use different names.

Returns a list. The default list is:

  RA Dec Target Radius Bright Faint Sort Number
  URL Timeout Proxy

=cut

sub _get_supported_init {
  return (qw/ RA Dec Target Radius Bright Faint Sort Number
                    URL Timeout Proxy /);
}


=item B<_set_query_options>

Set the query options.

  $q->_set_query_options( %newopt );

Keys are standardised and are not necessarily those used
in the query. A warning is issued if an attempt is made to
set an option for an option that is not used by the particular
subclass.

=cut

sub _set_query_options {
  my $self = shift;
  my %newopt = @_;

  my %allow = $self->_get_allowed_options();
  
  #foreach my $i ( sort keys %newopt ) {
  #   print "newopt $i = $newopt{$i} \n";
  #}  
    
  #foreach my $i ( sort keys %allow ) {
  #  print "allow  $i = $allow{$i} \n";
  #}   

  for my $newkey (keys %newopt) {
    if (!exists $allow{$newkey}) {
      warnings::warnif("Option $newkey not supported by catalog ".
		       ref($self)."\n");
      next;
    }
    # set the option
    $self->{OPTIONS}->{$newkey} = $newopt{$newkey};
  }
  return;
}

=item B<_set_default_options>

Each catalogue requires different default settings for the
URL parameters. They should be specified in a subclass.

=cut

sub _set_default_options {
  croak "default options are specified in subclass\n";
}

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last query made using querydb().

  @lines = $q->_dump_raw();

=cut

sub _dump_raw {
   my $self = shift;

   # split the BUFFER into an array
   my @portable = split( /\n/,$self->{BUFFER});
   chomp @portable;

   return @portable;
}

=item B<_set_raw>

Private function to fill the current buffer with a string. This is used
when deealing with the buffer cannot be encapsulated inside a Transport
class and must be deal with by child classese.

   $q->_set_raw( $buffer );
   
=cut

sub _set_raw {
   my $self = shift;
   $self->{BUFFER} = shift;
}   

=item B<_dump_options>

Private function for debugging and other testing purposes. It will return
the current query options as a hash.

=cut

sub _dump_options {
   my $self = shift;

   return $self->query_options;
}

=back

=head2 Translation Methods

The query options stored internally in the object are not necessarily
the form required for a query to a remote server. Methods for converting
from the internal representation to the external query format are
provided in the form of _from_$opt. ie:

  ($outkey, $outvalue) = $q->_from_ra();
  ($outkey, $outvalue) = $q->_from_object();

The base class only includes one to one mappings.

=cut

# RA and Dec replace spaces with pluses and + sign with special code

sub _from_ra {
  my $self = shift;
  my $ra = $self->query_options("ra");
  my %allow = $self->_get_allowed_options();

  # Must replace spaces with +
  $ra =~ s/\s/\+/g if defined $ra;

  return ($allow{ra},$ra);
}

sub _from_dec {
  my $self = shift;
  my $dec = $self->query_options("dec");
  my %allow = $self->_get_allowed_options();

  if (defined $dec) {
    # Must replace + with %2B
    $dec =~ s/\+/%2B/g;

    # Must replace spaces with +
    $dec =~ s/\s/\+/g;
  }

  return ($allow{dec},$dec);
}

# one to one mapping

sub _from_object {
  my $self = shift;
  my $key = "object";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_radmax {
  my $self = shift;
  my $key = "radmax";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_magfaint {
  my $self = shift;
  my $key = "magfaint";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_magbright {
  my $self = shift;
  my $key = "magbright";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_sort {
  my $self = shift;
  my $key = "sort";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_nout {
  my $self = shift;
  my $key = "nout";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

sub _from_format {
  my $self = shift;
  my $key = "format";
  my $value = $self->query_options($key);
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

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
