#!/bin/env perl 

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use strict;
use Test;

BEGIN { plan tests => 25 }

use SOAP::Lite;

my($a, $s, $r, $serialized, $deserialized);

{ # check 'use ...'
  print "'use SOAP::Lite ...' test(s)...\n";

  eval 'use SOAP::Lite 99.99'; # hm, definitely should fail

  ok($@ =~ /99\.99 required/);
}

{ # check serialization
  print "Arrays, structs, refs serialization test(s)...\n";

  $serialized = SOAP::Serializer->serialize(
    SOAP::Data->name(test => \SOAP::Data->value(1, [1,2], {a=>3}, \4))
  );

  ok($serialized =~ m!<test(?: xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"| xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"| xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"| xmlns:xsd="http://www.w3.org/1999/XMLSchema"| xmlns:namesp\d+="http://xml.apache.org/xml-soap"){5}><c-gensym(\d+) xsi:type="xsd:int">1</c-gensym\1><SOAP-ENC:Array(?: xsi:type="SOAP-ENC:Array"| SOAP-ENC:arrayType="xsd:int\[2\]"){2}><item xsi:type="xsd:int">1</item><item xsi:type="xsd:int">2</item></SOAP-ENC:Array><c-gensym(\d+) xsi:type="namesp\d+:SOAPStruct"><a xsi:type="xsd:int">3</a></c-gensym\2><c-gensym(\d+)><c-gensym(\d+) xsi:type="xsd:int">4</c-gensym\4></c-gensym\3></test>!);
}  

{ # check simple circular references
  print "Simple circular references (\$a=\\\$a) serialization test(s)...\n";

  $a = \$a;
  $serialized = SOAP::Serializer->namespaces({})->serialize($a);

  ok($serialized =~ m!<c-gensym(\d+) id="ref-(\w+)"><c-gensym(\d+) href="#ref-\2"/></c-gensym\1>!);

  $a = SOAP::Deserializer->deserialize($serialized)->root;
  ok(0+$a == 0+(values%$a)[0]);
}

{ # check complex circular references
  print "Complex circlular references serialization test(s)...\n";

  $a = SOAP::Deserializer->deserialize(<<'EOX')->root;
<root>
<a id='id1'>
   <x>1</x>
   <next id='id2'>
     <x>7</x>
     <next href='#id3'/>
   </next>
</a>
<item id='id3'>
  <x>8</x>
  <next href='#id1'/>
</item>
</root>
EOX

  ok($a->{a}->{next}->{next}->{next}->{next}->{x} == 
     $a->{a}->{next}->{x});

  $a = { a => 1 }; my $b = { b => $a }; $a->{a} = $b;
  $serialized = SOAP::Serializer->autotype(0)->namespaces({})->serialize($a);

  ok($serialized =~ m!<c-gensym(\d+) id="ref-(\w+)"><a id="ref-\w+"><b href="#ref-\2"/></a></c-gensym\1>!);
}

{ # check multirefs
  print "Multireferences serialization test(s)...\n";

  $a = 1; my $b = \$a;

  $serialized = SOAP::Serializer->new(multirefinplace=>1)->serialize(
    SOAP::Data->name(test => \SOAP::Data->value($b, $b))
  );

  ok($serialized =~ m!<test(?: xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"| xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"| xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"| xmlns:xsd="http://www.w3.org/1999/XMLSchema"){4}><c-gensym(\d+) id="ref-(\w+)"><c-gensym(\d+) xsi:type="xsd:int">1</c-gensym\3></c-gensym\1><c-gensym\d+ href="#ref-\2"/></test>!);

  $serialized = SOAP::Serializer->namespaces({})->serialize(
    SOAP::Data->name(test => \SOAP::Data->value($b, $b))
  );

  ok($serialized =~ m!<c-gensym\d+ href="#ref-(\w+)"/><c-gensym\d+ href="#ref-\1"/><c-gensym(\d+) id="ref-\1"><c-gensym(\d+) xsi:type="xsd:int">1</c-gensym\3></c-gensym\2>!);
}

{ # check base64, XML encoding of elements and attributes 
  print "base64, XML encoding of elements and attributes test(s)...\n";

  $serialized = SOAP::Serializer->serialize(
    SOAP::Data->name(test => \SOAP::Data->value("\0\1\2\3   \4\5\6", "<123>&amp;\015</123>"))
  );

  ok($serialized =~ m!<c-gensym(\d+) xsi:type="SOAP-ENC:base64">AAECAyAgIAQFBg==</c-gensym\1><c-gensym(\d+) xsi:type="xsd:string">&lt;123>&amp;amp;&#xd;&lt;/123></c-gensym\2>!);

  $serialized = SOAP::Serializer->namespaces({})->serialize(
    SOAP::Data->name(name=>'value')->attr({attr => '<123>"&amp"</123>'})
  );

  ok($serialized =~ m!^<\?xml version="1.0" encoding="UTF-8"\?><name(?: xsi:type="xsd:string"| attr="&lt;123>&quot;&amp;amp&quot;&lt;/123>"){2}>value</name>$!);
}

{ # check objects and SOAP::Data 
  print "Blessed references and SOAP::Data encoding test(s)...\n";

  $serialized = SOAP::Serializer->serialize(SOAP::Data->uri('some_urn' => bless {a => 1} => 'ObjectType'));

  ok($serialized =~ m!<namesp(\d+):c-gensym(\d+)(:? xsi:type="namesp\d+:ObjectType"| xmlns:namesp\d+="http://namespaces.soaplite.com/perl"| xmlns:namesp\1="some_urn"| xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"| xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"| xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"| xmlns:xsd="http://www.w3.org/1999/XMLSchema"){7}><a xsi:type="xsd:int">1</a></namesp\1:c-gensym\2>!);
}

{ # check for serialization with SOAPStruct (for interoperability with ApacheSOAP)
  print "Serialization w/out SOAPStruct test(s)...\n";

  $a = { a => 1 };

  ok(SOAP::Serializer->serialize($a) =~ m!SOAPStruct!); 
  ok(SOAP::Serializer->autotype(0)->serialize($a) !~ m!SOAPStruct!); 
}

{ # check serialization/deserialization of simple types  
  print "Serialization/deserialization of simple types test(s)...\n";

  $a = 'abc234xyz';

  $serialized = SOAP::Serializer->serialize(SOAP::Data->type(hex => $a));

  ok($serialized =~ m!<c-gensym(\d+)(?: xsi:type="xsd:hex"| xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"| xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"| xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"| xmlns:xsd="http://www.w3.org/1999/XMLSchema"){5}>61626332333478797A</c-gensym(\d+)>!);
  ok(SOAP::Deserializer->deserialize($serialized)->root eq $a); 

  $a = <<"EOBASE64";
qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?`1234567890-=\~!@#$%^&*()_+|
EOBASE64

  $serialized = SOAP::Serializer->serialize($a);

  ok(index($serialized, quotemeta(q!qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM&lt;>?`1234567890-=~\!@#0^&amp;*()_+|!)));
  UNIVERSAL::isa(SOAP::Deserializer->parser->parser => 'XML::Parser::Lite') ?
    skip(q!Entity decoding is not supported in XML::Parser::Lite! => undef) :
    ok(SOAP::Deserializer->deserialize($serialized)->root eq $a);

  $a = <<"EOBASE64";

qwertyuiop[]asdfghjkl;'zxcvbnm,./
QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?
\x00

EOBASE64

  $serialized = SOAP::Serializer->serialize($a);

  ok($serialized =~ /base64/);
}

{ # check serialization/deserialization of blessed reference  
  print "Serialization/deserialization of blessed reference test(s)...\n";

  $serialized = SOAP::Serializer->serialize(bless {a => 1} => 'SOAP::Lite');
  $a = SOAP::Deserializer->deserialize($serialized)->root;

  ok(ref $a eq 'SOAP::Lite' && UNIVERSAL::isa($a => 'HASH'));

  $a = SOAP::Deserializer->deserialize(
    SOAP::Serializer->serialize(bless [a => 1] => 'SOAP::Lite')
  )->root;

  ok(ref $a eq 'SOAP::Lite' && UNIVERSAL::isa($a => 'ARRAY'));
}

{ # check serialization/deserialization of undef/empty elements  
  print "Serialization/deserialization of undef/empty elements test(s)...\n";

  { local $^W; # suppress warnings
    $a = undef;
    $serialized = SOAP::Serializer->serialize(
      SOAP::Data->type(negativeInteger => $a)
    );

    ok(! defined SOAP::Deserializer->deserialize($serialized)->root);

    my $type = 'nonstandardtype';
    eval {
      $serialized = SOAP::Serializer->serialize(
        SOAP::Data->type($type => $a)
      );
    };
    ok($@ =~ /for type '$type' is not specified/);

    $serialized = SOAP::Serializer->serialize(
      SOAP::Data->type($type => {})
    );

    ok(ref SOAP::Deserializer->deserialize($serialized)->root eq $type);
  }
}

{
  print "Check for unspecified Transport module test(s)...\n";

  eval { SOAP::Lite->new->abc() };
  ok($@ =~ /Transport is not specified/);
}

{ 
  print "Deserialization of CDATA test(s)...\n";

  UNIVERSAL::isa(SOAP::Deserializer->parser->parser => 'XML::Parser::Lite') ?
    skip(q!CDATA decoding is not supported in XML::Parser::Lite! => undef) :
    ok(SOAP::Deserializer->deserialize('<root><![CDATA[<123>]]></root>')->root eq '<123>');
}
