#!/usr/local/bin/perl
#
# $Id: xblob.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

#use strict;

use vars qw($Pwd $Uid $Srv $loaded);

BEGIN {print "1..6\n";}
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
my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=tempdb", $Uid, $Pwd, {PrintError=>1});
#exit;
$dbh and print "ok 2\n"
    or print "not ok 2\n";

my $rc = $dbh->do("create table blob_test(id int, data image null, foo varchar(30))");
$rc and print "ok 3\n"
    or print "not ok 3\n";

open(IN, "t/screen.jpg") || die "Can't open t/screen.jpg: $!";
my $image = join('', <IN>);
close(IN);
my $heximg = unpack('H*', $image);
$rc = $dbh->do("insert blob_test(id, data, foo) values(1, '', 'screen.jpg')");
$rc and print "ok 4\n"
    or print "not ok 4\n";

#DBI->trace(3);
my $sth = $dbh->prepare("select id, data from blob_test");
#$sth->{syb_no_bind_blob} = 1;
$sth->execute;
while($sth->fetch) {
#    my $d;
#    $sth->func(2, \$d, 0, 'ct_get_data');
    
    $sth->func('CS_GET', 2, 'ct_data_info') || print $sth->errstr, "\n";
}
$sth->func('ct_prepare_send') || print $sth->errstr, "\n";
$sth->func('CS_SET', 2, {total_txtlen => length($image)}, 'ct_data_info') || print $sth->errstr, "\n";
$sth->func($image, length($image), 'ct_send_data') || print $sth->errstr, "\n";
$sth->func('ct_finish_send') || print $sth->errstr, "\n";

#$dbh->{LongReadLen} = 100000;
$sth = $dbh->prepare("select id, data from blob_test");
$dbh->{LongReadLen} = 100000;
#DBI->trace(3);
$sth->{syb_no_bind_blob} = 1;
$sth->execute;
my $heximg2 = '';
my $size = 0;
while(my $d = $sth->fetch) {
    my $data;
#    open(OUT, ">/tmp/mp_conf.jpg") || die "Can't open /tmp/mp_conf.jpg: $!";
    while(1) {
	my $read = $sth->func(2, \$data, 1024, 'ct_get_data');
	$heximg2 .= unpack('H*', $data);
	$size += $read;
	last unless $read == 1024;
#	print OUT $data;
    }
#    close(OUT);
}

#warn "Got $size bytes\n";

$heximg eq $heximg2 and print "ok 5\n"
    or print "not ok 5\n";

$rc = $dbh->do("drop table blob_test");

$rc and print "ok 6\n"
    or print "not ok 6\n";
