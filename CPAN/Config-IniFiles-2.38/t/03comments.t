#
# Comment preservation
#

use strict;
use Test;
use Config::IniFiles;

BEGIN { plan tests => 15 }

my $ors = $\ || "\n";
my ($ini, $value);

# Get files from the 't' directory, portably
chdir('t') if ( -d 't' );

# test 1
# Load ini file and write as new file
$ini = new Config::IniFiles -file => "test.ini";
$ini->SetFileName("test03.ini");
$ini->SetWriteMode("0666");
unlink "test03.ini";
$ini->RewriteConfig;
$ini->ReadConfig;
ok($ini);

# test 2
# Section comments preserved
$value = 0;
if( open FILE, "<test03.ini" ) {
	$_ = join( '', <FILE> );
	$value = /\# This is a section comment[$ors]\[test1\]/;
	close FILE;
}
ok($value);


# test 3
# Parameter comments preserved
$value = /\# This is a parm comment[$ors]five=value5/;
ok($value);


# test 4
# Setting Section Comment
$ini->setval('foo','bar','qux');
ok($ini->SetSectionComment('foo', 'This is a section comment', 'This comment takes two lines!'));

# test 5
# Getting Section Comment
my @comment = $ini->GetSectionComment('foo');
ok( join('', @comment) eq '# This is a section comment# This comment takes two lines!');

#test 6
# Deleting Section Comment
$ini->DeleteSectionComment('foo');
# Should not exist!
ok(not defined $ini->GetSectionComment('foo'));

# test 7
# Setting Parameter Comment
ok($ini->SetParameterComment('foo', 'bar', 'This is a parameter comment', 'This comment takes two lines!'));

# test 8
# Getting Parameter Comment
@comment = $ini->GetParameterComment('foo', 'bar');
ok(join('', @comment) eq '# This is a parameter comment# This comment takes two lines!');

# test 9
# Deleting Parameter Comment
$ini->DeleteParameterComment('foo', 'bar');
# Should not exist!
ok(not defined $ini->GetSectionComment('foo', 'bar'));


# test 10
# Reading a section comment from the file
@comment = $ini->GetSectionComment('test1');
ok(join('', @comment) eq '# This is a section comment');

# test 11
# Reading a parameter comment from the file
@comment = $ini->GetParameterComment('test2', 'five');
ok(join('', @comment) eq '# This is a parm comment');

# test 12
# Reading a comment that starts with ';'
@comment = $ini->GetSectionComment('MixedCaseSect');
ok(join('', @comment) eq '; This is a semi-colon comment');


# Test 13
# Loading from a file with alternate comment characters
# and also test continuation characters (in one file)
$ini = Config::IniFiles->new(
  -file => "cmt.ini",
  -commentchar => '@',
  -allowcontinue => 1
);
ok($ini);

# Test 14
$value = $ini->GetParameterComment('Library', 'addmultf_lib');
ok ($value =~ /\@#\@CF Automatically created by 'config_project' at Thu Mar 21 08:46:54 2002/);

# Test 15
$value = $ini->val('turbo_library', 'TurboLibPaths');
ok ($value =~ m:\$WORKAREA/resources/c11_test_flow/vhdl_rtl\s+\$WORKAREA/resources/cstarlib_reg_1v5/vhdl_rtl:);

# Clean up when we're done
unlink "test03.ini";

