# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Tk::Label;
require Tk;


use vars qw($VERSION);
$VERSION = '3.013'; # $Id: Label.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use base  qw(Tk::Widget);

Construct Tk::Widget 'Label';

sub Tk_cmd { \&Tk::label }

1;



