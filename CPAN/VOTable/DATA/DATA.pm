# DATA.pm

=pod

=head1 NAME

VOTable::DATA - VOTable DATA element class

=head1 SYNOPSIS

use VOTable::DATA

=head1 DESCRIPTION

This class implements an interface to VOTable DATA elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::DATA object. Throw an exception if an
error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'DATA' element, that object is used to create the
VOTable::DATA object (just by reblessing).

=head3 get_TABLEDATA()

Return the VOTable::TABLEDATA object for the TABLEDATA child element
of this DATA element, or undef if this DATA has no TABLEDATA. Throw an
exception if an error occurs.

=head3 set_TABLEDATA($tabledata)

Use $tabledata (a VOTable::TABLEDATA object, or a XML::LibXML::Element
object for a TABLEDATA element) to set the TABLEDATA element child of
this DATA element. Any existing TABLEDATA, BINARY, or FITS child
element in this DATA element is deleted first. Throw an exception if
an error occurs.

=head3 remove_TABLEDATA()

Remove any existing TABLEDATA child element. Throw an exception if an
error occurs.

=head3 get_BINARY()

Return the VOTable::BINARY object for the BINARY child element of this
DATA element, or undef if this DATA has no BINARY. Throw an exception
if an error occurs.

=head3 set_BINARY($binary)

Use $binary (a VOTable::BINARY object, or a XML::LibXML::Element
object for a BINARY element) to set the BINARY element child of this
DATA element. Any existing TABLEDATA, BINARY, or FITS child element in
this DATA element is deleted first. Throw an exception if an error
occurs.

=head3 remove_BINARY()

Remove any existing BINARY child element. Throw an exception if an
error occurs.

=head3 get_FITS()

Return the VOTable::FITS object for the FITS child element of this
DATA element, or undef if this DATA has no FITS. Throw an exception if
an error occurs.

=head3 set_FITS($fits)

Use $fits (a VOTable::FITS object, or a XML::LibXML::Element object
for a FITS element) to set the FITS element child of this DATA
element. Any existing TABLEDATA, BINARY, or FITS child element in this
DATA element is deleted first. Throw an exception if an error occurs.

=head3 remove_FITS()

Remove any existing FITS child element. Throw an exception if an error
occurs.

=head3 get_array()

Return a reference to a 2-D array containing the data contents of the
table. Throw an exception if an error occurs.

=head3 get_row($rownum)

Return row $rownum of the data, as an array of values. The array
elements should be interpreted in the same order as the FIELD elements
in the enclosing TABLE element. Throw an exception if an error occurs.

=head3 get_cell($i, $j)

Return column $j of row $i of the data, as a string. Throw an
exception if an error occurs. Note that row and field indices start at
0. NOTE: This method is slow, and should only be used in situations
where speed is not a concern.

=head3 get_num_rows()

Return the number of rows in the table. Throw an exception if an error
occurs.

=head1 WARNINGS

=over 4

=item

None.

=back

=head1 SEE ALSO

=over 4

=item

VOTable::Element

=back

=head1 AUTHOR

Eric Winter, NASA GSFC (Eric.L.Winter.1@gsfc.nasa.gov)

=head1 VERSION

