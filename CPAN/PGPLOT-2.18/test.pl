#!/usr/local/bin/perl

use Config;

# Run and check all the tests

$| = 1; # Unbuffer STDOUT

# Stop f77-linking causing spurious undefined symbols (alpha)

$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 

if ($ENV{'PGPLOT_DEV'}) {
    $dev = $ENV{'PGPLOT_DEV'};
} else {
print "Default Device for plot tests [recommend /XSERVE] ? ";
$dev = <STDIN>; chomp $dev;
$dev = "/XSERVE" unless $dev=~/\w/;
}

$ENV{PGPLOT_XW_WIDTH}=0.3;

foreach $jjj (1..12) {

   print "============== Running test$jjj.p ==============\n";
   %@ = ();       # Clear error status
   do "test$jjj.p";
   warn $@ if $@; # Report any error detected
   sleep 2;
}

