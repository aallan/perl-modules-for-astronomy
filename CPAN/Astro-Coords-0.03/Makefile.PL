use ExtUtils::MakeMaker;
use File::Spec;

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "Astro", 
			       "Coords.pm");


WriteMakefile( 
               'NAME'           => 'Astro::Coords',
	       'VERSION_FROM'   => $file,
               'PREREQ_PM'      => { 
				    Astro::SLA => '0.95',
				    Time::Piece => '1.02',
				    Astro::Telescope => '0.50',
				   },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => $file,
		 AUTHOR         => 'Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>') : ()),
             );

