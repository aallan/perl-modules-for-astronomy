
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'SrcCatalog::JCMT',
        'VERSION_FROM' => 'JCMT.pm',
        'PREREQ_PM' => {
                        'Astro::Coords' => 0.04,
        },
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
