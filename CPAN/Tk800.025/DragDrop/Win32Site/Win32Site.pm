package Tk::DragDrop::Win32Site;

use vars qw($VERSION);
$VERSION = '3.009'; # $Id: Win32Site.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);
require DynaLoader;
require Tk::DropSite;

use base qw(Tk::DropSite DynaLoader);

bootstrap Tk::DragDrop::Win32Site;

use strict;

Tk::DropSite->Type('Win32');

sub WM_DROPFILES () {563}

sub InitSite
{
 my ($class,$site) = @_;
 my $w = $site->widget;
 $w->BindClientMessage(WM_DROPFILES,[\&Win32Drop,$site]);
 DragAcceptFiles($w,1);
 warn "Enable $w";
}

sub Win32Drop
{
 print join(',',@_),"\n";
 my ($w,$site,$msg,$wParam,$lParam) = @_;
 my ($x,$y,@files) = DropInfo($wParam);
 my $cb = $site->{'-dropcommand'};
 if ($cb)
  {
   foreach my $file (@files)
    {
     print "$file @ $x,$y\n";
     $w->clipboardClear;
     $w->clipboardAppend('--',$file);
     $cb->Call('CLIPBOARD',$x,$y);
    }
  }
 return 0;
}

1;
__END__
