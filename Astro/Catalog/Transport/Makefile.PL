use ExtUtils::MakeMaker;

WriteMakefile( 
               # Name has XXX so that the modules appear in Astro/Catalog/IO
               # Directory. This requires that DISTNAME is set manually
               'NAME'           => 'Astro::Catalog::Transport::XXX',
               'DISTNAME'       => 'Astro-Catalog-Transport',

               # Version of distribution not any given module
	       'VERSION'        => '0.01',
               'PREREQ_PM'      => { },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Generic base class for catalog queries',
		 AUTHOR         => 'Tim Jenness <timj@jach.hawaii.edu') : ()),
             );

