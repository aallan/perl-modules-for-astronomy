package eSTAR::Database::DBbackend;

=head1 NAME

OMP::DBbackend - Connect and disconnect from specific database backend

=head1 SYNOPSIS

  use OMP::DBbackend;

  # Set up connection to database
  my $db = new OMP::DBbackend;

  # Get the connection handle
  $dbh = $db->handle;

  # disconnect (automatic when goes out of scope)
  $db->disconnect;

=head1 DESCRIPTION

Since the OMP interacts with many database tables but only
requires a single database connection we separate out the connection
management from the database interaction. This will allow us to optimize
connections for servers that are running continuously without having
to use the overhead of connecting for each transaction.

We use a HAS-A relationship with the OMP servers rather than an IS-A
relationship because we do not want to initiate a new connection each
time we instantiate a new low-level database object.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

# OMP

BEGIN { $ENV{SYBASE} = "/local/progs/sybase" unless exists $ENV{SYBASE} }

#use OMP::Error;
#use OMP::General;
#use eSTAR::Config;
use DBI;

our $VERSION = '0.01';
our $DEBUG = 0;

=head1 METHODS

=head2 Connections Details

=over 4

=item B<loginhash>

This class method returns the information required to connect to a
database. The details are returned in a hash with the following
keys:

  driver  =>  DBI driver to use for database connection [Sybase or Pg]
  server  =>  Database server (e.g. SYB_*) [only used for sybase]
  database=>  The database to use for the transaction
  user    =>  database login name
  password=>  password for user

This is a class method so that it can easily be subclassed.

  %details = OMP::DBbackend->loginhash;

The following environment variables are recognised to override
these values:

  OMP_DBSERVER - the server to use

In the future this method may well read the details from a config
file rather than hard-wiring the values in the module.

=cut

sub loginhash {
  my $class = shift;

#  my $config = new eSTAR::Config();

  my %details = (
#		 driver   => $config->get_option("database.driver"),
#		 server   => $config->get_option("database.server"),
#		 database => $config->get_option("database.database"),
#		 user     => $config->get_option("database.user"),
#		 password => $config->get_option("database.password"),
                 driver => 'Sybase',
                 server => 'SYB_OMP1',
                 database => 'estar',
                 user => 'estar',
                 password => 'estar_db',
		);

  # possible override for sybase users
  if ($details{driver} eq 'Sybase') {
    $details{server} = $ENV{OMP_DBSERVER}
      if (exists $ENV{OMP_DBSERVER} and defined $ENV{OMP_DBSERVER});

    # If we are now switching to SYB_UKIRT we have to change
    # the database field [this is only for development]
    $details{database} = 'estar'
      if (defined $details{server} && $details{server} eq 'SYB_OMP1');
  }

  return %details;
}

=item B<dbdriver>

Returns the DBD:: class name used for the backend connection. Databases
have different functionality and SQL dialects so this method should
be used to determine which database backend is being used by the software.
This is assumed to be fixed during the lifetime of the program (but
will support subclassing if the correct class is used).

 $driver = OMP::DBbackend->dbdriver();

Will return "Sybase" for Sybase or "Pg" for PostgreSQL.

=cut

sub dbdriver {
  my $class = shift;
  my %loginhash = $class->loginhash;
  my $driv = $loginhash{driver};
  $driv = "UNKNOWN" if !defined $driv;
  return $driv;
}

=item B<has_writetext>

Indicates whether the database supports the WRITETEXT SQL function.
Returns true if it does, false if it does not.

=cut

sub has_writetext {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return 1;
  } else {
    return 0;
  }
}

=item B<has_textsize>

Indicates whether the database supports the "SET TEXTSIZE" construct.
Returns true if it does, false if it does not.

=cut

sub has_textsize {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return 1;
  } else {
    return 0;
  }
}

=item B<has_automatic_serial_on_insert>

Returns true if a SERIAL/IDENTITY column is incremented automatically
during ordered insert. Returns false if SERIAL/IDENTITY columns have
to be dealt with explicitly in order insert (or alternatively, only
support named insert).

