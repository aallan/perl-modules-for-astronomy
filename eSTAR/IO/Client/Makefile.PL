use ExtUtils::MakeMaker;

# list of includes
my $inc = ' -I/home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include'.
          ' -I/home/globus/bin/ssl/include -I/home/globus/include';
       
# list of libs
my $lib = ' -L/home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/lib' .
          ' -L/home/globus/lib -L/home/globus/bin/ssl/lib -L./src' .
          ' -lglobus_io -lglobus_gss_assist -lglobus_gss -lssl -lcrypto ' .
          ' -lglobus_gaa -lglobus_common -lpthread -lestar_io';    


WriteMakefile(
    'NAME'		=> 'eSTAR::IO::Client',
    'VERSION_FROM'	=> 'Client.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, 
    'LIBS'		=> [$lib], 
    'DEFINE'		=> '-D_REENTRANT', 
    'INC'		=> $inc );
