use strict;
package Tk::ReindexedROText;

use vars qw($VERSION);
$VERSION = '3.002'; # $Id: ReindexedROText.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk::Reindex qw(Tk::ROText);
use base qw(Tk::Reindex Tk::ROText);
Construct Tk::Widget 'ReindexedROText';

1;


