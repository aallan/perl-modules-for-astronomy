# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tk::ROText;

use vars qw($VERSION);
$VERSION = '3.026'; # $Id: ROText.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk::Text;
use base  qw(Tk::Text);

Construct Tk::Widget 'ROText';

sub clipEvents
{
 return qw[Copy];
}

sub ClassInit
{
 my ($class,$mw) = @_;
 my $val = $class->bindRdOnly($mw);
 my $cb  = $mw->bind($class,'<Next>');
 $mw->bind($class,'<space>',$cb) if (defined $cb);
 $cb  = $mw->bind($class,'<Prior>');
 $mw->bind($class,'<BackSpace>',$cb) if (defined $cb);
 $class->clipboardOperations($mw,'Copy');
 return $val;
}

sub Tk::Widget::ScrlROText { shift->Scrolled('ROText' => @_) }

1;

__END__

