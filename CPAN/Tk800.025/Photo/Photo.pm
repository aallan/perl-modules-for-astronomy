package Tk::Photo;

use vars qw($VERSION);
$VERSION = '3.015'; # $Id: Photo.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);

use base  qw(Tk::Image);

Construct Tk::Image 'Photo';

bootstrap Tk::Photo;

sub Tk_image { 'photo' }

Tk::Methods('blank','copy','data','formats','get','put','read','redither','write');

1;
__END__
