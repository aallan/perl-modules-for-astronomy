#!/usr/local/bin/perl -w

# Simple test to just load the F77.pm module

use strict;
use vars qw/$loaded/;

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::F77;
$loaded = 1;
print "ok 1\n";