=cut

sub has_automatic_serial_on_insert {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return 1;
  } else {
    return 0;
  }
}

=item B<get_stmt_start>

Return character to be used at start of SQL statement that can
bracket it from subsequent statements in the same block. For Sybase
we can bracket statemetns with ( and ). For Postgres just need
semi-colon at the end.

=cut

sub get_stmt_start {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "(";
  } else {
    return "";
  }
}

=item B<get_stmt_end>

Return character to be used at end of SQL statement that can
bracket it from subsequent statements in the same block. For Sybase
we can bracket statements with ( and ). For Postgres just need
semi-colon at the end.

=cut

sub get_stmt_end {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return ")";
  } else {
    return ";";
  }
}

=item B<get_serial_type>

Indicates what type should be used to declare columns that should
be treated as unique sequential identifier columns.
For Sybase returns "IDENTITY", for PostgreSQL returns "SERIAL".

 $type = OMP::DBbackend->get_ident_type();

=cut

sub get_serial_type {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "numeric(9,0) IDENTITY";
  } else {
    return "SERIAL";
  }
}


=item B<get_datetime_type>

Returns the column type that should be used to represent a date and
time (at least 1 second precision). Returns the type.

=cut

sub get_datetime_type {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "DATETIME";
  } else {
    return "TIMESTAMP";
  }
}

=item B<get_boolean_type>

Return the column type suitable for use as a boolean.

=cut

sub get_boolean_type {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "BIT";
  } else {
    return "BOOLEAN";
  }
}

=item B<get_boolean_true>

Return the definition of "true" for a boolean type (as returned
by the C<get_boolean_type> method) suitable for use in a SELECT statement.

=cut

sub get_boolean_true {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "1";
  } else {
    return "true";
  }
}

=item B<get_boolean_false>

Return the definition of "false" for a boolean type (as returned
by the C<get_boolean_type> method) suitable for use in a SELECT statement.

=cut

sub get_boolean_false {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "0";
  } else {
    return "false";
  }
}


=cut

=item B<get_temptable_constructor>

String that should precede a temporary table constructor in a "SELECT INTO"
construct. For Sybase returns an empty string. For Postgres returns the
string "TEMPORARY". In conjunction with C<get_temptable_prefix> can
be used to construct a query:

  SELECT * INTO TEMPORARY temp

or

  SELECT * INTO #temp

=cut

sub get_temptable_constructor {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "";
  } else {
    return "TEMPORARY";
  }
}



=item B<get_temptable_prefix>

Retrieve any prefix that should be attached to a temporary table
name before it can be used in a query. For Sybase returns a "#"
for all other databases returns an empty string

  DROP TABLE #temp

or
  DROP TABLE temp

=cut

sub get_temptable_prefix {
  my $class = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "#";
  } else {
    return "";
  }
}

=item B<get_sql_typecast>

Given a SQL variable/column name and a variable type, returns the SQL
code necessary to convert the variable into the new type.

  $sql = OMP::DBbackend->get_sql_typecast( "float", "M.obscount" );

For Sybase:

  convert(float,M.obscount)

for PostgreSQL:

  CAST(M.obscount AS FLOAT)

=cut

sub get_sql_typecast {
  my $class = shift;
  my $newtype = shift;
  my $oldvar = shift;
  my $driver = $class->dbdriver;
  if ($driver eq 'Sybase') {
    return "convert($newtype,$oldvar)";
  } else {
    # postgres
    return "CAST($oldvar AS $newtype)";
  }
}

=back

=head2 Constructor

=over 4

=item B<new>

Instantiate a new object.

  $db = new OMP::DBbackend();
  $db = new OMP::DBbackend(1);

The connection to the database backend is made immediately.

By default the connection object is cached. A true argument forces a
brand new connection. The cache can be cleared using the <clear_cache>
class method. The class should not guarantee to return the same
database connection each time although it probably will. This is so
that connection pooling and automated expiry can be implemented at a
later date.

