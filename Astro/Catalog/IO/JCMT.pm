package Astro::Catalog::IO::JCMT;

=head1 NAME

Astro::Catalog::IO::JCMT - JCMT catalogue I/O for Astro::Catalog

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::JCMT->_read_catalog( \@lines );
  $arrref = Astro::Catalog::IO::JCMT->_write_catalog( $cat, %options );
  $filename = Astro::Catalog::IO::JCMT->_default_file();

=head1 DESCRIPTION

This class provides read and write methods for catalogues in the JCMT
pointing catalogue format. The methods are not public and should, in general,
only be called from the C<Astro::Catalog> C<write_catalog> and C<read_catalog>
methods.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;

use vars qw/$VERSION $DEBUG /;

$VERSION = '0.13';
$DEBUG   = 0;

# Name must be limited to 15 characters on write
use constant MAX_SRC_LENGTH => 15;

# Default location for a JCMT catalog
my $defaultCatalog = "/local/progs/etc/poi.dat";

# Planets appended to the catalogue
my @PLANETS = qw/ mars uranus saturn jupiter venus neptune /;

=over 4

=item B<_default_file>

Returns the location of the default JCMT pointing catalogue at the
JCMT itself. This is purely for convenience of the caller when they
are at the JCMT and wish to use the default catalogue without having
to know explicitly where it is.

  $filename = Astro::Catalog::IO::JCMT->_default_file();

Returns empty list/undef if the file is not available.

=cut

sub _default_file {
  my $class = shift;
  return (-e $defaultCatalog ? $defaultCatalog : () );
}

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog>
object containing the catalog entries.

 $cat = Astro::Catalog::IO::JCMT->_read_catalog( \@lines, %options );

Supported options (with defaults) are:

  telescope => Name of telescope to associate with each coordinate entry
               (defaults to JCMT). If the telescope option is specified
               but is undef or empty string, no telescope is used.

  incplanets => Append planets to catalogue entries (default is true)


=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  # Default options
  my %defaults = ( telescope => 'JCMT',
		   incplanets => 1);

  my %options = (%defaults, @_);

  croak "Must supply catalogue contents as a reference to an array"
    unless ref($lines) eq 'ARRAY';

  # Create a new telescope to associate with this 
  my $tel;
  $tel = new Astro::Telescope( $options{telescope} )
    if $options{telescope};

  # Go through each line and parse it
  # and store in the array if we had a successful read
  my @stars = map { $class->_parse_line( $_, $tel); } @$lines;

  # Add planets if required
  if ($options{incplanets}) {
    # create coordinate objects for the planets
    my @planets = map { new Astro::Coords(planet => $_) } @PLANETS;

    # And associate a telescope
    if ($tel) {
      for (@planets) {
	$_->telescope($tel);
      }
    }

    # And create the star objects
    push(@stars, map { new Astro::Catalog::Star( id => $_->name,
						 coords => $_ ) } @planets);

  }

  # Create the catalog object
  return new Astro::Catalog( Stars => \@stars,
			     Origin => 'JCMT',
			   );

}

=item B<_write_catalog>

Write the catalog to an array and return it. Returning a reference to
an array provides more flexibility to the caller.

 $ref = Astro::Catalog::IO::JCMT->_write_catalog( $cat );

Spaces are removed from source names. The contents of the catalog
are sanity checked.

=cut

