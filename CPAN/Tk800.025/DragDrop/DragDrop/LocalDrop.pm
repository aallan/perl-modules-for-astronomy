package Tk::DragDrop::Local;
use strict;   
use vars qw($VERSION);
$VERSION = '3.005'; # $Id: LocalDrop.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use base qw(Tk::DragDrop::Rect);
require Tk::DragDrop;

my @toplevels;

Tk::DragDrop->Type('Local');

sub XY
{
 my ($site,$event) = @_;
 return ($event->X - $site->X,$event->Y - $site->Y);
}

sub Apply
{
 my $site = shift;
 my $name = shift;
 my $cb   = $site->{$name};
 if ($cb)
  {
   my $event = shift;
   $cb->Call(@_,$site->XY($event));
  }
}

sub Drop
{
 my ($site,$token,$seln,$event) = @_;
 $site->Apply(-dropcommand => $event, $seln);
 $site->Apply(-entercommand => $event, 0);
 $token->Done;
}

sub Enter
{
 my ($site,$token,$event) = @_;
 $token->AcceptDrop;
 $site->Apply(-entercommand => $event, 1);
}

sub Leave
{
 my ($site,$token,$event) = @_;
 $token->RejectDrop;
 $site->Apply(-entercommand => $event, 0);
}

sub Motion
{
 my ($site,$token,$event) = @_;
 $site->Apply(-motioncommand => $event);
}      

1;     

__END__
