#!/usr/local/bin/perl
#
# $Id: place.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

BEGIN {print "1..11\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
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


my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {PrintError => 0});

die "Unable for connect to $Srv: $DBI::errstr"
    unless $dbh;

if(!$dbh->{syb_dynamic_supported}) {
    print STDERR "?-style placeholders aren't supported with this SQL Server.\n";
    my $i;
    for($i = 2; $i <= 11; ++$i) {
	print "ok $i # skip\n";
    }
    $dbh->disconnect;
    exit(0);
}

my $rc;

$rc = $dbh->do("create table #t(string varchar(20), date datetime, val float, other_val numeric(9,3))");
$rc and print "ok 2\n"
    or print "not ok 2\n";

my $sth = $dbh->prepare("insert #t values(?, ?, ?, ?)");
$sth and print "ok 3\n"
    or print "not ok 3\n";

$rc = $sth->execute("test", "Jan 3 1998", 123.4, 222.3334);
$rc and print "ok 4\n"
    or print "not ok 4\n";

$rc = $sth->execute("other test", "Jan 25 1998", 4445123.4, 2);
$rc and print "ok 5\n"
    or print "not ok 5\n";

$rc = $sth->execute("test", "Feb 30 1998", 123.4, 222.3334);
$rc and print "not ok 6\n"
    or print "ok 6\n";

$sth = $dbh->prepare("select * from #t where date > ? and val > ?");
$sth and print "ok 7\n"
    or print "not ok 7\n";

$rc = $sth->execute('Jan 1 1998', 120);
$rc and print "ok 8\n"
    or print "not ok 8\n";
my $row;
my $count = 0;

while($row = $sth->fetch) {
    print "@$row\n";
    ++$count;
}

($count == 2) and print "ok 9\n"
    or print "not ok 9\n";

$rc = $sth->execute('Jan 1 1998', 140);
$rc and print "ok 10\n"
    or print "not ok 10\n";

$count = 0;

while($row = $sth->fetch) {
    print "@$row\n";
    ++$count;
}

($count == 1) and print "ok 11\n"
    or print "not ok 11\n";

if(0) {
    $dbh->do("create table #t2(id int, c varchar(10))");
    $dbh->do("
insert #t2 values(1, 'one')
insert #t2 values(2, 'two')
");
    $sth = $dbh->prepare("select id, c from #t2 where id = ?");
    $sth->execute(1);
    DBI->trace(3);
    $row = $sth->fetch;
    #$sth->finish;
    $sth->execute(2);
    $row = $sth->fetch;
    $sth->finish;
}
    
$dbh->disconnect;

exit(0);
