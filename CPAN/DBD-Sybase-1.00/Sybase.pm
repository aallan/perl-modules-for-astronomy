# -*-Perl-*-
# $Id: Sybase.pm,v 1.1 2003/07/18 00:23:04 aa Exp $

# Copyright (c) 1996-2003   Michael Peppler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
# Based on DBD::Oracle Copyright (c) 1994,1995,1996,1997 Tim Bunce

{
    package DBD::Sybase;

    use DBI ();
    use DynaLoader ();
    use Exporter ();

    use Sys::Hostname ();

    @ISA = qw(DynaLoader Exporter);

    @EXPORT = qw(CS_ROW_RESULT CS_CURSOR_RESULT CS_PARAM_RESULT
		 CS_STATUS_RESULT CS_MSG_RESULT CS_COMPUTE_RESULT);


    $hostname = Sys::Hostname::hostname();
    $VERSION = '1.00';
    my $Revision = substr(q$Revision: 1.1 $, 10);

    require_version DBI 1.02;

    bootstrap DBD::Sybase $VERSION;


    $drh = undef;	# holds driver handle once initialised
    $err = 0;		# The $DBI::err value
    $errstr = '';
    $sqlstate = "00000";

 if(0) {
    my %syb_api = (
	'nsql' => ['db', { U =>[2,0,'$statement [, $type [, $callback ] ]'] } ],
			);
    foreach my $method (keys %syb_api){
	DBI->_install_method("DBI::$syb_api{$method}->[0]::$method", 
			     'Sybase.pm',
			     $syb_api{$method}->[1]);
    }
}

    sub driver {
	return $drh if $drh;
	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, {
	    'Name' => 'Sybase',
	    'Version' => $VERSION,
	    'Err'     => \$DBD::Sybase::err,
	    'Errstr'  => \$DBD::Sybase::errstr,
	    'State'   => \$DBD::Sybase::sqlstate,
	    'Attribution' => 'Sybase DBD by Michael Peppler',
	    });
	$drh;
    }


    1;
}