sub _write_catalog {
  my $class = shift;
  my $cat = shift;

  # Would make more sense to use the array ref here
  my @sources = $cat->stars;

  # Counter for unknown targets
  my $unk = 1;

  # Hash for storing target information
  # so that we can search for duplicates
  my %targets;

  # Loop over each source and extract catalog information
  # Make sure that we remove unique entries
  # BUT THAT WE RETAIN THE ORDER OF THE SOURCES IN THE CATALOG
  # Hence an array for the information
  my @processed;
  for my $star (@sources) {

    # Extract the coordinate object
    my $src = $star->coords;

    # Get the name but do not deal with undef yet
    # in case the type is not valid
    my $name = $src->name;

    # Somewhere to store the extracted information
    my %srcdata;

    # Store the name (stripped of spaces)
    # Treat srcdata{name} as the primary name from here on
    $name =~ s/\s+//g if defined $name;
    $srcdata{name} = $name;

    # Store a comment
    $srcdata{comment} = $src->comment;

    # Get the type of source
    my $type = $src->type;
    if ($type eq 'RADEC') {
      $srcdata{system} = "RJ";

      # Need to get the space separated RA/Dec and the sign
      $srcdata{long} = $src->ra(format => 'array');
      $srcdata{lat} = $src->dec(format => 'array');


    } elsif ($type eq 'PLANET') {
      # Planets are not supported in catalog form. Skip them
      next;

    } elsif ($type eq 'FIXED') {
      $srcdata{system} = "AZ";

      $srcdata{long} = $src->az(format => 'array');
      $srcdata{lat} = $src->el(format => 'array');

      # Need to remove + sign from long/AZ since we are not expecting
      # it in RA/DEC. This is probably a bug in Astro::Coords
      shift(@{ $srcdata{long} } ) if $srcdata{long}->[0] eq '+';

    } else {
      my $errname = ( defined $srcdata{name} ? $srcdata{name} : "<undefined>");
      warnings::warnif "Coordinate of type $type for target $errname not supported in JCMT catalog files\n";
      next;
    }

    # Generate a name if not defined
    if (!defined $srcdata{name}) {
      $srcdata{name} = "UNKNOWN$unk";
      $unk++;
    }

    # See if we already have this source and that it is really the
    # same source Note that we do not see whether this name is the
    # same as one of the derived names. Eg if CRL618 is in the
    # pointing catalogue 3 times with identical coords and we add a
    # new CRL618 with different coords then we trigger 3 warning
    # messages rather than 1 because we do not check that CRL618_2 is
    # the same as CRL618_1
    if (exists $targets{$srcdata{name}}) {
      my $previous = $targets{$srcdata{name}};

      # Create stringified form of previous coordinate with same name
      # and current coordinate
      my $prevcoords = join(" ",@{$previous->{long}},@{$previous->{lat}});
      my $curcoords = join(" ",@{$srcdata{long}},@{$srcdata{lat}});

      if ($prevcoords eq $curcoords) {
	# This is the same target so we can ignore it
      } else {
	# Make up a new name. Use the unknown counter for this since we probably
	# have not used it before. Probably not the best approach and might have
	# problems in edge cases but good enough for now
	my $oldname = $srcdata{name};
	$srcdata{name} .= "_$unk";

	# different target
	warn "Found target with the same name [$oldname] but with different coordinates, renaming it to $srcdata{name}!\n";

	# increment the unknown counter
	$unk++;

	$targets{$srcdata{name}} = \%srcdata;

	# Store it in the array
	push(@processed, \%srcdata);

      }

    } else {
      # Store in hash for easy lookup for duplicates
      $targets{$srcdata{name}} = \%srcdata;

      # Store it in the array
      push(@processed, \%srcdata);

    }

  }


  # Output array for new catalog lines
  my @lines;

  # Write a header
  push @lines, "*\n";
  push @lines, "* Catalog written automatically by class ". __PACKAGE__ ."\n";
  push @lines, "* on date " . gmtime . "UT\n";
  push @lines, "* Origin of catalogue: ". $cat->origin ."\n";
  push @lines, "*\n";

  # Now need to go through the targets and write them to disk
  for my $src (@processed) {
    my $name    = $src->{name};
    my $long    = $src->{long};
    my $lat     = $src->{lat};
    my $system  = $src->{system};
    my $comment = $src->{comment};
    $comment = '' unless defined $comment;

    # Name must be limited to MAX_SRC_LENGTH characters
    $name = substr($name,0,MAX_SRC_LENGTH);

    push @lines, 
      sprintf("%-". MAX_SRC_LENGTH.
      "s    %02d %02d %06.3f %1s %02d %02d %04.1f  %2s    n/a     n/a   n/a   LSR  RADIO %s\n",
      $name, @$long, @$lat, $system, $comment);

  }

  return \@lines;
}

=item B<_parse_line>

Parse a line from a JCMT format catalogue and return a corresponding
C<Astro::Catalog::Star> object. Returns empty list if the line can not
be parsed or refers to a comment line (so that map can be used in the
caller).

  $star = Astro::Catalog::IO::JCMT->_parse_line( $line, $tel );

where C<$line> is the line to be parsed and (optional) C<$tel>
is an C<Astro::Telescope> object to be associated with the 
coordinate objects.

The line is parsed using a pattern match.

=cut

