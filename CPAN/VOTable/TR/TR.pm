# TR.pm

=pod

=head1 NAME

VOTable::TR - VOTable TR element class

=head1 SYNOPSIS

use VOTable::TR

=head1 DESCRIPTION

This class implements an interface to VOTable TR elements. This class
inherits from VOTable::Element, and therefore all of the methods from
that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::TR object. Throw an exception if an
error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'TR' element, that object is used to create the
VOTable::TR object (just by reblessing).

=head3 get_TD()

Return a list containing the VOTable::TD objects for the TD child
elements of this TR element. Return an empty list if no TD elements
exist as children of this TR element. Throw an exception if an error
occurs.

=head3 set_TD(@tds)

Use @tds (a list of VOTable::TD objects) to set the TD element
children of this TR element. Any existing TD elements in this TR
element are deleted first. Throw an exception if an error occurs.

=head3 append_TD(@tds)

Use @tds (a list of VOTable::TD objects) to append the TD element
children to this TR element. Any existing TD elements in this TR
element are retained. Throw an exception if an error occurs.

=head3 toString($arg)

Return a string representation of the element and all of its
children. Character entities are replaced with entity references where
appropriate. If $arg is '1', the output has extra whitespace for
readability. If $arg is '2', text content is surrounded by
newlines. This method is directly inherited from XML::LibXML::Element,
so further documentation may be found in the XML::LibXML::Element
manual page.

=head3 as_array()

Return the contents of the TD elements for this TR element as an array
of values. Values for the TD elements are fetched using the TD method,
get(). Throw an exception if an error occurs.

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

$Id: TR.pm,v 1.1 2003/10/13 10:51:23 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: TR.pm,v $
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.13  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.12  2003/04/07 17:29:33  elwinter
# Updated documentation.
#
# Revision 1.1.1.11  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.10  2002/11/19 13:53:28  elwinter
# Moved all element accessors to VOTable::Element class.
#
# Revision 1.1.1.9  2002/11/17 16:29:51  elwinter
# Added code for get_valid_child_element_names.
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
# Revision 1.1.1.5  2002/11/12 15:30:11  elwinter
# Added toString method.
#
# Revision 1.1.1.4  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.3  2002/10/25 18:30:22  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.2  2002/09/11  16:48:44  elwinter
# Added as_array() method.
#
# Revision 1.1.1.1  2002/09/11  16:36:18  elwinter
# Placeholder for new branch.
#
# Revision 1.1  2002/09/11  15:10:29  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::TR;

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
use VOTable::TD;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_child_element_names) = qw(TD);

#******************************************************************************

# Method definitions

#------------------------------------------------------------------------------

sub as_array()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Array of values to return.
    my(@values);

    # Current TD element for this TR.
    my($td);

    #--------------------------------------------------------------------------

    # Empty the values array.
    @values = ();

    # Convert the TD elements to an array.
    foreach $td ($self->get_TD) {
	push(@values, $td->get);
    }

    # Return the array of values.
    return(@values);

}

#******************************************************************************
1;
__END__
