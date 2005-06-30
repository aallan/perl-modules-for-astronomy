use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'eSTAR::Database::DBbackend',
               'VERSION_FROM' => 'DBbackend.pm',
               'PREREQ_PM' => {},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
                (ABSTRACT_FROM => 'DBbackend.pm',
                 AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
               'dist' => { COMPRESS => 'gzip -9f',
                           SUFFIX => 'gz',
                         },
             );

