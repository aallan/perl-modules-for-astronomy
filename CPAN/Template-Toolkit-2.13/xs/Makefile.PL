# $Id: Makefile.PL,v 1.1 2004/03/03 02:43:07 aa Exp $

use lib qw( ../lib ./lib );
use ExtUtils::MakeMaker;
use Template;

WriteMakefile(
    'NAME'     => 'Template::Stash::XS',
    'C'        => [ qw( Stash.c ) ],
    'XS'       => { 'Stash.xs' => 'Stash.c' },
    'OBJECT'   => 'Stash.o',
    'VERSION'  => $Template::VERSION,
    'NORECURS' => 1,
);

