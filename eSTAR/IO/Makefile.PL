use ExtUtils::MakeMaker;
use strict;

# list of includes
my $inc = ' -I/home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include'.
          ' -I/home/globus/bin/ssl/include -I/home/globus/include';

# list of libs
my $lib = ' -L/home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/lib' .
          ' -L/home/globus/lib -L/home/globus/bin/ssl/lib' .
          ' -lglobus_io -lglobus_gss_assist -lglobus_gss -lssl -lcrypto ' .
          ' -lglobus_gaa -lglobus_common -lpthread -lestar_io';

WriteMakefile(
    'NAME'		=> 'eSTAR::IO',
    'VERSION_FROM'	=> 'IO.pm',
    'PREREQ_PM'		=> {},
    'LIBS'		=> [ $lib ],
    'DEFINE'		=> '-D_REENTRANT',
    'INC'		=> $inc );
