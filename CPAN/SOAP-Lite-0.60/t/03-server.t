#!/bin/env perl 

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use strict;
use Test;

BEGIN { plan tests => 30 }

use SOAP::Lite;

my($a, $s, $r, $serialized, $deserialized);

my %tests = (
  'XML only' => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body>
<namesp1:add xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 xsi:type="xsd:int">2</c-gensym5>
  <c-gensym7 xsi:type="xsd:int">5</c-gensym7>
</namesp1:add>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOM

  'message with headers' => <<'EOM',
Content-Type: text/xml

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body>
<namesp1:add xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 xsi:type="xsd:int">2</c-gensym5>
  <c-gensym7 xsi:type="xsd:int">5</c-gensym7>
</namesp1:add>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOM

  'singlepart MIME' => <<'EOM',
Content-Type: Multipart/Related; boundary=MIME_boundary; type="text/xml"; start="<calc061400a.xml@soaplite.com>"

--MIME_boundary
Content-Type: text/xml; charset=UTF-8
Content-Transfer-Encoding: 8bit
Content-ID: <calc061400a.xml@soaplite.com>

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body>
<namesp1:add xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 xsi:type="xsd:int">2</c-gensym5>
  <c-gensym7 xsi:type="xsd:int">5</c-gensym7>
</namesp1:add>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>

--MIME_boundary--
EOM

  'multipart MIME' => <<'EOM',
Content-Type: Multipart/Related; boundary=MIME_boundary; type="text/xml"; start="<calc061400a.xml@soaplite.com>"

--MIME_boundary
Content-Type: text/xml; charset=UTF-8
Content-Transfer-Encoding: 8bit
Content-ID: <calc061400a.xml@soaplite.com>

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body>
<namesp1:add xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 href="cid:calc061400a.a@soaplite.com"/>
  <c-gensym7 href="cid:calc061400a.b@soaplite.com"/>
</namesp1:add>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>

--MIME_boundary
Content-Type: text/plain
Content-Transfer-Encoding: binary
Content-ID: <calc061400a.a@soaplite.com>

2
--MIME_boundary
Content-Type: text/plain
Content-Transfer-Encoding: binary
Content-ID: <calc061400a.b@soaplite.com>

5
--MIME_boundary--
EOM
);

my $is_mimeparser = eval { SOAP::MIMEParser->new; 1 };
(my $reason = $@) =~ s/ at .+// unless $is_mimeparser;
print "MIME tests will be skipped: $reason" if defined $reason;
my $package = '
  package Calculator;
  sub new { bless {} => ref($_[0]) || $_[0] }
  sub add { $_[1] + $_[2] }
  sub schema { $SOAP::Constants::DEFAULT_XML_SCHEMA }
1';

{
  print "Server handler test(s)...\n";

  my $server = SOAP::Server->dispatch_to('Calculator');

  foreach (keys %tests) {
#    print STDERR "\ntest=$_\n";
    my $result = SOAP::Deserializer->deserialize($server->handle($tests{$_}));
#    print STDERR "result1=$result\n";
#    print STDERR "is_mimeparser1=$is_mimeparser\n";
#    print STDERR "faultstring=".$result->faultstring."\n";
    $_ =~ /XML/ || $is_mimeparser ? ok(($result->faultstring || '') =~ /Failed to access class \(Calculator\)/)
                                  : skip($reason => undef);
  }

  eval $package or die;

  foreach (keys %tests) {
#    print STDERR "\ntest=$_\n";
    my $result = SOAP::Deserializer->deserialize($server->handle($tests{$_}));
#    print STDERR "result2=$result\n";
    $_ =~ /XML/ || $is_mimeparser ? ok(($result->result || 0) == 7)
                                  : skip($reason => undef);
  }
}

{
  print "Server handler with complex dispatches test(s)...\n";

  for (
    # dispatch to class
    SOAP::Server->dispatch_to('Calculator'),

    # dispatch to object
    SOAP::Server->dispatch_to(Calculator->new),

    # dispatch to regexp
    SOAP::Server->dispatch_to('Calc\w+'),

    # dispatch URI to class
    SOAP::Server->dispatch_with({'http://www.soaplite.com/Calculator' => 'Calculator'}),

    # dispatch URI to object
    SOAP::Server->dispatch_with({'http://www.soaplite.com/Calculator' => Calculator->new}),

    # dispatch quoted SOAPAction to class
    SOAP::Server->action('"http://action/#method"')->dispatch_with({'http://action/#method' => 'Calculator'}),

    # dispatch non-quoted SOAPAction to class
    SOAP::Server->action('http://action/#method')->dispatch_with({'http://action/#method' => 'Calculator'}),

    # dispatch to class and BAD regexp.
    SOAP::Server->dispatch_to('\protocols', 'Calculator')
  ) {
    my $result = SOAP::Deserializer->deserialize($_->handle($tests{'XML only'}));
    ok(($result->result || 0) == 7);
  }
}

{
  print "Error handling in server test(s)...\n";

  $a = SOAP::Server->handle('<a></a>');
  ok($a =~ /Can't find root/);

  $a = SOAP::Server->handle('<Envelope></Envelope>');
  ok($a =~ /Can't find method/);

  $a = SOAP::Server->handle('<Envelope><Body><Add><a>1</a><b>1</b></Add></Body></Envelope>');
  ok($a =~ /Denied access to method/);

  $a = SOAP::Server->handle('<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body></SOAP-ENV:Body></SOAP-ENV:Envelope>');
  ok($a =~ /Can't find method/);
}

{
  print "Envelope with no namespaces test(s)...\n";

  eval 'sub add { $_[1] + $_[2] }; 1' or die;

  my $result = SOAP::Deserializer->deserialize(SOAP::Server->dispatch_to('add')->handle('<Envelope><Body><add><a>3</a><b>4</b></add></Body></Envelope>'));
  ok(($result->result || 0) == 7);
}

{
  print "Different XML Schemas test(s)...\n";

  my $server = SOAP::Server->dispatch_to('Calculator');
  $a = $server->handle('<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/1999/XMLSchema">
<SOAP-ENV:Body>
<namesp1:schema xmlns:namesp1="http://www.soaplite.com/Calculator"/>
</SOAP-ENV:Body></SOAP-ENV:Envelope>');

  ok($a =~ m!xsi="http://www.w3.org/1999/XMLSchema-instance"!);
  ok($a =~ m!xsd="http://www.w3.org/1999/XMLSchema"!);
  ok($a =~ m!>http://www.w3.org/1999/XMLSchema<!);

  $a = $server->handle('<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:Body>
<namesp1:schema xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 xsi:type="xsd:int">2</c-gensym5>
</namesp1:schema>
</SOAP-ENV:Body></SOAP-ENV:Envelope>');

  ok($a =~ m!xsi="http://www.w3.org/2001/XMLSchema-instance"!);
  ok($a =~ m!xsd="http://www.w3.org/2001/XMLSchema"!);
  ok($a =~ m!>http://www.w3.org/2001/XMLSchema<!);

  $a = $server->handle('<SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:Body>
<namesp1:schema xmlns:namesp1="http://www.soaplite.com/Calculator">
  <c-gensym5 xsi:type="xsd:int">2</c-gensym5>
</namesp1:schema>
</SOAP-ENV:Body></SOAP-ENV:Envelope>');

  ok($a =~ m!xsi="http://www.w3.org/2001/XMLSchema-instance"!);
  ok($a =~ m!xsd="http://www.w3.org/2001/XMLSchema"!);
  ok($a =~ m!>http://www.w3.org/2001/XMLSchema<!);
}
