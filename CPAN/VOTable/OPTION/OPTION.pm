# OPTION.pm

=pod

=head1 NAME

VOTable::OPTION - VOTable OPTION element class

=head1 SYNOPSIS

use VOTable::OPTION

=head1 DESCRIPTION

This class implements an interface to VOTable OPTION elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head1 WARNINGS

This class implements an interface to VOTable OPTION elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::OPTION object. Throw an exception if
an error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'OPTION' element, that object is used to create the
VOTable::OPTION object (just by reblessing).

=head3 get_name()

Return the value of the 'name' attribute for this OPTION
element. Return an empty string if the 'name' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_name($name)

Set the value of the 'name' attribute for this OPTION element to the
specified value. Throw an exception if an error occurs.

=head3 remove_name()

Remove the the 'name' attribute for this OPTION element. Throw an
exception if an error occurs.

=head3 get_value()

Return the value of the 'value' attribute for this OPTION
element. Return an empty string if the 'value' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_value($value)

Set the value of the 'value' attribute for this OPTION element to the
specified value. Throw an exception if an error occurs.

=head3 remove_value()

Remove the the 'value' attribute for this OPTION element. Throw an
exception if an error occurs.

=head3 get_OPTION()

Return a list containing the VOTable::OPTION objects for the OPTION
child elements of this OPTION element. Return an empty list if no
OPTION elements exist as children of this OPTION element. Throw an
exception if an error occurs.

=head3 set_OPTION(@options)

Use @options (a list of VOTable::OPTION objects) to set the OPTION
element children of this OPTION element. Any existing OPTION elements
in this OPTION element are deleted first. Throw an exception if an
error occurs.

=head3 append_OPTION(@options)

Use @options (a list of VOTable::OPTION objects) to append the OPTION
element children to this OPTION element. Any existing OPTION elements
in this OPTION element are retained. Throw an exception if an error
occurs.

=head3 toString($arg)

Return a string representation of the element and all of its
children. Character entities are replaced with entity references where
appropriate. If $arg is '1', the output has extra whitespace for
readability. If $arg is '2', text content is surrounded by
newlines. This method is directly inherited from XML::LibXML::Element,
so further documentation may be found in the XML::LibXML::Element
manual page.

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

$Id: OPTION.pm,v 1.1 2003/10/13 10:51:23 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: OPTION.pm,v $
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.10  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.9  2003/04/07 17:28:09  elwinter
# Updated documentation.
#
# Revision 1.1.1.8  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.7  2002/11/19 13:53:28  elwinter
# Moved all element accessors to VOTable::Element class.
#
# Revision 1.1.1.6  2002/11/17 16:29:51  elwinter
# Added code for get_valid_child_element_names.
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
# Revision 1.1  2002/09/11  15:06:23  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::OPTION;

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

our(@valid_child_element_names) = qw(OPTION);

#******************************************************************************

# Method definitions

#******************************************************************************
1;
__END__
