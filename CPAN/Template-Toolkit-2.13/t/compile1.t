#============================================================= -*-perl-*-
#
# t/compile1.t
#
# Test the facility for the Template::Provider to maintain a persistance
# cache of compiled templates by writing generated Perl code to files.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: compile1.t,v 1.1 2004/03/03 02:43:05 aa Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

# declare extra tests to follow test_expect();
$Template::Test::EXTRA = 2;

# script may be being run in distribution root or 't' directory
my $dir   = -d 't' ? 't/test/src' : 'test/src';
my $ttcfg = {
    POST_CHOMP   => 1,
    INCLUDE_PATH => $dir,
    COMPILE_EXT => '.ttc',
    EVAL_PERL   => 1,
};

# delete any existing files
foreach my $f ( "$dir/foo.ttc", "$dir/complex.ttc" ) {
    ok( unlink($f) ) if -f $f;
}

test_expect(\*DATA, $ttcfg);

# $EXTRA tests
ok( -f "$dir/foo.ttc" );
ok( -f "$dir/complex.ttc" );


__DATA__
-- test --
[% INCLUDE evalperl %]
-- expect --
This file includes a perl block.

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
[% INCLUDE baz %]
-- expect --
This is the baz file, a: 



