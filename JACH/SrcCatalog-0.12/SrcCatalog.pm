package SrcCatalog;

=head1 NAME

SrcCatalog - base class for creating catalog objects.

=head1 DESCRIPTION

SrcCatalog is a base class used for manipulating groups of 
target positions.

=cut

# base class for creating catalog objects.
use 5.006;
use Carp;
use strict;
use warnings;
use vars qw/$VERSION $DEBUG/;

use Time::Piece qw/:override/;
use Astro::Coords;

$DEBUG = 0;
$VERSION = '0.12';

=head1 PUBLIC METHODS

These are the methods availabe in this class:

=over 4

=item new

Creates an instance of the SrcCatalog base class and initializes the
arrays of Source objects used to keep inventory of the sources stored
in a catalog

   $src = new SrcCatalog();
   $src = new SrcCatalog(@args);

The type of argument depends on the subclass. The initialization method
is only invoked if an argument is supplied to the constructor.

Base class accepts an array of Astro::Coords objects.

=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		    sources => [],
		    current => [],
		    file    => undef,
		    isObservable => 0,
		    RefPos => undef,
		    RefTime => undef,
		   };
	bless $self, $class;
	if(@_)
	{
		$self->_init(@_);
	}
	return $self;
}

=item sources

Sets and returns the value(s) for a source object, specified by a
passed index value.

  $allsources = $src->sources();
  $source = $src->sources($index);

Can also be used to replace the source at a specific index:

  $src->sources($index, $coords);

=cut

sub sources
{
	my $self = shift;
	if(@_)
	{
		my $index = shift;
		if(@_)
		{
			$self->{sources}->[$index] = shift;
		}
		return $self->{sources}->[$index];
	}
	return $self->{sources};
}

=item current

Sets and returns the value(s) indexed for the current sources
resulting from searches or sorting.

  $value = $src->current();
  $value = $src->current($index);

Can also be used to replace the source at a specific index:

  $src->sources($index, $coords);

The contents of this array are synchronized with those contained in
sources() when the reset() method is invoked.

=cut

sub current
{
	my $self = shift;
	if(@_)
	{
		my $index = shift;
		if(@_)
		{
			$self->{current}->[$index] = shift;
		}
		return $self->{current}->[$index];
	}
	return $self->{current};
}

=item file

Sets and returns the filename for the catalog.

  $name = $src->file();
  $name = $src->file('filename');

=cut

sub file
{
	my $self = shift;
	if(@_)
	{
		$self->{file} = shift;
	}
	return $self->{file};
}

=item reference

If set this must contain an Astro::Coords object that can be
used as a reference position. When a reference is supplied
a distance will be calculated from each catalog target to the
reference. It will also be possible to sort by distance.

=cut

sub reference {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Astro::Coords")) {
        $self->{RefPos} = $val;
      } else {
        croak "Must supply reference as a Astro::Coords object";
      }
    } else {
      $self->{RefPos} = undef;
    }
  }
  return $self->{RefPos};
}

=item reftime

The reference time used for coordinate calculations. Extracted
from the reference coordinate object if one exists and no override
has been specified. If neither a default setting has been made
and no reference exists the current time is returned.

  $reftime = $src->reftime();

  $src->reftime( $newtime );

=cut

sub reftime {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Time::Piece")) {
        $self->{RefTime} = $val;
      } else {
        croak "Must supply start time with a Time::Piece object";
      }
    } else {
      $self->{RefTime} = undef;
    }
  }

  # if we have no default ask for a coordinate object
  my $retval = $self->{RefTime};

  if (!$retval) {
    my $ref = $self->reference;
    if ($ref) {
      # retrieve it from the coordinate object
      $retval = $ref->datetime;
    } else {
      # else we just say "now"
      $retval = gmtime();
    }
  }
  return $retval;
}

=item canObserve

Governs whether the source list will only contain observable
sources. If true reset() only returns observable targets,
if false returns all targets in sources() when the object is reset.

  $name = $src->canObserve();
  $name = $src->canObserve(1);

Default is false. If canObserve is set the object must still be
reset for this to take effect.

