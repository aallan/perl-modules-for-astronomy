# TABLE.pm

=pod

=head1 NAME

VOTable::TABLE - VOTable TABLE element class

=head1 SYNOPSIS

use VOTable::TABLE

=head1 DESCRIPTION

This class implements an interface to VOTable TABLE elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::TABLE object. Throw an exception if
an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'TABLE' element, that object is used to create the
VOTable::TABLE object (just by reblessing).

=head3 get_ID()

Return the value of the 'ID' attribute for this TABLE element. Return
an empty string if the 'ID' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ID($id)

Set the value of the 'ID' attribute for this TABLE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ID()

Remove the the 'ID' attribute for this TABLE element. Throw an
exception if an error occurs.

=head3 get_name()

Return the value of the 'name' attribute for this TABLE
element. Return an empty string if the 'name' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_name($name)

Set the value of the 'name' attribute for this TABLE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_name()

Remove the the 'name' attribute for this TABLE element. Throw an
exception if an error occurs.

=head3 get_ref()

Return the value of the 'ref' attribute for this TABLE element. Return
an empty string if the 'ref' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ref($ref)

Set the value of the 'ref' attribute for this TABLE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ref()

Remove the the 'ref' attribute for this TABLE element. Throw an
exception if an error occurs.

=head3 get_DESCRIPTION()

Return the VOTable::DESCRIPTION object for the DESCRIPTION child
element of this TABLE element, or undef if this TABLE has no
DESCRIPTION. Throw an exception if an error occurs.

=head3 set_DESCRIPTION(@description)

Use @description (a list of a single VOTable::DESCRIPTION object) to
set the DESCRIPTION element child of this TABLE element. Any existing
DESCRIPTION element in this TABLE element is deleted first. Throw an
exception if an error occurs.

=head3 get_LINK()

Return a list containing the VOTable::LINKS objects for the LINKS
child elements of this TABLE element. Return an empty list if no LINKS
elements exist as a child of this TABLE element. Throw an exception if
an error occurs.

=head3 set_LINK(@links)

Use @links (a list of VOTable::LINKS objects) to set the LINKS element
children of this TABLE element. Any existing LINKS elements in this
TABLE element are deleted first. Throw an exception if an error
occurs.

=head3 append_LINK(@links)

Use @links (a list of VOTable::LINKS objects) to append the LINKS
element children to this TABLE element. Any existing LINKS elements in
this TABLE element are retained. Throw an exception if an error
occurs.

=head3 get_FIELD()

Return a list containing the VOTable::FIELDS objects for the FIELDS
child elements of this TABLE element. Return an empty list if no
FIELDS elements exist as a child of this TABLE element. Throw an
exception if an error occurs.

=head3 set_FIELD(@fields)

Use @fields (a list of VOTable::FIELDS objects) to set the FIELDS
element children of this TABLE element. Any existing FIELDS elements
in this TABLE element are deleted first. Throw an exception if an
error occurs.

=head3 append_FIELD(@fields)

Use @fields (a list of VOTable::FIELDS objects) to append the FIELDS
element children to this TABLE element. Any existing FIELDS elements
in this TABLE element are retained. Throw an exception if an error
occurs.

=head3 get_DATA()

Return the VOTable::DATA object for the DATA child element of this
TABLE element, or undef if this TABLE has no DATA. Throw an exception
if an error occurs.

=head3 set_DATA(@data)

Use @data (a list of a single VOTable::DATA object) to set the DATA
element child of this TABLE element. Any existing DATA element in this
TABLE element is deleted first. Throw an exception if an error occurs.

=head3 toString($arg)

Return a string representation of the element and all of its
children. Character entities are replaced with entity references where
appropriate. If $arg is '1', the output has extra whitespace for
readability. If $arg is '2', text content is surrounded by
newlines. This method is directly inherited from XML::LibXML::Element,
so further documentation may be found in the XML::LibXML::Element
manual page.

=head3 get_array()

Return a reference to a 2-D array containing the data contents of the
table. Throw an exception if an error occurs.

=head3 get_row($rownum)