$Id: DATA.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: DATA.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.23  2003/05/31 21:37:17  elwinter
# Rearranged the code and updated documentation.
#
# Revision 1.1.1.22  2003/05/31 21:28:09  elwinter
# Added overriding set_FITS() method.
#
# Revision 1.1.1.21  2003/05/31 21:24:19  elwinter
# Added overriding set_BINARY() method.
#
# Revision 1.1.1.20  2003/05/31 21:20:22  elwinter
# Added overriding set_TABLEDATA() method.
#
# Revision 1.1.1.19  2003/05/16 19:35:58  elwinter
# Invalidated append_TABLEDATA(), append_BINARY(), and append_FITS() methods.
#
# Revision 1.1.1.18  2003/05/16 18:17:17  elwinter
# Added overriding get_FITS() method.
#
# Revision 1.1.1.17  2003/05/16 18:13:43  elwinter
# Added overriding get_BINARY() method.
#
# Revision 1.1.1.16  2003/05/16 16:46:19  elwinter
# Added overriding get_TABLEDATA() method.
#
# Revision 1.1.1.15  2003/04/07 17:25:51  elwinter
# Updated documentation.
#
# Revision 1.1.1.14  2003/03/20 16:09:37  elwinter
# Added get_array() method.
#
# Revision 1.1.1.13  2003/03/14 13:32:33  elwinter
# Added get_cell() method.
#
# Revision 1.1.1.12  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.11  2002/11/19 13:53:28  elwinter
# Moved all element accessors to VOTable::Element class.
#
# Revision 1.1.1.10  2002/11/17 16:29:51  elwinter
# Added code for get_valid_child_element_names.
#
# Revision 1.1.1.9  2002/11/14 17:12:02  elwinter
# Moved new to Element.
#
# Revision 1.1.1.8  2002/11/14 16:37:19  elwinter
# Moved toString and new_from_xmldom to Element.
#
# Revision 1.1.1.7  2002/11/13 19:04:01  elwinter
# Moved all accessor (get/set/remove methods to VOTable::Element AUTOLOAD.
#
# Revision 1.1.1.6  2002/11/12 15:28:33  elwinter
# Added toString method.
#
# Revision 1.1.1.5  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.4  2002/10/25 18:30:22  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.3  2002/09/11  17:50:00  elwinter
# Added get_num_rows() method.
#
# Revision 1.1.1.2  2002/09/11  17:01:03  elwinter
# Added get_row() method.
#
# Revision 1.1.1.1  2002/09/11  16:26:59  elwinter
# Placeholder for new branch.
#
# Revision 1.1  2002/09/11  15:27:33  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::DATA;

# Specify the minimum acceptable Perl version.

# Turn on strict syntax checking.
use strict;

# Use enhanced diagnostic messages.
use diagnostics;

# Use enhanced warnings.
use warnings;

#******************************************************************************

# Set up the inheritance mechanism.
use VOTable::Element;
our @ISA = qw(VOTable::Element);

# Module version.
our $VERSION = 1.0;

#******************************************************************************

# Specify external modules to use.

# Standard modules
use Carp;

# Third-party modules

# Project modules
use VOTable::BINARY;
use VOTable::FITS;
use VOTable::TABLEDATA;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_child_element_names) = qw(TABLEDATA BINARY FITS);

#******************************************************************************

# Method definitions

#******************************************************************************

sub get_TABLEDATA()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::TABLEDATA object for the TABLEDATA child element (if
    # any) of this DATA element.
    my($tabledata);

    #--------------------------------------------------------------------------

    # Find the first TABLEDATA child element, if any.
    ($tabledata) = $self->getChildrenByTagName('TABLEDATA');

    # If found and not yet a VOTable::TABLEDATA object, convert the
    # TABLEDATA object to a VOTable::TABLEDATA object.
    if ($tabledata and not $tabledata->isa('VOTable::TABLEDATA')) {
	$tabledata = VOTable::TABLEDATA->new($tabledata) or
	    croak('Unable to convert TABLEDATA object!');
    }

    # Return the TABLEDATA element object, or undef if none.
    return($tabledata);

}

#******************************************************************************

sub set_TABLEDATA()
{

    # Save arguments.
    my($self, $tabledata) = @_;

    #--------------------------------------------------------------------------

    # Delete any existing TABLEDATA, BINARY, or FITS elements.
    $self->_remove_child_elements('TABLEDATA');
    $self->_remove_child_elements('BINARY');
    $self->_remove_child_elements('FITS');

    # Set the new TABLEDATA element as the first child of this DATA
    # element.
    $self->_append_child_elements($tabledata);

}

#******************************************************************************

sub get_BINARY()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::BINARY object for the BINARY child element (if any) of
    # this DATA element.
    my($binary);

    #--------------------------------------------------------------------------

    # Find the first BINARY child element, if any.
    ($binary) = $self->getChildrenByTagName('BINARY');

    # If found and not yet a VOTable::BINARY object, convert the
    # BINARY object to a VOTable::BINARY object.
    if ($binary and not $binary->isa('VOTable::BINARY')) {
	$binary = VOTable::BINARY->new($binary) or
	    croak('Unable to convert BINARY object!');
    }

    # Return the BINARY element object, or undef if none.
    return($binary);

}

#******************************************************************************

