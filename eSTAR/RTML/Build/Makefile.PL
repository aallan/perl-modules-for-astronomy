use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'eSTAR::RTML::Build',
	       'VERSION_FROM'   => 'Build.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## 
	       ( ABSTRACT       => 'Module designed to build RTML messages',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

