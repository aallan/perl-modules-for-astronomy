#!/usr/local/bin/perl
#
# $Id: login.t,v 1.1 2003/07/18 00:23:04 aa Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use vars qw($Pwd $Uid);

BEGIN {print "1..3\n";}
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

my $dbh = DBI->connect("dbi:Sybase:server=$Srv", $Uid, $Pwd, {PrintError => 0});

$dbh and print "ok 2\n"
    or print "not ok 2\n";

$dbh->disconnect if $dbh;

$dbh = DBI->connect("dbi:Sybase:server=$Srv", 'ohmygod', 'xzyzzy', {PrintError => 0});

$dbh and print "not ok 3\n"
    or print "ok 3\n";

$dbh->disconnect if $dbh;

exit(0);
