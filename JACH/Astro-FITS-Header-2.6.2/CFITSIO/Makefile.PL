use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'Astro::FITS::Header::CFITSIO',
	      'VERSION_FROM'   => 'CFITSIO.pm',
              'PREREQ_PM' => {
			     },
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'CFITSIO.pm',
		AUTHOR     => 'Alasdari Allan <aa@astro.ex.ac.uk>') : ()),
	     );