Caching of subclasses will work so long as the sub class constructor
calls the base class constructor.

=cut

my %CACHE;
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $nocache = shift;

  if (!$nocache && defined $CACHE{$class}) {
    return $CACHE{$class};
  }

  my $db = bless {
                  TransCount => 0,
                  Handle => undef,
                  IsConnected => 0,
                 }, $class;

  # Store object in the cache
  $CACHE{$class} = $db;

  return $db;
}

=back

=head2 Accessor Methods

=over 4

=item B<_connected>

Set or retrieve the connection status of the database object.

  $db->_connected( 1 );
  $connected = $db->_connected;

When setting the status, this method takes one boolean parameter. It
returns a boolean when called in scalar context, and returns false
by default.

=cut

sub _connected {
  my $self = shift;
  if (@_) { $self->{IsConnected} = shift; }
  return $self->{IsConnected};
}

=item B<handle>

The database connection handle associated with this object.

  $dbh = $db->handle;
  $db->handle( $dbh );

If this object is around for a long time it is possible that the
connection may fail (maybe if the database has been rebooted). If that
happens we may want to check the connection each time we return this
object.

=cut

sub handle {
  my $self = shift;
  if (@_) {
    $self->{Handle} = shift;
  } elsif (!defined $self->{Handle} && !$self->_connected) {

    # Only do the connect when we're asked what the handle is. We
    # only do this here so that we don't run into an infinite loop
    # if we are supplied with a handle.
    $self->connect;

  }
  return $self->{Handle};
}

=item B<trans_count>

Indicate whether we are in a transaction or not.

  $intrans = $db->trans_count();
  $db->trans_count(1);

The number returned by this method indicates the number of
transactions that we have been asked to begin. A transaction
is only ended when this number hits zero [note that a transaction
is not committed automatically when this hits zero - the method
committing the transaction checks this number]

The method is usually called via the transaction handling methods
(e.g. C<begin_trans>, C<_inctrans>).

The number can not be negative (forced to zero if it is).

=cut

sub trans_count {
  my $self = shift;
  if (@_) {
    my $c = shift;
    $c = 0 if $c < 0;
    $self->{TransCount} = $c;
  }
  return $self->{TransCount};
}

=back

=head2 General Methods

=over 4

=item B<connect>

Connect to the database. Automatically called by the
constructor.

An C<OMP::Error::DBConnection> exception is thrown if the connection
does not succeed.

=cut

sub connect {
  my $self = shift;

  # Database details
  my %details    = $self->loginhash;
  my $DBIdriver  = $details{driver};
  my $DBserver   = $details{server};
  my $DBuser     = $details{user};
  my $DBpwd      = $details{password};
  my $DBdatabase = $details{database};

  # Work out arguments for "generic" DBI layer. Shame they can not all
  # be the same
  my $info = ''; # informational message in error
  my $dboptions = "";
  if ($DBIdriver eq "Sybase") {
    $dboptions = ":server=${DBserver};database=$DBdatabase;timeout=120";
    $info = "$DBserver Sybenv=$ENV{SYBASE}";
  } elsif ($DBIdriver eq 'Pg') {
    $DBserver = "<IRRELEVANT>";
    $dboptions = ":dbname=${DBdatabase}";
    $info = "Postgres";
  } elsif ($DBIdriver eq 'mSQL') {
    $DBserver = "<IRRELEVANT>";
    $dboptions = ":database=$DBdatabase";
    $info = "mSQL";
  } else {
    $DBserver = "<IRRELEVANT>";
    warn "DBI driver $DBIdriver not tested with OMP system. Leap of faith";
    $dboptions = ":database=$DBdatabase";
    $info = "???";
  }

  print "DBI DRIVER: $DBIdriver; SERVER: $DBserver DATABASE: $DBdatabase USER: $DBuser\n"
    if $DEBUG;

#  OMP::General->log_message( "------------> Login to DB $DBIdriver server $DBserver as $DBuser <-----");

  # We are using sybase
  my $dbh = DBI->connect("dbi:$DBIdriver".$dboptions, $DBuser, $DBpwd, { PrintError => 0 })
    or croak("Cannot connect to database '$info' : $DBI::errstr");

  # Indicate that we have connected
  $self->_connected(1);

  # Store the handle
  $self->handle( $dbh );

}

