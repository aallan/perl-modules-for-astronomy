use ExtUtils::MakeMaker;
use File::Spec;

my $file = File::Spec->catfile(File::Spec->curdir, "Query", "Query.pm");


WriteMakefile( 
               'NAME'           => 'Astro::ADS',
	       'VERSION_FROM'   => $file,
               'PREREQ_PM'      => { LWP::UserAgent },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Module designed to query the ADS',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

