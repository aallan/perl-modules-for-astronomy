# $Id: 9_Strict.t,v 1.1 2004/03/03 02:11:31 aa Exp $
# vim: syntax=perl

use strict;
use Test::More;

$^W = 1;

plan tests => 38;


##############################################################################
#                      T E S T   R O U T I N E S
##############################################################################

eval "use XML::Simple qw(:strict);";
ok(!$@, 'XML::Simple loads ok with qw(:strict)');

# Check that the basic functionality still works

my $xml = q(<opt name1="value1" name2="value2"></opt>);

$@ = '';
my $opt = eval {
  XMLin($xml, forcearray => 1, keyattr => {});
};
is($@, '', 'XMLin() did not fail');

my $keys = join(' ', sort keys %$opt);

is($keys, 'name1 name2', 'and managed to produce the expected results');


# Confirm that forcearray cannot be omitted

eval {
  $opt = XMLin($xml, keyattr => {});
};

isnt($@, '', 'omitting forcearray was a fatal error');
like($@, qr/(?i)No value specified for 'forcearray'/, 
  'with the correct error message');


# Confirm that keyattr cannot be omitted

eval {
  $opt = XMLin($xml, forcearray => []);
};

isnt($@, '', 'omitting keyattr was a fatal error');
like($@, qr/(?i)No value specified for 'keyattr'/,
  'with the correct error message');


# Confirm that element names from keyattr cannot be omitted from forcearray

eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => 0);
};

isnt($@, '', 'omitting forcearray for elements in keyattr was a fatal error');
like($@, qr/(?i)<part> set in keyattr but not in forcearray/,
  'with the correct error message');


eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => ['x','y']);
};

isnt($@, '', 'omitting keyattr elements from forcearray was a fatal error');
like($@, qr/(?i)<part> set in keyattr but not in forcearray/,
  'with the correct error message');


# Confirm that missing key attributes are detected

$xml = q(
<opt>
  <part partnum="12345" desc="Thingy" />
  <part partnum="67890" desc="Wotsit" />
  <part desc="Fnurgle" />
</opt>
);

eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => 1);
};

isnt($@, '', 'key attribute missing from names element was a fatal error');
like($@, qr/(?i)<part> element has no 'partnum' key attribute/,
  'with the correct error message');


# Confirm that stringification of references is trapped

$xml = q(
<opt>
  <item>
    <name><firstname>Bob</firstname></name>
    <age>21</age>
  </item>
</opt>
);

eval {
  $opt = XMLin($xml, keyattr => { item => 'name' }, forcearray => ['item']);
};

isnt($@, '', 'key attribute not a scalar was a fatal error');
like($@, qr/(?i)<item> element has non-scalar 'name' key attribute/,
  'with the correct error message');


##############################################################################
# Now confirm that XMLout gets checked too
#


# Check that the basic functionality still works under :strict

my $ref = {
  person => [
    { name => 'bob' },
    { name => 'kate' },
  ]
};

$@ = '';
$xml = eval {
  XMLout($ref, keyattr => {}, rootname => 'list');
};
is($@, '', 'XMLout() did not fail');

like($xml, qr{
      ^\s*<list\s*>
      \s*<person\s+name="bob"\s*/>
      \s*<person\s+name="kate"\s*/>
      \s*</list\s*>\s*$
    }xs, 'and managed to produce the expected results');


# Confirm that keyattr cannot be omitted

$@ = '';
eval {
  XMLout($ref, rootname => 'list');
};

isnt($@, '', 'omitting keyattr was a fatal error');
like($@, qr/(?i)No value specified for 'keyattr'/,
  'with the correct error message');


# Confirm that forcearray can be omitted (only rqd on input)

$@ = '';
eval {
  XMLout($ref, keyattr => {x => 'y'});
};

is($@, '', 'omitting forcearray was not a fatal error on output');


##############################################################################
# Now repeat all that using the OO syntax
##############################################################################

# Check that the basic functionality still works

$xml = q(<opt name1="value1" name2="value2"></opt>);

my $xs = XML::Simple->new(forcearray => 1, keyattr => {});

$@ = '';
$opt = eval {
  $xs->XMLin($xml);
};
is($@, '', '$xs->XMLin() did not fail');

$keys = join(' ', sort keys %$opt);

is($keys, 'name1 name2', 'and managed to produce the expected results');

# Confirm that forcearray cannot be omitted

$xs = XML::Simple->new(keyattr => {});

$@ = '';
eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'omitting forcearray was a fatal error');
like($@, qr/(?i)No value specified for 'forcearray'/, 
  'with the correct error message');


# Confirm that keyattr cannot be omitted

$xs = XML::Simple->new(forcearray => []);

eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'omitting keyattr was a fatal error');
like($@, qr/(?i)No value specified for 'keyattr'/,
  'with the correct error message');


# Confirm that element names from keyattr cannot be omitted from forcearray

$xs = XML::Simple->new(keyattr => { part => 'partnum' }, forcearray => 0);

eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'omitting forcearray for elements in keyattr was a fatal error');
like($@, qr/(?i)<part> set in keyattr but not in forcearray/,
  'with the correct error message');


$xs = XML::Simple->new(keyattr => { part => 'partnum' }, forcearray => ['x','y']);

eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'omitting keyattr elements from forcearray was a fatal error');
like($@, qr/(?i)<part> set in keyattr but not in forcearray/,
  'with the correct error message');


# Confirm that missing key attributes are detected

$xml = q(
<opt>
  <part partnum="12345" desc="Thingy" />
  <part partnum="67890" desc="Wotsit" />
  <part desc="Fnurgle" />
</opt>
);

$xs = XML::Simple->new(keyattr => { part => 'partnum' }, forcearray => 1);
eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'key attribute missing from names element was a fatal error');
like($@, qr/(?i)<part> element has no 'partnum' key attribute/,
  'with the correct error message');


# Confirm that stringification of references is trapped

$xml = q(
<opt>
  <item>
    <name><firstname>Bob</firstname></name>
    <age>21</age>
  </item>
</opt>
);

$xs = XML::Simple->new(keyattr => { item => 'name' }, forcearray => ['item']);

eval {
  $xs->XMLin($xml);
};

isnt($@, '', 'key attribute not a scalar was a fatal error');
like($@, qr/(?i)<item> element has non-scalar 'name' key attribute/,
  'with the correct error message');


##############################################################################
# Now confirm that XMLout gets checked too
#


# Check that the basic functionality still works under :strict

$ref = {
  person => [
    { name => 'bob' },
    { name => 'kate' },
  ]
};

$xs = XML::Simple->new(keyattr => {}, rootname => 'list');

$@ = '';
$xml = eval {
  $xs->XMLout($ref);
};
is($@, '', 'XMLout() did not fail');

like($xml, qr{
      ^\s*<list\s*>
      \s*<person\s+name="bob"\s*/>
      \s*<person\s+name="kate"\s*/>
      \s*</list\s*>\s*$
    }xs, 'and managed to produce the expected results');


# Confirm that keyattr cannot be omitted

$xs = XML::Simple->new(rootname => 'list');

eval {
  $xs->XMLout($ref);
};

isnt($@, '', 'omitting keyattr was a fatal error');
like($@, qr/(?i)No value specified for 'keyattr'/,
  'with the correct error message');


exit(0);

