package Tk::NBFrame;

use vars qw($VERSION);
$VERSION = '3.014'; # $Id: NBFrame.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);
use base  qw(Tk::Widget);

Construct Tk::Widget 'NBFrame';

bootstrap Tk::NBFrame;

sub Tk_cmd { \&Tk::nbframe }

Tk::Methods qw(activate add delete focus info geometryinfo identify
               move pagecget pageconfigure);

1;

