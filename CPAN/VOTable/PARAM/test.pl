# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use VOTable::PARAM;
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
sub test_get_DESCRIPTION();

#########################

# Test.
ok(test_set_datatype, 1);
ok(test_get_DESCRIPTION, 1);

#########################

sub test_set_datatype()
{

    # Local variables

    # Reference to test PARAM object.
    my($param);

    # Current datatype value.
    my($datatype);

    # Valid datatype attribute values.
    my(@valids) = qw(boolean bit unsignedByte short int long char
		     unicodeChar float double floatComplex doubleComplex);

    #--------------------------------------------------------------------------

    # Create the object.
    $param = new VOTable::PARAM or return(0);

    # Try each of the valid values.
    foreach $datatype (@valids) {
	$param->set_datatype($datatype);
	$param->get_datatype eq $datatype or return(0);
    }

    # Make sure bad values fail.
    eval { $param->set_datatype('BAD_VALUE!'); };
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

    # VOTable::PARAM object for the PARAM element.
    my($param);

    # VOTable::DESCRIPTION object for the DESCRIPTION element.
    my($description);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><DESCRIPTION>This is a PARAM description!</DESCRIPTION></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the PARAM element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);

    # Fetch the DESCRIPTION element.
    $description = $param->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is a PARAM description!' or return(0);

    # All tests succeeded.
    return(1);

}
