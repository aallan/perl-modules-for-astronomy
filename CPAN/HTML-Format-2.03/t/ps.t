
use Test;
BEGIN { plan 'tests' => 4 }

use strict;
ok 1;

use HTML::FormatPS;

open(PS, ">test.ps") || die "Can't create test.ps";
binmode(PS);
print PS HTML::FormatPS->format_file(
  "test.html",
    "leftmargin" => 0,
    "rightmargin" => 50,
);
close PS;
sleep 0;
ok(-s "test.ps");
print "# Resulting file is ", -s "test.ps", " bytes long.\n";

ok(  HTML::FormatPS->format_string('puppies'), '/puppies/'  );

print "# HTML::Formatter version $HTML::Formatter::VERSION\n"
 if defined $HTML::Formatter::VERSION;
print "# HTML::Element version $HTML::Element::VERSION\n"
 if defined $HTML::Element::VERSION;
print "# HTML::TreeBuilder version $HTML::TreeBuilder::VERSION\n"
 if defined $HTML::TreeBuilder::VERSION;
print "# HTML::Parser version $HTML::Parser::VERSION\n"
 if defined $HTML::Parser::VERSION;


ok 1;


