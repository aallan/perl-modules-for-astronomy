use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'Astro::FITS::Header::NDF',
	      'VERSION_FROM'   => 'NDF.pm',
              'PREREQ_PM' => {
			     },
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'NDF.pm',
		AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
	     );

