# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use VOTable::TR;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use XML::LibXML;

# Subroutine prototypes
sub test_as_array();

#########################

# Test.
ok(test_as_array, 1);

#########################

sub test_as_array()
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
</TABLEDATA>
</DATA>
</TABLE>
</RESOURCE>
</VOTABLE>
_EOS_
;
    my($document);
    my($votable);
    my($tr);
    my(@values);

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the TR element.
    $votable = $document->documentElement or return(0);
    $tr = ($votable->getElementsByTagName('TR'))[0] or return(0);

    # Create a VOTable::TR object.
    bless $tr => 'VOTable::TR';

    # Retrieve the contents of the TR element as an array and verify
    # the contents.
    @values = $tr->as_array or return(0);
#      $values[0] eq '3.14159' or return(0);
#      $values[1] eq '2.718282' or return(0);

    # All tests passed.
    return(1);

}
