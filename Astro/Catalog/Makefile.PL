use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::Catalog',
	       'VERSION'        => '2.3',
               'EXE_FILES'      => [  ],
               'PREREQ_PM'      => { LWP              => 5.53,
                                     Net::Domain      => 2.13,
                                     Pod::Usage       => 1.14,
                                     Astro::Coords    => 0.05,
                                     File::Spec       => 0.84,
                                     Test::More       => 0.47,
                                     Astro::Telescope => 0.50,
                                     Astro::SLA       => 0.96,
                                     Time::Piece      => 1.08,
                                     Math::Libm       => 1.00,
                                     SOAP::Lite       => 0.00,
                                     Test             => 1.24,
                                     Carp             => 1.01,
                                     Data::Dumper     => 2.12
	                           },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A generic astronomical catalogue class',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

