use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'eSTAR::RTML',
	       'VERSION'        => 1.6.1,
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## 
	       ( ABSTRACT       => 'Module designed to parse RTML messages',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

