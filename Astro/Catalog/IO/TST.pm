package Astro::Catalog::IO::TST;

=head1 NAME

Astro::Catalog::IO::TST - Standard Tab Separated Table format I/O

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::TST->_read_catalog( \@lines );
  \@lines = Astro::Catalog::IO::TST->_write_catalog( $cat );

=head1 DESCRIPTION

Performs IO for catalogues that use the standard Tab Separated Table
(TST) format. The TST format is commonly returned by astronomical catalogue
servers that use the Astronomical Catalogue Library (ACL) format, although
it is also perfectly reasonable to read and write this format to disk.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION $DEBUG /;
use Carp;
use Data::Dumper;

use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords;

$DEBUG = 0;
$VERSION = '0.02';

=begin __PRIVATE_METHODS__

=head1 Private Methods

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Read contents of a TST catalogue (supplied as an array of lines) and
return a corresponding C<Astro::Catalog> object.

  $cat = Astro::Catalog::IO::TST->_read_catalog( \@lines, %opts );

Generally assumes that the first three columns in the table
are ID, RA and Dec.

The supplied options can be used to specify non-standard
column positions. eg

  ra_col => 5, dec_col => 6

would indicate that "ra" and "dec" are in columns 5 and 6 rather than
columns 2 and 3. Note that all options passed in here are treated
identically to TST parameters. ie the parameters read from the
TST file are merged with the supplied parameters (with the supplied
parameters over-writing file content). If "id", "ra" and "dec" are
missing, they are assumed to be columns 0, 1 and 2 respectively.


