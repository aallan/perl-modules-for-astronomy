#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: browseentry-grabtest.t,v 1.1 2003/09/28 14:55:02 aa Exp $
# Author: Slaven Rezic
#

# test whether grabs are correctly saved

use strict;

use Tk;
use Tk::BrowseEntry;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $mw = tkinit;
my $t = $mw->Toplevel;

$mw->Label(-text => "disabled")->pack;
$mw->Entry->pack;

$t->BrowseEntry->pack;
$t->Button(-text => "OK",
	   -command => sub { $mw->destroy })->pack;
$t->grab;

if ($ENV{BATCH}) {
    $mw->after(500,sub{$mw->destroy});
}

MainLoop;

ok(1);

__END__
