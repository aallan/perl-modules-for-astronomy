# TABLEDATA.pm

=pod

=head1 NAME

VOTable::TABLEDATA - VOTable TABLEDATA element class

=head1 SYNOPSIS

use VOTable::TABLEDATA

=head1 DESCRIPTION

This class implements an interface to VOTable TABLEDATA elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::TABLEDATA object. Throw an exception
if an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'TABLEDATA' element, that object is used to create the
VOTable::TABLEDATA object (just by reblessing).

=head3 get_TR()

Return a list containing the VOTable::TR objects for the TR child
elements of this TABLEDATA element. Return an empty list if no TR
elements exist as children of this TABLEDATA element. Throw an
exception if an error occurs.

=head3 set_TR(@trs)

Use @trs (a list of VOTable::TR objects) to set the TR element
children of this TABLEDATA element. Any existing TR elements in this
TABLEDATA element are deleted first. Throw an exception if an error
occurs.

=head3 append_TR(@trs)

Use @trs (a list of VOTable::TR objects) to append the TR element
children to this TABLEDATA element. Any existing TR elements in this
TABLEDATA element are retained. Throw an exception if an error occurs.

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
in the enclosing TABLE element. Throw an exception if an error occurs.

=head3 get_cell($i, $j)

Return column $j of row $i of the data, as a string. Throw an
exception if an error occurs. Note that row and field indices start at
0.

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

$Id: TABLEDATA.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: TABLEDATA.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.17  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.16  2003/04/07 17:29:10  elwinter
# Updated documentation.
#
# Revision 1.1.1.15  2003/03/20 16:13:12  elwinter
# Changed getElementsByTagName to getChildrenByTagName.
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
# Revision 1.1.1.6  2002/11/12 15:30:11  elwinter
# Added toString method.
#
# Revision 1.1.1.5  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.4  2002/10/25 18:30:22  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.3  2002/09/11  17:47:19  elwinter
# Added get_num_rows() method.
#
# Revision 1.1.1.2  2002/09/11  16:55:41  elwinter
# Added get_row() method.
#
# Revision 1.1.1.1  2002/09/11  16:31:42  elwinter
# Placeholder for new branch.
#
# Revision 1.1  2002/09/11  15:13:13  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::TABLEDATA;

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
use VOTable::TR;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_child_element_names) = qw(TR);

#******************************************************************************

# Method definitions

#------------------------------------------------------------------------------

sub get_array()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # Array to hold the data.
    my($array);

    # Number of rows in the table.
    my($num_rows);

    # XML::LibXML::NodeList object for the child TR elements.
    my($nodelist);

    # Current TR element.
    my($tr);

    # Loop counter.
    my($i);

    #--------------------------------------------------------------------------

    # Create the array to hold the data.
    $array = [];

    # Fetch a list of the TR elements.
    $nodelist = $self->getChildrenByTagName('TR');
    return(undef) if not $nodelist;

    # Fetch the number of rows in the table.
    $num_rows = $nodelist->size or croak;

    # Process each TR element.
    for ($i = 0; $i < $num_rows; $i++) {
	$tr = $nodelist->get_node($i + 1) or croak;
	bless $tr => 'VOTable::TR';
	$array->[$i] = [$tr->as_array];
    }

    # Return the array.
    return($array);

}

#------------------------------------------------------------------------------

sub get_row()
{

    # Save arguments.
    my($self, $rownum) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # XML::LibXML::NodeList object for the child TR elements.
    my($nodelist);

    # Desired TR element.
    my($tr);

    # Array to hold fields of the row.
    my(@row);

    #--------------------------------------------------------------------------

    # Fetch a list of the TR elements.
    $nodelist = $self->getChildrenByTagName('TR')
	or croak('TABLEDATA has no TR!');

    # Fetch the specific TR element.
    $tr = $nodelist->get_node($rownum + 1)
	or croak('Undefined TR!');
    $tr = new VOTable::TR($tr)
	or croak('Unable to convert TR!');

    # Fetch the fields for the row.
    @row = $tr->as_array;

    # Return the row.
    return(@row);

}

#------------------------------------------------------------------------------

sub get_cell()
{

    # Save arguments.
    my($self, $i, $j) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # XML::LibXML::NodeList object for the child TR elements.
    my($tr_nodelist);

    # Desired TR element.
    my($tr);

    # XML::LibXML::NodeList object for child TD elements.
    my($td_nodelist);

    # Desired TD element.
    my($td);

    # Cell value to return.
    my($cell);

    #--------------------------------------------------------------------------

    # Fetch a list of the TR elements.
    $tr_nodelist = $self->getChildrenByTagName('TR')
	or croak('TABLEDATA has no TR!');

    # Fetch the specific TR element.
    $tr = $tr_nodelist->get_node($i + 1)
	or croak("Undefined TR $i!");

    # Fetch a list of the TD elements.
    $td_nodelist = $tr->getChildrenByTagName('TD')
	or croak('TR has no TD!');

    # Fetch the specific TD element.
    $td = $td_nodelist->get_node($j + 1)
	or croak("TR $i had no TD $j!");
    $td = new VOTable::TD($td)
	or croak('Unable to convert TD!');

    # Fetch the value of the cell.
    $cell = $td->get;

    # Return the cell value.
    return($cell);

}

#------------------------------------------------------------------------------

# get_num_rows()

# Fetch the number of rows in the table. Return undef if an error
# occurs.

sub get_num_rows()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # XML::LibXML::NodeList object for the child TR elements.
    my($nodelist);

    # Number of rows.
    my($num_rows);

    #--------------------------------------------------------------------------

    # Fetch a list of the TR elements.
    $nodelist = $self->getChildrenByTagName('TR');
    return(0) if not $nodelist;

    # Count the number of TR elements.
    $num_rows = $nodelist->size;

    # Return the row count.
    return($num_rows);

}

#******************************************************************************
1;
__END__
