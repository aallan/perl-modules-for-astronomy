# FIELD.pm

=pod

=head1 NAME

VOTable::FIELD - VOTable FIELD element class

=head1 SYNOPSIS

use VOTable::FIELD

=head1 DESCRIPTION

This class implements an interface to VOTable FIELD elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::FIELD object. Throw an exception if
an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'FIELD' element, that object is used to create the
VOTable::FIELD object (just by reblessing).

=head3 get_ID()

Return the value of the 'ID' attribute for this FIELD element. Return
an empty string if the 'ID' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ID($id)

Set the value of the 'ID' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ID()

Remove the the 'ID' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_unit()

Return the value of the 'unit' attribute for this FIELD
element. Return an empty string if the 'unit' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_unit($unit)

Set the value of the 'unit' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_unit()

Remove the the 'unit' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_datatype()

Return the value of the 'datatype' attribute for this FIELD
element. Return an empty string if the 'datatype' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_datatype($datatype)

Set the value of the 'datatype' attribute for this FIELD element to
the specified value. Throw an exception if an error occurs. Valid
values are 'boolean', 'bit', 'unsignedByte', 'short', 'int', 'long',
'char', 'unicodeChar', 'float', 'double', 'floatComplex', and
'doubleComplex'.

=head3 remove_datatype()

Remove the the 'datatype' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_precision()

Return the value of the 'precision' attribute for this FIELD
element. Return an empty string if the 'precision' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_precision($precision)

Set the value of the 'precision' attribute for this FIELD element to
the specified value. Throw an exception if an error occurs.

=head3 remove_precision()

Remove the the 'precision' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_width()

Return the value of the 'width' attribute for this FIELD
element. Return an empty string if the 'width' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_width($width)

Set the value of the 'width' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_width()

Remove the the 'width' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_ref()

Return the value of the 'ref' attribute for this FIELD element. Return
an empty string if the 'ref' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ref($ref)

Set the value of the 'ref' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ref()

Remove the the 'ref' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_name()

Return the value of the 'name' attribute for this FIELD
element. Return an empty string if the 'name' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_name($name)

Set the value of the 'name' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_name()

Remove the the 'name' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_ucd()

Return the value of the 'ucd' attribute for this FIELD element. Return
an empty string if the 'ucd' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ucd($ucd)

Set the value of the 'ucd' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ucd()

Remove the the 'ucd' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_arraysize()

Return the value of the 'arraysize' attribute for this FIELD
element. Return an empty string if the 'arraysize' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_arraysize($arraysize)

Set the value of the 'arraysize' attribute for this FIELD element to
the specified value. Throw an exception if an error occurs.

=head3 remove_arraysize()

Remove the the 'arraysize' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_type()

Return the value of the 'type' attribute for this FIELD
element. Return an empty string if the 'type' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_type($type)

Set the value of the 'type' attribute for this FIELD element to the
specified value. Throw an exception if an error occurs. Valid values
are 'hidden', 'no_query', and 'trigger'.

=head3 remove_type()

Remove the the 'type' attribute for this FIELD element. Throw an
exception if an error occurs.

=head3 get_DESCRIPTION()

Return the VOTable::DESCRIPTION object for the DESCRIPTION child
element of this FIELD element, or undef if this FIELD has no
DESCRIPTION. Throw an exception if an error occurs.

=head3 set_DESCRIPTION(@description)

Use $description (a VOTable::DESCRIPTION object, or a
XML::LibXML::Element object for a DESCRIPTION element) to set the
DESCRIPTION element child of this FIELD element. Any existing
DESCRIPTION child element in this FIELD element is deleted
first. Throw an exception if an error occurs.

=head3 get_VALUES()

Return a list containing the VOTable::VALUES objects for the VALUES
child elements of this FIELD element. Return an empty list if no
VALUES elements exist as a child of this FIELD element. Throw an
exception if an error occurs.

=head3 set_VALUES(@values)

Use @values (a list of VOTable::VALUES objects) to set the VALUES
element children of this FIELD element. Any existing VALUES elements
in this FIELD element are deleted first. Throw an exception if an
error occurs.

=head3 append_VALUES(@values)

Use @values (a list of VOTable::VALUES objects) to append the VALUES
element children to this FIELD element. Any existing VALUES elements
in this FIELD element are retained. Throw an exception if an error
occurs.

=head3 get_LINKS()

Return a list containing the VOTable::LINKS objects for the LINKS
child elements of this FIELD element. Return an empty list if no LINKS
elements exist as a child of this FIELD element. Throw an exception if
an error occurs.

=head3 set_LINKS(@links)

Use @links (a list of VOTable::LINKS objects) to set the LINKS element
children of this FIELD element. Any existing LINKS elements in this
FIELD element are deleted first. Throw an exception if an error
occurs.

