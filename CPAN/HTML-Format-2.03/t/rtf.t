
use Test;
BEGIN { plan 'tests' => 4 }

use strict;
ok 1;

use HTML::FormatRTF;

open(RTF, ">test.rtf") || die "Can't create test.rtf";
binmode(RTF);
print RTF HTML::FormatRTF->format_file(
  "test.html",
    "leftmargin" => 0,
    "rightmargin" => 50,
);
close RTF;
sleep 0;
ok(-s "test.rtf");
print "# Resulting file is ", -s "test.rtf", " bytes long.\n";

ok(  HTML::FormatRTF->format_string('puppies'), '/puppies/'  );

print "# HTML::Formatter version $HTML::Formatter::VERSION\n"
 if defined $HTML::Formatter::VERSION;
print "# HTML::Element version $HTML::Element::VERSION\n"
 if defined $HTML::Element::VERSION;
print "# HTML::TreeBuilder version $HTML::TreeBuilder::VERSION\n"
 if defined $HTML::TreeBuilder::VERSION;
print "# HTML::Parser version $HTML::Parser::VERSION\n"
 if defined $HTML::Parser::VERSION;


ok 1;