sub _parse_line {
  my $class = shift;
  my $line = shift;
  my $tel = shift;
  chomp $line;

  # Skip commented and blank lines
  return if ($line =~ /^\s*[\*\%]/);
  return if ($line =~ /^\s*$/);

  # Use a pattern match parser
  my @match = ( $line =~ m/^(.*?)  # Target name (non greedy)
		          \s*   # optional trailing space
                          (\d{1,2}) # 1 or 2 digits [RA:h] [greedy]
		          \s+       # separator
		          (\d{1,2}) # 1 or 2 digits [RA:m]
		          \s+       # separator
		          (\d{1,2}(?:\.\d*)?) # 1|2 digits opt .fraction [RA:s]
		                    # no capture on fraction
		          \s+
		          ([+-]?\s*\d{1,2}) # 1|2 digit [dec:d] inc sign
		          \s+
		          (\d{1,2}) # 1|2 digit [dec:m]
		          \s+
		          (\d{1,2}(?:\.\d*)?) # arcsecond (optional fraction)
                                              # no capture on fraction
		          \s+
		          (RJ|RB|GA|AZ) # coordinate type
		         # most everything else is optional
		         # [sign]velocity, flux,vrange,vel_def,frame,comments
		         \s*
		         (n\/a|[+-]\s*\d+(?:\.\d*)?)?  # velocity [8]
		         \s*
		         (n\/a|\d+(?:\.\d*)?)?    # flux [9]
		         \s*
		         (n\/a|\d+(?:\.\d*)?)?    # vel range [10]
		         \s*
		         ([\w\/]+)?               # vel frame [11]
		         \s*
		         ([\w\/]+)?               # vel defn [12]
		         \s*
		         (.*)$                    # comment [13]
		/xi);

  # Abort if we do not have matches for the first 8 fields
  for (0..7) {
    return unless defined $match[$_];
  }

  # Read the values
  my $target = $match[0];
  my $ra = join(":",@match[1..3]);
  my $dec = join(":",@match[4..6]);
  $dec =~ s/\s//g; # remove  space between the sign and number
  my $epoc = $match[7];

  print "Creating a new source in getsourcefromfile\n" if $DEBUG;

  # need to translate JCMT epoch to normal epoch
  my %coords;
  $epoc = uc($epoc);
  $coords{name} = $target;
  if ($epoc eq 'RJ') {
    $coords{ra} = $ra;
    $coords{dec} = $dec;
    $coords{type} = "j2000"
  } elsif ($epoc eq 'RB') {
    $coords{ra} = $ra;
    $coords{dec} = $dec;
    $coords{type} = "b1950";
  } elsif ($epoc eq 'GA') {
    $coords{long} = $ra;
    $coords{lat}  = $dec;
    $coords{type} = "galactic";
  } elsif ($epoc eq 'AZ') {
    $coords{az}   = $ra;
    $coords{el}   = $dec;
    $coords{units} = 'sexagesimal';
  } else {
    warnings::warnif "Unknown coordinate type: '$epoc' for target $target. Ignoring line.";
    return;
  }

  # Read the flux as a comment
  my $fcol = 9;  # flux column
  my $ccol = 13; # comment column

  my $flux = (defined $match[$fcol] ? $match[$fcol] : '');
  $flux = '' if $flux =~ /n\/a/i;

  # catalog comments are space delimited
  my $cat_comm = (defined $match[$ccol] ? $match[$ccol] : '');
  my $comment = $flux;
  $comment .= " $cat_comm" if $cat_comm;

  # Replace multiple spaces in comment with single space
  $comment =~ s/\s+/ /g;

  # create the source object
  my $source = new Astro::Coords( %coords );

  unless (defined $source ) {
    if ($DEBUG) {
      print "failed to create source for '$target' and $ra and $dec and $epoc\n";
      return;
    } else {
      croak "Error parsing line. Unable to create source date for target '$target' at RA '$ra' Dec '$dec' and Epoch '$epoc'\n";
    }
  }

  $source->telescope( $tel ) if $tel;
  $source->comment($comment);

  # Field name should simply be linked to the telescope
  my $field = (defined $tel ? $tel->name : '<UNKNOWN>' );

  print "Created a new source in getsourcefromfile\n" if $DEBUG;

  # Now create the star object
  return new Astro::Catalog::Star( id => $target,
				   coords => $source,
				   field => $field,
				 );

}


=back

=head1 NOTES

Coordinates are stored as C<Astro::Coords> objects inside
C<Astro::Catalog::Star> objects.


=head1 GLOBAL VARIABLES

The following global variables can be modified to control the state of the
module:

=over 4

=item $DEBUG

Controls debugging messages. Default state is false.

=back

=head1 CONSTANTS

The following constants are available for querying:

=over 4

=item MAX_SRC_LENGTH

The maximum length of sourcenames writable to a JCMT source catalogue.

=back

=head1 COPYRIGHT

Copyright (C) 1999-2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;