Return row $rownum of the data, as an array of values. The array
elements should be interpreted in the same order as the FIELD elements
in the TABLE. Throw an exception if an error occurs.

=head3 get_cell($i, $j)

Return column $j of row $i of the data, as a string. Throw an
exception if an error occurs. Note that row and field indices start at
0.

=head3 get_field_position_by_name($field_name)

Compute the position of the FIELD element with the specified name, and
return it. Throw an exception if an error occurs.

=head3 get_field_position_by_ucd($field_ucd)

Compute the position of the FIELD element with the specified UCD, and
return it. Throw an exception if an error occurs.

=head3 get_num_rows()

Return the number of rows in the table. Return undef if an error
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

$Id: TABLE.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: TABLE.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.24  2003/08/12 17:24:37  elwinter
# Fixed memory leak in get_field_position_by_ucd().
#
# Revision 1.1.1.23  2003/06/08 15:22:19  elwinter
# Added use Carp.
#
# Revision 1.1.1.22  2003/05/16 19:45:18  elwinter
# Invalidated append_DESCRIPTION() and append_DATA() methods.
#
# Revision 1.1.1.21  2003/05/16 13:59:37  elwinter
# Added overriding get_DATA() method.
#
# Revision 1.1.1.20  2003/05/16 13:56:33  elwinter
# Added overriding get_DESCRIPTION() method.
#
# Revision 1.1.1.19  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.18  2003/04/07 17:29:02  elwinter
# Updated documentation.
#
# Revision 1.1.1.17  2003/03/20 16:09:37  elwinter
# Added get_array() method.
#
# Revision 1.1.1.16  2003/03/14 13:32:33  elwinter
# Added get_cell() method.
#
# Revision 1.1.1.15  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.14  2002/11/19 15:14:01  elwinter
# Added code to check for empty table.
#
# Revision 1.1.1.13  2002/11/19 13:53:28  elwinter
# Moved all element accessors to VOTable::Element class.
#
# Revision 1.1.1.12  2002/11/17 16:29:51  elwinter
# Added code for get_valid_child_element_names.
#
# Revision 1.1.1.11  2002/11/17 16:05:32  elwinter
# Added code for get_valid_attribute_names.
#
# Revision 1.1.1.10  2002/11/14 17:12:02  elwinter
# Moved new to Element.
#
# Revision 1.1.1.9  2002/11/14 16:37:19  elwinter
# Moved toString and new_from_xmldom to Element.
#
# Revision 1.1.1.8  2002/11/13 19:04:01  elwinter
# Moved all accessor (get/set/remove methods to VOTable::Element AUTOLOAD.
#
# Revision 1.1.1.7  2002/11/12 15:30:11  elwinter
# Added toString method.
#
# Revision 1.1.1.6  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.5  2002/10/25 18:30:22  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.4  2002/09/11  17:54:13  elwinter
# Added get_num_rows() method.
#
# Revision 1.1.1.3  2002/09/11  17:28:46  elwinter
# Added get_field_position_by_name() and get_field_position_by_ucd() methods.
#
# Revision 1.1.1.2  2002/09/11  17:04:39  elwinter
# Added get_row() method.
#
# Revision 1.1.1.1  2002/09/11  16:23:30  elwinter
# Placeholder for new branch.
#
# Revision 1.1  2002/09/11  15:54:44  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::TABLE;

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
use VOTable::DATA;
use VOTable::DESCRIPTION;
use VOTable::FIELD;
use VOTable::LINK;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(ID name ref);
our(@valid_child_element_names) = qw(DESCRIPTION LINK FIELD DATA);

#******************************************************************************

# Method definitions

#******************************************************************************

sub get_DESCRIPTION()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::DESCRIPTION object for the DESCRIPTION child element
    # (if any) of this TABLE object.
    my($description);

    #--------------------------------------------------------------------------

    # Find the first DESCRIPTION child element, if any.
    ($description) = $self->getChildrenByTagName('DESCRIPTION');

    # If found and not yet a VOTable::DESCRIPTION object, convert the
    # DESCRIPTION object to a VOTable::DESCRIPTION object.
    if ($description and not $description->isa('VOTable::DESCRIPTION')) {
	$description = VOTable::DESCRIPTION->new($description) or
	    croak('Unable to convert DESCRIPTION object!');
    }

    # Return the DESCRIPTION element object, or undef if none.
    return($description);

}

