use strict;
use Test;

BEGIN { $| = 1; plan tests => 14 }
use Config::IniFiles;
my $loaded = 1;
ok($loaded);

my $ini;

# Get files from the 't' directory, portably
chdir('t') if ( -d 't' );

# a simple filehandle, such as STDIN
#** If anyone can come up with a test for STDIN that would be great
#   The following could be run in a separate file with data piped
#   in. e.g. ok( !system( "$^X stdin.pl < test.ini" ) );
#   But it's only good on platforms that support redirection.
#	use strict;
#	use Config::IniFiles;
#	my $ini = new Config::IniFiles -file => STDIN;
#	exit $ini ? 0; 1

local *CONFIG;
# Test 2
# a filehandle glob, such as *CONFIG
if( open( CONFIG, "test.ini" ) ) {
  $ini = new Config::IniFiles -file => *CONFIG;
  ok($ini);
  close CONFIG;
} else {
 ok( 0 );
}
	
# Test 3
# a reference to a glob, such as \*CONFIG
if( open( CONFIG, "test.ini" ) ) {
  $ini = new Config::IniFiles -file => \*CONFIG;
  ok($ini);
  close CONFIG;
} else {
  ok( 0 );
}

# Test 4
# an IO::File object
if( eval( "require IO::File" ) && (my $fh = new IO::File( "test.ini" )) ) {
  $ini = new Config::IniFiles -file => $fh;
  ok($ini);
  $fh->close;
} else {
  ok( 0 );
} # endif


# Test 5
# Reread on an open handle
if( open( CONFIG, "test.ini" ) ) {
  $ini = new Config::IniFiles -file => \*CONFIG;
  ok($ini && $ini->ReadConfig());
  close CONFIG;
} else {
  ok( 0 );
}


# Test 6
# Write to a new file name and write to it
if( open( CONFIG, "test.ini" ) ) {
  $ini = new Config::IniFiles -file => \*CONFIG;
  $ini->SetFileName( 'test01.ini' );
  $ini->RewriteConfig();
  close CONFIG;
  # Now test opening and re-write to the same handle
  if( open( CONFIG, "test01.ini" ) ) {
    $ini = new Config::IniFiles -file => \*CONFIG;
    my $badname = scalar(\*CONFIG);
                                       # Have to use open/close because -e seems to be always true!
    ok( $ini && $ini->RewriteConfig() && !(open( I, $badname )&&close(I)) );
    close CONFIG;
    # In case it failed, remove the file
    # (old behavior was to write to a file whose filename is the scalar value of the handle!)
    unlink $badname;
  } # end if
} else {
ok( 0 );
} # end if
  



# Test 7
# the pathname of a file
$ini = new Config::IniFiles -file => "test.ini";
ok($ini);

# Test 8
# A non-INI file should fail, but not throw warnings
local $@ = '';
my $ERRORS = '';
local $SIG{__WARN__} = sub { $ERRORS .= $_[0] };
eval { $ini = new Config::IniFiles -file => "00load.t" };
ok(!$@ && !$ERRORS && !defined($ini));


# Test 9
# Read in the DATA file without errors
$@ = '';
eval { $ini = new Config::IniFiles -file => \*DATA };
ok(!$@ && defined($ini));

# Test 10
# Try a file with utf-8 encoding (has a Byte-Order-Mark at the start)
$ini = new Config::IniFiles -file => "en.ini";
ok($ini);

# Test 11
# Create a new INI file, and set the name using SetFileName
$ini = new Config::IniFiles;
my $filename = $ini->GetFileName;
ok(not defined($filename));

# Test 12
# Check GetFileName method
$ini->SetFileName("test9_name.ini");
$filename = $ini->GetFileName;
ok($filename eq "test9_name.ini");

# Test 13
# Make sure that no warnings are thrown for an empty file
$@ = '';
eval { $ini = new Config::IniFiles -file => 'blank.ini' };
ok(!$@ && !defined($ini));

# Test 14
# A malformed file should throw an error message
$@ = '';
eval { $ini = new Config::IniFiles -file => 'bad.ini' };
ok(!$@ && !defined($ini) && @Config::IniFiles::errors);


# Clean up when we're done
unlink "test01.ini";


__END__
; File that has comments in the first line
; Comments are marked with ';'. 
; This should not fail when checking if the file is valid
[section]
parameter=value