sub set_BINARY()
{

    # Save arguments.
    my($self, $binary) = @_;

    #--------------------------------------------------------------------------

    # Delete any existing TABLEDATA, BINARY, or FITS elements.
    $self->_remove_child_elements('TABLEDATA');
    $self->_remove_child_elements('BINARY');
    $self->_remove_child_elements('FITS');

    # Set the new BINARY element as the first child of this DATA
    # element.
    $self->_append_child_elements($binary);

}

#******************************************************************************

sub get_FITS()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::FITS object for the FITS child element (if any) of this
    # DATA element.
    my($fits);

    #--------------------------------------------------------------------------

    # Find the first FITS child element, if any.
    ($fits) = $self->getChildrenByTagName('FITS');

    # If found and not yet a VOTable::FITS object, convert the FITS
    # object to a VOTable::FITS object.
    if ($fits and not $fits->isa('VOTable::FITS')) {
	$fits = VOTable::FITS->new($fits) or
	    croak('Unable to convert FITS object!');
    }

    # Return the FITS element object, or undef if none.
    return($fits);

}

#******************************************************************************

sub set_FITS()
{

    # Save arguments.
    my($self, $fits) = @_;

    #--------------------------------------------------------------------------

    # Delete any existing TABLEDATA, BINARY, or FITS elements.
    $self->_remove_child_elements('TABLEDATA');
    $self->_remove_child_elements('BINARY');
    $self->_remove_child_elements('FITS');

    # Set the new FITS element as the first child of this DATA
    # element.
    $self->_append_child_elements($fits);

}

#******************************************************************************

sub get_array()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Array of results.
    my($array);

    #--------------------------------------------------------------------------

    # Extract the data based on the underlying data format.
    if ($self->get_TABLEDATA) {
	$array = ($self->get_TABLEDATA)[0]->get_array;
    } elsif ($self->get_binary) {
	croak('BINARY not supported yet!');
    } elsif ($self->get_fits) {
	croak('FITS not supported yet!');
    } else {
	croak('No data found!');
    }

    # Return the array.
    return($array);

}

#******************************************************************************

sub get_row()
{

    # Save arguments.
    my($self, $rownum) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Row of results.
    my(@row);

    #--------------------------------------------------------------------------

    # Extract the row based on the underlying data format.
    if ($self->get_TABLEDATA) {
	@row = ($self->get_TABLEDATA)[0]->get_row($rownum);
    } elsif ($self->get_binary) {
	croak('BINARY not supported yet!');
    } elsif ($self->get_fits) {
	croak('FITS not supported yet!');
    } else {
	croak('No data found!');
    }

    # Return the row.
    return(@row);

}

#******************************************************************************

sub get_cell()
{

    # Save arguments.
    my($self, $i, $j) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Cell value.
    my($cell);

    #--------------------------------------------------------------------------

    # Extract the cell based on the underlying data format.
    if ($self->get_TABLEDATA) {
	$cell = ($self->get_TABLEDATA)[0]->get_cell($i, $j);
    } elsif ($self->get_binary) {
	croak('BINARY not supported yet!');
    } elsif ($self->get_fits) {
	croak('FITS not supported yet!');
    } else {
	croak('No data found!');
    }

    # Return the cell.
    return($cell);

}

#******************************************************************************

sub get_num_rows()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Number of rows in table.
    my($num_rows);

    #--------------------------------------------------------------------------

    # Extract the row count based on the underlying data format.
    if ($self->get_TABLEDATA) {
	$num_rows = ($self->get_TABLEDATA)[0]->get_num_rows;
    } elsif ($self->get_BINARY) {
	croak('BINARY not supported yet!');
    } elsif ($self->get_FITS) {
	croak('FITS not supported yet!');
    } else {
	croak('No data found!');
    }

    # Return row count.
    return($num_rows);

}

#******************************************************************************
#******************************************************************************

# Use overriding methods below to prevent certain methods from being
# invoked via AUTOLOAD in the VOTable::Element class.

sub append_TABLEDATA()
{
    croak('Invalid method!');
}

#******************************************************************************

sub append_BINARY()
{
    croak('Invalid method!');
}

#******************************************************************************

sub append_FITS()
{
    croak('Invalid method!');
}

#******************************************************************************
1;
__END__
