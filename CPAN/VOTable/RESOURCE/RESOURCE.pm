# RESOURCE.pm

=pod

=head1 NAME

VOTable::RESOURCE - VOTable RESOURCE element class

=head1 SYNOPSIS

use VOTable::RESOURCE

=head1 DESCRIPTION

This class implements an interface to VOTable RESOURCE elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::RESOURCE object. Throw an exception
if an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'RESOURCE' element, that object is used to create the
VOTable::RESOURCE object (just by reblessing).

=head3 get_name()

Return the value of the 'name' attribute for this RESOURCE
element. Return an empty string if the 'name' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_name($name)

Set the value of the 'name' attribute for this RESOURCE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_name()

Remove the the 'name' attribute for this RESOURCE element. Throw an
exception if an error occurs.

=head3 get_ID()

Return the value of the 'ID' attribute for this RESOURCE
element. Return an empty string if the 'ID' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_ID($id)

Set the value of the 'ID' attribute for this RESOURCE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ID()

Remove the the 'ID' attribute for this RESOURCE element. Throw an
exception if an error occurs.

=head3 get_type()

Return the value of the 'type' attribute for this RESOURCE
element. Return an empty string if the 'type' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_type($type)

Set the value of the 'type' attribute for this RESOURCE element to the
specified value. Throw an exception if an error occurs. Valid types
are 'results' and 'meta'.

=head3 remove_type()

Remove the the 'type' attribute for this RESOURCE element. Throw an
exception if an error occurs.

=head3 get_DESCRIPTION()

Return the VOTable::DESCRIPTION object for the DESCRIPTION child
element of this RESOURCE element, or undef if this RESOURCE has no
DESCRIPTION. Throw an exception if an error occurs.

=head3 set_DESCRIPTION(@description)

Use @description (a list of a single VOTable::DESCRIPTION object) to
set the DESCRIPTION element child of this RESOURCE element. Any
existing DESCRIPTION element in this RESOURCE element is deleted
first. Throw an exception if an error occurs.

=head3 get_INFO()

Return a list containing the VOTable::INFO objects for the INFO child
elements of this RESOURCE element. Return an empty list if no INFO
elements exist as a child of this RESOURCE element. Throw an exception
if an error occurs.

=head3 set_INFO(@info)

Use @info (a list of VOTable::INFO objects) to set the INFO element
children of this RESOURCE element. Any existing INFO elements in this
RESOURCE element are deleted first. Throw an exception if an error
occurs.

=head3 append_INFO(@info)

Use @info (a list of VOTable::INFO objects) to append the INFO element
children to this RESOURCE element. Any existing INFO elements in this
RESOURCE element are retained. Throw an exception if an error occurs.

=head3 get_COOSYS()

Return a list containing the VOTable::COOSYS objects for the COOSYS
child elements of this RESOURCE element. Return an empty list if no
COOSYS elements exist as a child of this RESOURCE element. Throw an
exception if an error occurs.

=head3 set_COOSYS(@coosys)

Use @coosys (a list of VOTable::COOSYS objects) to set the COOSYS
element children of this RESOURCE element. Any existing COOSYS
elements in this RESOURCE element are deleted first. Throw an
exception if an error occurs.

=head3 append_COOSYS(@coosys)

Use @coosys (a list of VOTable::COOSYS objects) to append the COOSYS
element children to this RESOURCE element. Any existing COOSYS
elements in this RESOURCE element are retained. Throw an exception if
an error occurs.

=head3 get_PARAM()

Return a list containing the VOTable::PARAM objects for the PARAM
child elements of this RESOURCE element. Return an empty list if no
PARAM elements exist as a child of this RESOURCE element. Throw an
exception if an error occurs.

=head3 set_PARAM(@param)

Use @param (a list of VOTable::PARAM objects) to set the PARAM element
children of this RESOURCE element. Any existing PARAM elements in this
RESOURCE element are deleted first. Throw an exception if an error
occurs.

=head3 append_PARAM(@param)

Use @param (a list of VOTable::PARAM objects) to append the PARAM
element children to this RESOURCE element. Any existing PARAM elements
in this RESOURCE element are retained. Throw an exception if an error
occurs.

=head3 get_LINK()

Return a list containing the VOTable::LINK objects for the LINK child
elements of this RESOURCE element. Return an empty list if no LINK
elements exist as a child of this RESOURCE element. Throw an exception
if an error occurs.

=head3 set_LINK(@link)

Use @link (a list of VOTable::LINK objects) to set the LINK element
children of this RESOURCE element. Any existing LINK elements in this
RESOURCE element are deleted first. Throw an exception if an error
occurs.

=head3 append_LINK(@link)

Use @link (a list of VOTable::LINK objects) to append the LINK element
children to this RESOURCE element. Any existing LINK elements in this
RESOURCE element are retained. Throw an exception if an error occurs.

=head3 get_TABLE()

Return a list containing the VOTable::TABLE objects for the TABLE
child elements of this RESOURCE element. Return an empty list if no
TABLE elements exist as a child of this RESOURCE element. Throw an
exception if an error occurs.

=head3 set_TABLE(@table)

Use @table (a list of VOTable::TABLE objects) to set the TABLE element
children of this RESOURCE element. Any existing TABLE elements in this
RESOURCE element are deleted first. Throw an exception if an error
occurs.

=head3 append_TABLE(@table)

Use @table (a list of VOTable::TABLE objects) to append the TABLE
element children to this RESOURCE element. Any existing TABLE elements
in this RESOURCE element are retained. Throw an exception if an error
occurs.

=head3 get_RESOURCE()

Return a list containing the single VOTable::RESOURCE object for the
RESOURCE child element of this RESOURCE element. Return an empty list
if no RESOURCE element exists as a child of this RESOURCE
element. Throw an exception if an error occurs.

=head3 set_RESOURCE(@resource)

Use @resource (a list of a single VOTable::RESOURCE object) to set the
RESOURCE element child of this RESOURCE element. Any existing RESOURCE
element in this RESOURCE element is deleted first. Throw an exception
if an error occurs.

=head3 append_RESOURCE(@resource)

Use @resource (a list of a single VOTable::RESOURCE object) to append
the RESOURCE element child to this RESOURCE element. Any existing
RESOURCE element in this RESOURCE element is retained, which is an
error condition. Throw an exception if an error occurs.

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

$Id: RESOURCE.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: RESOURCE.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.14  2003/05/16 19:47:30  elwinter
# Invalidated append_DESCRIPTION() method.
#
# Revision 1.1.1.13  2003/05/16 13:47:56  elwinter
# Added overriding get_DESCRIPTION() method.
#
# Revision 1.1.1.12  2003/05/13 21:33:34  elwinter
# Added overriding set_type() method to check for valid values.
#
# Revision 1.1.1.12  2003/05/13 21:04:57  elwinter
# Added overriding set_type() method to check for allowed values.
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:28:32  elwinter
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
# Revision 1.1  2002/09/11  15:59:01  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::RESOURCE;

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

# Third-party modules

# Project modules
use VOTable::COOSYS;
use VOTable::DESCRIPTION;
use VOTable::INFO;
use VOTable::LINK;
use VOTable::PARAM;
use VOTable::TABLE;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(name ID type);
our(@valid_child_element_names) = qw(DESCRIPTION INFO COOSYS PARAM LINK TABLE
				     RESOURCE);

#******************************************************************************

# Method definitions

#******************************************************************************

sub set_type()
{

    # Save arguments.
    my($self, $type) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # List of valid values for the 'type' attribute.
    my(@valids) = qw(results meta);

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
    # (if any) of this RESOURCE element.
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
1;
__END__
