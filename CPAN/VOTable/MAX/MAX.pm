# MAX.pm

=pod

=head1 NAME

VOTable::MAX - VOTable MAX element class

=head1 SYNOPSIS

use VOTable::MAX

=head1 DESCRIPTION

This class implements an interface to VOTable MAX elements. This class
inherits from VOTable::Element, and therefore all of the methods from
that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::MAX object. Throw an exception if an
error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'MAX' element, that object is used to create the
VOTable::MAX object (just by reblessing).

=head3 get()

Return all of the text from within this element as a single
string. Return an empty string if there is no text. Text which
contains character entities is NOT converted to entity
references. Throw an exception if an error occurs.

=head3 set($str)

Set the text content of the element to the specified string. Throw an
exception if an error occurs. Note that the existing text content of
the element is deleted first. Character entities should _not_ be
replaced with the corresponding entity references before this method
is called.

=head3 empty()

Empty the text content of the element. Throw an exception if an error
occurs.

=head3 get_value()

Return the value of the 'value' attribute for this MAX
element. Return an empty string if the 'value' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_value($value)

Set the value of the 'value' attribute for this MAX element to the
specified value. Throw an exception if an error occurs.

=head3 remove_value()

Remove the the 'value' attribute for this MAX element. Throw an
exception if an error occurs.

=head3 get_inclusive()

Return the value of the 'inclusive' attribute for this MAX
element. Return an empty string if the 'inclusive' attribute has not
been set. Throw an exception if an error occurs.

=head3 set_inclusive($inclusive)

Set the value of the 'inclusive' attribute for this MAX element to the
specified value. Throw an exception if an error occurs. Currently
supported values are 'yes' and 'no'.

=head3 remove_inclusive()

Remove the the 'inclusive' attribute for this MAX element. Throw an
exception if an error occurs.

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

Valid attribute values are not currently enforced.

=back

=head1 SEE ALSO

=over 4

=item

VOTable::Element

=back

=head1 AUTHOR

Eric Winter, NASA GSFC (Eric.L.Winter.1@gsfc.nasa.gov)

=head1 VERSION

$Id: MAX.pm,v 1.1 2003/10/13 10:51:23 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: MAX.pm,v $
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.13  2003/05/13 23:45:27  elwinter
# Added overriding set_inclusive() method to check for valid values.
#
# Revision 1.1.1.12  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.11  2003/04/07 17:27:48  elwinter
# Updated documentation.
#
# Revision 1.1.1.10  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.9  2002/11/17 16:05:32  elwinter
# Added code for get_valid_attribute_names.
#
# Revision 1.1.1.8  2002/11/14 17:12:02  elwinter
# Moved new to Element.
#
# Revision 1.1.1.7  2002/11/14 16:37:19  elwinter
# Moved toString and new_from_xmldom to Element.
#
# Revision 1.1.1.6  2002/11/13 19:04:01  elwinter
# Moved all accessor (get/set/remove methods to VOTable::Element AUTOLOAD.
#
# Revision 1.1.1.5  2002/11/13 17:03:36  elwinter
# Moved set() method to VOTable::Element.
#
# Revision 1.1.1.4  2002/11/13 16:30:34  elwinter
# Moved empty() method to VOTable::Element.
#
# Revision 1.1.1.3  2002/11/13 15:50:52  elwinter
# Moved get() method to VOTable::Element.
#
# Revision 1.1.1.2  2002/11/12 15:30:11  elwinter
# Added toString method.
#
# Revision 1.1.1.1  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1  2002/09/11  14:19:56  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::MAX;

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

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(value inclusive);

#******************************************************************************

# Method definitions

#******************************************************************************

sub set_inclusive()
{

    # Save arguments.
    my($self, $inclusive) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # List of valid values for the 'inclusive' attribute.
    my(@valids) = qw(yes no);

    #--------------------------------------------------------------------------

    # Make sure the specified value is allowed.
    die "Invalid inclusive: $inclusive!" if not grep(/^$inclusive$/, @valids);

    # Set the attribute.
    $self->setAttribute('inclusive', $inclusive);

}

#******************************************************************************
1;
__END__
