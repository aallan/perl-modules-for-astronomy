# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
use VOTable::DATA;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;
use VOTable::Document;

# Subroutine prototypes
sub test_get_TABLEDATA();
sub test_set_TABLEDATA();
sub test_get_BINARY();
sub test_set_BINARY();
sub test_get_FITS();
sub test_set_FITS();
sub test_get_array();
sub test_get_row();
sub test_get_num_rows();

#########################

# Test.
ok(test_get_TABLEDATA, 1);
ok(test_set_TABLEDATA, 1);
ok(test_get_BINARY, 1);
ok(test_set_BINARY, 1);
ok(test_get_FITS, 1);
ok(test_set_FITS, 1);
ok(test_get_array, 1);
ok(test_get_row, 1);
ok(test_get_num_rows, 1);

#########################

sub test_get_TABLEDATA()
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

    # VOTable::TABLEDATA object for the TABLEDATA element.
    my($tabledata);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><TABLEDATA/></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Fetch the TABLEDATA element.
    $tabledata = ($data->get_TABLEDATA)[0] or return(0);
    $tabledata->isa('VOTable::TABLEDATA') or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_TABLEDATA()
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

    # VOTable::TABLEDATA object for the TABLEDATA element.
    my($tabledata);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA/></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the TABLEDATA element.
    $tabledata = VOTable::TABLEDATA->new() or return(0);

    # Set then fetch the TABLEDATA element.
    $tabledata = $data->set_TABLEDATA($tabledata);
    $tabledata = ($data->get_TABLEDATA)[0] or return(0);
    $tabledata->isa('VOTable::TABLEDATA') or return(0);

    #--------------------------------------------------------------------------

    # Make sure it works when replacing another element.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><FITS/></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the TABLEDATA element.
    $tabledata = VOTable::TABLEDATA->new() or return(0);

    # Set then fetch the TABLEDATA element.
    $tabledata = $data->set_TABLEDATA($tabledata);
    $tabledata = ($data->get_TABLEDATA)[0] or return(0);
    $tabledata->isa('VOTable::TABLEDATA') or return(0);

    # Make sure there is no FITS.
    return(0) if ($data->get_FITS)[0];

    # All tests succeeded.
    return(1);

}

sub test_get_BINARY()
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

    # VOTable::BINARY object for the BINARY element.
    my($binary);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><BINARY><STREAM/></BINARY></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Fetch the BINARY element.
    $binary = ($data->get_BINARY)[0] or return(0);
    $binary->isa('VOTable::BINARY') or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_BINARY()
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

    # VOTable::BINARY object for the BINARY element.
    my($binary);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA/></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the BINARY element.
    $binary = VOTable::BINARY->new() or return(0);

    # Set then fetch the BINARY element.
    $binary = $data->set_BINARY($binary);
    $binary = ($data->get_BINARY)[0] or return(0);
    $binary->isa('VOTable::BINARY') or return(0);

    #--------------------------------------------------------------------------

    # Make sure it works when replacing another element.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><FITS/></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the BINARY element.
    $binary = VOTable::BINARY->new() or return(0);

    # Set then fetch the BINARY element.
    $binary = $data->set_BINARY($binary);
    $binary = ($data->get_BINARY)[0] or return(0);
    $binary->isa('VOTable::BINARY') or return(0);

    # Make sure there is no FITS.
    return(0) if ($data->get_FITS)[0];

    # All tests succeeded.
    return(1);

}

sub test_get_FITS()
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
    $fits = $data->get_FITS or return(0);
    $fits->isa('VOTable::FITS') or return(0);

    # All tests succeeded.
    return(1);

}

