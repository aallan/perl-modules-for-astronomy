use ExtUtils::MakeMaker;

my %config = (
    'NAME'	   => 'AppConfig',
    'VERSION_FROM' => 'lib/AppConfig.pm', # finds $VERSION
    'PMLIBDIRS'    => [ 'lib' ],
    'PREREQ_PM'    => { 
        'Test::More' => 0,
    },
    'MAN3PODS' => { 
        # We must explicitly name AppConfig.pm et al as manifyable files.
        # MakeMaker ignores files that match  /(config|setup).*\.pm/i;
        'lib/AppConfig.pm'        => '$(INST_MAN3DIR)/AppConfig.$(MAN3EXT)',
        map { 
            ( "lib/AppConfig/${_}.pm", 
              "\$(INST_MAN3DIR)/AppConfig::${_}.\$(MAN3EXT)" ) ;
        } qw( Args CGI File Getopt State Sys ),
    },
    'dist' => { 
        'COMPRESS' => 'gzip', 
        'SUFFIX'   => 'gz',
        'PREOP'    => 'cp docs/header README; \
                       pod2text lib/AppConfig.pm >> README',
    },
);

## for PPD on win32
if ($] ge '5.005') {
    $config{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>',
    $config{ ABSTRACT } = 'AppConfig is a bundle of Perl5 modules for reading configuration files and parsing command line arguments.';
}


WriteMakefile(%config);
