# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use VOTable::RESOURCE;
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
sub test_get_DESCRIPTION();

#########################

# Test.
ok(test_set_type, 1);
ok(test_get_DESCRIPTION, 1);

#########################

sub test_set_type()
{

    # Local variables

    # Reference to test RESOURCE object.
    my($resource);

    # Current type value.
    my($type);

    # Valid type attribute values.
    my(@valids) = qw(results meta);

    #--------------------------------------------------------------------------

    # Create the object.
    $resource = new VOTable::RESOURCE or return(0);

    # Try each of the valid values.
    foreach $type (@valids) {
	$resource->set_type($type);
	$resource->get_type eq $type or return(0);
    }

    # Make sure bad values fail.
    eval { $resource->set_type('BAD_VALUE!'); };
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

    # VOTable::RESOURCE element object for the RESOURCE element.
    my($resource);

    # VOTable::DESCRIPTION element object for the RESOURCE DESCRIPTION
    # element.
    my($description);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><DESCRIPTION>This is a RESOURCE description!</DESCRIPTION></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the DESCRIPTION element.
    $description = $resource->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is a RESOURCE description!' or return(0);

    # All tests succeeded.
    return(1);

}
