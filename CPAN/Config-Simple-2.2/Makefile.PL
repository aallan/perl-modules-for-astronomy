use ExtUtils::MakeMaker;

eval "require Digest::MD5";

if ( $@ ) {
	warn <<WARNING;
###JUST A WARNING:    ###################################
# You do not have optional Digest::MD5 module installed.#
# You can download the latest version from CPAN.org.    #
#########################################################
WARNING
}

WriteMakefile(
    'NAME'		=> 'Config::Simple',
    'VERSION_FROM'	=> 'Simple.pm', 
    'PREREQ_PM'		=> {Digest::MD5=>undef},
    ($] >= 5.005 ?    (ABSTRACT_FROM => 'Simple.pm', AUTHOR => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>') : ()),
);
