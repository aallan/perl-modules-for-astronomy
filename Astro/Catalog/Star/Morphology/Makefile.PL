use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::Catalog::Star::Morphology',
	       'VERSION_FROM'   => 'Morphology.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A stellar morphology descriptior object',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