=cut

sub canObserve
{
	my $self = shift;
	if(@_)
	{
		$self->{isObservable} = shift;
	}
	return $self->{isObservable};
}


=item reset

Sets all the values held in the current selection to the original
selection

  $current = $src->reset();

If canObserve is true, only those targets that are observable are
copied into current (assumes that the current state of the coordinate
objects is correct but will use the reference time returned by C<reftime>).

=cut

sub reset
{
  my $self = shift;
  my @copy = @{$self->sources};
  if ($self->canObserve) {
    $self->forceRefTime;
    my $reftime = $self->reftime;
    @copy = grep { $_->isObservable } @copy;
  }
  @{$self->{current}} = @copy;
  return $self->{current};
}

=item _init

Base class routine to initialise the object. Simply passes 
an array of Astro::Coords objects (either as a list or as
a reference) to the C<sources> method.

  $src->_init( @source );
  $src->_init( \@sources );

=cut

sub _init
{
  my $self = shift;

  # Argument must be a reference
  croak "Must supply either an Astro::Coords object or array reference to object initialisation routine" unless ref($_[0]);

  my @sources;

  if (UNIVERSAL::isa($_[0], "Astro::Coords")) {
    # coordinate objects
    @sources = @_;
  } elsif (ref($_[0]) eq 'ARRAY') {
    # reference to array of coordinate objects?
    @sources = @{ $_[0] };
  } else {
    # reference but we do not know what it is
    croak "Object initialisation routine could not recognize supplied reference";
  }

  # Add the sources. We can probably assume an empty source list
  # but play it safe
  @{$self->sources} = ();
  $self->addSources( @sources );

  return;
}

=item addSources

Add the supplied sources to the existing source list and
reset the list order and contents.

  $src->addSources( @sources );

The sources must be Astro::Coords objects.

=cut

sub addSources {
  my $self = shift;

  # Check the elements to make sure they are correct type
  for my $src (@_) {
    if (!UNIVERSAL::isa($src, "Astro::Coords")) {
      croak "Must supply catalog with Astro::Coords objects";
    }
  }

  push(@{$self->sources}, @_);
  $self->reset;
}


=item forceRefTime

Force the reference time into every (current) coordinate object

  $src->forceRefTime;

=cut

sub forceRefTime {
  my $self = shift;
  my $reftime = $self->reftime;
  for my $c (@{$self->current}) {
    $c->datetime( $reftime );
  }
}

=item searchByName

Retrieve all sources in the catalog that contain the specified
substring in their target name.

 @sources = $src->searchByName( $substring );

The search is case insensitive.

=cut

sub searchByName {
  my $self = shift;
  my $string = uc(shift);

  my @results;
  for my $src (@{$self->current}) {
    my $name = $src->name;
    next unless defined $name;
    $name = uc($name);
    push(@results, $src) if $name =~ /$string/;
  }

  $self->{current} = \@results;
  return @results;
}

=item findByArea

Retrieve all targets that are within the specified distance of the
supplied coordinate.

  @sources = $src->findByArea( $coord, $radius );

Where the coordinates of the reference point are supplied as an
Astro::Coords object and the radius is in radians (on the tangent
plane) [use Astro::SLA::DAS2R to convert arcseconds to radians]

The reference coordinate will be stored in the object using the
C<reference> method. If only one argument is supplied the internal
"reference" position will be used as a reference.

All calculations are done for the time stored in the reference
coordinate object (so it will work for both normal catalog sources and
"moving" targets). It is clear that the routine would be a lot faster
if an assumption could be made that all coordinate objects were in
fact equatorial coordinates.

Main problem associated with this approach (other than speed) is that
we can not tell whether the date object retrieved from each of the
catalog sources should be restored on exit or whether it was created
dynamically. For now assume we can muck around with the time in the
object without having to take a copy of the object.

=cut

