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
#     $Id: Catalog.pm,v 1.27 2003/07/27 08:26:56 timj Exp $

#  Copyright:
#     Copyright (C) 2002 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Catalog - A generic API for stellar catalogues

=head1 SYNOPSIS

  $catalog = new Astro::Catalog( Stars   => \@array );
  $catalog = new Astro::Catalog( Format => 'Cluster', File => $file_name );
  $catalog = new Astro::Catalog( Format => 'JCMT', Data => $scalar );
  $catalog = new Astro::Catalog( Format => 'JCMT', Data => \*STDIN );
  $catalog = new Astro::Catalog( Format => 'JCMT', Data => \@lines );

=head1 DESCRIPTION

Stores generic meta-data about an astronomical catalogue. Takes a hash
with an array refernce as an argument. The array should contain a list
of Astro::Catalog::Star objects. Alternatively it takes a catalog
format and either the name of a catalogue file or a reference to a
scalar, glob or array.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;

use Astro::Coords;
use Astro::Catalog::Star;
use Time::Piece qw/ :override /;
use Carp;

'$Revision: 1.27 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Catalog.pm,v 1.27 2003/07/27 08:26:56 timj Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options 

  $catalog = new Astro::Catalog( Stars       => \@array );
  $catalog = new Astro::Catalog( Format => 'Cluster', File => $file_name );
  $catalog = new Astro::Catalog( Format => 'JCMT', Data => $scalar );

returns a reference to an C<Astro::Catalog> object. See C<configure> method
for list of allowed arguments.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { ALLSTARS  => [],
		      CURRENT   => undef, # undefined until we copy
		      ERRSTR => '',
		      ORIGIN => '<UNKNOWN>',
		      COORDS => undef,
                      RADIUS => undef,
		      REFPOS => undef,
		      REFTIME => undef,
		    }, $class;

  # If we have arguments configure the object
  # Note that configuration can result in a new object
  $block = $block->configure( @_ ) if @_;

  return $block;

}

# O U P T U T  ------------------------------------------------------------

=back

=head2 Output Methods

=over 4

=item B<write_catalog>

Will serialise the catalogue object in a variety of file formats using
pluggable IO, see the C<Astro::Catalog::IO> classes

   $catalog->write_catalog( 
          File => $file_name, Format => $file_type, [%opts] )
     or die $catalog->errstr;

returns zero on sucess and non-zero if the write failed (the reason
can be obtained using the C<errstr> method). The C<%opts> are optional
arguments and are dependant on the output format chosen.  Current
valid output formats are 'Cluster' and 'JCMT'.

=cut

