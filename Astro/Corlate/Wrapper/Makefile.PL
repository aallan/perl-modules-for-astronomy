use ExtUtils::MakeMaker;
use ExtUtils::F77 qw(linux f95);

# Library location
$location = '-LFortran';

# list of libraries
$cor_lib = '-lCorlate';
$f95_lib = '-lf95';

# LIBS line for ExtUtils::MakeMaker
$libs = "$location $cor_lib $f95_lib "; 

WriteMakefile(
    'NAME'		=> 'Astro::Corlate::Wrapper',
    'VERSION_FROM'	=> 'Wrapper.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [ $libs ], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
