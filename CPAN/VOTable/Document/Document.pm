# Document.pm

=pod

=head1 NAME

VOTable::Document - VOTable document class

=head1 SYNOPSIS

use VOTable::Document

$doc = VOTable::Document->new;
$doc = VOTable::Document->new_from_string('<?xml version="1.0"?><VOTABLE/>');
$doc = VOTable::Document->new_from_file('votable.xml');
$votable = $doc->get_VOTABLE;
$doc->set_VOTABLE($votable);

=head1 DESCRIPTION

This class implements an interface to VOTable documents. This class
inherits from XML::LibXML:Document.

Upon initial loading of this module, the BEGIN subroutine creates a
XML::LibXML parser object for global use by the class.

=head2 Methods

=head3 new(%args)

Create and return a new VOTable::Document object, containing a single,
empty VOTABLE element. Throw an exception if an error occurs. The
%args argument is used to pass optional named parameters to the
constructor, in name => value format. The 'version' argument may be
used to set the XML version in the XML declaration (the default
version is '1.0'). The 'encoding' argument may be used to set the
document encoding (the default encoding is 'UTF8').

=head3 new_from_string($xml)

Create and return a new VOTable::Document object using the specified
XML string. Throw an exception if an error occurs.

=head3 new_from_file($path)

Create and return a new VOTable::Document object using the contents
(presumably valid XML!) of the specified file. Throw an exception if
an error occurs.

=head3 get_VOTABLE()

Return a VOTable::VOTABLE object for the VOTABLE element at the root
of this Document. Throw an exception if no VOTABLE element is found,
or an error occurs.

=head3 set_VOTABLE($votable)

Set the VOTABLE element for this Document using the supplied
VOTable::VOTABLE object. Return the old VOTABLE element on success, or
raise an exception if an error occurs.

=head1 WARNINGS

=over 4

=item

None.

=back

=head1 SEE ALSO

=over 4

=item

XML::DOM::Document

=back

=head1 AUTHOR

Eric Winter, NASA GSFC (elwinter@milkyway.gsfc.nasa.gov)

=head1 VERSION

$Id: Document.pm,v 1.2 2004/02/12 18:12:21 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: Document.pm,v $
# Revision 1.2  2004/02/12 18:12:21  aa
# Removed 'use 5.6.1' pragmas
#
# Revision 1.1  2003/10/13 10:51:23  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.13  2003/05/16 13:24:58  elwinter
# Changed to use isa() method.
#
# Revision 1.1.1.12  2003/05/16 11:37:58  elwinter
# Changed get_VOTABLE to use new() rather than bless().
#
# Revision 1.1.1.11  2003/04/09 16:25:00  elwinter
# Changed VERSION to 1.0.
#
# Revision 1.1.1.10  2003/04/07 17:26:41  elwinter
# Updated documentation.
#
# Revision 1.1.1.9  2003/03/12 12:41:44  elwinter
# Overhauled to use XML::LibXML.
#
# Revision 1.1.1.8  2002/12/02 19:07:22  elwinter
# Cleaned up toString method, modified constructors to properly bless children.
#
# Revision 1.1.1.7  2002/12/02 18:49:16  elwinter
# Added toString() method.
#
# Revision 1.1.1.6  2002/11/19 15:13:20  elwinter
# Changed get_votable to get_VOTABLE.
#
# Revision 1.1.1.5  2002/11/14 16:37:19  elwinter
# Moved toString and new_from_xmldom to Element.
#
# Revision 1.1.1.4  2002/11/13 19:04:01  elwinter
# Moved all accessor (get/set/remove methods to VOTable::Element AUTOLOAD.
#
# Revision 1.1.1.3  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1.1.2  2002/09/12  17:36:53  elwinter
# Added stub document code to ensure a root VOTABLE element is created.
#
# Revision 1.1.1.1  2002/09/12  17:29:39  elwinter
# Placeholder for new branch.
#
# Revision 1.1  2002/09/11  16:04:04  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable::Document;