sub write_catalog {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Go through hash and downcase all keys
  %args = _normalize_hash( %args );

  # unless we have a Filename forget it...
  my $file;
  unless( $args{file} ) {
     croak ( 'Usage: _write_catalog( File => $catalog, Format => $format');
  } else {
     $file = $args{file};
  }

  # default to cluster format if no filenames supplied
  $args{format} = 'Cluster' unless ( defined $args{format} );

  # Need to read the IO class
  my $ioclass = _load_io_plugin( $args{format} );
  return unless defined $ioclass;

  # remove the two handled hash options and pass the rest
  delete $args{file};
  delete $args{format};

  # call the io plugin's _write_catalog function
  my $lines = $ioclass->_write_catalog( $self, %args );

  # If file is a GLOB then we do not need to open or close it
  # Do we have a glob?
  my $isglob = ( ref($file) eq 'GLOB' ? 1 : 0 );

  # Open the output file (if we do not have a glob)
  my $fh;
  if ($isglob) {
    $fh = $file;
  } else {
    my $status = open $fh, ">$file";
    if (!$status) {
      $self->errstr(__PACKAGE__ .": Error creating catalog file $file: $!" );
      return;
    }
  }

  # Play it defensively - make sure we add the newlines
  chomp @$lines;

  # write to file
  print $fh join("\n", @$lines) ."\n";

  # close file if we opened it
  if (! $isglob) {
    my $status = close($fh);
    if (!$status) {
      $self->errstr(__PACKAGE__.": Error closing catalog file $file: $!");
      return;
    }
  }
  return 1;
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
  $origin = $catalog->origin();

=cut

sub origin {
  my $self = shift;
  if (@_) {
    $self->{ORIGIN} = shift;
  }
  return $self->{ORIGIN};
}

=item B<errstr>

Error string associated with any error. Can only be trusted immediately
after a call that sets it (eg write_catalog).

=cut

sub errstr {
  my $self = shift;
  if (@_) {
    $self->{ERRSTR} = shift;
  }
  return $self->{ERRSTR};
}

=item B<sizeof>

Return the number of stars in the catalogue (post filter).

   $num = $catalog->sizeof();

=cut

sub sizeof {
  my $self = shift;
  return scalar( @{$self->stars} );
}

=item B<sizeoffull>

Retursn the total number of stars in the catalogue without filtering.

=cut

sub sizeoffull {
  my $self = shift;
  return scalar( @{ $self->allstars} );
}

=item B<pushstar>

Push a new star (or stars) onto the end of the C<Astro::Catalog> object

   $catalog->pushstar( @stars );

returns the number of stars now in the Catalog object (even if no
arguments were supplied). The method guarantees that the stars are
pushed onto the internal original list and the filtered/sorted
version.

=cut

sub pushstar {
  my $self = shift;

  my $allref = $self->allstars;

  # push onto the original array
  push( @$allref, @_ );

  # And push onto the copy ONLY IF WE HAVE A COPY
  # We do not want to force a copy unnecsarily by using scalar context
  if ($self->_have_copy) {
    # push the new item onto the stack 
    my $ref = $self->stars;
    push( @$ref, @_);
  }
  return;
}

=item B<popstar>

Pop a star from the end of the C<Astro::Catalog> object. This forces
a copy of the array if one has not already been made (ie the original
version is unchanged).

   $star = $catalog->popstar();

the method deletes the star and returns the deleted C<Astro::Catalog::Star>
object.

=cut

sub popstar {
  my $self = shift;

  # pop the star out of the stack
  return pop( @{ $self->stars } );
}

=item B<popstarbyid>

Return C<Astro::Catalog::Star> objects that have the given ID. This forces
a copy of the array if one has not already been made (ie the original
version is unchanged).

  @stars = $catalog->popstarbyid( $id );

The method deletes the stars and returns the deleted C<Astro::Catalog::Star>
objects. If no star exists with the given ID, the method returns empty list.

If called in scalar context this method returns an array reference, and if
called in list context returns an array of C<Astro::Catalog::Star> objects.

This is effectively an inverse filter (see C<search_by_id> for complementary
method).

=cut

sub popstarbyid {
  my $self = shift;

  # Return undef if they didn't pass an ID.
  return () unless @_;

  my $id = shift;

  # This may need to be optimized because we traverse the array
  # twice and we generate a whole new array internally
  my @match = grep { $_->id == $id } @{ $self->stars };
  my @unmatched = grep { $_->id != $id } @{ $self->stars };

  @{ $self->stars } = \@unmatched;

  return ( wantarray ? @match : \@match );

}

=item B<allstars>

Return all the stars in the catalog in their original ordering and without
filtering.

  @allstars = $catalog->allstars();
  $ref = $catalog->allstars();

In list context returns all the stars, in scalar context returns a reference
to the internal array. This allows the primary array to be modified in place
so use this with care.

=cut

sub allstars {
  my $self = shift;
  return (wantarray ? @{ $self->{ALLSTARS} } : $self->{ALLSTARS} );
}

=item B<stars>

Return a list of all the C<Astro::Catalog::Star> objects that are currently
valid and in the current order. This method may well return different
stars to the C<allstars> method depending on the current sort in scope.

  @stars = $catalog->stars();

in list context the copy of the array is returned, while in scalar
context a reference to the array is return. In scalar context, the
referenced array will always be that of the current list of valid
stars. If the current list is empty the primary list will be copied
into the current array so that it can be modified independently of the
original list. This may cost you a lot of memory. Note that changes to
the array ordering or content may be lost in this case whenever the
C<reset_list> method is used.

=cut

sub stars {
  my $self = shift;

  # If we have a defined CURRENT array we just do whatever is needed
  return ( wantarray ? @{ $self->{CURRENT} } : $self->{CURRENT} )
    if $self->_have_copy;

  # If we are in list context we do not want to force a copy if
  # we have never copied. Just return the original list.
  # By this point we know that CURRENT is not defined
  if (wantarray) {
    return $self->allstars;
  } else {
    # scalar context so we are forced to copy the array from allstars
    @{ $self->{CURRENT} } = $self->allstars;
    return $self->{CURRENT};
  }

}


=item B<starbyindex>

Return the C<Astro::Catalog::Star> object at index $index

   $star = $catalog->starbyindex( $index );

the first star is at index 0 (not 1). Returns undef if no arguments
are provided.

=cut

sub starbyindex {
  my $self = shift;

  # return unless we have arguments
  return () unless @_;

  my $index = shift;

  return $self->stars->[$index];
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

  # grab the argument list and normalize hash
  my %args = _normalize_hash( @_ );

  if (defined $args{coords}) {
    $self->set_coords($args{coords});
  } elsif ( defined $args{ra} && defined $args{dec}) {
    my $c = new Astro::Coords( type => 'J2000',
			       ra => $args{ra},
			       dec => $args{dec},
			     );
    $self->set_coords($c);
  }

  # set field radius
  if ( defined $args{radius} ) {
     $self->set_radius($args{radius});
  }

}

=item B<set_radius>

Set the field centre radius. Must be in arcminutes.

  $catalog->set_radius( $radius );

=cut

sub set_radius {
  my $self = shift;
  my $r = shift;
  $self->{RADIUS} = $r;
  return;
}

=item B<set_coords>

Set the field centre coordinates with an C<Astro::Coords> object.

  $catalog->set_coords( $c );

=cut

sub set_coords {
  my $self = shift;
  my $c = shift;
  croak "Coords must be an Astro::Coords"
    unless UNIVERSAL::isa($c, "Astro::Coords");
  $self->{COORDS} = $c;
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

=item reference

If set this must contain an C<Astro::Coords> object that can be
used as a reference position. When a reference is supplied
distances will be calculated from each catalog target to the
reference. It will also be possible to sort by distance.

 $ref = $catalog->reference;
 $catalog->reference( $c );

If a reference position is not specified explicitly the field
centre will be used instead (if defined).

=cut

sub reference {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Astro::Coords")) {
        $self->{REFPOS} = $val;
      } else {
        croak "Must supply reference as a Astro::Coords object";
      }
    } else {
      $self->{REFPOS} = undef;
    }
  }

  # default to field centre
  return (defined $self->{REFPOS} ? $self->{REFPOS} : $self->get_coords );
}

