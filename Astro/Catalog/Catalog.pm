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
#     $Id: Catalog.pm,v 1.25 2003/07/27 03:06:33 timj Exp $

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

'$Revision: 1.25 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Catalog.pm,v 1.25 2003/07/27 03:06:33 timj Exp $

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
		      ERRSTR => '',
		      ORIGIN => '<UNKNOWN>',
		      COORDS => undef,
                      RADIUS => undef }, $class;

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

Return the number of stars in the catalogue.

   $num = $catalog->sizeof();

=cut

sub sizeof {
  my $self = shift;
  return scalar( @{$self->{STARS}} );
}


=item B<pushstar>

Push a new star (or stars) onto the end of the C<Astro::Catalog> object

   $catalog->pushstar( @stars );

returns the number of stars now in the Catalog object (even if no
arguments were supplied).

=cut

sub pushstar {
  my $self = shift;

  # push the new item onto the stack 
  return push( @{$self->{STARS}}, @_);
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

  # grab the argument list and normalize hash
  my %args = _normalize_hash( @_ );

  if (defined $args{coords}) {
    $self->{COORDS} = $args{coords};
  } elsif ( defined $args{ra} && defined $args{dec}) {
    my $c = new Astro::Coords( type => 'J2000',
			       ra => $args{ra},
			       dec => $args{dec},
			     );
    $self->{COORDS} = $c;
  }

  # set field radius
  if ( defined $args{radius} ) {
     $self->{RADIUS} = $args{radius};
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

# H A N D L E   C L U S T E R   F I L E S ------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

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
