use ExtUtils::MakeMaker;
use File::Spec;

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "Astro", 
                               "FITS", "HdrTrans.pm");


WriteMakefile( 
               'NAME'           => 'Astro::FITS::HdrTrans',
               'VERSION_FROM'   => $file,
               'PREREQ_PM'      => { 
                                    Switch => 0,
                                    'Math::Trig' => 0,
                                   },
               'dist'           => { COMPRESS => "gzip -9f"},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               ( ABSTRACT_FROM  => $file,
                 AUTHOR         => 'Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>') : ()),
             );


