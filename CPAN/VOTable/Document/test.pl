# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
use VOTable::Document;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;

# Subroutine prototypes
sub test_new();
sub test_new_from_string();
sub test_new_from_file();
sub test_get_VOTABLE();
sub test_set_VOTABLE();

#########################

# Test the constructor.
ok(test_new, 1);
ok(test_new_from_string, 1);
ok(test_new_from_file, 1);
ok(test_get_VOTABLE, 1);
ok(test_set_VOTABLE, 1);

#########################

sub test_new()
{
    my($document);
    $document = VOTable::Document->new or return(0);
    $document = VOTable::Document->new('version' => '2.0') or return(0);
    $document = VOTable::Document->new('encoding' => 'UTF8') or return(0);
    $document = VOTable::Document->new('version' => '1.0',
				       'encoding' => 'UTF8') or return(0);
    return(1);
}

sub test_new_from_string()
{
    my($xml) = '<VOTABLE/>';
    my($document);

    # Parse the XML into a document object.
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # All tests passed.
    return(1);

}

sub test_new_from_file()
{
    my($xml) = '<VOTABLE/>';
    my($document);
    my($testfile) = 'test.xml';

    # Create the test file.
    open(TEST, ">$testfile") or return(0);
    print TEST $xml;
    close(TEST) or return(0);

    # Parse the XML into a document object.
    $document = new_from_file VOTable::Document $testfile or return(0);

    # Delete the test file.
    unlink($testfile) or return(0);

    # All tests passed.
    return(1);

}

sub test_get_VOTABLE()
{

    # Local variables

    # Object for test document.
    my($document);

    # XML for test document.
    my($xml) = '<VOTABLE ID="test_ID"/>';

    # Object for test VOTABLE element.
    my($votable);

    #--------------------------------------------------------------------------

    # Create a document.
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Extract the VOTABLE element object.
    $votable = $document->get_VOTABLE or return(0);
    $votable->isa('VOTable::VOTABLE') or return(0);
    $votable->get_ID eq 'test_ID' or return(0);

    # All tests passed.
    return(1);

}

sub test_set_VOTABLE()
{
    my($document);
    my($votable);

    # Create the document, then get a reference to its VOTABLE
    # element.
    $document = VOTable::Document->new or return(0);

    # Set the VOTABLE element of the Document.
    $votable = new XML::LibXML::Element 'VOTABLE' or return(0);
    $document->set_VOTABLE($votable) or return(0);

    # All tests passed.
    return(1);

}
