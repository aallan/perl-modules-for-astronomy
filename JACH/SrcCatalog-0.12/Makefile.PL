
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'SrcCatalog',
        'VERSION_FROM' => 'SrcCatalog.pm',
        'DIR' => [
                  'JCMT'
		 ],
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
