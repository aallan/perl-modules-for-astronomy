# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use VOTable::VALUES;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;
use VOTable::Document;

# Subroutine prototypes
sub test_set_type();
sub test_set_invalid();
sub test_get_MIN();
sub test_set_MIN();
sub test_get_MAX();
sub test_set_MAX();

#########################

# Test.
ok(test_set_type, 1);
ok(test_set_invalid, 1);
ok(test_get_MIN, 1);
ok(test_set_MIN, 1);
ok(test_get_MAX, 1);
ok(test_set_MAX, 1);

#########################

sub test_set_type()
{

    # Local variables

    # Reference to test VALUES object.
    my($values);

    # Current type value.
    my($type);

    # Valid type attribute values.
    my(@valids) = qw(legal actual);

    #--------------------------------------------------------------------------

    # Create the object.
    $values = new VOTable::VALUES or return(0);

    # Try each of the valid values.
    foreach $type (@valids) {
	$values->set_type($type);
	$values->get_type eq $type or return(0);
    }

    # Make sure bad values fail.
    eval { $values->set_type('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}

sub test_set_invalid()
{

    # Local variables

    # Reference to test VALUES object.
    my($values);

    # Current invalid value.
    my($invalid);

    # Valid invalid attribute values.
    my(@valids) = qw(yes no);

    #--------------------------------------------------------------------------

    # Create the object.
    $values = new VOTable::VALUES or return(0);

    # Try each of the valid values.
    foreach $invalid (@valids) {
	$values->set_invalid($invalid);
	$values->get_invalid eq $invalid or return(0);
    }

    # Make sure bad values fail.
    eval { $values->set_invalid('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}

sub test_get_MIN()
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

    # VOTable::VALUES object for the VALUES element.
    my($values);

    # VOTable::MIN object for the MIN element.
    my($min);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MIN>-1</MIN></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Fetch the MIN element.
    $min = $values->get_MIN or return(0);
    $min->isa('VOTable::MIN') or return(0);
    $min->get == -1 or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_MIN()
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

    # VOTable::VALUES object for the VALUES element.
    my($values);

    # VOTable::MIN object for the old and new MIN element.
    my($old_min, $new_min);

    #--------------------------------------------------------------------------

    # Test setting the MIN for an empty VALUES.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES/></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MIN element.
    $new_min = new VOTable::MIN or return(0);
    $new_min->set(-2);

    # Set the MIN.
    $values->set_MIN($new_min);

    # Make sure it worked.
    $old_min = $values->get_MIN or return(0);
    $old_min->isa('VOTable::MIN') or return(0);
    $old_min->get == -2 or return(0);

    # Make sure the MIN element is the first child.
    $old_min = $values->firstChild;
    $old_min->textContent eq '-2' or return(0);

    #--------------------------------------------------------------------------

    # Test setting the MIN for a VALUES with an existing MAX (should
    # put the MIN before the MAX).

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MAX>1</MAX></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MIN element.
    $new_min = new VOTable::MIN or return(0);
    $new_min->set(-2);

    # Set the MIN.
    $values->set_MIN($new_min);

    # Make sure it worked.
    $old_min = $values->get_MIN or return(0);
    $old_min->isa('VOTable::MIN') or return(0);
    $old_min->get == -2 or return(0);

    # Make sure the MIN element is the first child.
    $old_min = $values->firstChild;
    $old_min->textContent eq '-2' or return(0);

    #--------------------------------------------------------------------------

    # Test replacing an existing MIN.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MIN>-1</MIN><MAX>1</MAX></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MIN element.
    $new_min = new VOTable::MIN or return(0);
    $new_min->set(-2);

    # Fetch the existing MIN element.
    $old_min = $values->get_MIN or return(0);
    $old_min->isa('VOTable::MIN') or return(0);
    $old_min->get == -1 or return(0);

    # Replace it.
    $values->set_MIN($new_min);

    # Make sure it worked.
    $old_min = undef;
    $old_min = $values->get_MIN or return(0);
    $old_min->isa('VOTable::MIN') or return(0);
    $old_min->get == -2 or return(0);

    # Make sure the MIN element is the first child.
    $old_min = undef;
    $old_min = $values->firstChild;
    $old_min->textContent eq '-2' or return(0);

    # All tests succeeded.
    return(1);

}

sub test_get_MAX()
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

    # VOTable::VALUES object for the VALUES element.
    my($values);

    # VOTable::MAX object for the MAX element.
    my($max);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MAX>1</MAX></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Fetch the MAX element.
    $max = $values->get_MAX or return(0);
    $max->isa('VOTable::MAX') or return(0);
    $max->get == 1 or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_MAX()
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

    # VOTable::VALUES object for the VALUES element.
    my($values);

    # VOTable::MAX object for the old and new MAX element.
    my($old_max, $new_max);

    # VOTable::MIN object for the existing MIN element.
    my($old_min);

    #--------------------------------------------------------------------------

    # Test setting the MAX for an empty VALUES.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES/></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MAX element.
    $new_max = new VOTable::MAX or return(0);
    $new_max->set(999);

    # Set the MAX.
    $values->set_MAX($new_max);

    # Make sure it worked.
    $old_max = $values->get_MAX or return(0);
    $old_max->isa('VOTable::MAX') or return(0);
    $old_max->get == 999 or return(0);

    # Make sure the MAX element is the first child.
    $old_max = $values->firstChild;
    $old_max->textContent eq '999' or return(0);

    #--------------------------------------------------------------------------

    # Test setting the MAX for a VALUES with an existing MIN (should
    # put the MAX after the MIN).

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MIN>-1</MIN></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MAX element.
    $new_max = new VOTable::MAX or return(0);
    $new_max->set(999);

    # Set the MAX.
    $values->set_MAX($new_max);

    # Make sure it worked.
    $old_max = $values->get_MAX or return(0);
    $old_max->isa('VOTable::MAX') or return(0);
    $old_max->get == 999 or return(0);

    # Make sure the MAX element is the second child.
    $old_min = $values->get_MIN;
    $old_max = $old_min->nextSibling;
    $old_max->textContent eq '999' or return(0);

    #--------------------------------------------------------------------------

    # Test replacing an existing MAX.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><PARAM><VALUES><MIN>-1</MIN><MAX>998</MAX></VALUES></PARAM></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the VALUES element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $param = ($resource->get_PARAM)[0] or return(0);
    $values = ($param->get_VALUES)[0] or return(0);

    # Create the new MAX element.
    $new_max = new VOTable::MAX or return(0);
    $new_max->set(999);

    # Fetch the existing MAX element.
    $old_max = $values->get_MAX or return(0);

    # Replace it.
    $values->set_MAX($new_max);

    # Make sure it worked.
    $old_max = undef;
    $old_max = $values->get_MAX or return(0);
    $old_max->isa('VOTable::MAX') or return(0);
    $old_max->get == 999 or return(0);

    # Make sure the MAX element is the second child element.
    $old_min = $values->firstChild;
    $old_max = $old_min->nextSibling;
    $old_max->textContent eq '999' or return(0);

    # All tests succeeded.
    return(1);

}
