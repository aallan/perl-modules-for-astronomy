#!/usr/local/bin/perl
#
# $Id: autocommit.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use vars qw($Pwd $Uid);

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
$loaded = 1;
print "ok 1\n";

#DBI->trace(2);

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

my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {PrintError => 0});

$dbh and print "ok 2\n"
    or print "not ok 2\n";

$dbh->do("create table #ttt (foo varchar(20), bar int)");
$dbh->{AutoCommit} = 0;

$dbh->do("insert #ttt values('a string', 1)");
$dbh->do("insert #ttt values('another string', 2)");
$dbh->do("insert #ttt values('foodiboo', 3)");
$dbh->do("insert #ttt values('a string', 4)");
$dbh->rollback;
my $sth = $dbh->prepare("select * from #ttt");
$sth->execute;
my $found = 0;
while(my $d = $sth->fetch) {
    print "@$d\n";
    ++$found;
}
$found && print "not ok 3\n" or print "ok 3\n";

$dbh->do("insert #ttt values('a string', 1)");
$dbh->do("insert #ttt values('another string', 2)");
$dbh->do("insert #ttt values('foodiboo', 3)");
$dbh->do("insert #ttt values('a string', 4)");
$dbh->commit;

$sth = $dbh->prepare("select * from #ttt");
$sth->execute;
$found = 0;
while(my $d = $sth->fetch) {
    print "@$d\n";
    ++$found;
}
$found == 4 && print "ok 4\n" or print "not ok 4\n";

$dbh->disconnect;


