# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tk::MMtry;
use Config;
require Exporter;

use vars qw($VERSION @EXPORT);
$VERSION = '3.012'; # $Id: MMtry.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use base  qw(Exporter);
@EXPORT = qw(try_compile try_run);
use strict;
use File::Basename;

my $stderr_too = ($^O eq 'MSWin32') ? '' : '2>&1';

sub try_compile
{
 my $file  = shift;
 my $out   = basename($file,'.c').$Config{'exe_ext'};
 warn "Test Compiling $file\n";
 my $msgs  = `$Config{'cc'} -o $out $Config{'ccflags'} $file $stderr_too`;
 my $ok = ($? == 0);
 unlink($out) if (-f $out);
 return $ok;
}

sub try_run
{
 my $file  = shift;
 my $out   = basename($file,'.c').$Config{'exe_ext'};
 warn "Test Compiling $file\n";
 my $msgs  = `$Config{'cc'} -o $out $Config{'ccflags'} $file $stderr_too`;
 my $ok = ($? == 0);
 if ($ok)
  {
   system($out);
   $ok = ($? == 0);
  }
 unlink($out) if (-f $out);
 return $ok;
}

1;
