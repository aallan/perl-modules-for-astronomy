package Tk::ImageBack;
require DynaLoader;

use vars qw($VERSION);
$VERSION = '3.010'; # $Id: ImageBack.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);

use base  qw(DynaLoader);

bootstrap Tk::ImageBack;

1;
__END__