=item reftime

The reference time used for coordinate calculations. Extracted
from the reference coordinate object if one exists and no override
has been specified. If neither a default setting has been made
and no reference exists the current time is returned.

  $reftime = $src->reftime();

  $src->reftime( $newtime );

Time must be a C<Time::Piece> object. This is only really important
for moving objects such as planets or asteroids or for occasions when
you are calcualting azimuth or elevation.

=cut

sub reftime {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Time::Piece")) {
        $self->{REFTIME} = $val;
      } else {
        croak "Must supply start time with a Time::Piece object";
      }
    } else {
      $self->{REFTIME} = undef;
    }
  }

  # if we have no default ask for a coordinate object
  my $retval = $self->{REFTIME};

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



# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $catalog->configure( %options );

Takes a hash as argument with the list of keywords. Supported options
are:

  Format => Format of supplied catalog
  File => File name for catalog on disk. Not used if 'Data' supplied.
  Data => Contents of catalogue, either as a scalar variable,
          reference to array of lines or reference to glob (file handle).
          This key is used in preference to 'File' if both are present

  Stars => Array of Astro::Catalog::Star objects. Supercedes all other options.

If Format is supplied without any other options, a default file is requested
from the class implementing the formatted read. If no default file is
forthcoming the method croaks.

If no options are specified the method does nothing, assumes you will
be supplying stars at a later time.