# Specify the minimum acceptable Perl version.

# Turn on strict syntax checking.
use strict;

# Use enhanced diagnostic messages.
use diagnostics;

# Use enhanced warnings.
use warnings;

#******************************************************************************

# Set up the inheritance mechanism.
use XML::LibXML;
our @ISA = qw(XML::LibXML::Document);

# Module version.
our $VERSION = 1.0;

#******************************************************************************

# Specify external modules to use.

# Standard modules
use Carp;

# Third-party modules

# Project modules
use VOTable::VOTABLE;

#******************************************************************************

# Class constants

#******************************************************************************

# Class variables

# This object is used to perform all parsing.
my($parser);

#******************************************************************************

BEGIN
{

    # Create the class parser.
    $parser = XML::LibXML->new or croak;

}

#******************************************************************************

# Method definitions

#------------------------------------------------------------------------------

sub new()
{

    # Save arguments.
    my($class, %args) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # Reference to new object.
    my($self);

    # New VOTABLE element.
    my($votable);

    #--------------------------------------------------------------------------

    # Create the object with the appropriate arguments.
    if ($args{'version'} and $args{'encoding'}) {
	$self = XML::LibXML::Document->new($args{'version'},
					   $args{'encoding'}) or croak;
    } elsif ($args{'version'}) {
	$self = XML::LibXML::Document->new($args{'version'}) or croak;
    } elsif ($args{'encoding'}) {
	$self = XML::LibXML::Document->new('1.0', $args{'encoding'}) or croak;
    } else {
	$self = XML::LibXML::Document->new or croak;
    }

    # Bless the new object into this class.
    bless $self => $class;

    # Create and add an empty VOTABLE element.
    $votable = XML::LibXML::Element->new('VOTABLE') or croak;
    $self->setDocumentElement($votable);

    # Return a reference to the new object.
    return($self);

}

#------------------------------------------------------------------------------

sub new_from_string()
{

    # Save arguments.
    my($class, $xml) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # Reference to new object.
    my($self);

    #--------------------------------------------------------------------------

    # Parse the XML to create a XML::LibXML::Document object.
    $self = $parser->parse_string($xml) or croak;

    # Bless into this class.
    bless $self => $class;

    # Return a reference to the new object.
    return($self);

}

#------------------------------------------------------------------------------

sub new_from_file()
{

    # Save arguments.
    my($class, $path) = @_;

    #--------------------------------------------------------------------------

    # Local variables

    # Reference to new object.
    my($self);

    #--------------------------------------------------------------------------

    # Parse the XML file to create a XML::LibXML::Document object.
    $self = $parser->parse_file($path) or croak;

    # Bless into this class.
    bless $self => $class;

    # Return a reference to the new object.
    return($self);

}

#------------------------------------------------------------------------------

sub get_VOTABLE()
{

    # Save arguments.
    my($self) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # VOTable::VOTABLE for VOTABLE element.
    my($votable);

    #--------------------------------------------------------------------------

    # Find the first (only) VOTABLE child element.
    $votable = $self->documentElement
	or croak('No VOTABLE element in document!');

    # If not one already, convert it to a VOTable::VOTABLE object.
    if (not $votable->isa('VOTable::VOTABLE')) {
	$votable = VOTable::VOTABLE->new($votable)
	    or croak('Unable to convert VOTABLE!');
    }

    # Return the VOTABLE element object.
    return($votable);

}

#------------------------------------------------------------------------------

sub set_VOTABLE()
{

    # Save arguments.
    my($self, $votable) = @_;

    #--------------------------------------------------------------------------

    # Local variables.

    # Old VOTABLE element object.
    my($old_votable);

    #--------------------------------------------------------------------------

    # Replace the existing VOTABLE element.
    $old_votable = $self->get_VOTABLE or croak;
    $self->replaceChild($votable, $old_votable);

    # Return the old element.
    return($old_votable);

}

#******************************************************************************
1;
__END__
