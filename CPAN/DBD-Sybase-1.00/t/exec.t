#!/usr/local/bin/perl
#
# $Id: exec.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

#use strict;

use vars qw($Pwd $Uid $Srv $loaded);

BEGIN {print "1..9\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI qw(:sql_types);
$loaded = 1;
print "ok 1\n";

#DBI->trace(3);

# Find the passwd file:
@dirs = ('./.', './..', './../..', './../../..');
foreach (@dirs)
{
    if(-f "$_/PWD")
    {
	open(PWD, "$_/PWD") || die "$_/PWD is not readable: $!\n";
	while(<PWD>)
	{
	    chop;
	    s/^\s*//;
	    next if(/^\#/ || /^\s*$/);
	    ($l, $r) = split(/=/);
	    $Uid = $r if($l eq UID);
	    $Pwd = $r if($l eq PWD);
	    $Srv = $r if($l eq SRV);
	}
	close(PWD);
	last;
    }
}
#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {PrintError=>1});
#exit;
$dbh and print "ok 2\n"
    or print "not ok 2\n";
my $sth = $dbh->prepare("exec sp_helpindex \@objname = ?");
$sth and print "ok 3\n"
    or print "not ok 3\n";

my $rc;

$rc = $sth->execute("sysusers");
#$rc = $sth->execute();
$rc != -2 and print "ok 4\n"
    or print "not ok 4\n";
do {
    while(my $d = $sth->fetch) {
#	print "@$d\n";
    }
} while($sth->{syb_more_results});

$dbh->do("use tempdb");
$dbh->do("set arithabort off");
#$dbh->do("drop proc dbitest");
$dbh->do(qq{
create proc dbitest \@one varchar(20), \@two int, \@three numeric(5,2), \@four smalldatetime, \@five float output
as
    select \@one, \@two, \@three, \@four
});

print "ok 5\n";

$sth = $dbh->prepare("exec dbitest \@one = ?, \@two = ?, \@three = ?, \@four = ?, \@five = ? output");
#$rc = $sth->execute("one", 2, 3.2, "jan 1 2001", 5.4);
$sth->bind_param(1, "one");
$sth->bind_param(2, 2, SQL_INTEGER);
$sth->bind_param(3, 3.2, SQL_DECIMAL);
$sth->bind_param(4, "jan 1 2001");
$sth->bind_param(5, 5.4, SQL_FLOAT);
$rc = $sth->execute();
$rc != -2 and print "ok 6\n"
    or print "not ok 6\n";
do {
    while(my $d = $sth->fetch) {
	print "@$d\n";
    }
} while($sth->{syb_more_results});

$rc = $sth->execute("one", 25, 333.2, "jan 1 2001", 5.4);
$rc != -2 and print "ok 7\n"
    or print "not ok 7\n";
do {
    while(my $d = $sth->fetch) {
	print "@$d\n";
    }
} while($sth->{syb_more_results});


$rc = $sth->execute(undef, 25, 3.2234, "jan 3 2001", 5.4);
$rc != -2 and print "ok 8\n"
    or print "not ok 8\n";
my @out = $sth->func('syb_output_params');
$out[0] == 5.4 and print "ok 9\n"
    or print "not ok 9\n";
#print "@out\n";
#do {
#    local $^W = 0;
#    while(my $d = $sth->fetch) {
#	print "@$d\n";
#    }
#} while($sth->{syb_more_results});

$dbh->do("drop proc dbitest");
