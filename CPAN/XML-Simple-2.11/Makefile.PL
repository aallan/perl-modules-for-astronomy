# $Id: Makefile.PL,v 1.1 2004/03/03 02:11:31 aa Exp $

use ExtUtils::MakeMaker;

my $make_params = {
    'NAME'          => 'XML::Simple',
    'VERSION_FROM'  => 'lib/XML/Simple.pm',
    'DISTNAME'      => 'XML-Simple',
    'PREREQ_PM'     => {
                         Test::Simple          => 0.41,
                       },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    ($] >= 5.005 ? (
      'AUTHOR'        => 'Grant McLean <grantm@cpan.org>',
      'ABSTRACT_FROM' => 'lib/XML/Simple.pm',
    ) : () )
};

print "Checking installed modules ...\n";

if ( eval { require XML::SAX } && ! $@ ) {
    print "XML::SAX is installed, it will be used by the test suite\n";
    $make_params->{PREREQ_PM}->{'XML::SAX'} = 0;
    $make_params->{PREREQ_PM}->{'XML::NamespaceSupport'} = 1.04;
}
elsif ( eval { require XML::Parser } && ! $@ ) {
    print "XML::Parser is installed, it will be used by the test suite\n";
    $make_params->{PREREQ_PM}->{'XML::Parser'} = 0;
} 
else {
    print "You don't have either XML::SAX or XML::Parser installed!\n";
    $make_params->{PREREQ_PM}->{'XML::SAX'} = 0;
    $make_params->{PREREQ_PM}->{'XML::NamespaceSupport'} = 1.04;
}

eval { require Storable };
if($@) {
  print "Storable is not installed ... caching functions will not be available\n";
}


WriteMakefile(%$make_params);
