
use Test;
BEGIN { plan 'tests' => 5 }

use strict;
ok 1;

use HTML::FormatText;

my $x = HTML::FormatText->format_file(
  "test.html",
     leftmargin => 5, rightmargin => 50
);
print "# Got back ", length($x), " characters.\n";
ok(length($x));
$x =~ s/^/#/mg;

print "# This should look right... \n$x\n";

ok( $x, '/\S/' );

ok(  HTML::FormatText->format_string('puppies'), '/puppies/'  );

print "# HTML::Formatter version $HTML::Formatter::VERSION\n"
 if defined $HTML::Formatter::VERSION;
print "# HTML::Element version $HTML::Element::VERSION\n"
 if defined $HTML::Element::VERSION;
print "# HTML::TreeBuilder version $HTML::TreeBuilder::VERSION\n"
 if defined $HTML::TreeBuilder::VERSION;
print "# HTML::Parser version $HTML::Parser::VERSION\n"
 if defined $HTML::Parser::VERSION;


ok 1;


