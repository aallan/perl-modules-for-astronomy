# $Id: Makefile.PL,v 1.1 2003/05/01 13:26:59 aa Exp $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::SSLeay::Handle',
    'VERSION_FROM'	=> 'Handle.pm', # finds $VERSION
);
