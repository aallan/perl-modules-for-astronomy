# VOTABLE.pm

=pod

=head1 NAME

VOTable::VOTABLE - VOTable VOTABLE element class

=head1 SYNOPSIS

use VOTable::VOTABLE

=head1 DESCRIPTION

This class implements an interface to VOTable VOTABLE elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::VOTABLE object. Throw an exception if
an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'VOTABLE' element, that object is used to create the
VOTable::VOTABLE object (just by reblessing).

=head3 get_ID()

Return the value of the 'ID' attribute for this VOTABLE
element. Return an empty string if the 'ID' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_ID($id)

Set the value of the 'ID' attribute for this VOTABLE element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ID()

Remove the the 'ID' attribute for this VOTABLE element. Throw an
exception if an error occurs.

=head3 get_version()

Return the value of the 'version' attribute for this VOTABLE
element. Return an empty string if the 'version' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_version($version)

Set the value of the 'version' attribute for this VOTABLE element to
the specified value. Throw an exception if an error occurs.

=head3 remove_version()

Remove the the 'version' attribute for this VOTABLE element. Throw an
exception if an error occurs.

=head3 get_DESCRIPTION()

Return the VOTable::DESCRIPTION object for the DESCRIPTION child
element of this VOTABLE element, or undef if this VOTABLE has no
DESCRIPTION. Throw an exception if an error occurs.

=head3 set_DESCRIPTION(@description)

Use @description (a list of a single VOTable::DESCRIPTION object) to
set the DESCRIPTION element child of this VOTABLE element. Any
existing DESCRIPTION element in this VOTABLE element is deleted
first. Throw an exception if an error occurs.

=head3 get_DEFINITIONS()

Return the VOTable::DEFINITIONS object for the DEFINITIONS child
element of this VOTABLE element, or undef if this VOTABLE has no
DEFINITIONS. Throw an exception if an error occurs.

=head3 set_DEFINITIONS(@definitions)

Use @definitions (a list of a single VOTable::DEFINITIONS object) to
set the DEFINITIONS element child of this VOTABLE element. Any
existing DEFINITIONS element in this VOTABLE element is deleted
first. Throw an exception if an error occurs.

=head3 get_INFO()

Return a list containing the VOTable::INFO objects for the INFO child
elements of this VOTABLE element. Return an empty list if no INFO
elements exist as a child of this VOTABLE element. Throw an exception
if an error occurs.

=head3 set_INFO(@info)

Use @info (a list of VOTable::INFO objects) to set the INFO element
children of this VOTABLE element. Any existing INFO elements in this
VOTABLE element are deleted first. Throw an exception if an error
occurs.

=head3 append_INFO(@info)

Use @info (a list of VOTable::INFO objects) to append the INFO element
children to this VOTABLE element. Any existing INFO elements in this
VOTABLE element are retained. Throw an exception if an error occurs.

=head3 get_RESOURCE()

Return a list containing the single VOTable::RESOURCE object for the
RESOURCE child element of this VOTABLE element. Return an empty list
if no RESOURCE element exists as a child of this VOTABLE
element. Throw an exception if an error occurs.

=head3 set_RESOURCE(@resource)

Use @resource (a list of a single VOTable::RESOURCE object) to set the
RESOURCE element child of this VOTABLE element. Any existing RESOURCE
element in this VOTABLE element is deleted first. Throw an exception
if an error occurs.

=head3 append_RESOURCE(@resource)

Use @resource (a list of a single VOTable::RESOURCE object) to append
the RESOURCE element child to this VOTABLE element. Any existing
RESOURCE element in this VOTABLE element is retained, which is an
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

$Id: VOTABLE.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: VOTABLE.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.14  2003/05/16 19:48:49  elwinter
# Invalidated append_DESCRIPTION() and append_DEFINITIONS() methods.
#
# Revision 1.1.1.13  2003/05/16 13:36:03  elwinter
# Added overriding get_DEFINITIONS() method.
#
# Revision 1.1.1.12  2003/05/16 13:25:53  elwinter
# Added overriding get_DESCRIPTION() method.
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:29:52  elwinter
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
# Revision 1.1  2002/09/11  16:01:07  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::VOTABLE;

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
use VOTable::DEFINITIONS;
use VOTable::DESCRIPTION;
use VOTable::INFO;
use VOTable::RESOURCE;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(ID version);
our(@valid_child_element_names) = qw(DESCRIPTION DEFINITIONS INFO RESOURCE);

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
    # (if any) of this VOTABLE object.
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

sub get_DEFINITIONS()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::DEFINITIONS object for the DEFINITIONS child element
    # (if any) of this VOTABLE object.
    my($definitions);

    #--------------------------------------------------------------------------

    # Find the first DEFINITIONS child element, if any.
    ($definitions) = $self->getChildrenByTagName('DEFINITIONS');

    # If found and not yet a VOTable::DEFINITIONS object, convert the
    # DEFINITIONS object to a VOTable::DEFINITIONS object.
    if ($definitions and not $definitions->isa('VOTable::DEFINITIONS')) {
	$definitions = VOTable::DEFINITIONS->new($definitions) or
	    croak('Unable to convert DEFINITIONS object!');
    }

    # Return the DEFINITIONS element object, or undef if none.
    return($definitions);

}

#******************************************************************************

sub append_DESCRIPTION()
{
    croak('Invalid method!');
}

#******************************************************************************

sub append_DEFINITIONS()
{
    croak('Invalid method!');
}

#******************************************************************************
1;
__END__
