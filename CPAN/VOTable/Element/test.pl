# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 9 };
use VOTable::Element;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;
use XML::LibXML;

# Subroutine prototypes
sub test_new();
sub test_get();
sub test_set();
sub test_empty();
sub test_AUTOLOAD();
sub test_get_valid_attribute_names();
sub test_get_valid_child_element_names();
sub test_toString();

#########################

# Test.
ok(test_new, 1);
ok(test_get, 1);
ok(test_set, 1);
ok(test_empty, 1);
ok(test_AUTOLOAD, 1);
ok(test_get_valid_attribute_names, 1);
ok(test_get_valid_child_element_names, 1);
ok(test_toString, 1);

#########################

sub test_new()
{

    # Local variables

    # Reference to test element object.
    my($element);

    #--------------------------------------------------------------------------

    # Test the plain-vanilla constructor.
    $element = VOTable::Element->new or return(0);

    # Try creating from a XML::LibXML::Element object.
    $element = VOTable::Element->new(new XML::LibXML::Element('Element'))
	or return(0);

    # Make sure the constructor fails when a bad reference is passed
    # in.
    $element = eval { VOTable::Element->new(\0) };
    return(0) if not $EVAL_ERROR;
    $element = eval { VOTable::Element->new([]) };
    return(0) if not $EVAL_ERROR;

    #--------------------------------------------------------------------------

    # Return success.
    return(1);

}

sub test_get()
{

    # Local variables

    # XML::LibXML parser object to create objects.
    my($parser);

    # Test XML string.
    my($xml);

    # XML::LibXML::Document object for test XML.
    my($document);

    # XML::LibXML::Element object for test description.
    my($description);

    #--------------------------------------------------------------------------

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $xml = '<VOTABLE><DESCRIPTION>This is a test.</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DESCRIPTION element.
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);

    # Manually bless the XML::LibXML::Element object to a
    # VOTable::Element object.
    bless $description => 'VOTable::Element';

    # Retrieve the content of the DESCRIPTION element.
    $description->get eq 'This is a test.' or return(0);

    # Make sure an empty element returns an empty string.
    $description = new VOTable::Element or return(0);
    $description->get eq '' or return(0);

    #--------------------------------------------------------------------------

    # Make sure character entity references are properly handled.

    # Ampersand ('&' => '&amp').
    $xml = '<VOTABLE><DESCRIPTION>&amp;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq '&' or return(0);

    # Less-than ('<' => '&lt').
    $xml = '<VOTABLE><DESCRIPTION>&lt;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq '<' or return(0);

    # Greater-than ('>' => '&gt').
    $xml = '<VOTABLE><DESCRIPTION>&gt;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq '>' or return(0);

    # Quote ('"' => '&quot').
    $xml = '<VOTABLE><DESCRIPTION>&quot;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
    		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq '"' or return(0);

    # Apostrophe ("'" => '&apos').
    $xml = '<VOTABLE><DESCRIPTION>&apos;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
    		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq "'" or return(0);

    #--------------------------------------------------------------------------

    # Test that CDATA sections are handled properly.
    $xml =<<_EOS_
