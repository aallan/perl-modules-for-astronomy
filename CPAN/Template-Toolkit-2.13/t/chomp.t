#============================================================= -*-perl-*-
#
# t/chomp.t
#
# Test the PRE_CHOMP and POST_CHOMP options.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: chomp.t,v 1.1 2004/03/03 02:43:05 aa Exp $
# 
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Template::Constants qw( :chomp );

$^W = 1;

#$Template::Directive::PRETTY = 1;
#$Template::Parser::DEBUG = 1;

match( CHOMP_NONE, 0 );
match( CHOMP_ALL, 1 );
match( CHOMP_COLLAPSE, 2 );

my $foo = "[% foo %]\n";
my $bar = "[% bar -%]\n";
my $baz = "[% foo +%]\n";
my $tt2 = Template->new({
    BLOCKS => {
	foo => $foo,
	bar => $bar,
	baz => $baz,
    },
});
my $vars = {
    foo => 3.14,
    bar => 2.718,
};

my $out;
ok( $tt2->process('foo', $vars, \$out), $tt2->error() );
match( $out, "3.14\n" );
$out = '';
ok( $tt2->process('bar', $vars, \$out), $tt2->error() );
match( $out, "2.718" );
$out = '';
ok( $tt2->process('baz', $vars, \$out), $tt2->error() );
match( $out, "3.14\n" );

$tt2 = Template->new({
    POST_CHOMP => 1,
    BLOCKS => {
	foo => $foo,
	bar => $bar,
	baz => $baz,
    },
});

$out = '';
ok( $tt2->process('foo', $vars, \$out), $tt2->error() );
match( $out, "3.14" );
$out = '';
ok( $tt2->process('bar', $vars, \$out), $tt2->error() );
match( $out, "2.718" );
$out = '';
ok( $tt2->process('baz', $vars, \$out), $tt2->error() );
match( $out, "3.14\n" );

my $tt = [
    tt_pre_none  => Template->new(PRE_CHOMP  => CHOMP_NONE),
    tt_pre_all   => Template->new(PRE_CHOMP  => CHOMP_ALL),
    tt_pre_coll  => Template->new(PRE_CHOMP  => CHOMP_COLLAPSE),
    tt_post_none => Template->new(POST_CHOMP => CHOMP_NONE),
    tt_post_all  => Template->new(POST_CHOMP => CHOMP_ALL),
    tt_post_coll => Template->new(POST_CHOMP => CHOMP_COLLAPSE),
];

test_expect(\*DATA, $tt);

__DATA__
#------------------------------------------------------------------------
# tt_pre_none
#------------------------------------------------------------------------
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin
     10
     20
end

#------------------------------------------------------------------------
# tt_pre_all
#------------------------------------------------------------------------
-- test --
-- use tt_pre_all --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin1020
end

#------------------------------------------------------------------------
# tt_pre_coll
#------------------------------------------------------------------------
-- test --
-- use tt_pre_coll --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin 10 20
end


#------------------------------------------------------------------------
# tt_post_none
#------------------------------------------------------------------------
-- test --
-- use tt_post_none --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin
     10
     20
end

#------------------------------------------------------------------------
# tt_post_all
#------------------------------------------------------------------------
-- test --
-- use tt_post_all --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin     10     20end

#------------------------------------------------------------------------
# tt_post_coll
#------------------------------------------------------------------------
-- test --
-- use tt_post_coll --
-- test --
begin[% a = 10; b = 20 %]     
[% a %]     
[% b %]     
end
-- expect --
begin 10 20 end

