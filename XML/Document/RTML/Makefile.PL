use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'          => 'XML::Document::RTML',
	       'VERSION'       => '0.1',
               'PREREQ_PM'     => {  },
	       'dist'          => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?   ## 
	       ( ABSTRACT      => 'Module designed to parse RTML messages',
		 AUTHOR        => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

