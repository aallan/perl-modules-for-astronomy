package Tk::Xlib;
require DynaLoader;

use vars qw($VERSION);
$VERSION = '3.010'; # $Id: Xlib.pm,v 1.1 2003/09/28 14:54:56 aa Exp $

use Tk qw($XS_VERSION);
use Exporter;

use base  qw(DynaLoader Exporter);
@EXPORT_OK = qw(XDrawString XLoadFont XDrawRectangle);

bootstrap Tk::Xlib;

1;
