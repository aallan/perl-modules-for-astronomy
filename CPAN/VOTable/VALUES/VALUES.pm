# VALUES.pm

=pod

=head1 NAME

VOTable::VALUES - VOTable VALUES element class

=head1 SYNOPSIS

use VOTable::VALUES

=head1 DESCRIPTION

This class implements an interface to VOTable VALUES elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::VALUES object. Throw an exception if
an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'VALUES' element, that object is used to create the
VOTable::VALUES object (just by reblessing).

=head3 get_ID()

Return the value of the 'ID' attribute for this VALUES element. Return
an empty string if the 'ID' attribute has not been set. Throw an
exception if an error occurs.

=head3 set_ID($id)

Set the value of the 'ID' attribute for this VALUES element to the
specified value. Throw an exception if an error occurs.

=head3 remove_ID()

Remove the the 'ID' attribute for this VALUES element. Throw an
exception if an error occurs.

=head3 get_type()

Return the value of the 'type' attribute for this VALUES
element. Return an empty string if the 'type' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_type($type)

Set the value of the 'type' attribute for this VALUES element to the
specified value. Throw an exception if an error occurs. Valid values
are 'legal' and 'actual'.

=head3 remove_type()

Remove the the 'type' attribute for this VALUES element. Throw an
exception if an error occurs.

=head3 get_null()

Return the value of the 'null' attribute for this VALUES
element. Return an empty string if the 'null' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_null($null)

Set the value of the 'null' attribute for this VALUES element to the
specified value. Throw an exception if an error occurs.

=head3 remove_null()

Remove the the 'null' attribute for this VALUES element. Throw an
exception if an error occurs.

=head3 get_invalid()

Return the value of the 'invalid' attribute for this VALUES
element. Return an empty string if the 'invalid' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_invalid($invalid)

Set the value of the 'invalid' attribute for this VALUES element to
the specified value. Throw an exception if an error occurs. Valid
values are 'yes' and 'no'.

=head3 remove_invalid()

Remove the the 'invalid' attribute for this VALUES element. Throw an
exception if an error occurs.

=head3 get_MIN()

Return the VOTable::MIN object for the MIN child element of this
VALUES element, or undef if this VALUES has no MIN. Throw an exception
if an error occurs.

=head3 set_MIN($min)

Use $min (a VOTable::MIN object, or a XML::LibXML::Element object for
a MIN element) to set the MIN element child of this VALUES
element. Any existing MIN element in this VALUES element is deleted
first. Throw an exception if an error occurs.

=head3 get_MAX()

Return the VOTable::MAX object for the MAX child element of this
VALUES element, or undef if this VALUES has no MAX. Throw an exception
if an error occurs.

=head3 set_MAX(@max)

Use $max (a VOTable::MAX object, or a XML::LibXML::Element object for
a MAX element) to set the MAX element child of this VALUES
element. Any existing MAX element in this VALUES element is deleted
first. Throw an exception if an error occurs.

=head3 get_OPTION()

Return a list containing the VOTable::OPTION objects for the OPTION
child elements of this VALUES element. Return an empty list if no
OPTION elements exist as children of this VALUES element. Throw an
exception if an error occurs.

=head3 set_OPTION(@options)

Use @options (a list of VOTable::OPTION objects) to set the OPTION
element children of this VALUES element. Any existing OPTION elements
in this OPTION element are deleted first. Throw an exception if an
error occurs.

=head3 append_OPTION(@options)

Use @options (a list of VOTable::OPTION objects) to append the OPTION
element children to this VALUES element. Any existing OPTION elements
in this VALUES element are retained. Throw an exception if an error
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

$Id: VALUES.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: VALUES.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.18  2003/05/21 16:23:26  elwinter
# Added overriding set_MAX() method.
#
# Revision 1.1.1.17  2003/05/21 15:49:40  elwinter
# Added overriding set_MIN() method.
#
# Revision 1.1.1.16  2003/05/16 19:33:56  elwinter
# Invalidated append_MIN() and append_MAX() methods.
#
# Revision 1.1.1.15  2003/05/16 18:49:56  elwinter
# Added overriding get_MAX() method.
#
# Revision 1.1.1.14  2003/05/16 18:47:28  elwinter
# Added overriding get_MIN() method.
#
# Revision 1.1.1.13  2003/05/13 22:27:56  elwinter
# Added overriding set_invalid() method, to check for valid values.
#
# Revision 1.1.1.12  2003/05/13 22:25:29  elwinter
# Added overriding set_type() method, to check for valid values.
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:29:40  elwinter
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
# Revision 1.1  2002/09/11  15:17:25  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::VALUES;

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
use VOTable::MAX;
use VOTable::MIN;
use VOTable::OPTION;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(ID type null invalid);
our(@valid_child_element_names) = qw(MIN MAX OPTION);

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
    my(@valids) = qw(legal actual);

    #--------------------------------------------------------------------------

    # Make sure the specified value is allowed.
    die "Invalid type: $type!" if not grep(/^$type$/, @valids);

    # Set the attribute.
    $self->setAttribute('type', $type);

}

