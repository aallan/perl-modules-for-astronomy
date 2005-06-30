use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'eSTAR::Database::Query',
               'VERSION_FROM' => 'Query.pm',
               'PREREQ_PM' => {},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
                (ABSTRACT_FROM => 'Query.pm',
                 AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
               'dist' => { COMPRESS => 'gzip -9f',
                           SUFFIX => 'gz',
                         },
             );

