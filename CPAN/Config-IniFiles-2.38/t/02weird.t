use strict;
use Test;
use Config::IniFiles;

BEGIN { plan tests => 6 }

my ($ini, $value);

# Get files from the 't' directory, portably
chdir('t') if ( -d 't' );

$ini = new Config::IniFiles -file => "test.ini";
$ini->SetFileName("test02.ini");
$ini->SetWriteMode("0666");

# Test 1
# print "Weird characters in section name . ";
$value = $ini->val('[w]eird characters', 'multiline');
ok($value eq "This$/is a multi-line$/value");

# Test 2
$ini->newval("test7|anything", "exists", "yes");
$ini->RewriteConfig;
$ini->ReadConfig;
$value = $ini->val("test7|anything", "exists");
ok($value eq "yes");

# Test 3/4
# Make sure whitespace after parameter name is not included in name
ok( $ini->val( 'test7', 'criterion' ) eq 'price <= maximum' );
ok( ! defined $ini->val( 'test7', 'criterion ' ) );

# Test 5
# Build a file from scratch with tied interface for testing
my %test;
ok( tie %test, 'Config::IniFiles' ); 
tied(%test)->SetFileName('test02.ini'); 

# Test 6
# Also with pipes when using tied interface using vlaue of 0
$test{'2'}={}; 
$test{'2'}{'test'}="sleep"; 
my $sectionheader="0|2"; 
$test{$sectionheader}={}; 
$test{$sectionheader}{'vacation'}=0;
tied(%test)->RewriteConfig(); 
tied(%test)->ReadConfig;
ok($test{$sectionheader}{'vacation'} == 0);


# Clean up when we're done
unlink "test02.ini";

