use ExtUtils::MakeMaker;

WriteMakefile( 
               # Name has XXX so that the modules appear in Astro/Catalog/IO
               # Directory. This requires that DISTNAME is set manually
               'NAME'           => 'Astro::Catalog::IO::XXX',
	       'DISTNAME'       => 'Astro-Catalog-IO',

	       # Version of distribution not any given module
	       'VERSION'        => '0.01',
               'PREREQ_PM'      => { 
				     Astro::Coords => 0,
				     Astro::Telescope => 0,
				   },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Pluggable IO for Astro::Catalog catalog formats',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );


