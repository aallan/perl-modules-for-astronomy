package TestParserPackage;
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);
sub new { 
    return bless {}, shift
}
sub supported_features {
    return ('http://axkit.org/sax/frobnosticating');
}
1;

