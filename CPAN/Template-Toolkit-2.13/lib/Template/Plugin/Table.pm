#============================================================= -*-Perl-*-
#
# Template::Plugin::Table
#
# DESCRIPTION
#
#   Plugin to order a linear data set into a virtual 2-dimensional table
#   from which row and column permutations can be fetched.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: Table.pm,v 1.1 2004/03/03 02:43:05 aa Exp $
#
#============================================================================

package Template::Plugin::Table;

require 5.004;

use strict;
use vars qw( @ISA $VERSION $AUTOLOAD );
use base qw( Template::Plugin );
use Template::Plugin;

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \@data, \%args)
#
# This constructor method initialises the object to iterate through
# the data set passed by reference to a list as the first parameter.
# It calculates the shape of the permutation table based on the ROWS
# or COLS parameters specified in the $args hash reference.  The
# OVERLAP parameter may be provided to specify the number of common
# items that should be shared between subseqent columns.
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $data, $params) = @_;
    my ($size, $rows, $cols, $coloff, $overlap, $error);

    # if the data item is a reference to a Template::Iterator object,
    # or subclass thereof, we call its get_all() method to extract all
    # the data it contains
    if (UNIVERSAL::isa($data, 'Template::Iterator')) {
	($data, $error) = $data->get_all();
	return $class->error("iterator failed to provide data for table: ",
			     $error)
	    if $error;
    }
	
    return $class->error('invalid table data, expecting a list')
	unless ref $data eq 'ARRAY';

    $params ||= { };
    return $class->error('invalid table parameters, expecting a hash')
	unless ref $params eq 'HASH';

    # ensure keys are folded to upper case
    @$params{ map { uc } keys %$params } = values %$params;

    $size = scalar @$data;
    $overlap = $params->{ OVERLAP } || 0;

    # calculate number of columns based on a specified number of rows
    if ($rows = $params->{ ROWS }) {
	if ($size < $rows) {
	    $rows = $size;   # pad?
	    $cols = 1;
	    $coloff = 0;
	}
	else {
	    $coloff = $rows - $overlap;
	    $cols = int ($size / $coloff) 
		  + ($size % $coloff > $overlap ? 1 : 0)
	}
    }
    # calculate number of rows based on a specified number of columns
    elsif ($cols = $params->{ COLS }) {
	if ($size < $cols) {
	    $cols = $size;
	    $rows = 1;
	    $coloff = 1;
	}
	else {
	    $coloff = int ($size / $cols) 
		    + ($size % $cols > $overlap ? 1 : 0);
	    $rows = $coloff + $overlap;
	}
    }
    else {
	$rows = $size;
	$cols = 1;
	$coloff = 0;
    }
    
    bless {
	_DATA    => $data,
	_SIZE    => $size,
	_NROWS   => $rows,
	_NCOLS   => $cols,
	_COLOFF  => $coloff,
	_OVERLAP => $overlap,
	_PAD     => defined $params->{ PAD } ? $params->{ PAD } : 1,
    }, $class;
}


#------------------------------------------------------------------------
# row($n)
#
# Returns a reference to a list containing the items in the row whose 
# number is specified by parameter.  If the row number is undefined,
# it calls rows() to return a list of all rows.
#------------------------------------------------------------------------

sub row {
    my ($self, $row) = @_;
    my ($data, $cols, $offset, $size, $pad) 
	= @$self{ qw( _DATA _NCOLS _COLOFF _SIZE _PAD) };
    my @set;

    # return all rows if row number not specified
    return $self->rows()
	unless defined $row;

    return () if $row >= $self->{ _NROWS } || $row < 0;
    
    my $index = $row;

    for (my $c = 0; $c < $cols; $c++) {
	push(@set, $index < $size 
		    ? $data->[$index] 
		    : ($pad ? undef : ()));
	$index += $offset;
    }
    return \@set;
}


#------------------------------------------------------------------------
# col($n)
#
# Returns a reference to a list containing the items in the column whose
# number is specified by parameter.  If the column number is undefined,
# it calls cols() to return a list of all columns.
#------------------------------------------------------------------------

sub col {
    my ($self, $col) = @_;
    my ($data, $size) = @$self{ qw( _DATA _SIZE ) };
    my ($start, $end);
    my $blanks = 0;

    # return all cols if row number not specified
    return $self->cols()
	unless defined $col;

    return () if $col >= $self->{ _NCOLS } || $col < 0;

    $start = $self->{ _COLOFF } * $col;
    $end = $start + $self->{ _NROWS } - 1;
    $end = $start if $end < $start;
    if ($end >= $size) {
	$blanks = ($end - $size) + 1;
	$end = $size - 1;
    }
    return () if $start >= $size;
    return [ @$data[$start..$end], 
	     $self->{ _PAD } ? ((undef) x $blanks) : () ];
}


#------------------------------------------------------------------------
# rows()
#
# Returns all rows as a reference to a list of rows.
#------------------------------------------------------------------------

sub rows {
    my $self = shift;
    return [ map { $self->row($_) } (0..$self->{ _NROWS }-1) ];
}


#------------------------------------------------------------------------
# cols()
#
# Returns all rows as a reference to a list of rows.
#------------------------------------------------------------------------

sub cols {
    my $self = shift;
    return [ map { $self->col($_) } (0..$self->{ _NCOLS }-1) ];
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides read access to various internal data members.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    if ($item =~ /^data|size|nrows|ncols|overlap|pad$/) {
	return $self->{ $item };
    }
    else {
	return (undef, "no such table method: $item");
    }
}



1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Plugin::Table - Plugin to present data in a table

