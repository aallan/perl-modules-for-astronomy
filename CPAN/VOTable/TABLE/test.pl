# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
use VOTable::TABLE;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use VOTable::DATA;
use VOTable::DESCRIPTION;
use VOTable::Document;
use VOTable::FIELD;
use VOTable::LINK;

# Subroutine prototypes
sub test_get_DESCRIPTION();
sub test_get_DATA();
sub test_get_array();
sub test_get_row();
sub test_get_field_position_by_name();
sub test_get_field_position_by_ucd();
sub test_get_num_rows();

#########################

# Test.
ok(test_get_DESCRIPTION, 1);
ok(test_get_DATA, 1);
ok(test_get_array, 1);
ok(test_get_row, 1);
ok(test_get_field_position_by_name, 1);
ok(test_get_field_position_by_ucd, 1);
ok(test_get_num_rows, 1);

#########################

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

    # VOTable::DESCRIPTION object for the DESCRIPTION element.
    my($description);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DESCRIPTION>This is a TABLE description!</DESCRIPTION></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DESCRIPTION element.
    $description = $table->get_DESCRIPTION or return(0);
    $description->isa('VOTable::DESCRIPTION') or return(0);
    $description->get eq 'This is a TABLE description!' or return(0);

    # All tests succeeded.
    return(1);

}

sub test_get_DATA()
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

    # VOTable::DATA object for the DATA element.
    my($data);

    #--------------------------------------------------------------------------

    # Parse the XML.
    $xml = '<VOTABLE><RESOURCE><TABLE><DATA/></TABLE></RESOURCE></VOTABLE>';
    $document = VOTable::Document->new_from_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->get_VOTABLE or return(0);
    $resource = ($votable->get_RESOURCE)[0] or return(0);
    $table = ($resource->get_TABLE)[0] or return(0);

    # Fetch the DATA element.
    $data = $table->get_DATA or return(0);
    $data->isa('VOTable::DATA') or return(0);

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
    my($table);
    my($array);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->documentElement or return(0);
    $table = ($votable->getElementsByTagName('TABLE'))[0] or return(0);

    # Create a VOTable::TABLE object.
    bless $table => 'VOTable::TABLE';

    # Fetch the table contents as an array.
    $array = $table->get_array or return(0);
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
    my($table);
    my(@values);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->getDocumentElement or return(0);
    $table = ($votable->getElementsByTagName('TABLE'))[0] or return(0);

    # Create a VOTable::TABLE object.
    bless $table => 'VOTable::TABLE';

    # Retrieve the contents of the TR elements as arrays and verify
    # the contents.
    @values = $table->get_row(0) or return(0);
    $values[0] eq '3.14159' or return(0);
    $values[1] eq '2.718282' or return(0);
    @values = $table->get_row(1) or return(0);
    $values[0] eq '2.22' or return(0);
    $values[1] eq '4.44' or return(0);

    # All tests passed.
    return(1);

}

sub test_get_field_position_by_name()
{
    my($parser);
    my($xml) = <<_EOS_
<VOTABLE>
<RESOURCE>
<TABLE>
<FIELD name="field_x" ucd="POS_EQ_RA_MAIN"/>
<FIELD name="field_y" ucd="POS_EQ_DEC_MAIN"/>
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
    my($table);
    my(@values);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->getDocumentElement or return(0);
    $table = ($votable->getElementsByTagName('TABLE'))[0] or return(0);

    # Create a VOTable::TABLE object.
    bless $table => 'VOTable::TABLE';

    # Find the FIELD positions and verify them.
    $table->get_field_position_by_name('field_x') == 0 or return(0);
    $table->get_field_position_by_name('field_y') == 1 or return(0);

    # All tests passed.
    return(1);

}

sub test_get_field_position_by_ucd()
{
    my($parser);
    my($xml) = <<_EOS_
<VOTABLE>
<RESOURCE>
<TABLE>
<FIELD name="field_x" ucd="POS_EQ_RA_MAIN"/>
<FIELD name="field_y" ucd="POS_EQ_DEC_MAIN"/>
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
    my($table);
    my(@values);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->getDocumentElement or return(0);
    $table = ($votable->getElementsByTagName('TABLE'))[0] or return(0);

    # Create a VOTable::TABLE object.
    bless $table => 'VOTable::TABLE';

    # Find the FIELD positions and verify them.
    $table->get_field_position_by_ucd('POS_EQ_RA_MAIN') == 0 or return(0);
    $table->get_field_position_by_ucd('POS_EQ_DEC_MAIN') == 1 or return(0);

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
<FIELD name="field_x" ucd="POS_EQ_RA_MAIN"/>
<FIELD name="field_y" ucd="POS_EQ_DEC_MAIN"/>
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
    my($table);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TABLE element.
    $votable = $document->getDocumentElement or return(0);
    $table = ($votable->getElementsByTagName('TABLE'))[0] or return(0);

    # Create a VOTable::TABLE object.
    bless $table => 'VOTable::TABLE';

    # Find and verify the row count.
    $table->get_num_rows == 2 or return(0);

    # All tests passed.
    return(1);

}
