use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::WaveBand',
	       'VERSION_FROM'   => 'WaveBand.pm',
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => 'WaveBand.pm',
		 AUTHOR         => 'Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>') : ()),
             );

