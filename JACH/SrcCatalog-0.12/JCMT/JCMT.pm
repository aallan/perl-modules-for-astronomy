package SrcCatalog::JCMT;

=head1 NAME

SrcCatalog::JCMT - Object representing JCMT catalog sources

=head1 DESCRIPTION

Manage a collection of coordinates read from a JCMT format catalog file.

=cut

use 5.006;
use warnings;
use Carp;
use strict;

use vars qw/$VERSION $DEBUG $defaultCatalog /;

$VERSION = '0.13';

use base qw/ SrcCatalog /;
use Astro::Coords 0.04;
use Astro::Telescope;

$DEBUG = 0;

# Name must be limited to 15 characters
use constant MAX_SRC_LENGTH => 15;

=head1 INSTANCE METHODS

=over 4

=item _init

Reads in file name and calls parsing function.

  $srcCatalog->_init($filename);
  $srcCatalog->_init($cat_contents);

If the arguments are Astro::Coords objects the routine
assumes that the objects should simply be stored without
reading a catalogue file.

  $srcCatalog->_init( @coords );

This allows the C<writeCatalog> method to work properly in JCMT
format.

=cut 

sub _init
{
	my $self = shift;

	# Look for a reference. If we have one use the base class.
	if (ref($_[0])) {

	  $self->SUPER::_init( @_ );

	} else {

	  # Assume a filename or a string
	  $self->file(shift());
	  $self->readCatalog();

	}

	return;
}

=item readCatalog

Reads in a catalog file and converts parsed items into
source objects. Configures the object and also returns
all the coordinate objects that were read from the file.

  @coords = $srcCatalog->readCatalog($filename);

If no arguments are supplied the file is obtained using the C<file>
method. If the catalog name is "default" the default pointing catalog
is used. (the default can be over-ridden using the C<defaultCatalog>
class method).

If the catalogue name contains spaces and newlines it is assumed to be
the contents of a catalogue file rather than the name of a catalogue
file.

Coordinate objects are created using telescope JCMT. This seems sensible
given the name of the class. If other telescopes adopt this we may want
to provide a better way of specifying the telescope.

Flux measurements are extracted from the pointing catalog and stored
as comments in the coordinate objects.

=cut

sub readCatalog
{
  my $self = shift;
  my $CATALOG = (@_ ? shift(): $self->file) || croak "Catalog undefined \n";
  my $array = $self->sources;

  print "Entered into the getting sources from file\n" if $DEBUG;

  my $isFile = 1;
  if ($CATALOG =~ /\s/ && $CATALOG =~ /\n/) {
    $isFile = 0;
  }

  # Create telescope object
  my $tel = new Astro::Telescope("JCMT");

  my $fh;
  if ($isFile) {
    $CATALOG = $self->defaultCatalog
      if $CATALOG =~ /^default$/i;

    print "Opening catalog $CATALOG\n" if $DEBUG;

    open my $fh, $CATALOG
      or croak "Error reading catalog file $CATALOG: $!";


    # Oops. Assume that \n is okay for all the cases of interest
    local $/ = "\n" if !defined $/;

    # Read the file a line at a time
    while (defined(my $line = <$fh>)) {
      print "Line: $line" if $DEBUG;

      # Parse the line
      my $source = $self->_parse_line( $line, $tel );
      print "Found entry for " . $source->name ."\n"
	if $DEBUG && $source;
      push (@$array, $source)
	if $source;
    }

    close $fh or croak "Error closing catalog file: $!";

  } else {
    # We have the contents of the file
    for my $line (split /\n/, $CATALOG) {
      # Parse the line
      print "Line = $line\n";
      my $source = $self->_parse_line( $line, $tel );

      push (@$array, $source)
	if $source;
    }

    # Remove the filename
    $self->file(undef);

  }

  print "Exiting getsourcesfromfile method\n" if $DEBUG;

  # For JCMT always add the planets [might want to make this configurable]
  my @planets = map { new Astro::Coords(planet => $_) }
    qw/ mars uranus saturn jupiter venus neptune /;
  for (@planets) {
    $_->telescope($tel);
  }
  push(@$array, @planets);

  # copy the results into the object
  @{$self->sources} = @$array;

  # and make sure the current values are set
  $self->reset;

  # return the objects we have found
  return (wantarray ? @{$self->sources} : $self->sources);
}

=item B<writeCatalog>

Write the source coordinates out to disk as a JCMT format catalog
file.

  $srcCatalog->writeCatalog( $file );

