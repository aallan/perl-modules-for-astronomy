package Tk::Bitmap;
require Tk;
import  Tk qw($XS_VERSION);
require Tk::Image;

use vars qw($VERSION);
$VERSION = '3.010'; # $Id: Bitmap.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use base  qw(Tk::Image);

Construct Tk::Image 'Bitmap';

bootstrap Tk::Bitmap;

sub Tk_image { 'bitmap' }

1;
__END__
