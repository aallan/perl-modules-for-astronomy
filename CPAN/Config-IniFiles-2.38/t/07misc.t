use strict;
use Test;
use Config::IniFiles;

BEGIN { plan tests => 4 }

my ($ini, $value);

# Get files from the 't' directory, portably
chdir('t') if ( -d 't' );
unlink "test07.ini";

# Test 1
# Multiple equals in a parameter - should split on the first
$ini = new Config::IniFiles( -file => 'test.ini' );
$value = $ini->val('test7', 'criterion') || '';
ok($value eq 'price <= maximum');

# Test 2
# Parameters whose name is a substring of existing parameters should be loaded
$value = $ini->val('substring', 'boot');
ok( $value eq 'smarty');

# test 3 
# See if default option works
$ini = new Config::IniFiles( -file => "test.ini", -default => 'test1', -nocase => 1 );
$ini->SetFileName("test07.ini");
$ini->SetWriteMode("0666");
ok( (defined $ini) && ($ini->val('test2', 'three') eq 'value3') );

# Test 4
# Check that Config::IniFiles respects RO permission on original INI file
$ini->WriteConfig("test07.ini");
chmod 0444, "test07.ini";
if (-w "test07.ini") {
	skip(1,'RO Permissions not settable.');
} else {
	$ini->setval('test2', 'three', 'should not be here');
	$value = $ini->WriteConfig("test07.ini");
	warn "Value is $value!" if (defined $value);
	ok(not defined $value);
} # end if


# Clean up when we're done
unlink "test07.ini";

