# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use VOTable::FITS;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use VOTable::Document;

# Subroutine prototypes
sub test_get_STREAM();

#########################

# Test.
ok(test_get_STREAM, 1);

#########################

sub test_get_STREAM()
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

    # VOTable::DATA object for the DATA element.
    my($data);

    # VOTable::FITS object for the FITS element.
    my($fits);

    # VOTable::STREAM object for the STREAM element.
    my($stream);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><FITS><STREAM/></FITS></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Fetch the FITS element.
    $fits = ($data->get_FITS)[0] or return(0);

    # Fetch the STREAM element.
    $stream = ($fits->get_STREAM)[0] or return(0);
    $stream->isa('VOTable::STREAM') or return(0);

    # All tests succeeded.
    return(1);

}