{   package DBD::Sybase::dr; # ====== DRIVER ======
    use strict;

    sub connect { 
        my($drh, $dbase, $user, $auth, $attr)= @_;
	my $ifile = '';
	my $server = $dbase || $ENV{DSQUERY} || 'SYBASE';


        my($this) = DBI::_new_dbh($drh, {
	    'Name' => $server,
	    'User' => $user,	
	    'CURRENT_USER' => $user,
	    });

	DBD::Sybase::db::_login($this, $server, $user, $auth, $attr) or return undef;

	$this;
    }

    sub data_sources {
	my @s;
	if ($^O eq 'MSWin32') {
	    open(INTERFACES, "$ENV{SYBASE}/ini/sql.ini") or return;
	    @s = map { /\[(\S+)\]/i; "dbi:Sybase:server=$1" } grep /\[/i, <INTERFACES>;
	    close(INTERFACES);
	} else {
	    open(INTERFACES, "$ENV{SYBASE}/interfaces") or return;
	    @s = map { /^(\S+)/i; "dbi:Sybase:server=$1" } grep /^[^\s\#]/i, <INTERFACES>;
	    close(INTERFACES);
	}

	return @s;
    }
}


{   package DBD::Sybase::db; # ====== DATABASE ======
    use strict;

    use DBI qw(:sql_types);
    use Carp;
    
    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });


	DBD::Sybase::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub tables {
	my $dbh = shift;

	my $sth = $dbh->prepare("select name from sysobjects where type in ('V', 'U')");
	$sth->execute;
	my @names;
	my $dat;
	while($dat = $sth->fetch) {
	    push(@names, $dat->[0]);
	}
	@names;
    }

# NOTE - RaiseError & PrintError is turned off while we are inside this
# function, so we must check for any error, and return immediately if
# any error is found.
# XXX add optional deadlock detection?
    sub do {
	my($dbh, $statement, $attr, @params) = @_;

	my $sth = $dbh->prepare($statement, $attr) or return undef;
	$sth->execute(@params) or return undef;
	return undef if $sth->err;
	my $rows = $sth->rows;
	if(defined($sth->{syb_more_results})) {
	    do {
		while(my $dat = $sth->fetch) {
		    return undef if $sth->err;
		    # XXX do something intelligent here...
		}
	    } while($sth->{syb_more_results});
	}

	($rows == 0) ? "0E0" : $rows;
    }

    sub table_info {
	my $dbh = shift;
	my $catalog = $dbh->quote(shift);
	my $schema  = $dbh->quote(shift);
	my $table   = $dbh->quote(shift);
	my $type    = $dbh->quote(shift);

	my $sth = $dbh->prepare("sp_tables $table, $schema, $catalog, $type");
# Another possibility would be:
#           select TABLE_QUALIFIER = NULL
#                , TABLE_OWNER     = u.name
#                , TABLE_NAME      = o.name
#                , TABLE_TYPE      = o.type  -- XXX
#                , REMARKS         = NULL
#             from sysobjects o
#                , sysusers   u
#            where o.type in ('U', 'V', 'S')
#              and o.uid = u.uid

	$sth->execute;
	$sth;
    }

{

    my $names = [qw(TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE
		    TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS
		    NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF SQL_DATA_TYPE
		    SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION
		    IS_NULLABLE
		    )];

    # Technique of using DBD::Sponge borrowed from DBD::mysql...
    sub column_info {
	my $dbh = shift;
	my $catalog = $dbh->quote(shift);
	my $schema  = $dbh->quote(shift);
	my $table   = $dbh->quote(shift);
	my $column  = $dbh->quote(shift);
	

	my $sth = $dbh->prepare("sp_columns $table, $schema, $catalog, $column");
	return undef unless $sth;

	if(!$sth->execute()) {
	    return DBI::set_err($dbh, $sth->err(), $sth->errstr());
	}
	my @cols;
	while(my $d = $sth->fetchrow_arrayref()) {
	    push(@cols, [@$d[0..11], @$d[14..19]]);
	}
	my $dbh2;
	if (!($dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'})) {
	    $dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'} =
		DBI->connect("DBI:Sponge:");
	    if (!$dbh2) {
	        DBI::set_err($dbh, 1, $DBI::errstr);
		return undef;
	    }
	}
	my $sth2 = $dbh2->prepare("SHOW COLUMNS", { 'rows' => \@cols,
						   'NAME' => $names,
						   'NUM_OF_FIELDS' => scalar(@$names) });
	if (!$sth2) {
	    DBI::set_err($sth2, $dbh2->err(), $dbh2->errstr());
	}
	$sth2->execute;
	$sth2;
    }
}

    sub primary_key_info {
	my $dbh = shift;
	my $catalog = $dbh->quote(shift);     # == database in Sybase terms
	my $schema = $dbh->quote(shift);      # == owner in Sybase terms
	my $table = $dbh->quote(shift);

	my $sth = $dbh->prepare("sp_pkeys $table, $schema, $catalog");

	$sth->execute;
	$sth;
    }

    sub ping {
	my $dbh = shift;
	return 0 if DBD::Sybase::db::_isdead($dbh);

	# Use "select 1" suggested by Henri Asseily.
	my $sth = $dbh->prepare("select 1");

	return 0 if !$sth;

	my $rc = $sth->execute;
	
	return 0 if(!defined($rc) && DBD::Sybase::db::_isdead($dbh));

	$sth->finish;
	return 1;
    }

    sub type_info_all {
	my ($dbh) = @_;

# Calling sp_datatype_info returns the appropriate data for the server that
# we are currently connected to.
# In general the data is static, so it's not really necessary, but ASE 12.5
# introduces some changes, in particular char/varchar max lenghts of 2048...
#	my $sth = $dbh->prepare("sp_datatype_info");
	my $data;
#	if($sth->execute) {
#	    $data = $sth->fetchall_arrayref;
#	} else {
	    $data = [
       ['bit',-7,1,undef,undef,undef,'0','0',2,undef,'0',undef,'bit',undef,undef,undef,undef,undef,undef],
       ['tinyint',-6,3,undef,undef,undef,1,'0',2,1,'0','0','tinyint',undef,undef,undef,undef,undef,undef],
       ['image',-4,'2147483647','0x',undef,undef,1,'0',1,undef,'0',undef,'image',undef,undef,undef,undef,undef,undef],
       ['timestamp',-3,8,'0x',undef,undef,1,'0',2,undef,'0',undef,'timestamp',undef,undef,undef,undef,undef,undef],
       ['varbinary',-3,255,'0x',undef,'maxlength',1,'0',2,undef,'0',undef,'varbinary',undef,undef,undef,undef,undef,undef],
       ['binary',-2,255,'0x',undef,'length',1,'0',2,undef,'0',undef,'binary',undef,undef,undef,undef,undef,undef],
       ['text',-1,'2147483647','\'','\'',undef,1,1,1,undef,'0',undef,'text',undef,undef,undef,undef,undef,undef],
       ['char',1,255,'\'','\'','length',1,1,3,undef,'0',undef,'char',undef,undef,undef,undef,undef,undef],
       ['nchar',1,255,'\'','\'',undef,1,1,3,undef,'0',undef,'nchar',undef,undef,undef,undef,undef,undef],
       ['numeric',2,38,undef,undef,'precision,scale',1,'0',2,'0','0','0','numeric','0',38,undef,undef,undef,undef],
       ['decimal',3,38,undef,undef,'precision,scale',1,'0',2,'0','0','0','decimal','0',38,undef,undef,undef,undef],
       ['money',3,19,'\$',undef,undef,1,'0',2,'0',1,'0','money',undef,undef,undef,undef,undef,undef],
       ['smallmoney',3,10,'\$',undef,undef,1,'0',2,'0',1,'0','smallmoney',undef,undef,undef,undef,undef,undef],
       ['int',4,10,undef,undef,undef,1,'0',2,'0','0','0','int',undef,undef,undef,undef,undef,undef],
       ['smallint',5,5,undef,undef,undef,1,'0',2,'0','0','0','smallint',undef,undef,undef,undef,undef,undef],
       ['float',6,15,undef,undef,undef,1,'0',2,'0','0','0','float',undef,undef,undef,undef,10,undef],
       ['real',7,7,undef,undef,undef,1,'0',2,'0','0','0','real',undef,undef,undef,undef,10,undef],
       ['datetime',11,23,'\'','\'',undef,1,'0',3,undef,'0',undef,'datetime',undef,undef,93,undef,undef,undef],
       ['smalldatetime',11,16,'\'','\'',undef,1,'0',3,undef,'0',undef,'smalldatetime',undef,undef,93,undef,undef,undef],
       ['nvarchar',12,255,'\'','\'',undef,1,1,3,undef,'0',undef,'nvarchar',undef,undef,undef,undef,undef,undef],
       ['sysname',12,30,'\'','\'','maxlength',1,1,3,undef,'0',undef,'sysname',undef,undef,undef,undef,undef,undef],
       ['varchar',12,255,'\'','\'','maxlength',1,1,3,undef,'0',undef,'varchar',undef,undef,undef,undef,undef,undef]
		    ];
#	}
	my $ti = 
	[     {   TYPE_NAME         => 0,
		  DATA_TYPE         => 1,
		  PRECISION         => 2,
		  LITERAL_PREFIX    => 3,
		  LITERAL_SUFFIX    => 4,
		  CREATE_PARAMS     => 5,
		  NULLABLE          => 6,
		  CASE_SENSITIVE    => 7,
		  SEARCHABLE        => 8,
		  UNSIGNED_ATTRIBUTE=> 9,
		  MONEY             => 10,
		  AUTO_INCREMENT    => 11,
		  LOCAL_TYPE_NAME   => 12,
		  MINIMUM_SCALE     => 13,
		  MAXIMUM_SCALE     => 14,
		  sql_data_type     => 15,
		  sql_datetime_sub  => 16,
		  num_prec_radix    => 17,
		  interval_precision => 18,
	      },
	];
#	foreach (@$data) {
#	    push(@$ti, $_);
#	}
	push(@$ti, @$data);

	return $ti;
    }

    # First straight port of DBlib::nsql.
    # mpeppler, 2/19/01
    # This version can't handle ? placeholders
    sub nsql {
	my ($dbh,$sql,$type,$callback) = @_;
	my (@res,$data);
	my $retrycount = $dbh->FETCH('syb_deadlock_retry');
	my $retrysleep = $dbh->FETCH('syb_deadlock_sleep') || 60;
	my $retryverbose = $dbh->FETCH('syb_deadlock_verbose');

#	warn "retrycount = $retrycount, retrysleep = $retrysleep, verbose = $retryverbose\n";

	if ( ref $type ) {
	    $type = ref $type;
	}
	elsif ( not defined $type ) {
	    $type = "";
	}
	
#	undef $DB_ERROR;
	my $sth = $dbh->prepare($sql);
	return unless $sth;

	my $raiserror = $dbh->FETCH('RaiseError');

#	warn "raiserror = $raiserror";
	my $errstr;
	my $err;

	# Rats - RaiseError doesn't seem to work inside of this routine.
	# So we fake it with lots of die() statements.
#	$sth->{RaiseError} = 1;

#	DBI->trace(3);
	
    DEADLOCK: 
        {	
	    # Use RaiseError technique to throw a fatal error if anything goes
	    # wrong in the execute or fetch phase.
	    eval { 
		$sth->execute || die $sth->errstr; 
#		$sth->execute;
		do {
		    if ( $type eq "HASH" ) {
			while ( $data = $sth->fetchrow_hashref ) {
			    die $sth->errstr if($sth->err);
			    if ( ref $callback eq "CODE" ) {
				unless ( $callback->(%$data) ) {
				    return;
				} 
			    }
			    else {
				push(@res,{%$data});
			    }
			}
		    }
		    elsif ( $type eq "ARRAY" ) {
			while ( $data = $sth->fetchrow_arrayref ) {
			    die $sth->errstr if($sth->err);
			    if ( ref $callback eq "CODE" ) {
				unless ( $callback->(@$data) ) {
				    return;
				} 
			    }
			    else {
				push(@res,( @$data == 1 ? $$data[0] : [@$data] ));
			    }
			}
		    }
		    else {
			# If you ask for nothing, you get nothing.  But suck out
			# the data just in case.
			while ( $data = $sth->fetch ) { 1; }
			$res[0]++;	# Return non-null (true)
		    }
		    
		    die $sth->errstr if($sth->err);
		    
		} while($sth->{'syb_more_results'});
	    };
	    # If $@ is set then something failed in the eval{} call above.
	    if($@) {
		$errstr = $@;
		$err = $sth->err || $dbh->err;
#		warn "in eval check: $errstr, $err";
		if ( $dbh->FETCH('syb_deadlock_retry') && $err == 1205 ) {
		    if ( $retrycount < 0 || $retrycount-- ) {
			carp "SQL deadlock encountered.  Retrying...\n" if $retryverbose;
			sleep($retrysleep);
			redo DEADLOCK;
		    }
		    else {
			carp "SQL deadlock retry failed ", $dbh->FETCH('syb_deadlock_retry'), " times.  Aborting.\n"
			    if $retryverbose;
			last DEADLOCK;
		    }
		}
		
		last DEADLOCK;
	    }
	}
	#
	# If we picked any sort of error, then don't feed the data back.
	#
#	warn "err = $err, raiserror = $raiserror, errstr = $errstr";
	if ( $err ) {
	    if($raiserror) {
		croak($errstr);
	    }
	    return;
	}
	elsif ( ref $callback eq "CODE" ) {
	    return 1;
	}
	else {
	    return @res;
	}
    }
}


{   package DBD::Sybase::st; # ====== STATEMENT ======
    use strict;

    sub syb_output_params {
	my ($sth) = @_;

	my @results;
	my $status;

	do {
	    while(my $d = $sth->fetch) {
		# The tie() doesn't work here, so call the FETCH method
		# directly....
		if($sth->FETCH('syb_result_type') == 4042) {
		    push(@results, @$d);
		} elsif($sth->FETCH('syb_result_type') == 4043) {
		   $status = $d->[0];
	       }
	    }
	} while($sth->FETCH('syb_more_results'));

	# XXX What to do if $status != 0???
	
	@results;
    }

    sub exec_proc {
	my ($sth) = @_;

	my @results;
	my $status;

	$sth->execute || return undef;

	do {
	    while(my $d = $sth->fetch) {
		# The tie() doesn't work here, so call the FETCH method
		# directly....
		if($sth->FETCH('syb_result_type') == 4043) {
		   $status = $d->[0];
	       }
	    }
	} while($sth->FETCH('syb_more_results'));

	# XXX What to do if $status != 0???
	
	$status;
    }
	
		    
}

1;

__END__

=head1 NAME

DBD::Sybase - Sybase database driver for the DBI module

=head1 SYNOPSIS

    use DBI;

    $dbh = DBI->connect("dbi:Sybase:", $user, $passwd);

    # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::Sybase is a Perl module which works with the DBI module to provide
access to Sybase databases.

=head1 Connecting to Sybase

=head2 The interfaces file

The DBD::Sybase module is built on top of the Sybase I<Open Client Client 
Library> API. This library makes use of the Sybase I<interfaces> file
(I<sql.ini> on Win32 machines) to make a link between a logical
server name (e.g. SYBASE) and the physical machine / port number that
the server is running on. The OpenClient library uses the environment
variable B<SYBASE> to find the location of the I<interfaces> file,
as well as other files that it needs (such as locale files). The B<SYBASE>
environment is the path to the Sybase installation (eg '/usr/local/sybase').
If you need to set it in your scripts, then you I<must> set it in a
C<BEGIN{}> block:

   BEGIN {
       $ENV{SYBASE} = '/opt/sybase/11.0.2';
   }

   $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);