=head1 SYNOPSIS

    [% USE table(list, rows=n, cols=n, overlap=n, pad=0) %]

    [% FOREACH item = table.row(n) %]
       [% item %]
    [% END %]

    [% FOREACH item = table.col(n) %]
       [% item %]
    [% END %]

    [% FOREACH row = table.rows %]
       [% FOREACH item = row %]
          [% item %]
       [% END %]
    [% END %]

    [% FOREACH col = table.cols %]
       [% col.first %] - [% col.last %] ([% col.size %] entries)
    [% END %]

=head1 DESCRIPTION

The Table plugin allows you to format a list of data items into a 
virtual table.  When you create a Table plugin via the USE directive,
simply pass a list reference as the first parameter and then specify 
a fixed number of rows or columns.

    [% USE Table(list, rows=5) %]
    [% USE table(list, cols=5) %]

The 'Table' plugin name can also be specified in lower case as shown
in the second example above.  You can also specify an alternative variable
name for the plugin as per regular Template Toolkit syntax.

    [% USE mydata = table(list, rows=5) %]

The plugin then presents a table based view on the data set.  The data
isn't actually reorganised in any way but is available via the row(),
col(), rows() and cols() as if formatted into a simple two dimensional
table of n rows x n columns.  Thus, if our sample 'alphabet' list
contained the letters 'a' to 'z', the above USE directives would
create plugins that represented the following views of the alphabet.

    [% USE table(alphabet, ... %]

    rows=5                  cols=5
    a  f  k  p  u  z        a  g  m  s  y
    b  g  l  q  v           b  h  n  t  z
    c  h  m  r  w           c  i  o  u
    d  i  n  s  x           d  j  p  v
    e  j  o  t  y           e  k  q  w
                            f  l  r  x

We can request a particular row or column using the row() and col() 
methods.

    [% USE table(alphabet, rows=5) %]
    [% FOREACH item = table.row(0) %]
       # [% item %] set to each of [ a f k p u z ] in turn
    [% END %]

    [% FOREACH item = table.col(2) %]
       # [% item %] set to each of [ m n o p q r ] in turn
    [% END %]

Data in rows is returned from left to right, columns from top to
bottom.  The first row/column is 0.  By default, rows or columns that
contain empty values will be padded with the undefined value to fill
it to the same size as all other rows or columns.  For example, the
last row (row 4) in the first example would contain the values [ e j o
t y undef ]. The Template Toolkit will safely accept these undefined
values and print a empty string.  You can also use the IF directive to
test if the value is set.

   [% FOREACH item = table.row(4) %]
      [% IF item %]
         Item: [% item %]
      [% END %]
   [% END %]

You can explicitly disable the 'pad' option when creating the plugin to 
returned shortened rows/columns where the data is empty.

   [% USE table(alphabet, cols=5, pad=0) %]
   [% FOREACH item = table.col(4) %]
      # [% item %] set to each of 'y z'
   [% END %]

The rows() method returns all rows/columns in the table as a reference
to a list of rows (themselves list references).  The row() methods
when called without any arguments calls rows() to return all rows in
the table.

Ditto for cols() and col().

    [% USE table(alphabet, cols=5) %]
    [% FOREACH row = table.rows %]
       [% FOREACH item = row %]
          [% item %]
       [% END %]
    [% END %]

The Template Toolkit provides the first(), last() and size() methods
that can be called on list references to return the first/last entry
or the number of entried.  The following example shows how we might 
use this to provide an alphabetical index split into 3 even parts.

    [% USE table(alphabet, cols=3, pad=0) %]
    [% FOREACH group = table.col %]
       [ [% group.first %] - [% group.last %] ([% group.size %] letters) ]
    [% END %]

This produces the following output:

    [ a - i (9 letters) ]
    [ j - r (9 letters) ]
    [ s - z (8 letters) ]

We can also use the general purpose join() list method which joins 
the items of the list using the connecting string specified.

    [% USE table(alphabet, cols=5) %]
    [% FOREACH row = table.rows %]
       [% row.join(' - ') %]
    [% END %]

Data in the table is ordered downwards rather than across but can easily
be transformed on output.  For example, to format our data in 5 columns
with data ordered across rather than down, we specify 'rows=5' to order
the data as such:

    a  f  .  .
    b  g  .
    c  h
    d  i
    e  j

and then iterate down through each column (a-e, f-j, etc.) printing
the data across.

    a  b  c  d  e
    f  g  h  i  j
    .  .
    .

Example code to do so would be much like the following:

    [% USE table(alphabet, rows=3) %]
    [% FOREACH cols = table.cols %]
      [% FOREACH item = cols %]
        [% item %]
      [% END %]
    [% END %]

    a  b  c
    d  e  f
    g  h  i
    j  .  .
    .

In addition to a list reference, the Table plugin constructor may be 
passed a reference to a Template::Iterator object or subclass thereof.
The get_all() method is first called on the iterator to return all 
remaining items.  These are then available via the usual Table interface.

    [% USE DBI(dsn,user,pass) -%]

    # query() returns an iterator
    [% results = DBI.query('SELECT * FROM alphabet ORDER BY letter') %]
    
    # pass into Table plugin
    [% USE table(results, rows=8 overlap=1 pad=0) -%]

    [% FOREACH row = table.cols -%]
       [% row.first.letter %] - [% row.last.letter %]:
          [% row.join(', ') %]
    [% END %]

=head1 AUTHOR

Andy Wardley E<lt>abw@andywardley.comE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.64, distributed as part of the
Template Toolkit version 2.13, released on 30 January 2004.

=head1 COPYRIGHT

  Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
