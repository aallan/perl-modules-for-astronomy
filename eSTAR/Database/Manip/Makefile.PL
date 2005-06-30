use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'eSTAR::Database::Manip',
               'VERSION_FROM' => 'Manip.pm',
               'PREREQ_PM' => {},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
                (ABSTRACT_FROM => 'Manip.pm',
                 AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
               'dist' => { COMPRESS => 'gzip -9f',
                           SUFFIX => 'gz',
                         },
             );

