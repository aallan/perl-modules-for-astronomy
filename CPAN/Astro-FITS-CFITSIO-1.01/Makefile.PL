use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$path =  shift if @ARGV && $ARGV[0] ne '--';
shift if $ARGV[0] eq '--';   # Rest of args are for MakeMaker

WriteMakefile(
    'NAME'	=> 'Astro::FITS::CFITSIO',
    'VERSION_FROM' => 'CFITSIO.pm', # finds $VERSION
    'LIBS'	=> ["-L$path/lib -lcfitsio -lm"],
    'INC'	=> "-I$path/include",
    'DEFINE'	=> '',
    'OBJECT' => 'CFITSIO.o util.o',
    'clean' => { FILES => "testprog.fit testprog/testprog.fit testprog/testprog.lis" },
);
