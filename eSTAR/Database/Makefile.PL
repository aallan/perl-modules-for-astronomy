use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'eSTAR::Database',
               'VERSION_FROM' => 'BaseDB.pm',
               'PREREQ_PM' => {},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
                (ABSTRACT_FROM => 'BaseDB.pm',
                 AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
               'dist' => { COMPRESS => 'gzip -9f',
                           SUFFIX => 'gz',
                         },
             );