=item B<disconnect>

Disconnect from the database. This method undefines the C<handle> object and
sets the C<_connected> status to disconnected.

=cut

sub disconnect {
  my $self = shift;
  $self->handle->disconnect;
  $self->handle( undef );
  $self->_connected( 0 );
}

=item B<begin_trans>

Begin a database transaction. This is defined as something that has
to happen in one go or trigger a rollback to reverse it.

If a transaction is already in progress this method increments the
transaction counter and returns without attempting to start a new
transaction.

Each transaction begun must be finished with a commit. If you start
two transactions the changes are only committed on the second commit.

=cut

sub begin_trans {
  my $self = shift;

  # Get the current count
  my $transcount = $self->trans_count;

  # If we are not in a transaction start one
  if ($transcount == 0) {

    my $dbh = $self->handle or croak("Database handle not valid");

    # Begin a transaction
    $dbh->begin_work or croak("Error in begin_work: $DBI::errstr\n");

  }

  # increment the counter
  $self->_inctrans;

}

=item B<commit_trans>

Commit the transaction. This informs the database that everthing
is okay and that the actions should be finalised.

Note that if we have started multiple nested transactions we only
commit when the last transaction is committed.

=cut

sub commit_trans {
  my $self = shift;

  # Get the current count and return if it is zero
  my $transcount = $self->trans_count;
  return unless $transcount;

  if ($transcount == 1) {
    # This is the last transaction so commit
    my $dbh = $self->handle or croak("Database handle not valid");

    $dbh->commit
      or throw OMP::Error::DBError("Error committing transaction: $DBI::errstr");

  }

  # Decrement the counter
  $self->_dectrans;

}

=item B<rollback_trans>

Rollback (ie reverse) the transaction. This should be called if
we detect an error during our transaction.

I<All transactions are rolled back since the database itself can not
handle nested transactions we must abort from all transactions.>

=cut

sub rollback_trans {
  my $self = shift;

  # Check that we are in a transaction
  if ($self->trans_count) {

    # Okay rollback the transaction
    my $dbh = $self->handle or croak("Database handle not valid");

    # Reset the counter
    $self->trans_count(0);

    $dbh->rollback or croak("Error rolling back transaction (ironically): $DBI::errstr");

  }
}

=item B<lockdb>

Lock the database. NOT YET IMPLEMENTED.

The API may change since we have not decided whether this should
lock all OMP tables or the tables supplied as arguments.

=cut

sub lockdb {
  my $self = shift;
  return;
}

=item B<unlockdb>

Unlock the database. NOT YET IMPLEMENTED.

The API may change since we have not decided whether this should
unlock all OMP tables or the tables supplied as arguments.

=cut

sub unlockdb {
  my $self = shift;
  return;
}

=item B<DESTROY>

Automatic destructor. Guarantees that we will try to disconnect
even if an exception has been thrown. Also forces a rollback if we
are in a transaction.

=cut

sub DESTROY {
  my $self = shift;
  if ($self->_connected) {
    my $dbh = $self->handle();
    if (defined $dbh) {
      $self->rollback_trans;
      $self->disconnect;
    }
  }
}

=back

=head2 Private Methods

=over 4

=item B<_inctrans>

Increment the transaction count by one.

=cut

sub _inctrans {
  my $self = shift;
  my $transcount = $self->trans_count;
  $self->trans_count( ++$transcount );
}

=item B<_dectrans>

Decrement the transaction count by one. Can not go lower than zero.

=cut

sub _dectrans {
  my $self = shift;
  my $transcount = $self->trans_count;
  $self->trans_count( --$transcount );
}

=back

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA

=cut

1;