sub findByArea {
  my $self = shift;
  my ($ref,$rad, $reftime);
  if (scalar(@_) == 2) {
    $ref = shift;
    $rad = shift;
    $reftime = $ref->datetime;
  } elsif (scalar(@_) == 1) {
    $rad = shift;
    $ref = $self->reference;
    $reftime = $self->reftime;
    croak "Only one arg supplied to findByArea by no reference position specified in object";
  } else {
    croak "Must supply 1 or 2 arguments to findByArea";
  }

  print $ref->status if $DEBUG;

  my @results;
  for my $src (@{$self->current}) {
    $src->datetime( $reftime );
    my $dist = $ref->distance( $src );
    print $src->name , " - ", ($dist ? $dist : "too far"),"\n" if $DEBUG;
    next unless defined $dist;
    push(@results, $src) if $dist < $rad;
  }
  $self->{current} = \@results;
  return @results;
}


=item searchFor

This method searches for sources that match the information
passed in the form of a hash with keys "name", "ra" and "dec".

  @results = $src->searchFor(%request);

For each key present in the request a full match to the value in the
catalog version is required. For example, if only a name is present
then a full (case insensitive) search for that name will be made (not
a substring search, for that see C<searchByName>). If name and ra are
present both must match but dec can be free. RA and Dec must be
supplied as colon separated strings.

Decimal places in coordinate strings are ignored so long as decimal
places are not used in the reference coordinate.

A coordinate match is probably better achieved using C<findByArea>.

=cut

sub searchFor 
{
  # This method is historical
  my $self = shift;
  my %info = @_;
  my @rSources = ();
  my $source;
  my $i;

  # set the info name
  my $iname = $info{name};
  $iname = '' unless defined $iname;
  $iname = uc($iname);

  # set the info Ra
  my $iRa = $info{ra};
  $iRa = '' unless defined $iRa;
  my $RaDecimal = ($iRa =~ /\./);
  my @iraParts = split (/:/, $iRa);

  # set the info Dec
  my $iDec = $info{dec};
  $iDec = '' unless defined $iDec;
  my $idecNeg = ($iDec =~ /\-/);
  my $DecDecimal = ($iDec =~ /\./);
  my @idecParts = split (/:/, $iDec);

  foreach $source (@{$self->current}) {
    my $passed = 1;

    # check the name
    if ($iname ne '') {
      my $name = $source->name;
      $name = '' unless defined $name;
      $name = uc($name);
      print "checking names  $iname   vs   $name" if $DEBUG;
      if ($name ne $iname) {
	print "...Did not match ...\n" if $DEBUG;
	$passed = 0;
      } else {
	print "\n" if $DEBUG;
      }
    }

    # check the Ra
    if ($iRa ne '') {
      # only support "normal" coordinates
      if ($source->can('ra')) {
	my $Ra = $source->ra(format => 'sexagesimal');
	$Ra =~ s/\..*// if !$RaDecimal;
	print "checking ra  $iRa   vs   $Ra\n" if $DEBUG;
	my @raParts = split (/:/, $Ra);
	$i = 0;
	foreach (@iraParts) {
	  print "     checking $_ vs $raParts[$i]\n" if $DEBUG;
	  if ($_ != $raParts[$i]) {
	    $passed = 0;
	  }
	  $i++;
	}
      } else {
	$passed = 0;
      }
    }

    # check the Dec
    if ($iDec ne '') {
      if ($source->can("dec")) {
	my $Dec = $source->dec(format => 'sexagesimal');
	my $decNeg = ($Dec =~ /\-/);
	if ($decNeg != $idecNeg) {
	  $passed = 0;
	} else {
	  $Dec =~ s/\..*// if !$DecDecimal;
	  print "checking dec  $iDec   vs   $Dec\n" if $DEBUG;
	  my @decParts = split (/:/, $Dec);
	  $i = 0;
	  foreach (@idecParts) {
	    print "     checking $_ vs $decParts[$i]\n" if $DEBUG;
	    if ($_ != $decParts[$i]) {
	      $passed = 0;
	    }
	    $i++;
	  }
	}
      } else {
	$passed = 0;
      }
    }

    # is it ok to add?
    if ($passed) {
      push (@rSources, $source);
    }
  }
  $self->{current} = \@rSources;

  return @rSources;
}


=item sortList

