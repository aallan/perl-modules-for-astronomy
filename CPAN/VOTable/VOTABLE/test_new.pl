# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use VOTable::VOTABLE;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;
use XML::LibXML;
use VOTable::DEFINITIONS;
use VOTable::DESCRIPTION;
use VOTable::Document;

# Subroutine prototypes
sub test_new();
sub test_set_ID();
sub test_get_DESCRIPTION();
sub test_set_DESCRIPTION();
sub test_get_DEFINITIONS();

#########################

# Test.
ok(test_new, 1);
ok(test_set_ID, 1);
ok(test_get_DESCRIPTION, 1);
ok(test_set_DESCRIPTION, 1);
ok(test_get_DEFINITIONS, 1);

#########################

sub test_new()
{

    # Local variables

    # New VOTable::VOTABLE object.
    my($votable);

    # XML parser for manufacturing objects.
    my($libxml);

    # Document object for LibXML document.
    my($document);

    #--------------------------------------------------------------------------

    # Test the plain vanilla constructor.
    $votable = new VOTable::VOTABLE or return(0);

    # Create a VOTABLE element via LibXML.
    $libxml = new XML::LibXML or return(0);
    $document = $libxml->parse_string('<VOTABLE/>') or return(0);

    # Convert the XML::LibXML object to a VOTable::VOTABLE object.
    $votable = new VOTable::VOTABLE $document->documentElement() or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_ID()
{

    # Local variables

    # VOTable::VOTABLE object to test with.
    my($votable);

    #--------------------------------------------------------------------------

    # Create a VOTable::VOTABLE object.
    $votable = new VOTable::VOTABLE or return(0);

    # Set the ID to a valid value.
    $votable->set_ID('VALID_ID');

    # Try invalid values.
    eval { $votable->set_ID('1NOT_VALID'); };
    return(0) if not $EVAL_ERROR;
    eval { $votable->set_ID('NOT VALID'); };
    return(0) if not $EVAL_ERROR;

    # All tests succeeded.
    return(1);

}

sub test_get_DESCRIPTION()
{

    # Local variables

    # String of XML to parse.
    my($xml);

    # VOTable::Document object for current document.
    my($document);

    # VOTable::VOTABLE element object for the document element.
    my($votable);

    # VOTable::DESCRIPTION element object for the VOTABLE DESCRIPTION
    # element.
    my($description);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><DESCRIPTION>This is a description!</DESCRIPTION></VOTABLE>';
    $document = new_from_string VOTable::Document $xml or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the DESCRIPTION element.
    $description = $votable->get_DESCRIPTION or return(0);
    $description->get eq 'This is a description!' or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_DESCRIPTION()
{

    # Local variables

    # VOTable::VOTABLE element object to test.
    my($votable);

    # VOTable::DESCRIPTION element object for the VOTABLE DESCRIPTION
    # element.
    my($description);

    #--------------------------------------------------------------------------

    # Create the VOTABLE element.
    $votable = new VOTable::VOTABLE or return(0);

    # Create the DESCRIPTION element.
    $description = new VOTable::DESCRIPTION or return(0);
    $description->set('This is a description.');

    # Set the DESCRIPTION element.
    $votable->set_DESCRIPTION($description);

    # Fetch the DESCRIPTION element.
    $description = $votable->get_DESCRIPTION or return(0);
    $description->get eq 'This is a description.' or return(0);

    # All tests succeeded.
    return(1);

}

sub test_get_DEFINITIONS()
{

    # Local variables

    # String of XML to parse.
    my($xml);

    # VOTable::Document object for current document.
    my($document);

    # VOTable::VOTABLE element object for the document element.
    my($votable);

    # VOTable::DEFINITIONS element object for the VOTABLE DEFINITIONS
    # element.
    my($definitions);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><DEFINITIONS/></VOTABLE>';
    $document = new_from_string VOTable::Document $xml or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the DEFINITIONS element.
    $definitions = $votable->get_DEFINITIONS or return(0);

    # All tests succeeded.
    return(1);

}
