#!/usr/local/bin/perl
#
# $Id: nsql.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use vars qw($Pwd $Uid $Srv);

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
#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {syb_deadlock_retry=>10, syb_deadlock_verbose=>1});
#exit;
$dbh and print "ok 2\n"
    or print "not ok 2\n";

my @d = $dbh->func("select * from sysusers", 'ARRAY', 'nsql');
foreach (@d) {
    local $^W = 0;
    print "@$_\n";
}
print "ok 3\n";


sub cb {
    my @data = @_;
    local $^W = 0;
    print "@data\n";

    1;
}
@d = $dbh->func("select * from sysusers", 'ARRAY', \&cb, 'nsql');
foreach (@d) {
    print "@$_\n";
}
print "ok 4\n";
