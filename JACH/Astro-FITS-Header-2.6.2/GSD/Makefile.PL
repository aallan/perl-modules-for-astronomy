use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'Astro::FITS::Header::GSD',
	      'VERSION_FROM'   => 'GSD.pm',
              'PREREQ_PM' => {
			     },
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'GSD.pm',
		AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
	     );

