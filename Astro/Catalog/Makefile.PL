use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::Catalog',
	       'VERSION'        => '2.1.3',
               'EXE_FILES'      => [ 'catalogs', 'supercosmos', 'finder' ],
               'PREREQ_PM'      => { LWP         => 5.53,
                                     Net::Domain => 2.13,
                                     Pod::Usage  => 1.14,
                                     Astro::Coords => 0.05,
	                           },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A generic astronomical catalog object',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

