# $Id: 20extras.t,v 1.1 2003/07/17 21:56:18 aa Exp $

use Test;

BEGIN { plan tests => 5 };
use XML::LibXML;

my $string = "<foo><bar/></foo>";

my $parser = XML::LibXML->new();

{
    my $doc = $parser->parse_string( $string );
    ok($doc);
    local $XML::LibXML::skipXMLDeclaration = 1;
    ok( $doc->toString(), $string );
    local $XML::LibXML::setTagCompression = 1;
    ok( $doc->toString(), "<foo><bar></bar></foo>" );
}

{
    local $XML::LibXML::skipDTD = 1;
    $parser->expand_entities(0);
    my $doc = $parser->parse_file( "example/dtd.xml" );
    ok($doc);
    my $test = "<?xml version=\"1.0\"?>\n<doc>This is a valid document &foo; !</doc>\n";
    ok( $doc->toString, $test );
}