=head2 Specifying the server name

The server that DBD::Sybase connects to defaults to I<SYBASE>, but
can be specified in two ways.

You can set the I<DSQUERY> environement variable:

    $ENV{DSQUERY} = "ENGINEERING";
    $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);

Or you can pass the server name in the first argument to connect():

    $dbh = DBI->connect("dbi:Sybase:server=ENGINEERING", $user, $passwd);

=head2 Specifying other connection specific parameters

It is sometimes necessary (or beneficial) to specify other connection
properties. Currently the following are supported:

=over 4

=item server

Specify the server that we should connect to

     $dbh = DBI->connect("dbi:Sybase:server=BILLING",
			 $user, $passwd);

The default server is I<SYBASE>, or the value of the I<$DSQUERY> environment
variable, if it is set.

=item database

Specify the database that should be made the default database.

     $dbh = DBI->connect("dbi:Sybase:database=sybsystemprocs",
			 $user, $passwd);

This is equivalent to 

    $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);
    $dbh->do("use sybsystemprocs");


=item charset

Specify the character set that the client uses.

     $dbh = DBI->connect("dbi:Sybase:charset=iso_1",
			 $user, $passwd);

=item language

Specify the language that the client uses.

     $dbh = DBI->connect("dbi:Sybase:language=us_english",
			 $user, $passwd);

Note that the language has to have been installed on the server (via
langinstall or sp_addlanguage) for this to work. If the language is not
installed the session will default to the default language of the 
server.

=item packetSize

Specify the network packet size that the connection should use. Using a
larger packet size can increase performance for certain types of queries.
See the Sybase documentation on how to enable this feature on the server.

     $dbh = DBI->connect("dbi:Sybase:packetSize=8192",
			 $user, $passwd);

=item interfaces

Specify the location of an alternate I<interfaces> file:

     $dbh = DBI->connect("dbi:Sybase:interfaces=/usr/local/sybase/interfaces",
			 $user, $passwd);

=item loginTimeout

Specify the number of seconds that DBI->connect() will wait for a 
response from the Sybase server. If the server fails to respond before the
specified number of seconds the DBI->connect() call fails with a timeout
error. The default value is 60 seconds, which is usually enough, but on a busy
server it is sometimes necessary to increase this value:

     $dbh = DBI->connect("dbi:Sybase:loginTimeout=240", # wait up to 4 minutes
			 $user, $passwd);


=item timeout

Specify the number of seconds after which any Open Client calls will timeout
the connection and mark it as dead. Once a timeout error has been received
on a connection it should be closed and re-opened for further processing.

Setting this value to 0 or a negative number will result in an unlimited
timeout value. See also the Open Client documentation on CS_TIMEOUT.

     $dbh = DBI->connect("dbi:Sybase:timeout=240", # wait up to 4 minutes
			 $user, $passwd);

=item scriptName

Specify the name for this connection that will be displayed in sp_who
(ie in the sysprocesses table in the I<program_name> column).

    $dbh->DBI->connect("dbi:Sybase:scriptName=myScript", $user, $password);

=item hostname

Specify the hostname that will be displayed by sp_who (and will be stored
in the hostname column of sysprocesses)..

    $dbh->DBI->connect("dbi:Sybase:hostname=kiruna", $user, $password);

=item tdsLevel

