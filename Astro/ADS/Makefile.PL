use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::ADS',
	       'VERSION'        => '1.20.2',
               'EXE_FILES'      => [ 'adsquery' ],
               'PREREQ_PM'      => { LWP         => 5.53,
                                     Net::Domain => 2.13,
                                     Pod::Usage  => 1.14 },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Module designed to query the ADS',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

