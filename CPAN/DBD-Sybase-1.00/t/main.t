#!/usr/local/bin/perl
#
# $Id: main.t,v 1.1 2003/07/18 00:23:04 aa Exp $

# Base DBD Driver Test

use lib 'blib/lib';
use lib 'blib/arch';

BEGIN {print "1..16\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
$loaded = 1;
print "ok 1\n";

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

my($switch) = DBI->internal;
#DBI->trace(2); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

print "Available Drivers: ",join(", ",DBI->available_drivers()),"\n";

my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {PrintError => 0});

die "Unable for connect to $Srv: $DBI::errstr"
    unless $dbh;

my $rc;

($rc = $dbh->do("use master"))
    and print "ok 2\n"
    or print "not ok 2\n";

my $sth;

($sth = $dbh->prepare("select * from sysusers"))
    and print "ok 3\n"
    or print "not ok 3\n";
if($sth->execute) {
    print "ok 4\n";
    print "Fields: $sth->{NUM_OF_FIELDS}\n";
    print "Names: @{$sth->{NAME}}\n";
    print "Null:  @{$sth->{NULLABLE}}\n";
    my $rows = 0;
    while(@dat = $sth->fetchrow) {
	++$rows;
	foreach (@dat) {
	    $_ = '' unless defined $_;
	}
	print "@dat\n";
    }
    ($rows == $sth->rows)
	and print "ok 5\n"
	    or print "not ok 5\n";
#    $sth->finish;
}
else {
    print STDERR ($DBI::err, ":\n", $sth->errstr);
    print "not ok 4\nnot ok 5\n";
}
undef $sth;
($sth = $dbh->prepare("select * from sys_users"))
    and print "ok 6\n"
    or print "not ok 6\n";
if($sth->execute) {
    print "not ok 7\n";		# SHOULD FAIL!!!

    while(@dat = $sth->fetchrow) {
	print "@dat\n";
    }
#    $sth->finish;
}
else {
    print "ok 7\n";
    ($DBI::err == 208)
	and print "ok 8\n"
	    or print "not ok 8\n";
#    print STDERR ($DBI::err, ":\n", $sth->errstr);
}
($sth = $dbh->prepare("select * from sysusers"))
    and print "ok 9\n"
    or print "not ok 9\n";
if($sth->execute) {
    print "ok 10\n";
    my @fields = @{$sth->{NAME}};
    my $rows = 0;
    my $d;
    my $ok = 1;
    while($d = $sth->fetchrow_hashref) {
	++$rows;
	foreach (@fields) {
	    if(!exists($d->{$_})) {
		$ok = 0;
	    }
	    my $t = $d->{$_} || '';
	    print "$t ";
	}
	print "\n";
    }
    $ok and print "ok 11\n"
	or print "not ok 11\n";
    ($rows == $sth->rows)
	and print "ok 12\n"
	    or print "not ok 12\n";
#    $sth->finish;
}
else {
    print STDERR ($DBI::err, ":\n", $sth->errstr);
    print "not ok 10\nnot ok 11\nnot ok 12";
}

undef $sth;

$dbh->{LongReadLen} = 32000;

$dbh->{syb_quoted_identifier} = 1;

($rc = $dbh->do('create table #tmp("TR Number" int, "Answer Code" char(2))'))
    and print "ok 13\n"
    or print "not ok 13\n";

($rc = $dbh->do(qq(insert #tmp ("TR Number", "Answer Code") values(123, 'B'))))
    and print "ok 14\n"
    or print "not ok 14\n";

$dbh->{syb_quoted_identifier} = 0;

# Test multiple result sets, varying column names
$sth = $dbh->prepare("
select uid, name from sysusers where uid = -2
select spid, kpid from master..sysprocesses where spid = \@\@spid
");
($rc = $sth->execute) 
    and print "ok 15\n"
    or print "not ok 15\n";

$result_set = 0;
do {
    while($row = $sth->fetchrow_hashref) {
	if($result_set == 1) {
	    if(!$row->{spid}) {
		print "not ok 16\n";
	    } else {
		print "ok 16\n";
	    }
	}
    }
    ++$result_set;
} while($sth->{syb_more_results});


$dbh->disconnect;


