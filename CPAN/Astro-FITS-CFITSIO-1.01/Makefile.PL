use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Astro::FITS::CFITSIO',
    'VERSION_FROM' => 'CFITSIO.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/local/lib -lcfitsio -lm'],
    'INC'	=> '-I/usr/local/include',
    'DEFINE'	=> '',
    'OBJECT' => 'CFITSIO.o util.o',
    'clean' => { FILES => "testprog.fit testprog/testprog.fit testprog/testprog.lis" },
);
