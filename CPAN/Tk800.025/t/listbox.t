#!/usr/bin/perl -w
# -*- perl -*-

# This file is the translation of a Tcl script to test out the "listbox"
# command of Tk.  It is organized in the standard fashion for Tcl tests.
#
# Copyright (c) 1993-1994 The Regents of the University of California.
# Copyright (c) 1994-1997 Sun Microsystems, Inc.
# Copyright (c) 1998-1999 by Scriptics Corporation.
# All rights reserved.
#
# RCS: @(#) $Id: listbox.t,v 1.1 2003/09/28 14:55:02 aa Exp $
#
# Translated to perl by Slaven Rezic
#

use strict;
use vars qw($Listbox);

use Tk;

BEGIN {
    $Listbox = "Listbox";
    #$Listbox = "TextList";
    eval "use Tk::$Listbox";
}

BEGIN {
    if (!eval q{
	use Test 1.13;
	1;
    }) {
	print "# tests only work with installed Test module:\n";
	print join("\n", map { "## $_" } split(/\n/, $@)), "\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 425 }

my $partial_top;
my $partial_lb;

my $mw = new MainWindow;
$mw->geometry('');
$mw->raise;
my $fixed = 'Courier -12';
ok(Tk::Exists($mw), 1);

# Create entries in the option database to be sure that geometry options
# like border width have predictable values.
$mw->optionAdd("*$Listbox.borderWidth",2);
$mw->optionAdd("*$Listbox.highlightThickness",2);
$mw->optionAdd("*$Listbox.font",'Helvetica -12 bold');

my $lb = $mw->$Listbox->pack;
ok(Tk::Exists($lb), 1);
ok($lb->isa("Tk::$Listbox"), 1);
$lb->update;

resetGridInfo();

foreach my $test
    (['-background', '#ff0000', '#ff0000', 'non-existent',
      'unknown color name "non-existent"'],
     [qw{-bd 4 4 badValue}, q{bad screen distance "badValue"}],
     ['-bg', '#ff0000', '#ff0000', 'non-existent',
      'unknown color name "non-existent"'],
     [qw{-borderwidth 1.3 1 badValue}, q{bad screen distance "badValue"}],
     [qw{-cursor arrow arrow badValue}, q{bad cursor spec "badValue"}],
# XXX error test skipped...
     [qw{-exportselection yes 1}, "", #"xyzzy",
      q{expected boolean value but got "xyzzy"}],
     ['-fg', '#110022', '#110022', 'bogus', q{unknown color name "bogus"}],
# XXX should test perl font object
#     ['-font', 'Helvetica 12', 'Helvetica 12', '', "font \"\" doesn't exist"],
     ['-foreground', '#110022', '#110022', 'bogus',
      q{unknown color name "bogus"}],
# XXX q{expected integer but got "20p"}
     [qw{-height 30 30 20p}, "'20p' isn't numeric"],
     ['-highlightbackground', '#112233', '#112233', 'ugly',
      q{unknown color name "ugly"}],
     ['-highlightcolor', '#123456', '#123456', 'bogus',
      q{unknown color name "bogus"}],
     [qw{-highlightthickness 6 6 bogus}, q{bad screen distance "bogus"}],
     [qw{-highlightthickness -2 0}, '', ''],
     [qw{-relief groove groove 1.5},
      ($Tk::VERSION < 803
       ? q{bad relief type "1.5": must be flat, groove, raised, ridge, solid, or sunken}
       : q{bad relief "1.5": must be flat, groove, raised, ridge, solid, or sunken})],
     ['-selectbackground', '#110022', '#110022', 'bogus',
      q{unknown color name "bogus"}],
     [qw{-selectborderwidth 1.3 1 badValue},
      q{bad screen distance "badValue"}],
     ['-selectforeground', '#654321', '#654321', 'bogus',
      q{unknown color name "bogus"}],
     [qw{-selectmode string string}, '', ''],
     [qw{-setgrid false 0}, "", # XXX "lousy",
      q{expected boolean value but got "lousy"}],
     ['-takefocus', "any string", "any string", '', ''],
     [qw{-width 45 45 3p}, "'3p' isn't numeric"],
      #XXXq{expected integer but got "3p"}],
#XXX Callback object      ['-xscrollcommand', 'Some command', 'Some command', '', ''],
#XXX     ['-yscrollcommand', 'Another command', 'Another command', '', ''],
#XXX not yet in 800.022     [qw{-listvar}, \$testVariable,  testVariable {}}, q{}],
    ) {
	my $name = $test->[0];

	if ($Listbox eq 'TextList' &&
	    $name =~ /^-(bg|fg|foreground|height|selectborderwidth)$/) {
	    skip(1,1);
	    if ($test->[3] ne "") {
		skip(1,1);
	    }
	    next;
	}

	$lb->configure($name, $test->[1]);
	ok(($lb->configure($name))[4], $test->[2], "configuration option $name");
	ok($lb->cget($name), $test->[2], "cget call with $name");
	if ($test->[3] ne "") {
	    eval {
		$lb->configure($name, $test->[3]);
	    };
	    ok($@ =~ /$test->[4]/, 1, "wrong error message for $name, got $@");
	}
	$lb->configure($name, ($lb->configure($name))[3]);
    }

if ($Listbox ne 'Listbox') {
    skip(1, 1);
} else {
    eval { Tk::listbox() };
    ok($@ =~ /Usage \$widget->listbox(...)/, 1, "wrong error message $@");
}

eval {
    $lb->destroy;
    $lb = $mw->$Listbox;
};
ok(Tk::Exists($lb), 1);
ok($lb->class, "$Listbox");

eval {
    $lb->destroy;
    $lb = $mw->$Listbox(-gorp => "foo");
};
ok($Tk::VERSION < 803
   ? $@ =~ /Bad option \`-gorp\'/
   : $@ =~ /unknown option \"-gorp\"/,
   1, "wrong error message, got $@");
ok(Tk::Exists($lb), 0);

$lb = $mw->$Listbox(-width => 20, -height => 5, -bd => 4,
		   -highlightthickness => 1,
		   -selectborderwidth => 2)->pack;
$lb->insert(0,
	    'el0','el1','el2','el3','el4','el5','el6','el7','el8','el9','el10',
	    'el11','el12','el13','el14','el15','el16','el17');
$lb->update;
eval { $lb->activate };
ok($@ =~ /wrong \# args: should be "\.listbox.* activate index"/, 1,
   "wrong error message, got $@");

eval { $lb->activate("fooey") };
ok($@ =~ /bad listbox index "fooey": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message, got $@");

$lb->activate(3);
ok($lb->index("active"), 3);

$lb->activate(-1);
ok($lb->index("active"), 0);

$lb->activate(30);
ok($lb->index("active"), 17);

$lb->activate("end");
ok($lb->index("active"), 17);

eval { $lb->bbox };
ok($@ =~ /wrong \# args: should be "\.listbox.* bbox index"/, 1,
   "wrong error message, got $@");

eval { $lb->bbox(qw/a b/) };
ok($@ =~ /wrong \# args: should be "\.listbox.* bbox index"/, 1,
   "wrong error message, got $@");

eval { $lb->bbox("fooey") };
ok($@ =~ /bad listbox index "fooey": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message, got $@");

$lb->yview(3);
$lb->update;
ok($lb->bbox(2), undef);
ok($lb->bbox(8), undef);

# Used to generate a core dump before a bug was fixed (the last
# element would be on-screen if it existed, but it doesn't exist).
eval {
    my $l2 = $mw->$Listbox;
    $l2->pack(-side => "top");
    $l2->waitVisibility;
    my $x = $l2->bbox(0);
    $l2->destroy;
};
ok($@, '', "wrong error message, got $@");

$lb->yview(3);
$lb->update;
ok(join(" ", $lb->bbox(3)), "7 7 17 14");
ok(scalar @{[$lb->bbox(3)]}, 4);
ok(($lb->bbox(3))[0], 7);
ok(($lb->bbox(3))[-1], 14);
ok(join(" ", $lb->bbox(4)), "7 26 17 14");

$lb->yview(0);
$lb->update;
ok($lb->bbox(-1), undef);
ok(join(" ", $lb->bbox(0)), "7 7 17 14");

$lb->yview("end");
$lb->update;
ok(join(" ", $lb->bbox(17)), "7 83 24 14");
ok(join(" ", $lb->bbox("end")), "7 83 24 14");
ok($lb->bbox(18), undef);

{
    my $t = $mw->Toplevel;
    $t->geometry("+0+0");
    my $lb = $t->$Listbox(-width => 10,
			 -height => 5);
    $lb->insert(0, "Short", "Somewhat longer",
		"Really, quite a whole lot longer than can possibly fit on the screen",
		"Short");
    $lb->pack;
    $lb->update;
    $lb->xview(moveto => 0.2);
    ok(join(" ", $lb->bbox(2)), '-72 39 393 14');
    $t->destroy;
}

mkPartial();
ok(join(" ", $partial_lb->bbox(3)), "5 56 24 14");
ok(join(" ", $partial_lb->bbox(4)), "5 73 23 14");

eval { $lb->cget };
ok($@ =~ /wrong \# args: should be \"\.listbox.* cget option\"/, 1,
   "wrong error message, got $@");

eval { $lb->cget(qw/a b/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* cget option\"/, 1,
   "wrong error message, got $@");

eval { $lb->cget(-gorp) };
ok($@ =~ /unknown option "-gorp"/, 1, "wrong error message, got $@");

ok($lb->cget(-setgrid), 0);
# XXX why 25 in Tk800?
ok(scalar @{[$lb->configure]}, ($Tk::VERSION < 803 ? 25 : 24));
ok(join(" ", $lb->configure(-setgrid)),
   "-setgrid setGrid SetGrid 0 0");
eval { $lb->configure(-gorp) };
ok($@ =~ /unknown option "-gorp"/, 1, "wrong error message, got $@");

{
    my $oldbd = $lb->cget(-bd);
    my $oldht = $lb->cget(-highlightthickness);
    $lb->configure(-bd => 3, -highlightthickness => 0);
    ok($lb->cget(-bd), 3);
    ok($lb->cget(-highlightthickness), 0);
    $lb->configure(-bd => $oldbd);
    $lb->configure(-highlightthickness => $oldht);
}

eval { $lb->curselection("a") };
ok($@ =~ /wrong \# args: should be \"\.listbox.* curselection\"/, 1,
   "wrong error message, got $@");

$lb->selection("clear", 0, "end");
$lb->selection("set", 3, 6);
$lb->selection("set", 9);
ok(join(" ", $lb->curselection), "3 4 5 6 9");

# alternative perl/Tk methods
$lb->selectionClear(0, "end");
$lb->selectionSet(3, 6);
$lb->selectionSet(9);
ok(join(" ", $lb->curselection), "3 4 5 6 9");

eval { $lb->delete };
ok($@ =~ /wrong \# args: should be \"\.listbox.* delete firstIndex \?lastIndex\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->delete(qw/a b c/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* delete firstIndex \?lastIndex\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->delete("badindex") };
ok($@ =~ /bad listbox index "badindex": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

eval { $lb->delete(2, "123ab") };
ok($@ =~ /bad listbox index "123ab": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(3);
    ok($l2->get(2), "el2");
    ok($l2->get(3), "el4");
    ok($l2->index("end"), "7");
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(2, 4);
    ok($l2->get(1), "el1");
    ok($l2->get(2), "el5");
    ok($l2->index("end"), "5");
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(-3, 2);
    ok(join(" ", $l2->get(0, "end")), "el3 el4 el5 el6 el7");
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(-3, -1);
    ok(join(" ", $l2->get(0, "end")), join(" ", map { "el$_" } (0 .. 7)));
    ok(scalar @{[$l2->get(0, "end")]}, 8);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(2, "end");
    ok(join(" ", $l2->get(0, "end")), "el0 el1");
    ok(scalar @{[$l2->get(0, "end")]}, 2);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(5, 20);
    ok(join(" ", $l2->get(0, "end")), "el0 el1 el2 el3 el4");
    ok(scalar @{[$l2->get(0, "end")]}, 5);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete("end", 20);
    ok(join(" ", $l2->get(0, "end")), "el0 el1 el2 el3 el4 el5 el6");
    ok(scalar @{[$l2->get(0, "end")]}, 7);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    $l2->delete(8, 20);
    ok(join(" ", $l2->get(0, "end")), "el0 el1 el2 el3 el4 el5 el6 el7");
    ok(scalar @{[$l2->get(0, "end")]}, 8);
    $l2->destroy;
}

eval { $lb->get };
ok($Tk::VERSION < 803
   ? $@ =~ /wrong \# args: should be \"\.listbox.* get first \?last\?\"/
   : $@ =~ /wrong \# args: should be \"\.listbox.* get firstIndex \?lastIndex\?\"/,
   1,
   "wrong error message, got $@");

eval { $lb->get(qw/a b c/) };
ok($Tk::VERSION < 803
   ? $@ =~ /wrong \# args: should be \"\.listbox.* get first \?last\?\"/
   : $@ =~ /wrong \# args: should be \"\.listbox.* get firstIndex \?lastIndex\?\"/,
   1,
   "wrong error message, got $@");

# XXX ok in perl/Tk
#  eval { $lb->get("2.4") };
#  ok($@ =~ /bad listbox index "2.4": must be active, anchor, end, \@x,y, or a number/, 1,
#     "wrong error message, got $@");

eval { $lb->get("badindex") };
ok($@ =~ /bad listbox index "badindex": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

eval { $lb->get("end", "bogus") };
ok($@ =~ /bad listbox index "bogus": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7));
    ok($l2->get(0), "el0");
    ok($l2->get(3), "el3");
    ok($l2->get("end"), "el7");
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    ok($l2->get(0), undef);
    ok($l2->get("end"), undef);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, qw(el0 el1 el2), "two words", qw(el4 el5 el6 el7));
    ok($l2->get(3), "two words");
    ok(($l2->get(3, "end"))[0], "two words");
    ok(join(" ", $l2->get(3, "end")), "two words el4 el5 el6 el7");
}

ok($lb->get(-1), undef);
ok($lb->get(-2, -1), undef);
ok(join(" ", $lb->get(-2, 3)), "el0 el1 el2 el3");
ok(scalar @{[ $lb->get(-2, 3) ]}, 4);

ok(join(" ", $lb->get(12, "end")), "el12 el13 el14 el15 el16 el17");
ok(scalar @{[ $lb->get(12, "end") ]}, 6);
ok(join(" ", $lb->get(12, 20)), "el12 el13 el14 el15 el16 el17");
ok(scalar @{[ $lb->get(12, 20) ]}, 6);

ok($lb->get("end"), "el17");
ok($lb->get(30), undef);
ok($lb->get(30, 35), ());

eval { $lb->index };
ok($@ =~ /wrong \# args: should be \"\.listbox.* index index\"/, 1,
   "wrong error message, got $@");

eval { $lb->index(qw/a b/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* index index\"/, 1,
   "wrong error message, got $@");

eval { $lb->index(qw/@/) };
ok($@ =~ /bad listbox index "\@": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

ok($lb->index(2), 2);
ok($lb->index(-1), -1);
ok($lb->index("end"), 18);
ok($lb->index(34), 34);

eval { $lb->insert };
ok($@ =~ /wrong \# args: should be \"\.listbox.* insert index \?element element \.\.\.\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->insert("badindex") };
ok($@ =~ /bad listbox index "badindex": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

{
    my $l2 = $mw->$Listbox;
    $l2->insert("end", qw/a b c d e/);
    $l2->insert(3, qw/x y z/);
    ok(join(" ", $l2->get(0, "end")), 'a b c x y z d e');
    ok(scalar @{[ $l2->get(0, "end") ]}, 8);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert("end", qw/a b c/);
    $l2->insert(-1, qw/x/);
    ok(join(" ", $l2->get(0, "end")), 'x a b c');
    ok(scalar @{[ $l2->get(0, "end") ]}, 4);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert("end", qw/a b c/);
    $l2->insert("end", qw/x/);
    ok(join(" ", $l2->get(0, "end")), 'a b c x');
    ok(scalar @{[ $l2->get(0, "end") ]}, 4);
    $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert("end", qw/a b c/);
    $l2->insert(43, qw/x/);
    ok(join(" ", $l2->get(0, "end")), 'a b c x');
    ok(scalar @{[ $l2->get(0, "end") ]}, 4);
    $l2->insert(4, qw/y/);
    ok(join(" ", $l2->get(0, "end")), 'a b c x y');
    $l2->insert(6, qw/z/);
    ok(join(" ", $l2->get(0, "end")), 'a b c x y z');
    $l2->destroy;
}

eval { $lb->nearest };
ok($@ =~ /wrong \# args: should be \"\.listbox.* nearest y\"/, 1,
   "wrong error message, got $@");

eval { $lb->nearest(qw/a b/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* nearest y\"/, 1,
   "wrong error message, got $@");

eval { $lb->nearest("badindex") };
ok($@ =~ /\'badindex\' isn\'t numeric/, 1,
   "wrong error message, got $@");

$lb->yview(3);
ok($lb->nearest(1000), 7);

eval { $lb->scan };
ok($Tk::VERSION < 803
   ? $@ =~ /wrong \# args: should be \"\.listbox.* scan mark x y\" or \"\.listbox.* scan dragto x y \?gain\?\"/
   : $@ =~ /wrong \# args: should be \"\.listbox.* scan mark\|dragto x y\"/, 1,
   "wrong error message, got $@");

eval { $lb->scan(qw/a b/) };
ok($Tk::VERSION < 803
   ? $@ =~ /wrong \# args: should be \"\.listbox.* scan mark x y\" or \"\.listbox.* scan dragto x y \?gain\?\"/
   : $@ =~ /wrong \# args: should be \"\.listbox.* scan mark\|dragto x y\"/, 1,
   "wrong error message, got $@");

eval { $lb->scan(qw/a b c d/) };
ok($Tk::VERSION < 803
   ? $@ =~ /\'b\' isn\'t numeric/
   : $@ =~ /wrong \# args: should be \"\.listbox.* scan mark\|dragto x y\"/,
   1, "wrong error message, got $@");

eval { $lb->scan(qw/foo bogus 2/) };
ok($@ =~ /\'bogus\' isn\'t numeric/,
   1, "wrong error message, got $@");

## ok in perl
#  eval { $lb->scan(qw/foo 2 2.3/) };
#  ok($@ =~ /'2.3' isn't numeric/, 1,
#     "wrong error message, got $@");

eval { $lb->scan(qw/foo 2 3/) };
ok($Tk::VERSION < 803
   ? $@ =~ /bad scan option \"foo\": must be mark or dragto/
   : $@ =~ /bad option \"foo\": must be mark, or dragto/,
   1, "wrong error message, got $@");

{
    my $t = $mw->Toplevel;
    $t->geometry("+0+0");
    my $lb = $t->$Listbox(-width => 10, -height => 5);
    $lb->insert(0, "Short", "Somewhat longer",
		"Really, quite a whole lot longer than can possibly fit on the screen", "Short",
		qw/a b c d e f g h i j/);
    $lb->pack;
    $lb->update;
    $lb->scan("mark", 100, 140);
    $lb->scan("dragto", 90, 137);
    $lb->update;
    ok(join(",",$lb->xview) =~ /^0\.24936.*,0\.42748.*$/, 1,
       join(",",$lb->xview));
    ok(join(",",$lb->yview) =~ /^0\.071428.*,0\.428571.*$/, 1,
       join(",",$lb->yview));
    $t->destroy;
}

eval { $lb->see };
ok($@ =~ /wrong \# args: should be \"\.listbox.* see index\"/, 1,
   "wrong error message, got $@");

eval { $lb->see("a","b") };
ok($@ =~ /wrong \# args: should be \"\.listbox.* see index\"/, 1,
   "wrong error message, got $@");

eval { $lb->see("badindex") };
ok($@ =~ /bad listbox index "badindex": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

$lb->yview(7);
$lb->see(7);
ok($lb->index('@0,0'), 7);

$lb->yview(7);
$lb->see(11);
ok($lb->index('@0,0'), 7);

$lb->yview(7);
$lb->see(6);
ok($lb->index('@0,0'), 6);

$lb->yview(7);
$lb->see(5);
ok($lb->index('@0,0'), 3);

$lb->yview(7);
$lb->see(12);
ok($lb->index('@0,0'), 8);

$lb->yview(7);
$lb->see(13);
ok($lb->index('@0,0'), 11);

$lb->yview(7);
$lb->see(-1);
ok($lb->index('@0,0'), 0);

$lb->yview(7);
$lb->see("end");
ok($lb->index('@0,0'), 13);

$lb->yview(7);
$lb->see(322);
ok($lb->index('@0,0'), 13);

mkPartial();
$partial_lb->see(4);
ok($partial_lb->index('@0,0'), 1);

eval { $lb->selection };
ok($@ =~ /wrong \# args: should be \"\.listbox.* selection option index \?index\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->selection("a") };
ok($@ =~ /wrong \# args: should be \"\.listbox.* selection option index \?index\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->selection(qw/a b c d/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* selection option index \?index\?\"/, 1,
   "wrong error message, got $@");

eval { $lb->selection(qw/a bogus/) };
ok($@ =~ /bad listbox index \"bogus\": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

eval { $lb->selection(qw/a 0 lousy/) };
ok($@ =~ /bad listbox index \"lousy\": must be active, anchor, end, \@x,y, or a number/, 1,
   "wrong error message, got $@");

eval { $lb->selection(qw/anchor 0 0/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* selection anchor index\"/, 1,
   "wrong error message, got $@");

$lb->selection("anchor", 5);
ok($lb->index("anchor"), 5);
$lb->selectionAnchor(0);
ok($lb->index("anchor"), 0);

$lb->selectionAnchor(-1);
ok($lb->index("anchor"), 0);
$lb->selectionAnchor("end");
ok($lb->index("anchor"), 17);
$lb->selectionAnchor(44);
ok($lb->index("anchor"), 17);

$lb->selection("clear", 0, "end");
$lb->selection("set", 2, 8);
$lb->selection("clear", 3, 4);
ok(join(",",$lb->curselection), "2,5,6,7,8");

$lb->selectionClear(0, "end");
$lb->selectionSet(2, 8);
$lb->selectionClear(3, 4);
ok(join(",",$lb->curselection), "2,5,6,7,8");

eval { $lb->selection(qw/includes 0 0/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* selection includes index\"/, 1,
   "wrong error message, got $@");

$lb->selectionClear(0, "end");
$lb->selectionSet(2,8);
$lb->selectionClear(4);
ok($lb->selection("includes", 3), 1);
ok($lb->selection("includes", 4), 0);
ok($lb->selection("includes", 5), 1);
ok($lb->selectionIncludes(3), 1);

$lb->selectionSet(0, "end");
ok($lb->selectionIncludes(-1), 0);

$lb->selectionClear(0, "end");
$lb->selectionSet("end");
ok($lb->selection("includes", "end"), 1);

$lb->selectionClear(0, "end");
$lb->selectionSet("end");
ok($lb->selection("includes", 44), 0);

{
    my $l2 = $mw->$Listbox;
    ok($l2->selectionIncludes(0), 0);
    $l2->destroy;
}

$lb->selection(qw(clear 0 end));
$lb->selection(qw(set 2));
$lb->selection(qw(set 5 7));
ok(join(" ", $lb->curselection), "2 5 6 7");
ok(scalar @{[$lb->curselection]}, 4);
$lb->selection(qw(set 5 7));
ok(join(" ", $lb->curselection), "2 5 6 7");
ok(scalar @{[$lb->curselection]}, 4);

eval { $lb->selection(qw/badOption 0 0/) };
ok($Tk::VERSION < 803
   ? $@ =~ /bad selection option \"badOption\": must be anchor, clear, includes, or set/
   : $@ =~ /bad option \"badOption\": must be anchor, clear, includes, or set/,
   1, "wrong error message, got $@");

eval { $lb->size(qw/a/) };
ok($@ =~ /wrong \# args: should be \"\.listbox.* size\"/, 1,
   "wrong error message, got $@");

ok($lb->size, 18);

{
    my $l2 = $mw->$Listbox;
    $l2->update;
    ok(($l2->xview)[0], 0);
    ok(($l2->xview)[1], 1);
    $l2->destroy;
}

eval { $lb->destroy };
$lb = $mw->$Listbox(-width => 10, -height => 5, -font => $fixed);
$lb->insert(qw/0 a b c d e f g h i j k l m n o p q r s t/);
$lb->pack;
$lb->update;
ok(($lb->xview)[0], 0);
ok(($lb->xview)[1], 1);

eval { $lb->destroy };
$lb = $mw->$Listbox(-width => 10, -height => 5, -font => $fixed);
$lb->insert(qw/0 a b c d e f g h i j k l m n o p q r s t/);
$lb->insert(qw/1 0123456789a123456789b123456789c123456789d123456789/);
$lb->pack;
$lb->update;

$lb->xview(4);
ok(join(",",$lb->xview), "0.08,0.28");

eval { $lb->xview("foo") };
ok($@ =~ /\'foo\' isn\'t numeric/, 1,
   "wrong error message, got $@");

eval { $lb->xview("zoom", "a", "b") };
ok($@ =~ /unknown option \"zoom\": must be moveto or scroll/, 1,
   "wrong error message, got $@");

$lb->xview(0);
$lb->xview(moveto => 0.4);
$lb->update;
ok(($lb->xview)[0], 0.4);
ok(($lb->xview)[1], 0.6);

$lb->xview(0);
$lb->xview(scroll => 2, "units");
$lb->update;
ok("@{[ $lb->xview ]}", '0.04 0.24');

$lb->xview(30);
$lb->xview(scroll => -1, "pages");
$lb->update;
ok("@{[ $lb->xview ]}", '0.44 0.64');

$lb->configure(-width => 1);
$lb->update;
$lb->xview(30);
$lb->xview("scroll", -4, "pages");
$lb->update;
ok("@{[ $lb->xview ]}", '0.52 0.54');

eval { $lb->destroy };
$lb = $mw->$Listbox->pack;
$lb->update;
ok(($lb->yview)[0], 0);
ok(($lb->yview)[1], 1);

eval { $lb->destroy };
$lb = $mw->$Listbox->pack;
$lb->insert(0, "el1");
$lb->update;
ok(($lb->yview)[0], 0);
ok(($lb->yview)[1], 1);

eval { $lb->destroy };
$lb = $mw->$Listbox(-width => 10, -height => 5, -font => $fixed);
$lb->insert(0,'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
	    'p','q','r','s','t');
$lb->pack;
$lb->update;
$lb->yview(4);
$lb->update;
ok(($lb->yview)[0], 0.2);
ok(($lb->yview)[1], 0.45);

mkPartial();
ok(($partial_lb->yview)[0], 0);
ok(($partial_lb->yview)[1] =~ /^0\.26666/, 1,
   "got " . (($partial_lb->yview)[1]));

eval { $lb->xview("foo") };
ok($@ =~ /\'foo\' isn\'t numeric/, 1,
   "wrong error message, got $@");

eval { $lb->xview("foo", "a", "b") };
ok($@ =~ /unknown option \"foo\": must be moveto or scroll/, 1,
   "wrong error message, got $@");

$lb->yview(0);
$lb->yview(moveto => 0.31);
ok("@{[ $lb->yview ]}", "0.3 0.55");

$lb->yview(2);
$lb->yview(scroll => 2 => "pages");
ok("@{[ $lb->yview ]}", "0.4 0.65");

$lb->yview(10);
$lb->yview(scroll => -3 => "units");
ok("@{[ $lb->yview ]}", "0.35 0.6");

$lb->configure(-height => 2);
$lb->update;
$lb->yview(15);
$lb->yview(scroll => -4 => "pages");
ok("@{[ $lb->yview ]}", "0.55 0.65");

# No tests for DestroyListbox:  I can't come up with anything to test
# in this procedure.

eval { $lb->destroy };
$lb = $mw->$Listbox(-setgrid => 1, -width => 25, -height => 15);
$lb->pack;
$mw->update;
ok(getsize($mw), "25x15");
$lb->configure(-setgrid => 0);
$mw->update;
ok(getsize($mw), "185x263");

resetGridInfo();

$lb->configure(-highlightthickness => -3);
ok($lb->cget(-highlightthickness), 0);

$lb->configure(-exportselection => 0);
$lb->delete(0, "end");
$lb->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7 el8));
$lb->selection("set", 3, 5);
$lb->configure(-exportselection => 1);
ok($mw->SelectionGet, "el3\nel4\nel5");

my $e = $mw->Entry;
$e->insert(0, "abc");
$e->selection("from", 0);
$e->selection("to", 2);
$lb->configure(-exportselection => 0);
$lb->delete(0, "end");
$lb->insert(0, qw(el0 el1 el2 el3 el4 el5 el6 el7 el8));
$lb->selectionSet(3, 5);
$lb->selectionClear(3, 5);
$lb->configure(-exportselection => 1);
ok($mw->SelectionOwner, $e);
ok($mw->SelectionGet, "ab");
$e->destroy;

$mw->SelectionClear;
$lb->configure(-exportselection => 1);
$lb->delete(0, "end");
$lb->insert(qw(0 el0 el1 el2 el3 el4 el5 el6 el7 el8));
$lb->selection("set", 1, 1);
ok($mw->SelectionGet, "el1");
ok($lb->curselection, "1");
$lb->configure(-exportselection => 0);
eval { $mw->SelectionGet };
ok($@ =~ /PRIMARY selection doesn\'t exist or form \"STRING\" not defined/, 1,
   "wrong error message: $@");
ok($lb->curselection, "1");
$lb->selection("clear", 0, "end");
eval { $mw->SelectionGet };
ok($@ =~ /PRIMARY selection doesn\'t exist or form \"STRING\" not defined/, 1,
   "wrong error message: $@");
ok($lb->curselection, ());
$lb->selection("set", 1, 3);
eval { $mw->SelectionGet };
ok($@ =~ /PRIMARY selection doesn\'t exist or form \"STRING\" not defined/, 1,
   "wrong error message: $@");
ok("@{[$lb->curselection]}", "1 2 3");
$lb->configure(-exportselection => 1);
ok($mw->SelectionGet, "el1\nel2\nel3");
ok("@{[$lb->curselection]}", "1 2 3");

$lb->destroy;
$mw->geometry("300x300");
$mw->update;
$mw->geometry("");
$mw->withdraw;
$lb = $mw->$Listbox(-font => $fixed, -width => 15, -height => 20);
$lb->pack;
$lb->update;
$mw->deiconify;
ok(getsize($mw), "118x328");
$lb->configure(-setgrid => 1);
$mw->update;
ok(getsize($mw), "15x20");

$lb->destroy;
$mw->withdraw;
$lb = $mw->$Listbox(-font => $fixed, -width => 30, -height => 20,
		   -setgrid => 1);
$mw->geometry("+0+0");
$lb->pack;
$mw->update;
$mw->deiconify;
ok(getsize($mw), "30x20");
$mw->geometry("26x15");
$mw->update;
ok(getsize($mw), "26x15");
$lb->configure(-setgrid => 1);
$lb->update;
ok(getsize($mw), "26x15");

$mw->geometry("");
$lb->destroy;
resetGridInfo();

my @log;

$lb = $mw->$Listbox(-width => 15, -height => 20,
		   -xscrollcommand => sub { record("x", @_) },
		   -yscrollcommand => [qw/record y/],
		  )->pack;
$lb->update;
$lb->configure(-fg => "black");
@log = ();
$lb->update;
ok($log[0], "y 0 1");
ok($log[1], "x 0 1");

$lb->destroy;
my @x = qw/a b c d/;
#XXX these are missing: -listvar tests, because 800.023 do not know this option
# $lb = $mw->$Listbox(-listvar => \@x);
# ok(join(",",$lb->get(0, "end")), "a,b,c,d");

#test listbox-4.10 {ConfigureListbox, no listvar -> existing listvar} {
#    catch {destroy $_lb}
#    set x [list a b c d]
#    listbox $_lb
#    $_lb insert end 1 2 3 4
#    $_lb configure -listvar x
#    $_lb get 0 end
#} [list a b c d]
#test listbox-4.11 {ConfigureListbox procedure, listvar -> no listvar} {
#    catch {destroy $_lb}
#    set x [list a b c d]
#    listbox $_lb -listvar x
#    $_lb configure -listvar {}
#    $_lb insert end 1 2 3 4
#    list $x [$_lb get 0 end]
#} [list [list a b c d] [list a b c d 1 2 3 4]]
#test listbox-4.12 {ConfigureListbox procedure, listvar -> different listvar} {
#    catch {destroy $_lb}
#    set x [list a b c d]
#    set y [list 1 2 3 4]
#    listbox $_lb
#    $_lb configure -listvar x
#    $_lb configure -listvar y
#    $_lb insert end 5 6 7 8
#    list $x $y
#} [list [list a b c d] [list 1 2 3 4 5 6 7 8]]
#test listbox-4.13 {ConfigureListbox, no listvar -> non-existant listvar} {
#    catch {destroy $_lb}
#    catch {unset x}
#    listbox $_lb
#    $_lb insert end a b c d
#    $_lb configure -listvar x
#    set x
#} [list a b c d]
#test listbox-4.14 {ConfigureListbox, non-existant listvar} {
#    catch {destroy $_lb}
#    catch {unset x}
#    listbox $_lb -listvar x
#    list [info exists x] $x
#} [list 1 {}]
#test listbox-4.15 {ConfigureListbox, listvar -> non-existant listvar} {
#    catch {destroy $_lb}
#    catch {unset y}
#    set x [list a b c d]
#    listbox $_lb -listvar x
#    $_lb configure -listvar y
#    list [info exists y] $y
#} [list 1 [list a b c d]]
#test listbox-4.16 {ConfigureListbox, listvar -> same listvar} {
#    catch {destroy $_lb}
#    set x [list a b c d]
#    listbox $_lb -listvar x
#    $_lb configure -listvar x
#    set x
#} [list a b c d]
#test listbox-4.17 {ConfigureListbox, no listvar -> no listvar} {
#    catch {destroy $_lb}
#    listbox $_lb
#    $_lb insert end a b c d
#    $_lb configure -listvar {}
#    $_lb get 0 end
#} [list a b c d]
#test listbox-4.18 {ConfigureListbox, no listvar -> bad listvar} {
#    catch {destroy $_lb}
#    listbox $_lb
#    $_lb insert end a b c d
#    set x {this is a " bad list}
#    catch {$_lb configure -listvar x} result
#    list [$_lb get 0 end] [$_lb cget -listvar] $result
#} [list [list a b c d] {} \
#	"unmatched open quote in list: invalid listvar value"]

# No tests for DisplayListbox:  I don't know how to test this procedure.

Tk::catch { $lb->destroy if Tk::Exists($lb) };
$lb = $mw->$Listbox(-font => $fixed, -width => 15, -height => 20)->pack;
ok($lb->reqwidth, 115);
ok($lb->reqheight, 328);

eval { $lb->destroy };
$lb = $mw->$Listbox(-font => $fixed, -width => 0, -height => 10)->pack;
$lb->update;
ok($lb->reqwidth, 17);
ok($lb->reqheight, 168);

eval { $lb->destroy };
$lb = $mw->$Listbox(-font => $fixed, -width => 0, -height => 10,
		   -bd => 3)->pack;
$lb->insert(0, "Short", "Really much longer", "Longer");
$lb->update;
ok($lb->reqwidth, 138);
ok($lb->reqheight, 170);

eval { $lb->destroy };
$lb = $mw->$Listbox(-font => $fixed, -width => 10, -height => 0,
		  )->pack;
$lb->update;
ok($lb->reqwidth, 80);
ok($lb->reqheight, 24);

eval { $lb->destroy };
$lb = $mw->$Listbox(-font => $fixed, -width => 10, -height => 0,
		   -highlightthickness => 0)->pack;
$lb->insert(0, "Short", "Really much longer", "Longer");
$lb->update;
ok($lb->reqwidth, 76);
ok($lb->reqheight, 52);

eval { $lb->destroy };
# If "0" in selected font had 0 width, caused divide-by-zero error.
$lb = $mw->$Listbox(-font => '{open look glyph}')->pack;
$lb->update;

eval { $lb->destroy };
$lb = $mw->$Listbox(-height => 2,
		   -xscrollcommand => sub { record("x", @_) },
		   -yscrollcommand => sub { record("y", @_) })->pack;
$lb->update;

$lb->delete(0, "end");
$lb->insert(qw/end a b c d/);
$lb->insert(qw/5 x y z/);
$lb->insert(qw/2 A/);
$lb->insert(qw/0 q r s/);
ok(join(" ",$lb->get(qw/0 end/)), 'q r s a b A c d x y z');

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 2/);
$lb->insert(qw/2 A B/);
ok($lb->index(qw/anchor/), 4);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 2/);
$lb->insert(qw/3 A B/);
ok($lb->index(qw/anchor/), 2);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->insert(qw/2 A B/);
ok($lb->index(q/@0,0/), 5);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->insert(qw/3 A B/);
ok($lb->index(q/@0,0/), 3);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/5/);
$lb->insert(qw/5 A B/);
ok($lb->index(qw/active/), 7);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/5/);
$lb->insert(qw/6 A B/);
ok($lb->index(qw/active/), 5);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c/);
ok($lb->index(qw/active/), 2);

$lb->delete(qw/0 end/);
$lb->insert(qw/0/);
ok($lb->index(qw/active/), 0);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b/, "two words", qw/c d e f g h i j/);
$lb->update;
@log = ();
$lb->insert(qw/0 word/);
$lb->update;
print "# @log\n";
ok("@log" =~ /^y 0 0\.083333/);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b/, "two words", qw/c d e f g h i j/);
$lb->update;
@log = ();
$lb->insert(0, "much longer entry");
$lb->update;
print "# @log\n";
ok("$log[0]" =~ /^y 0 0\.083333/);
ok("$log[1]", "x 0 1");

{
    my $l2 = $mw->$Listbox(-width => 0, -height => 0)->pack(-side => "top");
    $l2->insert(0, "a", "b", "two words", "c", "d");
    ok($l2->reqwidth, 80);
    ok($l2->reqheight, 93);
    $l2->insert(0, "much longer entry");
    ok($l2->reqwidth, 122);
    ok($l2->reqheight, 110);
    $l2->destroy;
}

{
      my @x = qw(a b c d);
    ## -listvar XXX
#      my $l2 = $mw->$Listbox(-listvar => \@x);
#      $l2->insert(0, 1 .. 4);
#      ok(join(" ", @x), "1 2 3 4 a b c d");
#      ok(scalar @x, 8);
#      ok($x[0], 1);
#      ok($x[-1], "d");
#      $l2->destroy;
}

{
    my $l2 = $mw->$Listbox;
    $l2->insert(0, 0 .. 4);
    $l2->selection("set", 2, 4);
    $l2->insert(0, "a");
    ok("@{[ $l2->curselection ]}", "3 4 5");
    ok(scalar @{[ $l2->curselection ]}, 3);
    $l2->destroy;
}

$lb->delete(0, "end");
$lb->insert(0, qw/a b c d e f g h i j/);
$lb->selectionSet(1, 6);
$lb->delete(4, 3);
ok($lb->size, 10);
ok($mw->SelectionGet, "b
c
d
e
f
g");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/set 3 6/);
$lb->delete(qw/4 4/);
ok($lb->size, 9);
ok($lb->get(4), "f");
ok("@{[ $lb->curselection ]}", "3 4 5");
ok(scalar @{[ $lb->curselection ]}, 3);
ok(($lb->curselection)[0], 3);
ok(($lb->curselection)[-1], 5);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->delete(qw/0 3/);
ok($lb->size, 6);
ok($lb->get(0), "e");
ok($lb->get(1), "f");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->delete(qw/8 1000/);
ok($lb->size, 8);
ok($lb->get(7), "h");

$lb-> delete(0, qw/end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 2/);
$lb->delete(qw/0 1/);
ok($lb->index(qw/anchor/), 0);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 2/);
$lb->delete(qw/2/);
ok($lb->index(qw/anchor/), 2);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 4/);
$lb->delete(qw/2 5/);
ok($lb->index(qw/anchor/), 2);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->selection(qw/anchor 3/);
$lb->delete(qw/4 5/);
ok($lb->index(qw/anchor/), 3);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->delete(qw/1 2/);
ok($lb->index(q/@0,0/), 1);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->delete(qw/3 4/);
ok($lb->index(q/@0,0/), 3);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->delete(qw/4 6/);
ok($lb->index(q/@0,0/), 3);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
$lb->delete(qw/3 end/);
ok($lb->index(q/@0,0/), 2);

mkPartial();
$partial_lb->yview(8);
$mw->update;
$partial_lb->delete(10, 13);
ok($partial_lb->index('@0,0'), 7);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/6/);
$lb->delete(qw/3 4/);
ok($lb->index(qw/active/), 4);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/6/);
$lb->delete(qw/5 7/);
ok($lb->index(qw/active/), 5);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/6/);
$lb->delete(qw/5 end/);
ok($lb->index(qw/active/), 4);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->activate(qw/6/);
$lb->delete(qw/0 end/);
ok($lb->index(qw/active/), 0);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c/, "two words", qw/d e f g h i j/);
$lb->update;
@log = ();
$lb->delete(qw/4 6/);
$lb->update;
ok($log[0], "y 0 0.125");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c/, "two words", qw/d e f g h i j/);
$lb->update;
@log = ();
$lb->delete(qw/3/);
$lb->update;
ok($log[0], "y 0 0.1");
ok($log[1], "x 0 1");

{
    my $l2 = $mw->$Listbox(-width => 0, -height => 0)->pack(-side => "top");
    $l2->insert(0, "a", "b", "two words", qw/c d e f g/);
    ok($l2->reqwidth, 80);
    ok($l2->reqheight, 144);
    $l2->delete(2, 4);
    ok($l2->reqwidth, 17);
    ok($l2->reqheight, 93);
    $l2->destroy;
}

## -listvar
#  catch {destroy .l2}
#  test listbox-7.21 {DeleteEls procedure, check -listvar update} {
#      catch {destroy .l2}
#      set x [list a b c d]
#      listbox .l2 -listvar x
#      .l2 delete 0 1
#      set x
#  } [list c d]

$lb->destroy;
$lb = $mw->$Listbox(-setgrid => 1)->pack;
$lb->update;
ok(getsize($mw), "20x10");
$lb->destroy;
ok(getsize($mw), "150x178");
ok(Tk::Exists($lb), 0);

resetGridInfo();

$lb = $mw->$Listbox(-height => 5, -width => 10);
$lb->insert(qw/0 a b c/, "A string that is very very long",
	    qw/ d e f g h i j k/);
$lb->pack;
$lb->update;
$lb->place(qw/-width 50 -height 80/);
$lb->update;
ok(join(" ", $lb->xview) =~ /^0 0\.2222/);
ok(join(" ", $lb->yview) =~ /^0 0\.3333/);

map { $_->destroy } $mw->children;
my $l1 = $mw->$Listbox(-bg => "#543210");
my $l2 = $l1;
ok(join(",", map { $_->PathName } $mw->children) =~ /^\.listbox\d*$/, 1);
ok($l2->cget(-bg), "#543210");
$l2->destroy;

my $top = $mw->Toplevel;
$top->geometry("+0+0");
my $top_lb = $top->$Listbox(-setgrid => 1,
			   -width => 20,
			   -height => 10)->pack;
$top_lb->update;
ok($top->geometry, "20x10+0+0");
$top_lb->destroy;
ok($top->geometry, "150x178+0+0");

$lb = $mw->$Listbox->pack;
$lb->delete(0, "end");
$lb->insert(qw/0 el0 el1 el2 el3 el4 el5 el6 el7 el8 el9 el10 el11/);
$lb->activate(3);
ok($lb->index("active"), 3);
$lb->activate(6);
ok($lb->index("active"), 6);

$lb->selection(qw/anchor 2/);
ok($lb->index(qw/anchor/), 2);

$lb->insert(qw/end A B C D E/);
$lb->selection(qw/anchor end/);
$lb->delete(qw/12 end/);
ok($lb->index("anchor"), 12);
ok($lb->index("end"), 12);

eval { $lb->index("a") };
ok($@ =~ /bad listbox index \"a\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@") };
ok($@ =~ /bad listbox index \"\@\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@foo") };
ok($@ =~ /bad listbox index \"\@foo\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@1x3") };
ok($@ =~ /bad listbox index \"\@1x3\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@1,") };
ok($@ =~ /bad listbox index \"\@1,\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@1,foo") };
ok($@ =~ /bad listbox index \"\@1,foo\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("\@1,2x") };
ok($@ =~ /bad listbox index \"\@1,2x\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

eval { $lb->index("1xy") };
ok($@ =~ /bad listbox index \"1xy\": must be active, anchor, end, \@x,y, or a number/, 1, "wrong error message $@");

ok($lb->index("end"), 12);

ok($lb->get(qw/end/), "el11");

$lb->delete(qw/0 end/);
ok($lb->index(qw/end/), 0);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 el0 el1 el2 el3 el4 el5 el6 el7 el8 el9 el10 el11/);
$lb->update;

ok($lb->index(q/@5,57/), 3);
ok($lb->index(q/@5,58/), 3);

ok($lb->index(qw/3/), 3);
ok($lb->index(qw/20/), 20);

ok($lb->get(qw/20/), undef);

ok($lb->index(qw/-2/), -2);

$lb->delete(qw/0 end/);
ok($lb->index(qw/1/), 1);

$lb->destroy;
$lb = $mw->$Listbox(-height => 5)->pack;
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
ok($lb->index(q/@0,0/), 3);
$lb->yview(qw/-1/);
$lb->update;
ok($lb->index(q/@0,0/), 0);

$lb->destroy;
$lb = $mw->$Listbox(qw/-height 5/)->pack;
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
ok($lb->index(q/@0,0/), 3);
$lb->yview(qw/20/);
$lb->update;
ok($lb->index(q/@0,0/), 5);

$lb->destroy;
$lb = $mw->$Listbox(qw/-height 5 -yscrollcommand/, [qw/record y/])->pack;
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->update;
@log = ();
$lb->yview(qw/2/);
$lb->update;
ok("@{[ $lb->yview ]}", "0.2 0.7");
ok($log[0], "y 0.2 0.7");

$lb->destroy;
$lb = $mw->$Listbox(qw/-height 5 -yscrollcommand/, [qw/record y/])->pack;
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->update;
@log = ();
$lb->yview(qw/8/);
$lb->update;
ok("@{[ $lb->yview ]}", "0.5 1");
ok($log[0], "y 0.5 1");

$lb->destroy;
$lb = $mw->$Listbox(qw/-height 5 -yscrollcommand/, [qw/record y/])->pack;
$lb->insert(qw/0 a b c d e f g h i j/);
$lb->yview(qw/3/);
$lb->update;
@log = ();
$lb->yview(qw/3/);
$lb->update;
ok("@{[ $lb->yview ]}", "0.3 0.8");
ok(scalar @log, 0);

mkPartial();
$partial_lb->yview(13);
ok($partial_lb->index('@0,0'), 11);

$lb->destroy;
$lb = $mw->$Listbox(-font => $fixed,
		   -xscrollcommand => ["record", "x"],
		   -width => 10);
$lb->insert(qw/0 0123456789a123456789b123456789c123456789d123456789e123456789f123456789g123456789h123456789i123456789/);
$lb->pack;
$lb->update;

@log = ();
$lb->xview(qw/99/);
$lb->update;
ok("@{[ $lb->xview ]}", "0.9 1");
ok(($lb->xview)[0], 0.9);
ok(($lb->xview)[1], 1);
ok($log[0], "x 0.9 1");

@log = ();
$lb->xview(qw/moveto -.25/);
$lb->update;
ok("@{[ $lb->xview ]}", "0 0.1");
ok($log[0], "x 0 0.1");

$lb->xview(qw/10/);
$lb->update;
@log = ();
$lb->xview(qw/10/);
$lb->update;
ok("@{[ $lb->xview ]}", "0.1 0.2");
ok(scalar @log, 0);

$lb->destroy;
$lb = $mw->$Listbox(-font => $fixed, -width => 10, -height => 5)->pack;
$lb->insert(qw/0 a bb c d e f g h i j k l m n o p q r s/);
$lb->insert(qw/0 0123456789a123456789b123456789c123456789d123456789/);
$lb->update;
my $width  = ($lb->bbox(2))[2] - ($lb->bbox(1))[2];
my $height = ($lb->bbox(2))[1] - ($lb->bbox(1))[1];

$lb->yview(qw/0/);
$lb->xview(qw/0/);
$lb->scan(qw/mark 10 20/);
$lb->scan(qw/dragto/, 10-$width, 20-$height);
$lb->update;
ok("@{[ $lb->xview ]}", "0.2 0.4");
ok("@{[ $lb->yview ]}", "0.5 0.75");

$lb->yview(qw/5/);
$lb->xview(qw/10/);
$lb->scan(qw/mark 10 20/);
$lb->scan(qw/dragto 20 40/);
$lb->update;
ok("@{[ $lb->xview ]}", "0 0.2");
ok("@{[ $lb->yview ]}", "0 0.25");

$lb->scan(qw/dragto/, 20-$width, 40-$height);
$lb->update;
ok("@{[ $lb->xview ]}", "0.2 0.4");
ok("@{[ $lb->yview ]}", "0.5 0.75");

$lb->yview(qw/moveto 1.0/);
$lb->xview(qw/moveto 1.0/);
$lb->scan(qw/mark 10 20/);
$lb->scan(qw/dragto 5 10/);
$lb->update;
ok("@{[ $lb->xview ]}", "0.8 1");
ok("@{[ $lb->yview ]}", "0.75 1");
$lb->scan(qw/dragto/, 5+$width, 10+$height);
$lb->update;
ok("@{[ $lb->xview ]}", "0.62 0.82");
ok("@{[ $lb->yview ]}", "0.25 0.5");

mkPartial();
ok($partial_lb->nearest($partial_lb->height), 4);

$lb->destroy;
$lb = $mw->$Listbox(-font => $fixed,
		   -width => 20,
		   -height => 10);
$lb->insert(qw/0 a b c d e f g h i j k l m n o p q r s t/);
$lb->yview(qw/4/);
$lb->pack;
$lb->update;

ok($lb->index(q/@50,0/), 4);

ok($lb->index(q/@50,35/), 5);
ok($lb->index(q/@50,36/), 6);

ok($lb->index(q/@50,200/), 13);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j k l m n o p/);
$lb->selection(qw/set 2 4/);
$lb->selection(qw/set 7 12/);
$lb->selection(qw/clear 4 7/);
ok("@{[ $lb->curselection ]}", "2 3 8 9 10 11 12");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f g h i j k l m n o p/);

$e = $mw->Entry;
$e->insert(0, "This is some text");
$e->selection(qw/from 0/);
$e->selection(qw/to 7/);
$lb->selection(qw/clear 2 4/);
ok($mw->SelectionOwner, $e);
$lb->selection(qw/set 3/);
ok($mw->SelectionOwner, $lb);
ok($mw->SelectionGet, "d");

$lb->delete(qw/0 end/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set 0 end/);
ok($lb->curselection, ());

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set -2 -1/);
ok($lb->curselection, ());

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set -1 3/);
ok(join(",",$lb->curselection), "0,1,2,3");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set 2 4/);
ok(join(" ", $lb->curselection), "2 3 4");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set 4 end/);
ok(join(" ", $lb->curselection), "4 5");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set 4 30/);
ok(join(",", $lb->curselection), "4,5");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set end 30/);
ok(join(",", $lb->curselection), 5);
ok(scalar @{[ $lb->curselection ]}, 1);

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e f/);
$lb->selection(qw/clear 0 end/);
$lb->selection(qw/set 20 25/);
ok($lb->curselection, ());

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c/, "two words", qw/ e f g h i \ k l m n o p/);
$lb->selection(qw/set 2 4/);
$lb->selection(qw/set 9/);
$lb->selection(qw/set 11 12/);
ok($mw->SelectionGet, "c\ntwo words\ne\n\\\nl\nm");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c/, "two words", qw/ e f g h i \ k l m n o p/);
$lb->selection(qw/set 3/);
ok($mw->SelectionGet, "two words");

my $long = "This is quite a long string\n" x 11;
$lb->delete(qw/0 end/);
$lb->insert(0, "1$long", "2$long", "3$long", "4$long", "5$long");
$lb->selection(qw/set 0 end/);
ok($mw->SelectionGet, "1$long\n2$long\n3$long\n4$long\n5$long");

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e/);
$lb->selection(qw/set 0 end/);
$e->destroy;
$e = $mw->Entry;
$e->insert(0, "This is some text");
$e->selection(qw/from 0/);
$e->selection(qw/to 5/);
ok($lb->curselection, ());

$lb->delete(qw/0 end/);
$lb->insert(qw/0 a b c d e/);
$lb->selection(qw/set 0 end/);
$lb->configure(qw/-exportselection 0/);
$e->destroy;
$e = $top->Entry;
$e->insert(0, "This is some text");
$e->selection(qw/from 0/);
$e->selection(qw/to 5/);
ok(join(" ", $lb->curselection), "0 1 2 3 4");

$lb->destroy;
$lb = $mw->$Listbox(-font => $fixed, -width => 10, -height => 5);
$lb->pack;
$lb->update;

$lb->configure(qw/-yscrollcommand/, [qw/record y/]);
@log = ();
$lb->insert(qw/0 a b c/);
$lb->update;
$lb->insert(qw/end d e f g h/);
$lb->update;
$lb->delete(qw/0 end/);
$lb->update;
ok($log[0], "y 0 1");
ok($log[1], "y 0 0.625");
ok($log[2], "y 0 1");

mkPartial();
$partial_lb->configure(-yscrollcommand => ["record", "y"]);
@log = ();
$partial_lb->yview(3);
$partial_lb->update;
ok($log[0] =~ /^y 0\.2 0\.46666/);

@x = ();

sub Tk::Error {
    push @x, @_;
}

# XXX dumps core with 5.7.0 and 803.023
$lb->configure(qw/-yscrollcommand gorp/);
$lb->insert(qw/0 foo/);
$lb->update;
ok("@x" =~ /Undefined subroutine &main::gorp called.*vertical scrolling command executed by listbox/s, 1, "x is @x");

$lb->destroy;
$lb = $mw->$Listbox(-font => $fixed, qw/-width 10 -height 5/)->pack;
$lb->update;

$lb->configure(qw/-xscrollcommand/, ["record", "x"]);
@log = ();
$lb->insert(qw/0 abc/);
$lb->update;
$lb->insert(qw/0/, "This is a much longer string...");
$lb->update;
$lb->delete(qw/0 end/);
$lb->update;
ok($log[0], "x 0 1");
ok($log[1] =~ /^x 0 0\.32258/, 1, "expected: x 0 0.32258 in $log[1]");
ok($log[2], "x 0 1");

@x = ();
$lb->configure(qw/-xscrollcommand bogus/);
$lb->insert(qw/0 foo/);
$lb->update;
ok("@x" =~ /Undefined subroutine &main::bogus.*horizontal scrolling command executed by listbox/s, 1, "x is @x");

foreach ($mw->children) { $_->destroy }

## XXX not yet
#  # tests for ListboxListVarProc
#  test listbox-21.1 {ListboxListVarProc} {
#      catch {destroy $_lb}
#      catch {unset x}
#      listbox $_lb -listvar x
#      set x [list a b c d]
#      $_lb get 0 end
#  } [list a b c d]
#  test listbox-21.2 {ListboxListVarProc} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      unset x
#      set x
#  } [list a b c d]
#  test listbox-21.3 {ListboxListVarProc} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      $_lb configure -listvar {}
#      unset x
#      info exists x
#  } 0
#  test listbox-21.4 {ListboxListVarProc} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      lappend x e f g
#      $_lb size
#  } 7
#  test listbox-21.5 {ListboxListVarProc, test selection after listvar mod} {
#      catch {destroy $_lb}
#      set x [list a b c d e f g]
#      listbox $_lb -listvar x
#      $_lb selection set end
#      set x [list a b c d]
#      set x [list 0 1 2 3 4 5 6]
#      $_lb curselection
#  } {}
#  test listbox-21.6 {ListboxListVarProc, test selection after listvar mod} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      $_lb selection set 3
#      lappend x e f g
#      $_lb curselection
#  } 3
#  test listbox-21.7 {ListboxListVarProc, test selection after listvar mod} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      $_lb selection set 0
#      set x [linsert $x 0 1 2 3 4]
#      $_lb curselection
#  } 0
#  test listbox-21.8 {ListboxListVarProc, test selection after listvar mod} {
#      catch {destroy $_lb}
#      set x [list a b c d]
#      listbox $_lb -listvar x
#      $_lb selection set 2
#      set x [list a b c]
#      $_lb curselection
#  } 2
#  test listbox-21.9 {ListboxListVarProc, test hscrollbar after listvar mod} {
#      catch {destroy $_lb}
#      catch {unset x}
#      set log {}
#      listbox $_lb -font $fixed -width 10 -xscrollcommand "record x" -listvar x
#      pack $_lb
#      update
#      lappend x "0000000000"
#      update
#      lappend x "00000000000000000000"
#      update
#      set log
#  } [list {x 0 1} {x 0 1} {x 0 0.5}]
#  test listbox-21.10 {ListboxListVarProc, test hscrollbar after listvar mod} {
#      catch {destroy $_lb}
#      catch {unset x}
#      set log {}
#      listbox $_lb -font $fixed -width 10 -xscrollcommand "record x" -listvar x
#      pack $_lb
#      update
#      lappend x "0000000000"
#      update
#      lappend x "00000000000000000000"
#      update
#      set x [list "0000000000"]
#      update
#      set log
#  } [list {x 0 1} {x 0 1} {x 0 0.5} {x 0 1}]
#  test listbox-21.11 {ListboxListVarProc, bad list} {
#      catch {destroy $_lb}
#      catch {unset x}
#      listbox $_lb -listvar x
#      set x [list a b c d]
#      catch {set x {this is a " bad list}} result
#      set result
#  } {can't set "x": invalid listvar value}
#  test listbox-21.12 {ListboxListVarProc, cleanup item attributes} {
#      catch {destroy $_lb}
#      set x [list a b c d e f g]
#      listbox $_lb -listvar x
#      $_lb itemconfigure end -fg red
#      set x [list a b c d]
#      set x [list 0 1 2 3 4 5 6]
#      $_lb itemcget end -fg
#  } {}
#  test listbox-21.12 {ListboxListVarProc, cleanup item attributes} {
#      catch {destroy $_lb}
#      set x [list a b c d e f g]
#      listbox $_lb -listvar x
#      $_lb itemconfigure end -fg red
#      set x [list a b c d]
#      set x [list 0 1 2 3 4 5 6]
#      $_lb itemcget end -fg
#  } {}
#  test listbox-21.13 {listbox item configurations and listvar based deletions} {
#      catch {destroy $_lb}
#      catch {unset x}
#      listbox $_lb -listvar x
#      $_lb insert end a b c
#      $_lb itemconfigure 1 -fg red
#      set x [list b c]
#      $_lb itemcget 1 -fg
#  } red
#  test listbox-21.14 {listbox item configurations and listvar based inserts} {
#      catch {destroy $_lb}
#      catch {unset x}
#      listbox $_lb -listvar x
#      $_lb insert end a b c
#      $_lb itemconfigure 0 -fg red
#      set x [list 1 2 3 4 a b c]
#      $_lb itemcget 0 -fg
#  } red
#  test listbox-21.15 {ListboxListVarProc, update vertical scrollbar} {
#      catch {destroy $_lb}
#      catch {unset x}
#      set log {}
#      listbox $_lb -listvar x -yscrollcommand "record y" -font fixed -height 3
#      pack $_lb
#      update
#      lappend x a b c d e f
#      update
#      set log
#  } [list {y 0 1} {y 0 0.5}]
#  test listbox-21.16 {ListboxListVarProc, update vertical scrollbar} {
#      catch {destroy $_lb}
#      catch {unset x}
#      listbox $_lb -listvar x -height 3
#      pack $_lb
#      update
#      set x [list 0 1 2 3 4 5]
#      $_lb yview scroll 3 units
#      update
#      set result {}
#      lappend result [$_lb yview]
#      set x [lreplace $x 3 3]
#      set x [lreplace $x 3 3]
#      set x [lreplace $x 3 3]
#      update
#      lappend result [$_lb yview]
#      set result
#  } [list {0.5 1} {0 1}]

# UpdateHScrollbar

@log = ();
$lb = $mw->Listbox(-font => $fixed, -width => 10, -xscrollcommand => ["record", "x"])->pack;
$mw->update;
$lb->insert("end", "0000000000");
$mw->update;
$lb->insert("end", "00000000000000000000");
$mw->update;
ok($log[0], "x 0 1");
ok($log[1], "x 0 1");
ok($log[2], "x 0 0.5");

## no itemconfigure in Tk800.x
#  # ConfigureListboxItem
#  test listbox-23.1 {ConfigureListboxItem} {
#      catch {destroy $_lb}
#      listbox $_lb
#      catch {$_lb itemconfigure 0} result
#      set result
#  } {item number "0" out of range}
#  test listbox-23.2 {ConfigureListboxItem} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      $_lb itemconfigure 0
#  } [list {-background background Background {} {}} \
#  	{-bg -background} \
#  	{-fg -foreground} \
#  	{-foreground foreground Foreground {} {}} \
#  	{-selectbackground selectBackground Foreground {} {}} \
#  	{-selectforeground selectForeground Background {} {}}]
#  test listbox-23.3 {ConfigureListboxItem, itemco shortcut} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      $_lb itemco 0 -background
#  } {-background background Background {} {}}
#  test listbox-23.4 {ConfigureListboxItem, wrong num args} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a
#      catch {$_lb itemco} result
#      set result
#  } {wrong # args: should be "$_lb itemconfigure index ?option? ?value? ?option value ...?"}
#  test listbox-23.5 {ConfigureListboxItem, multiple calls} {
#      catch {destroy $_lb}
#      listbox $_lb
#      set i 0
#      foreach color {red orange yellow green blue darkblue violet} {
#  	$_lb insert end $color
#  	$_lb itemconfigure $i -bg $color
#  	incr i
#      }
#      pack $_lb
#      update
#      list [$_lb itemcget 0 -bg] [$_lb itemcget 1 -bg] [$_lb itemcget 2 -bg] \
#  	    [$_lb itemcget 3 -bg] [$_lb itemcget 4 -bg] [$_lb itemcget 5 -bg] \
#  	    [$_lb itemcget 6 -bg]
#  } {red orange yellow green blue darkblue violet}
#  catch {destroy $_lb}
#  listbox $_lb
#  $_lb insert end a b c d
#  set i 6
#  #      {-background #ff0000 #ff0000 non-existent
#  #  	    {unknown color name "non-existent"}}
#  #      {-bg #ff0000 #ff0000 non-existent {unknown color name "non-existent"}}
#  #      {-fg #110022 #110022 bogus {unknown color name "bogus"}}
#  #      {-foreground #110022 #110022 bogus {unknown color name "bogus"}}
#  #      {-selectbackground #110022 #110022 bogus {unknown color name "bogus"}}
#  #      {-selectforeground #654321 #654321 bogus {unknown color name "bogus"}}
#  #XXX
#  foreach test { A } {
#      set name [lindex $test 0]
#      test listbox-23.$i {configuration options} {
#  	$_lb itemconfigure 0 $name [lindex $test 1]
#  	list [lindex [$_lb itemconfigure 0 $name] 4] [$_lb itemcget 0 $name]
#      } [list [lindex $test 2] [lindex $test 2]]
#      incr i
#      if {[lindex $test 3] != ""} {
#  	test listbox-1.$i {configuration options} {
#  	    list [catch {$_lb configure $name [lindex $test 3]} msg] $msg
#  	} [list 1 [lindex $test 4]]
#      }
#      $_lb configure $name [lindex [$_lb configure $name] 3]
#      incr i
#  }

#  # ListboxWidgetObjCmd, itemcget
#  test listbox-24.1 {itemcget} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      $_lb itemcget 0 -fg
#  } {}
#  test listbox-24.2 {itemcget} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      $_lb itemconfigure 0 -fg red
#      $_lb itemcget 0 -fg
#  } red
#  test listbox-24.3 {itemcget} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      catch {$_lb itemcget 0} result
#      set result
#  } {wrong # args: should be "$_lb itemcget index option"}
#  test listbox-24.3 {itemcget, itemcg shortcut} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c d
#      catch {$_lb itemcg 0} result
#      set result
#  } {wrong # args: should be "$_lb itemcget index option"}

#  # General item configuration issues
#  test listbox-25.1 {listbox item configurations and widget based deletions} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a
#      $_lb itemconfigure 0 -fg red
#      $_lb delete 0 end
#      $_lb insert end a
#      $_lb itemcget 0 -fg
#  } {}
#  test listbox-25.2 {listbox item configurations and widget based inserts} {
#      catch {destroy $_lb}
#      listbox $_lb
#      $_lb insert end a b c
#      $_lb itemconfigure 0 -fg red
#      $_lb insert 0 1 2 3 4
#      list [$_lb itemcget 0 -fg] [$_lb itemcget 4 -fg]
#  } [list {} red]

resetGridInfo();

sub record {
    push @log, join(" ", @_);
}

sub getsize {
    my $w = shift;
    my $geom = $w->geometry;
    $geom =~ /(\d+x\d+)/;
    $1;
}

sub resetGridInfo {
    # Some window managers, such as mwm, don't reset gridding information
    # unless the window is withdrawn and re-mapped.  If this procedure
    # isn't invoked, the window manager will stay in gridded mode, which
    # can cause all sorts of problems.  The "wm positionfrom" command is
    # needed so that the window manager doesn't ask the user to
    # manually position the window when it is re-mapped.
    $mw->withdraw;
    $mw->positionfrom('user');
    $mw->deiconify;
}

# Procedure that creates a second listbox for checking things related
# to partially visible lines.
sub mkPartial {
    eval {
	$partial_top->destroy
	    if Tk::Exists($partial_top);
    };
    $partial_top = $mw->Toplevel;
    $partial_top->geometry('+0+0');
    $partial_lb = $partial_top->Listbox(-width => 30, -height => 5);
    $partial_lb->pack('-expand',1,'-fill','both');
    $partial_lb->insert('end','one','two','three','four','five','six','seven',
			'eight','nine','ten','eleven','twelve','thirteen',
			'fourteen','fifteen');
    $partial_top->update;
    my $geom = $partial_top->geometry;
    my($width, $height) = $geom =~ /(\d+)x(\d+)/;
    $partial_top->geometry($width . "x" . ($height-3));
    $partial_top->update;
}

__END__

