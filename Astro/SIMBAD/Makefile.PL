use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::SIMBAD',
	       'VERSION_FROM'   => 'SIMBAD.pm',
               'PREREQ_PM'      => { LWP => 5.53 },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Module designed to query CDS SIMBAD',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