#******************************************************************************

sub append_DESCRIPTION()
{
    croak('Invalid method!');
}

#******************************************************************************

sub get_DATA()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::DATA object for the DATA child element (if any) of this
    # TABLE object.
    my($data);

    #--------------------------------------------------------------------------

    # Find the first DATA child element, if any.
    ($data) = $self->getChildrenByTagName('DATA');

    # If found and not yet a VOTable::DATA object, convert the DATA
    # object to a VOTable::DATA object.
    if ($data and not $data->isa('VOTable::DATA')) {
	$data = VOTable::DATA->new($data) or
	    croak('Unable to convert DATA object!');
    }

    # Return the DATA element object, or undef if none.
    return($data);

}

#******************************************************************************

sub append_DATA()
{
    croak('Invalid method!');
}

#------------------------------------------------------------------------------

# get_table()

# Fetch the contents of the table as a 2-D array.

sub get_array()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Reference to array of table data.
    my($array);

    #--------------------------------------------------------------------------

    # Extract the table data as an array.
    $array = ($self->get_DATA)[0]->get_array;

    # Return the array.
    return($array);

}

#------------------------------------------------------------------------------

# get_row()

# Fetch a single row from the table and return an array containing its
# values.

sub get_row()
{

    # Save arguments.
    my($self, $rownum) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Reference to underlying VOTable::DATA object.
    my($data);

    # Row of results.
    my(@row);

    #--------------------------------------------------------------------------

    # Extract the row.
    @row = ($self->get_DATA)[0]->get_row($rownum);

    # Return the row.
    return(@row);

}

#------------------------------------------------------------------------------

# get_cell()

# Fetch a single cell from the table and return its value.

sub get_cell()
{

    # Save arguments.
    my($self, $i, $j) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Cell value.
    my($cell);

    #--------------------------------------------------------------------------

    # Extract the cell.
    $cell = ($self->get_DATA)[0]->get_cell($i, $j);

    # Return the cell.
    return($cell);

}

#------------------------------------------------------------------------------

# get_field_position_by_name()

sub get_field_position_by_name()
{

    # Save arguments.
    my($self, $field_name) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Current FIELD element object.
    my($field);

    # Position of desired FIELD element.
    my($field_position);

    #--------------------------------------------------------------------------

    # Determine the position of the FIELD element with the specified
    # name.
    $field_position = 0;
    foreach $field ($self->get_FIELD) {
	last if $field->get_name eq $field_name;
	$field_position++;
    }

    # Make sure the desired FIELD was found.
    undef($field_position) if $field_position == scalar($self->get_FIELD);

    # Return the FIELD pposition.
    return($field_position);

}

#------------------------------------------------------------------------------

# get_field_position_by_ucd()

sub get_field_position_by_ucd()
{

    # Save arguments.
    my($self, $field_ucd) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Current FIELD element object.
    my($field);

    # Position of desired FIELD element.
    my($field_position);

    # Temporary array to hold FIELDs.
    my(@fields);

    #--------------------------------------------------------------------------

    # Determine the position of the FIELD element with the specified
    # UCD.
    $field_position = 0;
    foreach $field ($self->get_FIELD) {
	last if $field->get_ucd eq $field_ucd;
	$field_position++;
    }

    # Make sure the desired FIELD was found.
    @fields = $self->get_FIELD;
    undef($field_position) if $field_position == scalar(@fields);

    # Return the FIELD pposition.
    return($field_position);

}

#------------------------------------------------------------------------------

# get_num_rows()

sub get_num_rows()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Number of rows in table.
    my($num_rows);

    #--------------------------------------------------------------------------

    # Count the rows.
    if ($self->get_DATA) {
	$num_rows = ($self->get_DATA)[0]->get_num_rows;
    } else {
	$num_rows = 0;
    }

    # Return row count.
    return($num_rows);

}

#******************************************************************************
1;
__END__
