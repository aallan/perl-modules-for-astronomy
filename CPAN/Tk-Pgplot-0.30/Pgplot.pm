package Tk::Pgplot;
require Tk;

use base qw(Tk::Widget);

Construct Tk::Widget 'Pgplot';


use vars qw($VERSION);
$VERSION = '0.30';

bootstrap Tk::Pgplot $Tk::VERSION;

sub Tk_cmd { \&Tk::pgplot }

Tk::Methods('xview', 'yview', 'world', 'setcursor', 'clrcursor',
	    'id', 'pixel');

1;