Specify the TDS protocol level to use when connecting to the server.
Valid values are CS_TDS_40, CS_TDS_42, CS_TDS_46, CS_TDS_495 and CS_TDS_50.
In general this is automatically negotiated between the client and the 
server, but in certain cases this may need to be forced to a lower level
by the client. 

    $dbh->DBI->connect("dbi:Sybase:tdsLevel=CS_TDS_42", $user, $password);

B<NOTE>: Setting the tdsLevel below CS_TDS_495 will disable a number of
features, ?-style placeholders and CHAINED non-AutoCommit mode, in particular.

=item encryptPassword

Specify the use of the client password encryption supported by CT-Lib.
Specify a value of 1 to use encrypted passwords.

    $dbh->DBI->connect("dbi:Sybase:encryptPassword=1", $user, $password);

=back

These different parameters (as well as the server name) can be strung
together by separating each entry with a semi-colon:

    $dbh = DBI->connect("dbi:Sybase:server=ENGINEERING;packetSize=8192;language=us_english;charset=iso_1",
			$user, $pwd);


=head1 Handling Multiple Result Sets

Sybase's Transact SQL has the ability to return multiple result sets
from a single SQL statement. For example the query:

    select b.title, b.author, s.amount
      from books b, sales s
     where s.authorID = b.authorID
     order by b.author, b.title
    compute sum(s.amount) by b.author

which lists sales by author and title and also computes the total sales
by author returns two types of rows. The DBI spec doesn't really 
handle this situation, nor the more hairy

    exec my_proc @p1='this', @p2='that', @p3 out

