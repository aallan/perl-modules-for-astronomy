# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use VOTable::FIELD;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;
use VOTable::Document;

# Subroutine prototypes
sub test_set_datatype();
sub test_set_type();
sub test_get_DESCRIPTION();
sub test_set_DESCRIPTION();

#########################

# Test.
ok(test_set_datatype, 1);
ok(test_set_type, 1);
ok(test_get_DESCRIPTION, 1);
ok(test_set_DESCRIPTION, 1);

#########################

sub test_set_datatype()
{

    # Local variables

    # Reference to test FIELD object.
    my($field);

    # Current datatype value.
    my($datatype);

    # Valid datatype attribute values.
    my(@valids) = qw(boolean bit unsignedByte short int long char
		     unicodeChar float double floatComplex doubleComplex);

    #--------------------------------------------------------------------------

    # Create the object.
    $field = new VOTable::FIELD or return(0);

    # Try each of the valid values.
    foreach $datatype (@valids) {
	$field->set_datatype($datatype);
	$field->get_datatype eq $datatype or return(0);
    }

    # Make sure bad values fail.
    eval { $field->set_datatype('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}

sub test_set_type()
{

    # Local variables

    # Reference to test FIELD object.
    my($field);

    # Current type value.
    my($type);

    # Valid type attribute values.
    my(@valids) = qw(hidden no_query trigger);

    #--------------------------------------------------------------------------

    # Create the object.
    $field = new VOTable::FIELD or return(0);

    # Try each of the valid values.
    foreach $type (@valids) {
	$field->set_type($type);
	$field->get_type eq $type or return(0);
    }

    # Make sure bad values fail.
    eval { $field->set_type('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
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

    # VOTable::RESOURCE object for the RESOURCE element.
    my($resource);

    # VOTable::TABLE object for the TABLE element.
    my($table);

    # VOTable::FIELD object for the FIELD element.
    my($field);

    # VOTable::DESCRIPTION object for the DESCRIPTION element.
    my($description);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><FIELD><DESCRIPTION>This is a FIELD description!</DESCRIPTION></FIELD></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the FIELD element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $table = ($resource->get_TABLE)[0] or return(0);
    $field = ($table->get_FIELD)[0] or return(0);

    # Fetch the DESCRIPTION element.
    $description = $field->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is a FIELD description!' or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_DESCRIPTION()
{

    # Local variables

    # String of XML to parse.
    my($xml);

    # VOTable::Document object for current document.
    my($document);

    # VOTable::VOTABLE object for the document element.
    my($votable);

    # VOTable::RESOURCE object for the RESOURCE element.
    my($resource);

    # VOTable::TABLE object for the TABLE element.
    my($table);

    # VOTable::FIELD object for the FIELD element.
    my($field);

    # VOTable::DESCRIPTION object for the DESCRIPTION element.
    my($description);

    #--------------------------------------------------------------------------

    # Test a FIELD without any child elements.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><FIELD/></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the FIELD element.
    $field = ($table->get_FIELD)[0] or return(0);

    # Create the DESCRIPTION element.
    $description = VOTable::DESCRIPTION->new() or return(0);
    $description->set('This is a test.');

    # Set then fetch the DESCRIPTION element.
    $field->set_DESCRIPTION($description);
    $description = $field->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is a test.' or return(0);

    #--------------------------------------------------------------------------

    # Make sure it works when replacing another DESCRIPTION.

    # Create the second DESCRIPTION element.
    $description = VOTable::DESCRIPTION->new() or return(0);
    $description->set('This is another test.');

    # Set then fetch the DESCRIPTION element.
    $field->set_DESCRIPTION($description);
    $description = $field->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is another test.' or return(0);

    #--------------------------------------------------------------------------

    # Make sure it works when other child elements are present.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><FIELD><VALUES/></FIELD></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the FIELD element.
    $field = ($table->get_FIELD)[0] or return(0);

    # Create the DESCRIPTION element.
    $description = VOTable::DESCRIPTION->new() or return(0);
    $description->set('This is yet another test.');

    # Set then fetch the DESCRIPTION element.
    $field->set_DESCRIPTION($description);
    $description = $field->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is yet another test.' or return(0);

    # All tests succeeded.
    return(1);

}
