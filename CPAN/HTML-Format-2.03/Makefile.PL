require 5.004;
# Time-stamp: "2002-11-07 00:31:25 MST"
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'HTML-Format',
    VERSION_FROM => 'lib/HTML/Formatter.pm',
    PREREQ_PM    => {
		     'HTML::Element' => 3.15,
		     'Font::AFM'     => 1.17,
		    },
    dist         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