where C<my_proc> could return any number of result sets (ie it could
perform an unknown number of C<select> statements.

I've decided to handle this by returning an empty row at the end
of each result set, and by setting a special Sybase attribute in $sth
which you can check to see if there is more data to be fetched. The 
attribute is B<syb_more_results> which you should check to see if you
need to re-start the C<fetch()> loop.

To make sure all results are fetched, the basic C<fetch> loop can be 
written like this:

     do {
         while($d = $sth->fetch) {
            ... do something with the data
         }
     } while($sth->{syb_more_results});

You can get the type of the current result set with 
$sth->{syb_result_type}. This returns a numerical value, as defined in 
$SYBASE/include/cspublic.h:

	#define CS_ROW_RESULT		(CS_INT)4040
	#define CS_CURSOR_RESULT	(CS_INT)4041
	#define CS_PARAM_RESULT		(CS_INT)4042
	#define CS_STATUS_RESULT	(CS_INT)4043
	#define CS_MSG_RESULT		(CS_INT)4044
	#define CS_COMPUTE_RESULT	(CS_INT)4045

In particular, the return status of a stored procedure is returned
as CS_STATUS_RESULT (4043), and is normally the last result set that is 
returned in a stored proc execution.

If you add a 

    use DBD::Sybase;

to your script then you can use the symbolic values (CS_xxx_RESULT) 
instead of the numeric values in your programs, which should make them 
easier to read.

See also the C<syb_output_param> func() call to handle stored procedures 
that B<only> return B<OUTPUT> parameters.

=head1 $sth->execute() failure mode behavior

B<THIS HAS CHANGED IN VERSION 0.21!>

DBD::Sybase has the ability to handle multi-statement SQL commands
in a single batch. For example, you could insert several rows in 
a single batch like this:

   $sth = $dbh->prepare("
   insert foo(one, two, three) values(1, 2, 3)
   insert foo(one, two, three) values(4, 5, 6)
   insert foo(one, two, three) values(10, 11, 12)
   insert foo(one, two, three) values(11, 12, 13)
   ");
   $sth->execute;

If anyone of the above inserts fails for any reason then $sth->execute
will return C<undef>, B<HOWEVER> the inserts that didn't fail will still
be in the database, unless C<AutoCommit> is off.

It's also possible to write a statement like this:

   $sth = $dbh->prepare("
   insert foo(one, two, three) values(1, 2, 3)
   select * from bar
   insert foo(one, two, three) values(10, 11, 12)
   ");
   $sth->execute;

If the second C<insert> is the one that fails, then $sth->execute will
B<NOT> return C<undef>. The error will get flagged after the rows
from C<bar> have been fetched.

I know that this is not as intuitive as it could be, but I am
constrained by the Sybase API here.

As an aside, I know that the example above doesn't really make sense, 
but I need to illustrate this particular sequence... You can also see the 
t/fail.t test script which shows this particular behavior.

=head1 Sybase Specific Attributes

There are a number of handle  attributes that are specific to this driver.
These attributes all start with B<syb_> so as to not clash with any
normal DBI attributes.

=head2 Database Handle Attributes

The following Sybase specific attributes can be set at the Database handle
level:

=over 4

=item syb_show_sql (bool)

If set then the current statement is included in the string returned by 
$dbh->errstr.

=item syb_show_eed (bool)

If set, then extended error information is included in the string returned 
by $dbh->errstr. Extended error information include the index causing a
duplicate insert to fail, for example.

=item syb_err_handler (subroutine ref)

This attribute is used to set an ad-hoc error handler callback (ie a
perl subroutine) that gets called before the normal error handler does
it's job.  If this subroutine returns 0 then the error is
ignored. This is useful for handling PRINT statements in Transact-SQL,
for handling messages from the Backup Server, showplan output, dbcc
output, etc.
 
The subroutine is called with nine parameters:
 
  o the Sybase error number
  o the severity
  o the state
  o the line number in the SQL batch
  o the server name (if available)
  o the stored procedure name (if available)
  o the message text
  o the current SQL command buffer
  o either of the strings "client" (for Client Library errors) or
    "server" (for server errors, such as SQL syntax errors, etc),
    allowing you to identify the error type.
  
As a contrived example, here is a port of the distinct error and
message handlers from the Sybase documentation:
  
  Example:
  
  sub err_handler {
      my($err, $sev, $state, $line, $server,
 	$proc, $msg, $sql, $err_type) = @_;
 
      my @msg = ();
      if($err_type eq 'server') {
 	 push @msg,
 	   ('',
 	    'Server message',
 	    sprintf('Message number: %ld, Severity %ld, State %ld, Line %ld',
 		    $err,$sev,$state,$line),
 	    (defined($server) ? "Server '$server' " : '') .
 	    (defined($proc) ? "Procedure '$proc'" : ''),
 	    "Message String:$msg");
      } else {
 	 push @msg,
 	   ('',
 	    'Open Client Message:',
 	    sprintf('Message number: SEVERITY = (%ld) NUMBER = (%ld)',
 		    $sev, $err),
 	    "Message String: $msg");
      }
      print STDERR join("\n",@msg);
      return 0; ## CS_SUCCEED
  }
 
In a simpler and more focused example, this error handler traps
showplan messages:
 
   %showplan_msgs = map { $_ => 1}  (3612 .. 3615, 6201 .. 6299, 10201 .. 10299);
   sub err_handler {
      my($err, $sev, $state, $line, $server,
 	$proc, $msg, $sql, $err_type) = @_;
  
       if($showplan_msgs{$err}) { # it's a showplan message
  	 print SHOWPLAN "$err - $msg\n";
  	 return 0;    # This is not an error
       }
       return 1;
   }
  
and this is how you would use it:
 
    $dbh = DBI->connect('dbi:Sybase:server=troll', 'sa', '');
    $dbh->{syb_err_handler} = \&err_handler;
    $dbh->do("set showplan on");
    open(SHOWPLAN, ">>/var/tmp/showplan.log") || die "Can't open showplan log: $!";
    $dbh->do("exec someproc");    # get the showplan trace for this proc.
    $dbh->disconnect;

B<NOTE> - if you set the error handler in the DBI->connect() call like this

    $dbh = DBI->connect('dbi:Sybase:server=troll', 'sa', '', 
		    { syb_err_handler => \&err_handler });

then the err_handler() routine will get called if there is an error during
       the connect itself. This is B<new> behavior in DBD::Sybase 0.95.


=item syb_flush_finish (bool)

If $dbh->{syb_flush_finish} is set then $dbh->finish will drain any
results remaining for the current command by actually fetching them.
The default behaviour is to issue a ct_cancel(CS_CANCEL_ALL), but this
I<appears> to cause connections to hang or to fail in certain cases
(although I've never witnessed this myself.)

=item syb_dynamic_supported (bool)

This is a read-only attribute that returns TRUE if the dataserver
you are connected to supports ?-style placeholders. Typically placeholders are
not supported when using DBD::Sybase to connect to a MS-SQL server.

=item syb_chained_txn (bool)

If set then we use CHAINED transactions when AutoCommit is off. 
Otherwise we issue an explicit BEGIN TRAN as needed. The default is off.

This attribute should usually be used only during the connect() call:

    $dbh = DBI->connect('dbi:Sybase:', $user, $pwd, {syb_chained_txn => 1});

Using it at any other time with B<AutoCommit> turned B<off> will 
B<force a commit> on the current handle.

=item syb_quoted_identifier (bool)

If set, then identifiers that would normally clash with Sybase reserved
words can be quoted using C<"identifier">. In this case strings must
be quoted with the single quote.

Default is for this attribute to be B<off>.

=item syb_rowcount (int)

Setting this attribute to non-0 will limit the number of rows returned by
a I<SELECT>, or affected by an I<UPDATE> or I<DELETE> statement to the
I<rowcount> value. Setting it back to 0 clears the limit.

Default is for this attribute to be B<0>.

=item syb_do_proc_status (bool)

Setting this attribute causes $sth->execute() to fetch the return status
of any executed stored procs in the SQL being executed. If the return
status is non-0 then $sth->execute() will report that the operation 
failed (ie it will return C<undef>). This will B<NOT> cause an error
to be raised if RaiseError is set, however. To get that behaviour
you need to generate a user error code in the stored proc via
a 

    raiserror <num> <errmsg> 

statement.

Setting this attribute does B<NOT> affect existing $sth handles, only
those that are created after setting it. To change the behavior of 
an existing $sth handle use $sth->{syb_do_proc_status}.

The default is for this attribute to be B<off>.

=item syb_use_bin_0x

If set, BINARY and VARBINARY values are prefixed with '0x'
in the result. The default is off.

=item syb_binary_images

If set, IMAGE data is returned in raw binary format. Otherwise the data is
converted to a long hex string. The default is off.

=item syb_oc_version (string)

Returns the identification string of the version of Client Library that
this binary is currently using. This is a read-only attribute.

For example:

    troll (7:59AM):348 > perl -MDBI -e '$dbh = DBI->connect("dbi:Sybase:", "sa"); print "$dbh->{syb_oc_version}\n";' 
    Sybase Client-Library/11.1.1/P/Linux Intel/Linux 2.2.5 i586/1/OPT/Mon Jun  7 07:50:21 1999

This is very useful information to have when reporting a problem.

=item syb_failed_db_fatal (bool)

If this is set, then a connect() request where the I<database>
specified doesn't exist or is not accessible will fail. This needs
to be set in the attribute hash passed during the DBI->connect() call
to be effective.

Default: off

=item syb_no_child_con (bool)

If this attribute is set then DBD::Sybase will B<not> allow multiple
simultaneously active statement handles on one database handle (i.e.
multiple $dbh->prepare() calls without completely processing the
results from any existing statement handle). This can be used
to debug situations where incorrect or unexpected results are
found due to the creation of a sub-connection where the connection
attributes (in particular the current database) are different.

Default: off

=item syb_bind_empty_string_as_null (bool)

B<New in 0.95>

If this attribute is set then an empty string (i.e. "") passed as
a parameter to an $sth->execute() call will be converted to a NULL
value. If the attribute is not set then an empty string is converted to
a single space.

Default: off

=item syb_cancel_request_on_error (bool)

B<New in 0.95>

If this attribute is set then a failure in a multi-statement request
(for example, a stored procedure execution) will cause $sth->execute()
to return failure, and will cause any other results from this request to 
be discarded.

The default value (B<on>) changes the behavior that DBD::Sybase exhibited
up to version 0.94. 

Default: on

=back

=head2 Statement Handle Attributes

The following read-only attributes are available at the statement level:

=over 4

=item syb_more_results (bool)

See the discussion on handling multiple result sets above.

=item syb_result_type (int)

Returns the numeric result type of the current result set. Useful when 
executing stored procedurs to determine what type of information is
currently fetchable (normal select rows, output parameters, status results,
etc...).

=item syb_do_proc_status (bool)

See above (under Database Handle Attributes) for an explanation.

=item syb_no_bind_blob (bool)

If set then any IMAGE or TEXT columns in a query are B<NOT> returned
when calling $sth->fetch (or any variation).

Instead, you would use

    $sth->func($column, \$data, $size, 'ct_get_data');

to retrieve the IMAGE or TEXT data. If $size is 0 then the entire item is
fetched, otherwis  you can call this in a loop to fetch chunks of data:

    while(1) {
	$sth->func($column, \$data, 1024, 'ct_get_data');
	last unless $data;
	print OUT $data;
    }

The fetched data is still subject to Sybase's TEXTSIZE option (see the
SET command in the Sybase reference manual). This can be manipulated with
DBI's B<LongReadLen> attribute, but C<$dbh->{LongReadLen}> I<must> be 
set before $sth->execute() is called to take effect (note that LongReadLen
has no effect  when using DBD::Sybase with an MS-SQL server).

B<Note>: The IMAGE or TEXT column that is to be fetched this way I<must> 
be I<last> in the select list.

See also the description of the ct_get_data() API call in the Sybase
OpenClient manual, and the "Working with TEXT/IMAGE columns" section
elsewhere in this document.

=back

=head1 Controlling DATETIME output formats

By default DBD::Sybase will return I<DATETIME> and I<SMALLDATETIME>
columns in the I<Nov 15 1998 11:13AM> format. This can be changed
via a special B<_date_fmt()> function that is accessed via the $dbh->func()
method.

The syntax is

    $dbh->func($fmt, '_date_fmt');

where $fmt is a string representing the format that you want to apply.

The formats are based on Sybase's standard conversion routines. The following
subset of available formats has been implemented:

=over 4

=item LONG

Nov 15 1998 11:30:11:496AM

=item SHORT

Nov 15 1998 11:30AM

=item DMY4_YYYY

15 Nov 1998

=item MDY1_YYYY

11/15/1998

=item DMY1_YYYY

15/11/1998

=item DMY2_YYYY

15.11.1998

=item YMD3_YYYY

19981115

=item HMS

11:30:11

=back

=head1 Retrieving OUTPUT parameters from stored procedures

Sybase lets you pass define B<OUTPUT> parameters to stored procedures,
which are a little like parameters passed by reference in C (or perl.)

In Transact-SQL this is done like this

   declare @id_value int, @id_name char(10)
   exec my_proc @name = 'a string', @number = 1234, @id = @id_value OUTPUT, @out_name = @id_name OUTPUT
   -- Now @id_value and @id_name are set to whatever 'my_proc' set @id and @out_name to


So how can we get at @param using DBD::Sybase? 

If your stored procedure B<only> returns B<OUTPUT> parameters, then you
can use this shorthand:

    $sth = $dbh->prepare('...');
    $sth->execute;
    @results = $sth->func('syb_output_params');

This will return an array for all the OUTPUT parameters in the proc call,
and will ignore any other results. The array will be undefined if there are 
no OUTPUT params, or if the stored procedure failed for some reason.

The more generic way looks like this:

   $sth = $dbh->prepare("declare \@id_value int, \@id_name
      exec my_proc @name = 'a string', @number = 1234, @id = @id_value OUTPUT, @out_name = @id_name OUTPUT");
   $sth->execute;
   do {
      while($d = $sth->fetch) {
         if($sth->{syb_result_type} == 4042) { # it's a PARAM result
            $id_value = $d->[0];
            $id_name  = $d->[1];
         }
      }
   } while($sth->{syb_more_results});

So the OUTPUT params are returned as one row in a special result set.


=head1 Multiple active statements on one $dbh

It is possible to open multiple active statements on a single database 
handle. This is done by opening a new physical connection in $dbh->prepare()
if there is already an active statement handle for this $dbh.

This feature has been implemented to improve compatibility with other
drivers, but should not be used if you are coding directly to the 
Sybase driver.

If AutoCommit is B<OFF> then multiple statement handles on a single $dbh
is B<NOT> supported. This is to avoid various deadlock problems that
can crop up in this situation, and because you will not get real transactional
integrity using multiple statement handles simultaneously as these in 
reality refer to different physical connections.


=head1 Working with IMAGE and TEXT columns

DBD::Sybase can store and retrieve IMAGE or TEXT data (aka "blob" data)
via standard SQL statements. The B<LongReadLen> handle attribute controls
the maximum size of IMAGE or TEXT data being returned for each data 
element.

When using standard SQL the default for IMAGE data is to be converted
to a hex string, but you can use the I<syb_binary_images> handle attribute 
to change this behaviour. Alternatively you can use something like

    $binary = pack("H*", $hex_string);

to do the conversion.

IMAGE and TEXT datatypes can B<not> be passed as parameters using
?-style placeholders, and placeholders can't refer to IMAGE or TEXT 
columns (this is a limitation of the TDS protocol used by Sybase, not
a DBD::Sybase limitation.)

There is an alternative way to access and update IMAGE/TEXT data
using the natice OpenClient API. This is done via $h->func() calls,
and is, unfortunately, a little convoluted.

=head2 Handling IMAGE/TEXT data with ct_get_data()/ct_send_data()

=over 4

=item $len = ct_fetch_data($col, $dataref, $numbytes)

The ct_get_data() call allows you to fetch IMAGE/TEXT data in
raw format, either in one piece or in chunks. To use this function
you must set the I<syb_no_bind_blob> statement handle to I<TRUE>. 

ct_get_data() takes 3 parameters: The column number (starting at 1)
of the query, a scalar ref and a byte count. If the byte count is 0 
then we read as many bytes as possible.

Note that the IMAGE/TEXT column B<must> be B<last> in the select list
for this to work.

The call sequence is:

    $sth = $dbh->prepare("select id, img from some_table where id = 1");
    $sth->{syb_no_bind_blob} = 1;
    $sth->execute;
    while($d = $sth->fetchrow_arrayref) {
       # The data is in the second column
       $len = $sth->func(2, \$img, 0, 'ct_get_data');
    }

ct_get_data() returns the number of bytes that were effectively fetched,
so that when fetching chunks you can do something like this:

   while(1) {
      $len = $sth->func(2, $imgchunk, 1024, 'ct_get_data');
      ... do something with the $imgchunk ...
      last if $len != 1024;
   }

To explain further: Sybase stores IMAGE/TEXT data separately from 
normal table data, in a chain of 2k blocks. To update an IMAGE/TEXT
column Sybase needs to find the head of this chain, which is known as
the "text pointer". As there is no I<where> clause when the ct_send_data()
API is used we need to retrieve the I<text pointer> for the correct
data item first, which is done via the ct_data_info(CS_GET) call. Subsequent
ct_send_data() calls will then know which data item to update.

=item $status = ct_data_info($action, $column, $attr)

ct_data_info() is used to fetch or update the CS_IODESC structure
for the IMAGE/TEXT data item that you wish to update. $action should be
one of "CS_SET" or "CS_GET", $column is the column number of the
active select statement (ignored for a CS_SET operation) and $attr is
a hash ref used to set the values in the struct.

ct_data_info() must be first called with CS_GET to fetch the CS_IODESC
structure for the IMAGE/TEXT data item that you wish to update. Then 
you must update the value of the I<total_txtlen> structure element
to the length (in bytes) of the IMAGE/TEXT data that you are going to
insert, and optionally set the I<log_on_update> to B<TRUE> to enable full 
logging of the operation.

ct_data_info(CS_GET) will I<fail> if the IMAGE/TEXT data for which the 
CS_IODESC is being fetched is NULL. If you have a NULL value that needs
updating you must first update it to some non-NULL value (for example
an empty string) using standard SQL before you can retrieve the CS_IODESC
entry. This actually makes sense because as long as the data item is NULL
there is B<no> I<text pointer> and no TEXT page chain for that item.

See the ct_send_data() entry below for an example.

=item ct_prepare_send()

ct_prepare_send() must be called to initialize a IMAGE/TEXT write operation.
See the ct_send_data() entry below for an example.

=item ct_finish_send()

ct_finish_send() is called to finish/commit an IMAGE/TEXT write operation.
See the ct_send_data() entry below for an example.

=item ct_send_data($image, $bytes)

Send $bytes bytes of $image to the database. The request must have been set
up via ct_prepare_send() and ct_data_info() for this to work. ct_send_data()
returns B<TRUE> on success, and B<FALSE> on failure.

In this example, we wish to update the data in the I<img> column
where the I<id> column is 1:

  # first we need to find the CS_IODESC data for the data
  $sth = $dbh->prepare("select img from imgtable where id = 1");
  $sth->execute;
  while($sth->fetch) {    # don't care about the data!
      $sth->func('CS_GET', 1, 'ct_data_info');
  }

  # OK - we have the CS_IODESC values, so do the update:
  $sth->func('ct_prepare_send');
  # Set the size of the new data item (that we are inserting), and make
  # the operation unlogged
  $sth->func('CS_SET', 1, {total_txtlen => length($image), log_on_update => 0}, 'ct_data_info');
  # now transfer the data (in a single chunk, this time)
  $sth->func($image, length($image), 'ct_send_data');
  # commit the operation
  $sth->func('ct_finish_send');

The ct_send_data() call can also transfer the data in chunks, however you 
must know the total size of the image before you start the insert. For example:

  # update a database entry with a new version of a file:
  my $size = -s $file;
  # first we need to find the CS_IODESC data for the data
  $sth = $dbh->prepare("select img from imgtable where id = 1");
  $sth->execute;
  while($sth->fetch) {    # don't care about the data!
      $sth->func('CS_GET', 1, 'ct_data_info');
  }

  # OK - we have the CS_IODESC values, so do the update:
  $sth->func('ct_prepare_send');
  # Set the size of the new data item (that we are inserting), and make
  # the operation unlogged
  $sth->func('CS_SET', 1, {total_txtlen => $size, log_on_update => 0}, 'ct_data_info');

  # open the file, and store it in the db in 1024 byte chunks.
  open(IN, $file) || die "Can't open $file: $!";
  while($size) {
      $to_read = $size > 1024 ? 1024 : $size;
      $bytesread = read(IN, $buff, $to_read);
      $size -= $bytesread;

      $sth->func($buff, $bytesread, 'ct_send_data');
  }
  close(IN);
  # commit the operation
  $sth->func('ct_finish_send');
      

=back
       

=head1 AutoCommit, Transactions and Transact-SQL

When $h->{AutoCommit} is I<off> all data modification SQL statements
that you issue (insert/update/delete) will only take effect if you
call $dbh->commit.

DBD::Sybase implements this via two distinct methods, depending on 
the setting of the $h->{syb_chained_txn} attribute and the version of the
server that is being accessed.

If $h->{syb_chained_txn} is I<off>, then the DBD::Sybase driver
will send a B<BEGIN TRAN> before the first $dbh->prepare(), and
after each call to $dbh->commit() or $dbh->rollback(). This works
fine, but will cause any SQL that contains any I<CREATE TABLE>
(or other DDL) statements to fail. These I<CREATE TABLE> statements can be
burried in a stored procedure somewhere (for example,
C<sp_helprotect> creates two temp tables when it is run). 
You I<can> get around this limit by setting the C<ddl in tran> option
(at the database level, via C<sp_dboption>.) You should be aware that
this can have serious effects on performance as this causes locks to
be held on certain system tables for the duration of the transaction.

If $h->{syb_chained_txn} is I<on>, then DBD::Sybase sets the
I<CHAINED> option, which tells Sybase not to commit anything automatically.
Again, you will need to call $dbh->commit() to make any changes to the data
permanent. In this case Sybase will not let you issue I<BEGIN TRAN> 
statements in the SQL code that is executed, so if you need to execute
stored procedures that have I<BEGIN TRAN> statements in them you 
must use $h->{syb_chained_txn} = 0, or $h->{AutoCommit} = 1.

=head1 Using ? Placeholders & bind parameters to $sth->execute

DBD::Sybase supports the use of ? placeholders in SQL statements as long
as the underlying library and database engine supports it. It does 
this by using what Sybase calls I<Dynamic SQL>. The ? placeholders allow
you to write something like:

	$sth = $dbh->prepare("select * from employee where empno = ?");

        # Retrieve rows from employee where empno == 1024:
	$sth->execute(1024);
	while($data = $sth->fetch) {
	    print "@$data\n";
	}

       # Now get rows where empno = 2000:
	
	$sth->execute(2000);
	while($data = $sth->fetch) {
	    print "@$data\n";
	}

When you use ? placeholders Sybase goes and creates a temporary stored 
procedure that corresponds to your SQL statement. You then pass variables
to $sth->execute or $dbh->do, which get inserted in the query, and any rows
are returned.

DBD::Sybase uses the underlying Sybase API calls to handle ?-style 
placeholders. For select/insert/update/delete statements DBD::Sybase
calls the ct_dynamic() family of Client Library functions, which gives
DBD::Sybase data type information for each parameter to the query.

You can only use ?-style placeholders for statements that return a single
result set, and the ? placeholders can only appear in a 
B<WHERE> clause, in the B<SET> clause of an B<UPDATE> statement, or in the
B<VALUES> list of an B<INSERT> statement. 

The DBI docs mention the following regarding NULL values and placeholders:

=over 4

       Binding an `undef' (NULL) to the placeholder will not
       select rows which have a NULL `product_code'! Refer to the
       SQL manual for your database engine or any SQL book for
       the reasons for this.  To explicitly select NULLs you have
       to say "`WHERE product_code IS NULL'" and to make that
       general you have to say:

         ... WHERE (product_code = ? OR (? IS NULL AND product_code IS NULL))

       and bind the same value to both placeholders.

=back

This will not work with a Sybase database server. If you attempt the 
above construct you will get the following error:

=over 4

The datatype of a parameter marker used in the dynamic prepare statement could not be resolved.

=back

The specific problem here is that when using ? placeholders the prepare()
operation is sent to the database server for parameter resoltion. This extracts
the datatypes for each of the placeholders. Unfortunately the C<? is null>
construct doesn't tie the ? placeholder with an existing table column, so
the database server can't find the data type. As this entire operation happens
inside the Sybase libraries there is no easy way for DBD::Sybase to work around
it.

Note that Sybase will normally handle the C<foo = NULL> construct the same way
that other systems handle C<foo is NULL>, so the convoluted construct that
is described above is not necessary to obtain the correct results when
querying a Sybase database.


The underlying API does not support ?-style placeholders for stored 
procedures, but see the section on titled B<Stored Procedures and Placeholders>
elsewhere in this document.

?-style placeholders can B<NOT> be used to pass TEXT or IMAGE data
items to the server. This is a limitation of the TDS protocol, not of
DBD::Sybase.

There is also a performance issue: OpenClient creates stored procedures in
tempdb for each prepare() call that includes ? placeholders. Creating
these objects requires updating system tables in the tempdb database, and
can therefore create a performance hotspot if a lot of prepare() statements
from multiple clients are executed simultaneously. This problem
has been corrected for Sybase 11.9.x and later servers, as they create
"lightweight" temporary stored procs which are held in the server memory
cache and don't affect the system tables at all. 

In general however I find that if your application is going to run 
against Sybase it is better to write ad-hoc
stored procedures rather than use the ? placeholders in embedded SQL.

Out of curiosity I did some simple timings to see what the overhead
of doing a prepare with ? placehoders is vs. a straight SQL prepare and
vs. a stored procedure prepare. Against an 11.0.3.3 server (linux) the
placeholder prepare is significantly slower, and you need to do ~30
execute() calls on the prepared statement to make up for the overhead.
Against a 12.0 server (solaris) however the situation was very different,
with placeholder prepare() calls I<slightly> faster than straight SQL
prepare(). This is something that I I<really> don't understand, but
the numbers were pretty clear.

In all cases stored proc prepare() calls were I<clearly> faster, and 
consistently so.

This test did not try to gauge concurrency issues, however.

It is not possible to retrieve the last I<IDENTITY> value
after an insert done with ?-style placeholders. This is a Sybase
limitation/bug, not a DBD::Sybase problem. For example, assuming table
I<foo> has an identity column:

  $dbh->do("insert foo(col1, col2) values(?, ?)", undef, "string1", "string2");
  $sth = $dbh->prepare('select @@identity') 
    || die "Can't prepare the SQL statement: $DBI::errstr";
  $sth->execute || die "Can't execute the SQL statement: $DBI::errstr";

  #Get the data back.
  while (my $row = $sth->fetchrow_arrayref()) {
    print "IDENTITY value = $row->[0]\n";
  }

will always return an identity value of 0, which is obviously incorrect.
This behaviour is due to the fact that the handling of ?-style placeholders
is implemented using temporary stored procedures in Sybase, and the value
of C<@@identity> is reset when the stored procedure has executed. Using an 
explicit stored procedure to do the insert and trying to retrieve
C<@@identity> after it has executed results in the same behaviour.


Please see the discussion on Dynamic SQL in the 
OpenClient C Programmer's Guide for details. The guide is available on-line
at http://sybooks.sybase.com/

=head1 Stored Procedures and Placeholders

B<NOTE: This feature is experimental>

This version of DBD::Sybase introduces the ability to use ?-style
placeholders as parameters to stored proc calls. The requirements are
that the stored procedure call be initiated with an "exec" and that it be
the only statement in the batch that is being prepared():

For example, this prepares a stored proc call with named parameters:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?");
    $sth->execute('one', 'two');

You can also use positional parameters:

    my $sth = $dbh->prepare("exec my_proc ?, ?");
    $sth->execute('one', 'two');

You may I<not> mix positional and named parameter in the same prepare.

You can specify I<OUTPUT> parameters in the usual way, but you can B<NOT>
use bind_param_inout() to get the output result - instead you have to call
fetch() and/or $sth->func('syb_output_params'):

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?, \@p3 = ? OUTPUT ");
    $sth->execute('one', 'two', 'three');
    my (@data) = $sth->func('syb_output_params');

DBD::Sybase does not attempt to figure out the correct parameter type
for each parameter (it would be possible to do this for most cases, but
there are enough exceptions that I preferred to avoid the issue for the 
time being). DBD::Sybase defaults all the parameters to SQL_CHAR, and
you have to use bind_param() with an explicit type value to set this to
something different. The type is then remembered, so you only need to 
use the explicit call once for each parameter:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?");
    $sth->bind_param(1, 'one', SQL_CHAR);
    $sth->bind_param(2, 2.34, SQL_FLOAT);
    $sth->execute;
    ....
    $sth->execute('two', 3.456);
    etc...

When binding SQL_NUMERIC or SQL_DECIMAL data you may get fatal conversion
errors if the scale or the precision exceeds the size of the target
parameter definition.

For example, consider the following stored proc definition:

    declare proc my_proc @p1 numeric(5,2) as...

and the following prepare/execute snippet:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?");
    $sth->bind_param(1, 3.456, SQL_NUMERIC);

This generates the following error:

DBD::Sybase::st execute failed: Server message number=241 severity=16 state=2 line=0 procedure=dbitest text=Scale error during implicit conversion of NUMERIC value '3.456' to a NUMERIC field.

You can tell Sybase (and DBD::Sybase) to ignore these sorts of errors by
setting the I<arithabort> option:

    $dbh->do("set arithabort off");

See the I<set> command in the Sybase Adaptive Server Enterprise Reference 
Manual for more information on the set command and on the arithabort option.


=head1 BUGS

You can run out of space in the tempdb database if you use a lot of
calls with bind variables (ie ?-style placeholders) without closing the
connection. On my system, with an 8 MB tempdb database I run out of space
after 760 prepare() statements with ?-parameters. This is because
Sybase creates stored procedures for each prepare() call. So my
suggestion is to only use ?-style placeholders if you really need them
(i.e. if you are going to execute the same prepared statement multiple
times).

The new primary_key_info() method will only return data for tables 
where a declarative "primary key" constraint was included when the table
was created.

I have a simple bug tracking database at http://www.peppler.org/cgi-bin/bug.cgi .
You can use it to view known problems, or to report new ones. Keep in
mind that peppler.org is connected to the net via a K56 dialup line, so
it may be slow.

=head1 Using DBD::Sybase with MS-SQL 

MS-SQL started out as Sybase 4.2, and there are still a lot of similarities
between Sybase and MS-SQL which makes it possible to use DBD::Sybase
to query a MS-SQL dataserver using either the Sybase OpenClient libraries
or the FreeTDS libraries (see http://www.freetds.org).

However, using the Sybase libraries to query an MS-SQL server has
certain limitations. In particular ?-style placeholders are not 
supported (although support when using the FreeTDS libraries is
possible in a future release of the libraries), and certain B<syb_> 
attributes may not be supported.

Sybase defaults the TEXTSIZE attribute (aka B<LongReadLen>) to
32k, but MS-SQL 7 doesn't seem to do that correctly, resulting in
very large memory requests when querying tables with TEXT/IMAGE 
data columns. The work-around is to set TEXTSIZE to some decent value
via $dbh->{LongReadLen} (if that works - I haven't had any confirmation
that it does) or via $dbh->do("set textsize <somesize>");

=head1 nsql

The nsql() call is a direct port of the function of the same name that
exists in Sybase::DBlib.

Usage:

   @data = $dbh->func($sql, $type, $callback, 'nsql');

This executes the query in $sql, and returns all the data in @data. The 
$type parameter can be used to specify that each returned row be in array
form (i.e. $type passed as 'ARRAY', which is the default) or in hash form 
($type passed as 'HASH') with column names as keys.

If $callback is specified it is taken as a reference to a perl sub, and
each row returned by the query is passed to this subroutine I<instead> of
being returned by the routine (to allow processing of large result sets, 
for example).

C<nsql> also checks three special attributes to enable deadlock retry logic
\(I<Note> none of these attributes have any effect anywhere else at the moment):

=over 4

=item syb_deadlock_retry I<count>

Set this to a non-0 value to enable deadlock detection and retry logic within
nsql(). If a deadlock error is detected (error code 1205) then the entire
batch is re-submitted up to I<syb_deadlock_retry> times. Default is 0 (off).

=item syb_deadlock_sleep I<seconds>

Number of seconds to sleep between deadlock retries. Default is 60.

=item syb_deadlock_verbose (bool)

Enable verbose logging of deadlock retry logic. Default is off.

=back

Deadlock detection will be added to the $dbh->do() method in a future
version of DBD::Sybase. 


=head1 SEE ALSO

L<DBI>

Sybase OpenClient C manuals.

Sybase Transact SQL manuals.

=head1 AUTHOR

DBD::Sybase by Michael Peppler

=head1 COPYRIGHT

The DBD::Sybase module is Copyright (c) 1997-2003 Michael Peppler.
The DBD::Sybase module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Tim Bunce for DBI, obviously!

See also L<DBI/ACKNOWLEDGEMENTS>.

=cut
