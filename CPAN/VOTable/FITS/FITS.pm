# FITS.pm

=pod

=head1 NAME

VOTable::FITS - VOTable FITS element class

=head1 SYNOPSIS

use VOTable::FITS

=head1 DESCRIPTION

This class implements an interface to VOTable FITS elements. This
class inherits from VOTable::Element, and therefore all of the methods
from that class are available to this class.

=head2 Methods

=head3 new($arg)

Create and return a new VOTable::FITS object. Throw an exception if an
error occurs. If $arg is supplied, and is a XML::LibXML::Element
object for a 'FITS' element, that object is used to create the
VOTable::FITS object (just by reblessing).

=head3 get_extnum()

Return the value of the 'extnum' attribute for this FITS
element. Return an empty string if the 'extnum' attribute has not been
set. Throw an exception if an error occurs.

=head3 set_extnum($extnum)

Set the value of the 'extnum' attribute for this FITS element to the
specified value. Throw an exception if an error occurs.

=head3 remove_extnum()

Remove the the 'extnum' attribute for this FITS element. Throw an
exception if an error occurs.

=head3 get_STREAM()

Return the VOTable::STREAM object for the STREAM child element of this
BINARY element, or undef if this BINARY has no STREAM. Throw an
exception if an error occurs.

=head3 set_STREAM(@stream)

Use @stream (a list of one VOTable::STREAM object) to set the STREAM
element child of this FITS element. Any existing STREAM element in
this FITS element are deleted first. Each FITS can only have one
STREAM, so the list should contain a single element. Throw an
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

The code does NOT currently enforce the restriction of a FITS element
having only a single STREAM child element.

=back

=head1 SEE ALSO

=over 4

=item

VOTable::Element

=back

=head1 AUTHOR

Eric Winter, NASA GSFC (Eric.L.Winter.1@gsfc.nasa.gov)

=head1 VERSION

$Id: FITS.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: FITS.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.13  2003/05/16 19:29:39  elwinter
# Invalidated append_STREAM() method.
#
# Revision 1.1.1.12  2003/05/16 19:14:59  elwinter
# Added overriding get_STREAM() method.
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:27:09  elwinter
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
# Revision 1.1  2002/09/11  14:53:20  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::FITS;

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
use VOTable::STREAM;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

our(@valid_attribute_names) = qw(extnum);
our(@valid_child_element_names) = qw(STREAM);

#******************************************************************************

# Method definitions

#******************************************************************************

sub get_STREAM()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # VOTable::STREAM object for the STREAM child element (if any) of
    # this FITS element.
    my($stream);

    #--------------------------------------------------------------------------

    # Find the first STREAM child element, if any.
    ($stream) = $self->getChildrenByTagName('STREAM');

    # If found and not yet a VOTable::STREAM object, convert the
    # STREAM object to a VOTable::STREAM object.
    if ($stream and not $stream->isa('VOTable::STREAM')) {
	$stream = VOTable::STREAM->new($stream) or
	    croak('Unable to convert STREAM object!');
    }

    # Return the STREAM element object, or undef if none.
    return($stream);

}

#******************************************************************************

sub append_STREAM()
{
    croak('Invalid method!');
}

#******************************************************************************
1;
__END__
