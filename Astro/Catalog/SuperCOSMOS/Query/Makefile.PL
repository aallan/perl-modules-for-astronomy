use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::Catalog::SuperCOSMOS::Query',
	       'VERSION_FROM'   => 'Query.pm',
               'PREREQ_PM'      => { },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT  => 'Module designed to return SuperCOSMOS catalogs',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