=head3 append_LINKS(@links)

Use @links (a list of VOTable::LINKS objects) to append the LINKS
element children to this FIELD element. Any existing LINKS elements in
this FIELD element are retained. Throw an exception if an error
occurs.

=head3 toString($arg)

Return a string representation of the element and all of its
children. Character entities are replaced with entity references where
appropriate. If $arg is '1', the output has extra whitespace for
readability. If $arg is '2', text content is surrounded by
newlines. This method is directly inherited from XML::LibXML::Element,
so further documentation may be found in the XML::LibXML::Element
manual page.

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

$Id: FIELD.pm,v 1.1 2003/10/13 10:51:23 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: FIELD.pm,v $
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.16  2003/06/01 17:59:08  elwinter
# Added overriding set_DESCRIPTION() method.
#
# Revision 1.1.1.15  2003/05/16 19:38:07  elwinter
# Invalidated append_DESCRIPTION() method.
#
# Revision 1.1.1.14  2003/05/16 18:29:27  elwinter
# Added overriding get_DESCRIPTION() method.
#
# Revision 1.1.1.13  2003/05/13 21:46:17  elwinter
# Added overriding set_type() method to check for valid values.
#
# Revision 1.1.1.12  2003/05/13 21:41:46  elwinter
# Added overriding set_datatype() method to check for valid values.
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:26:59  elwinter
# Updated documentation.
#
# Revision 1.1.1.9  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.8  2002/11/19 13:53:28  elwinter
# Moved all element accessors to VOTable::Element class.
#
# Revision 1.1.1.7  2002/11/17 16:29:51  elwinter
# Added code for get_valid_child_element_names.
#
# Revision 1.1.1.6  2002/11/17 16:05:32  elwinter
# Added code for get_valid_attribute_names.
#
# Revision 1.1.1.5  2002/11/14 17:12:02  elwinter
# Moved new to Element.
#
# Revision 1.1.1.4  2002/11/14 16:37:19  elwinter
# Moved toString and new_from_xmldom to Element.
#
# Revision 1.1.1.3  2002/11/13 19:04:01  elwinter
# Moved all accessor (get/set/remove methods to VOTable::Element AUTOLOAD.
#
# Revision 1.1.1.2  2002/11/12 15:30:11  elwinter
# Added toString method.
#
# Revision 1.1.1.1  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1  2002/09/11  15:41:04  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::FIELD;

# Specify the minimum acceptable Perl version.
use 5.6.1;

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

# Third-party modules

# Project modules
use VOTable::DESCRIPTION;
use VOTable::LINK;
use VOTable::VALUES;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(ID unit datatype precision width ref name
				 ucd arraysize type);
our(@valid_child_element_names) = qw(DESCRIPTION VALUES LINK);

#******************************************************************************

# Method definitions

#******************************************************************************

sub set_datatype()
{

    # Save arguments.
    my($self, $datatype) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # List of valid values for the 'datatype' attribute.
    my(@valids) = qw(boolean bit unsignedByte short int long char
		     unicodeChar float double floatComplex doubleComplex);

    #--------------------------------------------------------------------------

    # Make sure the specified value is allowed.
    die "Invalid datatype: $datatype!" if not grep(/^$datatype$/, @valids);

    # Set the attribute.
    $self->setAttribute('datatype', $datatype);

}

#******************************************************************************

sub set_type()
{

    # Save arguments.
    my($self, $type) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # List of valid values for the 'type' attribute.
    my(@valids) = qw(hidden no_query trigger);

    #--------------------------------------------------------------------------

    # Make sure the specified value is allowed.
    die "Invalid type: $type!" if not grep(/^$type$/, @valids);

    # Set the attribute.
    $self->setAttribute('type', $type);

}

#******************************************************************************

sub get_DESCRIPTION()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::DESCRIPTION object for the DESCRIPTION child element
    # (if any) of this FIELD element.
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

sub set_DESCRIPTION()
{

    # Save arguments.
    my($self, $description) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # Reference to first child element of this FIELD.
    my($first_child_element);

    #--------------------------------------------------------------------------

    # Delete any existing DESCRIPTION element.
    $self->_remove_child_elements('DESCRIPTION');

    # Set the new DESCRIPTION element as the first child element of
    # this FIELD element.
    $first_child_element = $self->firstChild;
    while ($first_child_element) {
	last if $first_child_element->nodeType == 1;
	$first_child_element = $first_child_element->nextSibling;
    }
    if (not $first_child_element) {
	$self->appendChild($description);
    } elsif ($first_child_element->nodeType == 1) {
	$self->insertBefore($description, $first_child_element);
    } else {
	$self->insertAfter($description, $first_child_element);
    }

}

#******************************************************************************

sub append_DESCRIPTION()
{
    croak('Invalid method!');
}

#******************************************************************************
1;
__END__
