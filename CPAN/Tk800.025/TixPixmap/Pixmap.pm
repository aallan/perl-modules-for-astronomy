package Tk::Pixmap;

use vars qw($VERSION);
$VERSION = '3.011'; # $Id: Pixmap.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);

use Tk::Image ();

use base  qw(Tk::Image);

Construct Tk::Image 'Pixmap';

bootstrap Tk::Pixmap;

sub Tk_image { 'pixmap' }

1;