The options are case-insensitive.

Note that in some cases (when reading a catalogue) this method will
act as a constructor. In any case, always returns a catalog object
(either the same one that went in or a modified one).

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return $self unless @_;

  # grab the argument list
  my %args = @_;

  # Go through hash and downcase all keys
  %args = _normalize_hash( %args );

  # Check for deprecation
  if ( exists $args{cluster} ) {
    warnings::warnif("deprecated", 
     "Cluster option now deprecated. Use Format=>'Cluster',File=>file instead");
    $args{file} = $args{cluster};
    $args{format} = 'Cluster';
  }

  # Define the actual catalogue
  # ---------------------------

  # Stars has priority
  if ( defined $args{stars} ) {

    # grab the array reference and stuff it into the object
    $self->pushstar( @{ $args{stars} } );

    # Make sure we do not loop over this later
    delete( $args{stars} );

  } elsif ( defined $args{format} ) {

    # Need to read the IO class
    my $ioclass = _load_io_plugin( $args{format} );
    return unless defined $ioclass;

    # Lines for the content
    my @lines;

    # Now need to either look for some data or read a file
    if ( defined $args{data}) {

      # Need to extract the data from this and convert to array
      if (not ref($args{data})) {
	# must be a scalar
	@lines = split /\n/, $args{data};
      } else {
	if (ref($args{data}) eq 'GLOB') {
	  # A file handle
	  local $/ = "\n";
	  # For some reason <$args{data}> does not do the right thing
	  my $fh = $args{data};
	  @lines = <$fh>;
	} elsif (ref($args{data}) eq 'ARRAY') {
	  # An array of lines
	  @lines = @{ $args{data} };
	} else {
	  # Who knows
	  croak "Can not extract catalog information from scalar of type ".
	    ref($args{data}) ."\n";
	}
      }

    } else {
      # Look for a filename or the default file
      my $file;
      if ( defined $args{file} ) {
	$file = $args{file};
      } else {
	# Need to ask for the default file
	$file = $ioclass->_default_file()
	  if $ioclass->can( '_default_file' );
	croak "Unable to read catalogue since no file specified and ".
	  "no default known." unless defined $file;
      }

      # Open the file
      my $CAT;
      croak("Astro::Catalog - Cannot open catalogue file $file: $!")
	unless open( $CAT, "< $file" );

      # read from file
      local $/ = "\n";
      @lines = <$CAT>;
      close($CAT);

    }

    # remove new lines
    chomp @lines;

    # Now read the catalog (overwriting $self)
    $self =  $ioclass->_read_catalog( \@lines );

    # Remove used args
    delete $args{format};
    delete $args{file};
    delete $args{data};
	
  }

  # Define the field centre if provided
  # -----------------------------------
  $self->fieldcentre( %args );

  # Remove field centre args
  delete $args{ra};
  delete $args{dec};
  delete $args{coords};


  # Loop over any remaining args
  for my $key ( keys %args ) {
    my $method = lc($key);
    $self->$method( $args{$key} ) if $self->can($method);
  }

  return $self;
}

=item B<reset_list>

Forces the star list to return to the original unsorted, unfiltered catalogue
list.

  $catalog->reset_list();

=cut

sub reset_list {
  my $self = shift;

  # Simply need to clear the CURRENT
  $self->{CURRENT} = undef;

}

=item B<force_ref_time>

Force the specified reference time into the coordinate object
associated with each star (in the current list). This ensures that
calculations on the catalogue entries are all calculated for the same
time.

 $catalog->force_ref_time();

After this, the times in the coordinate objects will be set and will
no longer reflect current time (if they had it originally).

=cut

sub force_ref_time {
  my $self = shift;
  my $reftime = $self->reftime;
  for my $star (@{$self->stars}) {
    my $c = $star->coords;
    next unless defined $c;

    # Force the time (since we can not tell if the ref time is the
    # current time then we can not know whether we need to override
    # the coords objects or not
    $c->datetime( $reftime );
  }
}