Sorts the current list of sources by name, ra, dec, az and el or unsorted.

  $src->sortList();
  $src->sortList($mode);

If a reference position is supplied an additional option
of "distance" is available.

Elevation sorts are such that the highest elevation sources are at
the top of the list.

=cut

sub sortList
{
	my $self = shift;
	my $sort = shift;
 	my @rSources;	

	# shortcut unsorted since that is strictly a reset at the moment
	if ($sort =~ /unsort/) {
	  $self->reset;
	  return;
	}

	# Need to force the reference time into them all
	$self->forceRefTime;

	# see if we have a reference object
	my $ref = $self->reference;

	# to try to speed up all the queries, rather than
	# calculating the dynamic values during the sort we should
	# do it outside the sort. Create an array of hashes for the
	# sorting
	my @unsorted = map {
	  my %calc = (
		      object => $_,
		      ra => $_->ra_app,
		      dec => $_->dec_app,
		      az => $_->az,
		      el => $_->el,
		      name => $_->name,
		      );
	  if ($ref) {
	    $calc{distance} = $ref->distance( $_ );
	    $calc{distance} = "Inf" unless defined $calc{distance};
	  }
	  \%calc;
	} @{$self->current};

	# Now do the search
	if ($sort =~ /name/) {
	  @rSources = sort  by_name @unsorted;
	} elsif ($sort =~ /ra/) {
	  @rSources = sort by_ra @unsorted;
	} elsif ($sort =~ /dec/) {
	  @rSources = sort by_dec @unsorted;
	} elsif ($sort =~ /az/) {
	  @rSources = sort { $a->{az} <=> $b->{az} } @unsorted;
	} elsif ($sort =~ /el/) {
	  # reverse sort
	  @rSources = sort { $b->{el} <=> $a->{el} } @unsorted;
	} elsif ($sort =~ /dist/) {
	  @rSources = sort by_dist @unsorted;
	} else {
	  croak "Unknown sort type: $sort";
	}

	# extract the objects
	@rSources = map { $_->{object} } @rSources;

	# Set the object to the result
	$self->{current} = \@rSources;
}

=item by_name

Internal routine to sort the entries in a source catalog by name.

  sort by_name @sources;

Returns -1,0,1

=cut

############################################################
# Sort by name routine
sub by_name
{
  my $b2 = $b->{name};
  my $a2 = $a->{name};

  # only compare if the name is defined and has length
  if (defined $a2 && defined $b2 &&
     length($a2) > 0 && length($b2) > 0) {
    $a2 = uc($a2);
    $b2 = uc($b2);
  } else {
    return -1;
  }

  ($a2 cmp $b2);
}

=item by_ra

Internal routine to sort the entries in a source catalog by RA
(actually sorts by apparent RA).

  sort by_ra @sources;

Returns -1,0,1

=cut

############################################################
# Sort by name routine
sub by_ra
{
  return $a->{ra} <=> $b->{ra};
}

=item by_dec

Internal routine to sort the entries in a source catalog by Dec.
(actually uses apparent Dec)

  sort by_dec @sources;

Returns -1,0,1

=cut

############################################################
# Sort by name routine
sub by_dec
{
  return $a->{dec} <=> $b->{dec};
}

=item by_dist

Sorts by distance from a reference position.

"Inf" is handled as being a long way off even though it is included
in the search results.

=cut


sub by_dist {
  my $a2 = $a->{distance};
  my $b2 = $b->{distance};

  # need to trap for Inf
  if ($a2 eq 'Inf' && $b2 eq 'Inf') {
    # they are the same
    return 0;
  } elsif ($a2 eq 'Inf') {
    # A is larger than B
    return 1;
  } elsif ($b2 eq 'Inf') {
    return -1;
  }

  $a2 <=> $b2;
}

=back

=head1 COPYRIGHT

Copyright (C) 1999-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Major subroutines originally designed by Casey Best (University of
Victoria) with modifications to create a module suitable for use with
Tk::SrcCatalog by Tim Jenness and Pam Shimek (University of Victoria).

Rewrite to use C<Astro::Coords> by Tim Jenness.

=cut

