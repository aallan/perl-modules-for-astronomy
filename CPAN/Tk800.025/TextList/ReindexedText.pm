use strict;
package Tk::ReindexedText;

use vars qw($VERSION);
$VERSION = '3.002'; # $Id: ReindexedText.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk::Reindex qw(Tk::Text);
use base qw(Tk::Reindex Tk::Text);
Construct Tk::Widget 'ReindexedText';

1;