=back

=head2 Filters

All these filters work on a copy of the full star list. The filters are
cumulative.

=over 4

=item B<filter_by_observability>

Generate a filtered catalogue where only those targets that are
observable are present (assumes that the current state of the
coordinate objects is correct but will use the reference time returned
by C<reftime>).  ie the object is returned to its original state and
then immediately filtered by observability. Any stars without
coordinates are also filtered.  Starts from the current star list
(which may already have been filtered).

  @new = $catalog->filter_by_observability();

Returns the newly selected stars (as if the C<stars> method was called
immediately.

=cut

sub filter_by_observability {
  my $self = shift;

  $self->forceRefTime;
  my $ref = $self->stars;

  # For each star, extract the coordinate object and, if defined
  # check for observability
  @$ref = grep { $_->coords->isObservable } grep { $_->coords; } @$ref;
  return $self->stars;
}

=item B<filter_by_id>

Given a source name filter the source list such that the
star ID matches the supplied name.

  @stars = $catalog->filter_by_id( "IRAS" );

This is just a convenient alternative to C<filter_by_cb>.
There is no convenient wrapper for pattern matches. Just use:

  @stars = $catalog->filter_by_cb( sub { $_[0] =~ /^IRAS/; } );

The match is case sensitive.

=cut

sub filter_by_id {
  my $self = shift;
  my $id = shift;

  return $self->filter_by_cb( sub { $_[0] == $id } );
}

=item B<filter_by_distance>

Retrieve all targets that are within the specified distance of the
reference position. 

  @selected = $catalog->filter_by_distance( $radius, $refpos );

The radius is in radians. The reference position defaults to
the value returned by the C<reference> method if none supplied.

API uncertainty:

  - Should the radius default to the get_radius() method?
  - Should this method take hash arguments?
  - Should there be a units argument? (radians, arcmin, arcsec, degrees)

=cut

sub filter_by_distance {
  my $self = shift;
  croak "Must be at least one argument"
    unless scalar(@_) > 0;

  # Read the arguments
  my $radius = shift;
  my $refpos = shift;
  $refpos = $self->reference if not defined $refpos;

  croak "Reference position not defined"
    if not defined $refpos;

  # Calculate distance and throw away outliers
  return $self->filter_by_cb( sub {
				my $star = shift;
				my $c = $star->coords;
				return if not defined $c;
				my $dist = $refpos->distance( $c );
				return if not defined $dist;
				return $dist < $radius;
			      } );
}

=item B<filter_by_cb>

Filter the star list using the given the supplied callback (reference
to a subroutine). The callback should expect a star object and should
return a boolean.

  @selected = $catalog->filter_by_cb( sub { $_[0]->id == "HLTau" } );
  @selected = $catalog->filter_by_cb( sub { $_[0] =~ /^IRAS/; } );

=cut

sub filter_by_cb {
  my $self = shift;
  my $cb = shift;

  croak "Callback was be a reference to a subroutine"
    unless ref($cb) == "CODE";

  # Get reference to array (force copy)
  my $ref = $self->stars;

  @$ref = grep { $cb->( $_ );  } @$ref;
  return $self->stars;
}

=back

=head2 Sorting

The following routines are available for sorting the star catalogue.
The sort applies to the current source list and not the original source list.
This is the case even if no filters have been applied (ie the original
unsorted catalogue is always available).

=over 4

=item B<sort_catalog>

Sort the catalog.

  $catalog->sort_catalog( $mode );

where mode can be one of

 "unsorted"
 "id"
 "ra"
 "dec"
 "az"
 "el"

and

 "distance"

if a reference position is available. "az" and "el" require that the
star coordinates have an associated telescope and that the reference
time is correct.

If mode is a code reference, that will be passed to the sort
routine directly. Note that the callback must expect $a and
$b to be set.

The method C<force_ref_time> is invoked prior to sorting
unless the mode is "id". "name" is a synonym for "id".

Currently the C<unsorted> option simply forces a C<reset_list>
since there is currently no tracking of the applied filters.
It should be possible to step through the original list and
the current filtered list and end up with a filtered but
unsorted list. This is not implemented.

Pre-canned sorts are optimized because the values are precalculated
prior to doing the sort rather than calculated each time through
the sort.

=cut

sub sort_catalog {
  my $self = shift;
  my $mode = shift;

  # unsort is a kluge at the moment
  if ($mode =~ /^unsort/i) {
    $self->reset_list;
    return;
  }

  # For reference time unless we are in id/name mode
  $self->force_ref_time
    unless ($mode =~ /^(id|name)/i);

  # Get the star list
  my $stars = $self->stars;

  # If we have a code ref we cannot optimize so just do it
  if (ref($mode)) {

    # Just sort it all
    @$stars = sort $mode, @$stars;

  } else {

    # see if we have a reference object
    my $ref = $self->reference;

    # to try to speed up all the queries, rather than
    # calculating the dynamic values during the sort we should
    # do it outside the sort. Create an array of hashes for the
    # sorting
    my @unsorted = map {
      my $c = $_->coords;
      return () unless defined $c;
      my %calc = (
		  object => $_,
		  ra => $c->ra_app,
		  dec => $c->dec_app,
		  az => $c->az,
		  el => $c->el,
		  id => $_->id,
		 );
      if ($ref) {
	$calc{distance} = $ref->distance( $c );
	$calc{distance} = "Inf" unless defined $calc{distance};
      }
      \%calc;
    } @$stars;

    # down case
    my $sort = lc($mode);

    # Array to hold the sorted hashes
    my @rSources;

    # Now do the search
    if ($sort =~ /(name|id)/) {
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

    # extract the objects in the right order
    @$stars = map { $_->{object} } @rSources;
  }
}

=back

=begin __PRIVATE_METHODS__

=head3 Internal sort optimizers.

=over 4

=item by_name

Internal routine to sort the entries in a source catalog by name.

  sort by_name @sources;

Returns -1,0,1

=cut

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

=head2 Private methods

These methods and functions are for internal use only.

=over 4

=item B<_have_copy>

Internal method indicating whether we have a copy of the stars array
or whether we are using the original version.

  $havecopy = $catalog->_have_copy;

=cut

sub _have_copy {
  my $self = shift;
  return (defined $self->{CURRENT} );
}

=item B<_normalize_hash>

Given a hash, returns a new hash with each key down cased. If a 
key is duplicated after downcasing a warning is issued if the keys
contain differing values.

  %n = _normalize_hash( %args );

=cut

sub _normalize_hash {
  my %args = @_;

  my %out;

  for my $key ( keys %args ) {
    my $outkey = lc($key);
    if (exists $out{$outkey} && $out{$outkey} ne $args{$key}) {
      warnings::warnif("Key '$outkey' supplied more than once with differing values. Ignoring second version");
      next;
    }

    # Store the key in the new hash
    $out{$outkey} = $args{$key};

  }

  return %out;
}

=item B<_load_io_plugin>

Given a file format, load the corresponding IO class. In general the
IO class is lower case except for the first letter. JCMT is an exception.
All plugins are in hierarchy C<Astro::Catalog::IO>.

Returns the class name on successful load. If the class can not be found
a warning is issued and false is returned.

=cut

sub _load_io_plugin {
  my $format = shift;

  # Force case
  $format = ucfirst( lc( $format ) );

  # Horrible kluge since I prefer "JCMT" to "Jcmt".
  # Maybe we should not try to fudge case at all?
  $format = 'JCMT' if $format eq 'Jcmt';

  my $class = "Astro::Catalog::IO::" . $format;

  # For some reason eval require does not work for us. Use string eval
  # instead.
  #  eval { require $class; };
  eval "use $class;";
  if ($@) {
    warnings::warnif("Error reading IO plugin $class: $@");
    return;
  } else {
    return $class;
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=end __PRIVATE_METHODS__

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
