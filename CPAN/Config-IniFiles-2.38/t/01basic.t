use strict;
use Test;
use Config::IniFiles;

BEGIN { plan tests => 10 }

my ($value, @value);
umask 0000;

# Get files from the 't' directory, portably
chdir('t') if ( -d 't' );

# Test 1
# Loading from a file
my $ini = new Config::IniFiles -file => "test.ini";
unlink "test01.ini";
$ini->SetFileName("test01.ini");
$ini->SetWriteMode("0666");
ok($ini);

# Test 2
# Reading a single value in scalar context
$value = $ini->val('test1', 'one');
ok (defined $value and $value eq 'value1');

# Test 3
# Reading a single value in list context
@value = $ini->val('test1', 'one');
ok ($value[0] eq 'value1');

# Test 4
# Reading a multiple value in scalar context
$value = $ini->val('test1', 'mult');
ok (defined $value and $value eq "one$/two$/three");

# Test 5
# Reading a multiple value in list context
@value = $ini->val('test1', 'mult');
$value = join "|", @value;
ok ($value eq "one|two|three");

# Test 6
# Creating a new multiple value
@value = ("one", "two", "three");
$ini->newval('test1', 'eight', @value);
$value = $ini->val('test1', 'eight');
ok($value eq "one$/two$/three");

# Test 7
# Creating a new value
$ini->newval('test1', 'seven', 'value7');
$ini->RewriteConfig;
$ini->ReadConfig;
$value='';
$value = $ini->val('test1', 'seven');
ok ($value eq 'value7');

# Test 8
# Deleting a value
$ini->delval('test1', 'seven');
$ini->RewriteConfig;
$ini->ReadConfig;
$value='';
$value = $ini->val('test1', 'seven');
ok (! defined ($value));

# Test 9
# Reading a default values from existing section
$value = $ini->val('test1', 'not a real parameter name', '12345');
ok (defined($value) && ($value == '12345'));

# Test 10
# Reading a default values from non-existent section
$value = $ini->val('not a real section', 'no parameter by this name', '12345');
ok (defined($value) && ($value == '12345'));

# Clean up when we're done
unlink "test01.ini";

