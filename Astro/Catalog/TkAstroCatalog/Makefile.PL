
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Tk::AstroCatalog',
        'VERSION_FROM' => 'AstroCatalog.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
          ( ABSTRACT       => 'A Tk widget for browsing catalogue classes',
            AUTHOR         => 'Tim Jenness <tjenness@cpan.org>') : ()),

);