=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  my %options = @_;

  # Are we in the main table yet?
  my $intable;

  # Parameters
  my %params;

  # Descriptive comments
  my @descr;

  # General comments (usually ignored)
  my @comments;

  # Column names in order
  my @columns;

  # Actual star information
  my @stars;

  # Column formats, types and units (optional)
  my %extras;

  # Loop over each line
  for (@$lines) {

    # Make sure we have a copy since there is some processing
    # of the line and we do not want the content of the supplied
    # catalog to change from under the caller.
    my $line = $_;
    chomp($line);

    # Simply loop if there is no content
    next unless $line =~ /\S/;

    # Look for comments
    if ($line =~ /^\[EOD\]/) {
      # Usually indicates that we can stop parsing.
      # At the very least this means end of data.
      # so reset $intable
      print "FOUND EOD - no need to continue\n" if $DEBUG;
      last;

    } elsif ($line =~ /^\s*\#/) {
      # probably a comment although CURSA extensions allow
      # some column information
      if ($line =~ /^\s*\#column-(.*):/) {
	# Special key: usually units, types or formats
	my $key = $1;

	# Remove the crud
	$line =~ s/^\s*\#column-$key://;

	my @content = $class->_parse_line( $line );

	# and store it for now
	$extras{$key} = [] unless exists $extras{$key};
	push(@{ $extras{$key} }, @content);

	warnings::warnif("CURSA-style parameters encountered whilst inside table!")
	  if $intable;

      } else {
	# Standard comment - strip the hash
	$line =~ s/^\s*\#//;
	push(@comments, $line);
      }
    } elsif ($line =~ /\t/) {
      # Parse the line in standard manner
      my @content = $class->_parse_line( $line );

      # If the line includes tab characters it is probably a table
      # entry. Either the header or the content or the separator
      if ($intable) {
	# Must be reading real content
	warnings::warnif("Column mismatch: name count different to actual content!:\n$line\n") if @columns != @content;

	# Store the content in a hash indexed by the associated columns
	# This will be a problem for degenerate headings!
	my %star = map { lc($columns[$_]), $content[$_] } (0..$#content);

	push(@stars, \%star);
      } elsif ( !@columns ) {
	# We have read no column information so this must be
	# the table description
	@columns = @content;

      } elsif ($line =~ /^[-\t]+$/) {

	warnings::warnif("Table separator has already been encountered!")
	    if $intable;

	# separator, so next time around is a real table
	$intable = 1;
      } else {
	# Should not get here
	croak "Fatal parse error reading TST table, line '$line'";
      }

    } elsif ($line =~ /^\w+:/) {
      # A parameter is some characters ending in a colon
      my ($key, $value) = $line =~ /^(\w+):\s*(.*?)\s*$/;

      if (defined $key && defined $value) {
	$params{$key} = $value;
      } else {
	warnings::warnif("Error extracting parameter from line '$line'");
      }

      warnings::warnif("Parameter specified after table has been started. This is non-standard!")
	  if $intable;

    } else {
      # This is probably general description
      push(@descr, $line);
    }

    # loop around
  }

  # First merge the supplied parameters into those read from the file
  # itself. The supplied values override values read from the file
  %params = (%params, %options);

  print Dumper( \@descr, \@comments, \@columns, \%params, \%extras, \@stars)
    if $DEBUG;

  # Now we need to go through the parameters to see whether there are
  # any _col parameters that we need to map to an "ra", "dec" and "id"
  # field
  for my $key (keys %params) {
    next unless $key =~ /^(\w+)_col$/;
    my $col = lc($1);

    # find the column name (noting that the column numbers start
    # counting at 0)
    my $colnum = $params{$key};

    # This is the translated name [either the name supplied
    # directly or a column number
    my $oldname;

    # it is possible that this number is actually a column name
    if ($colnum =~ /[A-Za-z]/) {
      # has a word character
      $oldname = lc($colnum);
    } else {
      # Need to map column number to a name

      # Negative value indicates that we are not actually specifying
      # a column
      if ($colnum == -1) {
	# should the entry "$col" be deleted from each star hash
	# if it is present but has been designated -1 by a parameter?
	next;
      }

      # The old column name
      $oldname = lc( $columns[$colnum]);
    }

    # Insert new column into hash
    # overwriting existing content if required without warning
    # Assuming $star->{$oldname} actually exists
    for my $star (@stars) {
      $star->{$col} = $star->{$oldname} if exists $star->{$oldname};
    }

  }

  # if we do not yet have id, ra or dec assume columns (0,1,2)
  # Is this the correct thing to do? The spec in SSN/75 is vague
  # on this since it seems to imply that the first 3 columns may be
  # ra,dec and id without being called that and that *_col must be
  # present as parameters if the first 3 columns are not id,ra,dec
  # content. How do I know if they are id,ra and dec if they are not
  # called that.
  if (@stars) {
    my $colnum = 0;
    for my $key (qw/ id ra dec /) {
      # only check first star
      if (not exists $stars[0]->{$key}) {
	# did not have it, loop over all
	warnings::warnif("Guessing column $colnum contains $key");
	for (@stars) {
	  $_->{$key} = $_->{lc($columns[$colnum])};
	}
      }
      $colnum++;
    }
  }

  # Now convert the information into a star object

  # This is a back-of-the-envelope data dictionary from looking
  # at USNO. Maps, A::C::Star methods to different columns names
  my %datadict = (
		  field => [ qw/ field /],
		  quality => [ qw/ qual /],
		  distance => [ "d'" ],
		  posangle => [ qw/ pa /],
		 );


  # precalculate EQUINOX (type for Astro::Coords at the moment
  # since it can not deal with JXXXX.XX format)
  my $type = $params{EQUINOX};
  if (defined $type) {
    if ($type =~ /(B1950|J2000)(\.0*)?$/) {
      $type = $1;
    } else {
      warnings::warnif("Unsupported equinox '$type'. Defaulting to J2000");
      $type = "J2000";
    }
  } else {
    # default to J2000
    $type = "J2000";
  }

  for my $star (@stars) {

    my %construct;

    # Create some coordinates
    # decimal degrees or sexagesimal hours/deg
    if (exists $star->{ra} && exists $star->{dec}) {
      my $units;
      if ($star->{ra} =~ /:/) {
	$units = "sex";
      } else {
	# must be decimal degrees
	$units = "deg";
      }

      my $c = new Astro::Coords( ra => $star->{ra},
				 dec => $star->{dec},
				 type => $type,
				 units => $units,
				 name => $star->{id}
			       );

      if (defined $c) {
	$construct{coords} = $c;
      } else {
	warnings::warnif("Error instantiating coordinate object");
      }

    }


    # Assume that some field names are standardised. This is
    # probably rubbish (whoever heard of standards!).
    # Need to create a data dictionary with all the alternatives
    # that are in use.
    # Be very scared if we have to provide mapping routines
    for my $starkey (keys %datadict) {
      for my $colname (@{ $datadict{$starkey} }) {
	if (exists $star->{$colname}) {
	  $construct{$starkey} = $star->{$colname};

	  # stop looking
	  next;
	}
      }
    }

    # In GSC, posangle has junk on the end. We know it should be
    # a number
    $construct{posangle} =~ s/\D+$// if exists $construct{posangle};

    # gsc flag requires some work
    if (exists $star->{gsc}) {
      $construct{gsc} = ( $star->{gsc} eq '+' ? "TRUE" : "FALSE");
    } elsif ($params{gsc}) {
      $construct{gsc} = "TRUE";
    }

    # Magnitudes <- anything that ends in mag
    # Assdume filter is in X_mag
    # If no prefix assume R (yeah right) - we do not know the
    # source of the catalog at this point so can not even guess
    $construct{magnitudes} = {};
    $construct{magerr} = {};
    for my $key (keys %$star) {
      next unless $key =~ /^(.*?)_?mag$/; # non-greedy

      # No capture - assume R
      my $filter = ( $1 ? uc($1) : "R" );

      # if the filter starts with e_ then it is probably an
      # error in the magnitude
      if ($filter =~ /^E_(\w)$/i) {
	# error in magnitude
	my $err = $1;
	$construct{magerr}->{$err} = $star->{$key}
	  if $star->{$key} =~ /\d/;
	print "Found Mag Error $err ... \n" if $DEBUG;
      } elsif ($filter =~ /_/) {
	# is this a color?
	warnings::warnif "Found unrecognised filter string: $filter\n";
      } else {
	# Assume it is a filter
	$construct{magnitudes}->{$filter} = $star->{$key};
	print "Found filter $filter ...\n" if $DEBUG;
      }

    }

    # Colors: Look for B-V
    $construct{colours} = {};
    for my $key (keys %$star) {
      next unless $key =~ /^(\w)-(\w)$/; # non-greedy
      $construct{colours}->{uc($key)} = $star->{$key};
      print "Found color ".uc($key)." ... \n" if $DEBUG;
    }

    # Modify the array in place
    $star = new Astro::Catalog::Star( id => $star->{id}, %construct );

  }

  return new Astro::Catalog( Stars => \@stars);
}