sub test_set_FITS()
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

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA/></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the FITS element.
    $fits = VOTable::FITS->new() or return(0);

    # Set then fetch the FITS element.
    $fits = $data->set_FITS($fits);
    $fits = ($data->get_FITS)[0] or return(0);
    $fits->isa('VOTable::FITS') or return(0);

    #--------------------------------------------------------------------------

    # Make sure it works when replacing another element.

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA><BINARY/></DATA></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Fetch the VOTABLE element.
    $votable = $document->get_VOTABLE or return(0);

    # Fetch the RESOURCE element.
    $resource = ($votable->get_RESOURCE)[0] or return(0);

    # Fetch the TABLE element.
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = ($table->get_DATA)[0] or return(0);

    # Create the FITS element.
    $fits = VOTable::FITS->new() or return(0);

    # Set then fetch the FITS element.
    $fits = $data->set_FITS($fits);
    $fits = ($data->get_FITS)[0] or return(0);
    $fits->isa('VOTable::FITS') or return(0);

    # Make sure there is no BINARY.
    return(0) if ($data->get_BINARY)[0];

    # All tests succeeded.
    return(1);

}

sub test_get_array()
{
    my($parser);
    my($xml) = <<_EOS_
<VOTABLE>
<RESOURCE>
<TABLE>
<DATA>
<TABLEDATA>
<TR>
<TD>3.14159</TD><TD>2.718282</TD>
</TR>
<TR>
<TD>2.22</TD><TD>4.44</TD>
</TR>
</TABLEDATA>
</DATA>
</TABLE>
</RESOURCE>
</VOTABLE>
_EOS_
;
    my($document);
    my($votable);
    my($data);
    my($array);

    # Create the parser.
    $parser = XML::LibXML->new() or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DATA element.
    $votable = $document->documentElement or return(0);
    $data = ($votable->getElementsByTagName('DATA'))[0] or return(0);

    # Create a VOTable::DATA object.
    bless $data => 'VOTable::DATA';

    # Fetch the table contents as an array.
    $array = $data->get_array or return(0);
    $array->[0][0] eq '3.14159' or return(0);
    $array->[0][1] eq '2.718282' or return(0);
    $array->[1][0] eq '2.22' or return(0);
    $array->[1][1] eq '4.44' or return(0);

    # Return normally.
    return(1);

}

sub test_get_row()
{
    my($parser);
    my($xml) = <<_EOS_
<VOTABLE>
<RESOURCE>
<TABLE>
<DATA>
<TABLEDATA>
<TR>
<TD>3.14159</TD><TD>2.718282</TD>
</TR>
<TR>
<TD>2.22</TD><TD>4.44</TD>
</TR>
</TABLEDATA>
</DATA>
</TABLE>
</RESOURCE>
</VOTABLE>
_EOS_
;
    my($document);
    my($votable);
    my($data);
    my(@values);

    # Create the parser.
    $parser = XML::LibXML->new() or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DATA element.
    $votable = $document->documentElement or return(0);
    $data = ($votable->getElementsByTagName('DATA'))[0] or return(0);

    # Create a VOTable::DATA object.
    bless $data => 'VOTable::DATA';

    # Retrieve the contents of the TR elements as arrays and verify
    # the contents.
    @values = $data->get_row(0) or return(0);
    $values[0] eq '3.14159' or return(0);
    $values[1] eq '2.718282' or return(0);
    @values = $data->get_row(1) or return(0);
    $values[0] eq '2.22' or return(0);
    $values[1] eq '4.44' or return(0);

    # All tests passed.
    return(1);

}

sub test_get_num_rows()
{
    my($parser);
    my($xml) = <<_EOS_
<VOTABLE>
<RESOURCE>
<TABLE>
<DATA>
<TABLEDATA>
<TR>
<TD>3.14159</TD><TD>2.718282</TD>
</TR>
<TR>
<TD>2.22</TD><TD>4.44</TD>
</TR>
</TABLEDATA>
</DATA>
</TABLE>
</RESOURCE>
</VOTABLE>
_EOS_
;
    my($document);
    my($votable);
    my($data);

    # Create the parser.
    $parser = XML::LibXML->new() or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DATA element.
    $votable = $document->documentElement or return(0);
    $data = ($votable->getElementsByTagName('DATA'))[0] or return(0);

    # Create a VOTable::DATA object.
    bless $data => 'VOTable::DATA';

    # Retrieve and verify the row count.
    $data->get_num_rows == 2 or return(0);

    # All tests passed.
    return(1);

}