<VOTABLE>
  <DESCRIPTION><![CDATA[&<>\"\']]></DESCRIPTION>
</VOTABLE>
_EOS_
    ;
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
    		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->get eq '&<>"\'' or return(0);

    #--------------------------------------------------------------------------

    # All tests passed.
    return(1);

}

sub test_set()
{

    # Local variables

    # XML::LibXML parser object to create objects.
    my($parser);

    # Test XML string.
    my($xml);

    # XML::LibXML::Document object for test XML.
    my($document);

    # XML::LibXML::Element object for test description.
    my($description);

    #--------------------------------------------------------------------------

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $xml = '<VOTABLE><DESCRIPTION/></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DESCRIPTION element.
    $description = ($document->documentElement->
		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);

    # Manually bless the XML::DOM::Element object to a
    # VOTable::Element object.
    bless $description => 'VOTable::Element';

    # Set then retrieve the content of the DESCRIPTION element.
    $description->set('This is a test.') or return(0);
    $description->get eq 'This is a test.' or return(0);

    #--------------------------------------------------------------------------

    # Make sure character entity references are properly handled.

    # Ampersand ('&' => '&amp').
    $description->set('&');
    $description->get eq '&' or return(0);
    $description->set('&amp;');
    $description->get eq '&amp;' or return(0);

    # Less-than ('<' => '&lt').
    $description->set('<');
    $description->get eq '<' or return(0);
    $description->set('&lt;');
    $description->get eq '&lt;' or return(0);

    # Greater-than ('>' => '&gt').
    $description->set('>');
    $description->get eq '>' or return(0);
    $description->set('&gt;');
    $description->get eq '&gt;' or return(0);

    # Quote ('"' => '&quot').
    $description->set('"');
    $description->get eq '"' or return(0);
    $description->set('&quot;');
    $description->get eq '&quot;' or return(0);

    # Apostrophe (''' => '&apos').
    $description->set("'");
    $description->get eq "'" or return(0);
    $description->set('&apos;');
    $description->get eq '&apos;' or return(0);

    #--------------------------------------------------------------------------

    # All tests passed.
    return(1);

}

sub test_empty()
{
    my($parser);
    my($xml) = '<VOTABLE><DESCRIPTION>This is a test.</DESCRIPTION></VOTABLE>';
    my($document);
    my($description);

    #--------------------------------------------------------------------------

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the DESCRIPTION element.
    $description = ($document->documentElement->
		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);

    # Manually bless the XML::DOM::Element object to a
    # VOTable::Element object.
    bless $description => 'VOTable::Element';

    # Empty then check the content of the DESCRIPTION element.
    $description->empty;
    $description->get eq '' or return(0);

    # All tests passed.
    return(1);

}

sub test_AUTOLOAD()
{
    my($parser);
    my($xml) = '<VOTABLE><RESOURCE ID="test"/></VOTABLE>';
    my($document);
    my($votable);
    my($resource1);
    my($resource2);
    my($resource3);
    my($resource4);
    my(@resources);

    #--------------------------------------------------------------------------

    # Create the parser.
    $parser = new XML::LibXML or return(0);

    # Parse the XML into a document object.
    $document = $parser->parse_string($xml) or return(0);

    # Drill down to the VOTABLE element.
    $votable = $document->documentElement or return(0);
    bless $votable => 'VOTable::Element';

    #--------------------------------------------------------------------------

    # Test the element 'get' mechanism.
    use vars @VOTable::Element::valid_child_element_names;
    @VOTable::Element::valid_child_element_names = qw(RESOURCE);
    $resource1 = $votable->get_RESOURCE(0) or return(0);
    ref($resource1) eq 'VOTable::RESOURCE' or return(0);

    # Test the element 'set' mechanism.
    $resource2 = new VOTable::Element or return(0);
    $resource2->setNodeName('RESOURCE');
    $votable->set_RESOURCE($resource2);
    $resource3 = ($votable->get_RESOURCE)[0] or return(0);
    $resource2->isSameNode($resource3) or return(0);

    # Test the element 'append' mechanism.
    $resource4 = new VOTable::Element or return(0);
    $resource4->setNodeName('RESOURCE');
    $votable->append_RESOURCE($resource4);
    @resources = $votable->get_RESOURCE;
    $resource4->isSameNode($resources[1]) or return(0);

    # Test the element 'remove' mechanism.
    $votable->remove_RESOURCE;
    not defined($votable->get_RESOURCE) or return(0);

    #--------------------------------------------------------------------------

    # Test the attribute 'set' and 'get' mechanisms.
    use vars @VOTable::Element::valid_attribute_names;
    @VOTable::Element::valid_attribute_names = qw(ID);
    $resource4->set_ID('another test');
    $resource4->get_ID eq 'another test' or return(0);

    # Test the attribute 'remove' mechanism.
    $resource4->remove_ID;
    not defined($resource4->get_ID) or return(0);

    #--------------------------------------------------------------------------

    # All tests passed.
    return(1);

}

sub test_get_valid_attribute_names()
{
    my($element);
    my(@attribute_names);

    # Create a new Element object.
    $element = new VOTable::Element or return(0);
    use vars @VOTable::Element::valid_attribute_names;
    @VOTable::Element::valid_attribute_names = ();

    # Make sure it has no attributes.
    not $element->get_valid_attribute_names or return(0);

    # Now add some and check them.
    @VOTable::Element::valid_attribute_names = qw(ID);
    @attribute_names = $element->get_valid_attribute_names;
    @attribute_names == 1 or return(0);
    $attribute_names[0] eq 'ID' or return(0);

    # All tests passed.
    return(1);

}

sub test_get_valid_child_element_names()
{
    my($element);
    my(@names);

    # Create a new Element object.
    $element = new VOTable::Element or return(0);
    use vars @VOTable::Element::valid_child_element_names;
    @VOTable::Element::valid_child_element_names = ();

    # Make sure it has no child elements.
    not $element->get_valid_child_element_names or return(0);

    # Now add some and check them.
    @VOTable::Element::valid_child_element_names = qw(VOTABLE);
    @names = $element->get_valid_child_element_names;
    @names == 1 or return(0);
    $names[0] eq 'VOTABLE' or return(0);

    # All tests passed.
    return(1);

}

sub test_toString()
{
    my($xml) = '<VOTABLE><DESCRIPTION>This is a test.</DESCRIPTION></VOTABLE>';
    my($parser);
    my($document);
    my($description);

    #--------------------------------------------------------------------------

    # Create the new parser.
    $parser = new XML::LibXML or return(0);

    # Create the document.
    $document = $parser->parse_string($xml) or return(0);

    # Fetch the description.
    $description = ($document->documentElement->
		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>This is a test.</DESCRIPTION>'
	or return(0);
    $description->toString(1) eq '<DESCRIPTION>This is a test.</DESCRIPTION>'
	or return(0);
    $description->toString(2) eq
	"<DESCRIPTION>\nThis is a test.\n</DESCRIPTION>"
	    or return(0);

    #--------------------------------------------------------------------------

    # Test that character entities are properly handled.

    # Ampersand ('&' => '&amp;').
    $xml = '<VOTABLE><DESCRIPTION>&amp;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>&amp;</DESCRIPTION>' or return(0);

    # Less-than ('<' => '&lt').
    $xml = '<VOTABLE><DESCRIPTION>&lt;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>&lt;</DESCRIPTION>' or return(0);

    # Greater-than ('>' => '&gt').
    $xml = '<VOTABLE><DESCRIPTION>&gt;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
  		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>&gt;</DESCRIPTION>' or return(0);

    # Quote ('"' => '&quot').
    $xml = '<VOTABLE><DESCRIPTION>&quot;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
    		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>&quot;</DESCRIPTION>' or return(0);

    # Apostrophe ("'" => '&apos').
    $xml = '<VOTABLE><DESCRIPTION>&apos;</DESCRIPTION></VOTABLE>';
    $document = $parser->parse_string($xml) or return(0);
    $description = ($document->documentElement->
    		    getChildrenByTagName('DESCRIPTION'))[0] or return(0);
    bless $description => 'VOTable::Element';
    $description->toString eq '<DESCRIPTION>\'</DESCRIPTION>' or return(0);
    # N.B. This should be '&apos;'!

    # All tests passed.
    return(1);

}