=item B<_write_catalog>

Create an output catalogue in the TST format and return the lines
in an array.

  $ref = Astro::Catalog::IO::TST->_write_catalog( $catalog );

Argument is an C<Astro::Catalog> object.

=cut

sub _write_catalog {
  croak "Not yet implemented.";
}

=item B<_parse_line>

Internal routine for doing the tab delimited parsing.
Returns back the columns.

 @content = $class->_parse_line( $line );

This routine is trivial but it seemed sensible to put it in a function
since the parse is done in more than one place in _read_catalog. 
Whitespace around the column separators is stripped.

=cut

sub _parse_line {
  my $class = shift;
  my $line = shift;

  # Just so we do things correctly, add a ' ' to the
  # end of a string if it ends in a tab. Otherwise for blank
  # last column we end up being a column short
  $line .= " " if $line =~ /\t$/;

  # Do the split on tab and then clean up each string
  # Safer since \s include \t
  my @cols =  split(/\t/,$line);

  for (@cols) {
    s/^\s*//;
    s/\s*$//;
  }

  return @cols;
}


=back


=head1 REVISION

 $Id: TST.pm,v 1.3 2003/08/03 11:20:35 timj Exp $

=head1 FORMAT

The TST format is specified in a number of documents. For example
SSN/75 [http://www.starlink.rl.ac.uk/star/docs/ssn75.htx//ssn75.html]
by Clive Davenhall.

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>.

=head1 COPYRIGHT

Copyright (C) 2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;