If filename is supplied it is used. If filename is not supplied then
the file returned from the C<file> method is used.  Dies if no
filename can be determined. If the filename is a reference to a glob
then it is assumed to be an open filehandle (which is not closed on
exit)

  $srcCatalog->writeCatalog( \*STDOUT );

Only writes the currently selected sources rather than all the
sources.

Note that spaces are removed from source names.

=cut

sub writeCatalog {
  my $self = shift;
  my $file = shift;

  # Ask the object if we do not know the file name
  $file = $self->file unless defined $file;

  croak "Unable to determine an output filename for writeCatalog"
    unless defined $file;

  # Do we have a glob?
  my $isglob = ( ref($file) eq 'GLOB' ? 1 : 0 );

  # Get the sources
  my @sources = @{ $self->current };

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
  for my $src (@sources) {

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
      warn "Coordinate of type $type for target $errname not supported in JCMT catalog files\n";
      next;
    }

    # Generate a name if not defined
    if (!defined $srcdata{name}) {
      $srcdata{name} = "UNKNOWN$unk";
      $unk++;
    }

    # See if we already have this source and that it is really the same source
    # Note that we do not see whether this name is the same as one of the derived
    # names. Eg if CRL618 is in the pointing catalogue 3 times with identical coords
    # and we add a new CRL618 with different coords then we trigger 3 warning
    # messages rather than 1 because we do not check that CRL618_2 is the same
    # as CRL618_1
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

  # Open the output file (if we do not have a glob)
  my $fh;
  if ($isglob) {
    $fh = $file;
  } else {
    open $fh, ">$file"
      or croak "Error creating catalog file $file: $!";
  }

  # Write a header
  print $fh "*\n";
  print $fh "* Catalog written automatically by SrcCatalog::JCMT\n";
  print $fh "* on date " . gmtime . "UT\n";
  print $fh "*\n";

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

    printf $fh "%-". MAX_SRC_LENGTH.
      "s    %02d %02d %06.3f %1s %02d %02d %04.1f  %2s    n/a     n/a   n/a   LSR  RADIO %s\n",
      $name, @$long, @$lat, $system, $comment;

  }


  # close the file [if we opened it]
  if (!$isglob) {
    close $fh or croak "Error closing catalog file: $!";
  }

  return;
}

=back

=head1 CLASS METHODS

=over 4

=item B<defaultCatalog>

Set or retrieve the default catalog to be used for all classes if no
other can be determined.

  SrcCatalog::JCMT->defaultCatalog( "new.cat" );
  my $catfile = SrcCatalog::JCMT->defaultCatalog;

=cut

{
  my $defaultCatalog = "/local/progs/etc/poi.dat";
  sub defaultCatalog {
    my $class = shift;
    if (@_) {
      $defaultCatalog = shift;
    }
    return $defaultCatalog;
  }
}

=back

=head2 Internal Methods

=over 4

=item B<_parse_line>

Parse a line in the catalogue and return the relevant source
object (as an Astro::Coords object). Returns undef if no source
information could be extracted from the line.

 $source = $cat->_parse_line( $line, $tel );

An Astro::Telescope object is passed in as the second argument. This
usually refers to the JCMT.

The target name is extracted from the first MAX_SRC_LENGTH
characters (fixed format) rather than relying on space delimiting. This
is because the JCMT catalog reader allows 15 character names which
merge straight into the longitude value for non RA targets. All other
columns are derived using space-delimiting.

=cut

sub _parse_line {
  my $self = shift;
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
    carp "Unknown coordinate type: $epoc";
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
      return $source;
    } else {
      croak "Error parsing line. Unable to create source date for target '$target' at RA '$ra' Dec '$dec' and Epoch '$epoc'\n";
    }
  }

  $source->telescope( $tel ); # This is JCMT
  $source->comment($comment);

  print "Created a new source in getsourcefromfile\n" if $DEBUG;

  return $source;
}

=back

=head1 NOTES

Coordinates are stored as C<Astro::Coords> objects.

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

The maximum length of sourcenames readable from or writable to
a JCMT source catalogue.

=back

=head1 COPYRIGHT

Copyright (C) 1999-2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Major subroutines originally designed by Casey Best (University of
Victoria) with modifications made to create a module by Tim Jenness
and Pam Shimek (University of Victoria)

Rewritten to use Astro::Coords by Tim Jenness.

=cut

1;
