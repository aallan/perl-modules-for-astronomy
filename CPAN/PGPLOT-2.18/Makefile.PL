
require 5.003;
use lib ".";
use ExtUtils::MakeMaker;

BEGIN {
eval 'use blib "../ExtUtils";' # For KGB development
if -e "../ExtUtils";
}

use ExtUtils::F77; # This should work most of the time

# Examples of how to explicitly override default automatic choice
# of OS and compiler (currently commented out):

#use ExtUtils::F77 qw(solaris); 
#use ExtUtils::F77 qw(generic g77); 

use Config;

my $ldir = defined $ENV{PGPLOT_DIR} ? "-L$ENV{PGPLOT_DIR}" : "";
my $idir = defined $ENV{PGPLOT_DIR} ? "-I$ENV{PGPLOT_DIR}" : "";

WriteMakefile(
    'NAME'	=> 'PGPLOT',
    'PREREQ_PM' => { 'ExtUtils::F77' => 1.13 },
    'VERSION_FROM'	=> 'PGPLOT.pm',
     ($^O eq 'VMS' ? ('LIBS' => 'pgplot_dir:cpgplot.olb') :
     (-d 'pgplot_tmp' ? 
        ('OBJECT' => '$(BASEEXT)$(OBJ_EXT) pgplot_tmp/libcpgplot.a '.
                    'pgplot_tmp/libpgplot.a',
        'LIBS'	=> ['-L/usr/openwin/lib -L/usr/X11/lib -L/usr/X11R6/lib -lX11 '.
                    ExtUtils::F77->runtime])
       :
         ('LIBS' => [$ldir.' -L/usr/local/pgplot -L/usr/local/lib -lcpgplot -lpgplot '.
                    '-L/usr/openwin/lib -L/usr/X11/lib -L/usr/X11R6/lib -lX11 '.
                    ExtUtils::F77->runtime])
     )),
    'DEFINE'	=>  ExtUtils::F77->trail_ ? "" : "-DNO_TRAILING_USCORE",
    ($^O eq 'VMS' ? ('INC' => 'pgplot_dir:') : (
    'INC'	=> $idir.' -I/home/aaossm/kgb/soft/pgplot/bld -I/usr/local/pgplot'  # where cpgplot.h should be
    )),
    'dist'      => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'depend'    => { '$(OBJECT)' => q[pgfun.c arrays.c PGPLOT.c]}
);

