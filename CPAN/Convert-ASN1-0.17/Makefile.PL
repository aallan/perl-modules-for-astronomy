# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1 2003/06/13 18:56:39 aa Exp $

use 5.004;
use ExtUtils::MakeMaker;

my @ppd;

@ppd = (
  AUTHOR    	=> 'Graham Barr <gbarr@pobox.com>',
  ABSTRACT  	=> 'Convert between perl data structures and ASN.1 encoded packets',
) if $] >= 5.00503;

WriteMakefile(
  VERSION_FROM  => 'lib/Convert/ASN1.pm',
  NAME          => 'Convert::ASN1',
  clean         => { FILES => 'y.tab.pl' },
  @ppd,
);

sub MY::postamble {


<<"EDQ";

run_byacc:
	\$(PERL) mkparse parser.y lib/Convert/ASN1/parser.pm

EDQ
}