#******************************************************************************

sub set_invalid()
{

    # Save arguments.
    my($self, $invalid) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # List of valid values for the 'invalid' attribute.
    my(@valids) = qw(yes no);

    #--------------------------------------------------------------------------

    # Make sure the specified value is allowed.
    die "Invalid invalid: $invalid!" if not grep(/^$invalid$/, @valids);

    # Set the attribute.
    $self->setAttribute('invalid', $invalid);

}

#******************************************************************************

sub get_MIN()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::MIN object for the MIN child element (if any) of this
    # VALUES element.
    my($min);

    #--------------------------------------------------------------------------

    # Find the first MIN child element, if any.
    ($min) = $self->getChildrenByTagName('MIN');

    # If found and not yet a VOTable::MIN object, convert the MIN
    # object to a VOTable::MIN object.
    if ($min and not $min->isa('VOTable::MIN')) {
	$min = VOTable::MIN->new($min) or
	    croak('Unable to convert MIN object!');
    }

    # Return the MIN element object, or undef if none.
    return($min);

}

#******************************************************************************

sub set_MIN()
{

    # Save arguments.
    my($self, $min) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::MIN object for existing MIN element, if any.
    my($old_min);

    # XML::LibXML::Element object for the first child element (if any)
    # of this VALUES elelement.
    my($first_child);

    #--------------------------------------------------------------------------

    # Make sure the argument is a valid object.
    if (not $min->isa('VOTable::MIN')) {
	if (not $min->isa('XML::LibXML::Element')) {
	    croak('Must be a VOTable::MIN object or a XML::LibXML::Element ' .
		  'object for a MIN element!');
	} elsif ($min->nodeName ne 'MIN') {
	    croak('Must be a MIN element!');
	}
    }

    # If there is an existing MIN element, replace it. Otherwise, set
    # the new MIN element to be the first child element of this VALUES
    # element.
    if ($self->hasChildNodes) {
	if ($old_min = $self->get_MIN) {
	    $self->replaceChild($min, $old_min);
	} else {
	    $first_child = $self->firstChild;
	    $self->insertBefore($min, $first_child);
	}   
    } else {
	$self->appendChild($min);
    }

}

#******************************************************************************

sub get_MAX()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::MAX object for the MAX child element (if any) of this
    # VALUES element.
    my($max);

    #--------------------------------------------------------------------------

    # Find the first MAX child element, if any.
    ($max) = $self->getChildrenByTagName('MAX');

    # If found and not yet a VOTable::MAX object, convert the MAX
    # object to a VOTable::MAX object.
    if ($max and not $max->isa('VOTable::MAX')) {
	$max = VOTable::MAX->new($max) or
	    croak('Unable to convert MAX object!');
    }

    # Return the MAX element object, or undef if none.
    return($max);

}

#******************************************************************************

sub set_MAX()
{

    # Save arguments.
    my($self, $max) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::MAX object for existing MAX element, if any.
    my($old_max);

    # XML::LibXML::Element object for the first child element (if any)
    # of this VALUES elelement.
    my($first_child);

    # VOTable::MIN object for any existing MIN child element of this
    # VALUES element.
    my($old_min);

    #--------------------------------------------------------------------------

    # Make sure the argument is a valid object.
    if (not $max->isa('VOTable::MAX')) {
	if (not $max->isa('XML::LibXML::Element')) {
	    croak('Must be a VOTable::MAX object or a XML::LibXML::Element ' .
		  'object for a MAX element!');
	} elsif ($max->nodeName ne 'MAX') {
	    croak('Must be a MAX element!');
	}
    }

    # If there is an existing MAX element, replace it. Otherwise, set
    # the new MAX element to be the first child element _after_ any
    # MIN element child of this VALUES element.
    if ($self->hasChildNodes) {
	if ($old_max = $self->get_MAX) {
	    $self->replaceChild($max, $old_max);
	} elsif ($old_min = $self->get_MIN) {
	    $self->insertAfter($max, $old_min);
	} else {
	    $first_child = $self->firstChild;
	    $self->insertBefore($max, $first_child);
	}
    } else {
	$self->appendChild($max);
    }

}

#******************************************************************************

sub append_MIN()
{
    croak('Invalid method!');
}

#******************************************************************************

sub append_MAX()
{
    croak('Invalid method!');
}

#******************************************************************************
1;
__END__
