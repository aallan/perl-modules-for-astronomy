#============================================================= -*-perl-*-
#
# t/compile4.t
#
# Test the facility for the Template::Provider to maintain a persistance
# cache of compiled templates by writing generated Perl code to files.
# This is similar to compile1.t but defines COMPILE_DIR as well as
# COMPILE_EXT.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: compile4.t,v 1.1 2004/03/03 02:43:05 aa Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Cwd qw( abs_path );
use File::Path;
$^W = 1;

# declare extra tests to follow test_expect();
#$Template::Test::EXTRA = 2;

# script may be being run in distribution root or 't' directory
my $dir   = abs_path( -d 't' ? 't/test' : 'test' );
my $cdir  = abs_path("$dir/tmp") . "/cache";
my $ttcfg = {
    POST_CHOMP   => 1,
    INCLUDE_PATH => "$dir/src",
    COMPILE_DIR  => $cdir,
    COMPILE_EXT  => '.ttc',
    ABSOLUTE     => 1,
};

# delete any existing cache files
rmtree($cdir) if -d $cdir;
mkpath($cdir);

test_expect(\*DATA, $ttcfg, { root => abs_path($dir) } );


__DATA__
-- test --
[% TRY %]
[% INCLUDE foo %]
[% CATCH file %]
Error: [% error.type %] - [% error.info %]
[% END %]
-- expect --
This is the foo file, a is 

-- test --
[% META author => 'abw' version => 3.14 %]
[% INCLUDE complex %]
-- expect --
This is the header, title: Yet Another Template Test
This is a more complex file which includes some BLOCK definitions
This is the footer, author: abw, version: 3.14
- 3 - 2 - 1 

-- test --
[% TRY %]
[% INCLUDE bar/baz word = 'wibble' %]
[% CATCH file %]
Error: [% error.type %] - [% error.info %]
[% END %]
-- expect --
This is file baz
The word is 'wibble'

-- test --
[% INCLUDE "$root/src/blam" %]
-- expect --
This is the blam file
