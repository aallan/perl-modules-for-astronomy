use Tk::MMutil;
use Tk::Config;
my $l = $Config::Config{'lib_ext'};

Tk::MMutil::TkExtMakefile(
    'NAME'         => 'Tk::JPEG', 
    'INC'          => '-Ijpeg',
    'EXE_FILES'    => ['tkjpeg'],
    'PMLIBDIRS'    => [],
    'OBJECT'       => '$(O_FILES)',
    'VERSION_FROM' => 'JPEG.pm',
    'XS_VERSION'   => $Tk::Config::VERSION,
    'MYEXTLIB'     => 'jpeg/libjpeg.a',   
    'MYEXTLIB'     => "jpeg/libjpeg$l",
    'dist'         => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'clean'        => { FILES => 'jpeg/Makefile jpeg/config.status jpeg/jconfig.h' }   );


sub MY::postamble {
'
$(MYEXTLIB)  : FORCE
	cd jpeg && $(MAKE) libjpeg'.$l.'
';
}



