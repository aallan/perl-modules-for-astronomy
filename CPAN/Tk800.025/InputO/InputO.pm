package Tk::InputO;

use vars qw($VERSION);
$VERSION = '3.014'; # $Id: InputO.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);
use base  qw(Tk::Widget);

Construct Tk::Widget 'InputO';

bootstrap Tk::InputO;

sub Tk_cmd { \&Tk::inputo }

#Tk::Methods qw(add ...);

1;

