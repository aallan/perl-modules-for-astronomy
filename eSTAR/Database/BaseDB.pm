package eSTAR::Database::BaseDB;

=head1 NAME

eSTAR::Database::BaseDB - Base class for eSTAR database manipulation

=head1 SYNOPSIS

  $db->_db_begin_trans;

  $db->_db_commit_trans;

=head1 DESCRIPTION

This class has all the generic methods required by eSTAR to
deal with database transactions of all kinds that are shared
between subclasses (ie nothing that is different between science
program database and project database).

=cut


use 5.006;
use strict;
use warnings;
use Carp;

# OMP Dependencies
#use OMP::Error;
#use OMP::Constants qw/ :fb :logging /;
#use OMP::General;
#use OMP::FeedbackDB;

#use Mail::Internet;
#use MIME::Entity;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Base class for constructing a new instance of a OMP DB connectivity
class.


  $db = new eSTAR::Database::BaseDB( ProjectID => $project,
                                     Password  => $passwd
                                     DB => $connection,
                                   );

See C<OMP::ProjDB> and C<OMP::MSBDB> for more details on the
use of these arguments and for further keys.

If supplied, the database connection object must be of type
C<OMP::DBbackend>.  It is not accepted if that is not the case.
(but no error is raised - this is probably a bug).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Read the arguments
  my %args;
  %args = @_ if @_;

  my $db = {
	    InTrans => 0,
	    Locked => 0,
	    Password => undef,
	    ProjectID => undef,
	    DB => undef,
	   };

  # create the object (else we cant use accessor methods)
  my $object = bless $db, $class;

  # Populate the object by invoking the accessor methods
  # Do this so that the values can be processed in a standard
  # manner. Note that the keys are directly related to the accessor
  # method name
  for (qw/Password ProjectID/) {
    my $method = lc($_);
    $object->$method( $args{$_} ) if exists $args{$_};
  }

  # Check the DB handle
  $object->_dbhandle( $args{DB} ) if exists $args{DB};

  return $object;
}


=back

=head2 Accessor Methods

=over 4

=item B<projectid>

The project ID associated with this object.

  $pid = $db->projectid;
  $db->projectid( "M01BU53" );

All project IDs are upper-cased automatically.

=cut

sub projectid {
  my $self = shift;
  if (@_) {
    $self->{ProjectID} = uc(shift);
  }
  return $self->{ProjectID};
}

=item B<password>

The password associated with this object.

 $passwd = $db->password;
 $db->password( $passwd );

=cut

sub password {
  my $self = shift;
  if (@_) { $self->{Password} = shift; }
  return $self->{Password};
}

=item B<_locked>

Indicate whether the system is currently locked.

  $locked = $db->_locked();
  $db->_locked(1);

=cut

sub _locked {
  my $self = shift;
  if (@_) { $self->{Locked} = shift; }
  return $self->{Locked};
}

=item B<_intrans>

Indicate whether we are in a transaction or not.

  $intrans = $db->_intrans();
  $db->_intrans(1);

Contains the total number of transactions entered into by this
instance. Must be zero or positive.

=cut

sub _intrans {
  my $self = shift;
  if (@_) { 
    my $c = shift;
    $c = 0 if $c < 0;
    $self->{InTrans} = $c;
  }
  return $self->{InTrans};
}


=item B<_dbhandle>

Returns database handle associated with this object (the thing used by
C<DBI>).  Returns C<undef> if no connection object is present.

  $dbh = $db->_dbhandle();

Takes a database connection object (C<OMP::DBbackend> as argument in
order to set the state.

  $db->_dbhandle( new OMP::DBbackend );

If the argument is C<undef> the database handle is cleared.

If the method argument is not of the correct type an exception
is thrown.

=cut

sub _dbhandle {
  my $self = shift;
  if (@_) { 
    my $db = shift;
    if (UNIVERSAL::isa($db, "eSTAR::Database::DBbackend")) {
      $self->{DB} = $db;
    } elsif (!defined $db) {
      $self->{DB} = undef;
    } else {
      croak "Attempt to set database handle in eSTAR::Database::BaseDB using incorrect class");
    }
  }
  my $db = $self->{DB};
  if (defined $db) {
    return $db->handle;
  } else {
    return undef;
  }
}


=item B<db>

Retrieve the database connection (as an C<OMP::DBbackend> object)
associated with this object.

  $dbobj = $db->db();
  $db->db( new OMP::DBbackend );

=cut

sub db {
  my $self = shift;
  if (@_) { $self->_dbhandle( shift ); }
  return $self->{DB};
}

=back

=head2 DB methods

=over 4

=item B<_db_begin_trans>

Begin a database transaction. This is defined as something that has
to happen in one go or trigger a rollback to reverse it.

This method is delegated to C<OMP::DBbackend>.

=cut

sub _db_begin_trans {
  my $self = shift;

  my $db = $self->db
    or croak "Database connection not valid";

#  OMP::General->log_message( "Begin DB transaction",
#			     OMP__LOG_DEBUG );
  $db->begin_trans;

  # Keep a per-class count so that we can control
  # our destructor
  $self->_inctrans;

#  OMP::General->log_message( "Begun DB transaction",
#			     OMP__LOG_DEBUG );

}

=item B<_db_commit_trans>

Commit the transaction. This informs the database that everthing
is okay and that the actions should be finalised.

This method is delegated to C<OMP::DBbackend>.

=cut

sub _db_commit_trans {
  my $self = shift;

  my $db = $self->db
    or croak "Database connection not valid";

#  OMP::General->log_message( "Commit DB transaction",
#			     OMP__LOG_DEBUG );
  $db->commit_trans;

  # Keep a per-class count so that we can control
  # our destructor
  $self->_dectrans;

#  OMP::General->log_message( "Committed DB transaction",
#			     OMP__LOG_DEBUG );

}

=item B<_db_rollback_trans>

Rollback (ie reverse) the transaction. This should be called if
we detect an error during our transaction.

This method is delegated to C<OMP::DBbackend>.

This method triggers a full rollback of the entire transaction
regradless of whether other classes are using the transaction.
This is meant to be a feature!

=cut

sub _db_rollback_trans {
  my $self = shift;

  my $db = $self->db
    or croak "Database connection not valid";

#  OMP::General->log_message( "Rolling back DB transaction",
#			     OMP__LOG_DEBUG );
  $db->rollback_trans;

  # Reset the counter
  $self->_intrans(0);

#  OMP::General->log_message( "Rolled back DB transaction",
#			     OMP__LOG_DEBUG );

}

=item B<_inctrans>

Increment the transaction count by one.

=cut

sub _inctrans {
  my $self = shift;
  my $transcount = $self->_intrans;
  $self->_intrans( ++$transcount );
}

=item B<_dectrans>

Decrement the transaction count by one. Can not go lower than zero.

=cut

sub _dectrans {
  my $self = shift;
  my $transcount = $self->_intrans;
  $self->_intrans( --$transcount );
}



=item B<_dblock>

Lock the MSB database tables (ompobs and ompmsb but not the project table)
so that they can not be accessed by other processes.

NOT IMPLEMENTED.

=cut

sub _dblock {
  my $self = shift;
  $self->_locked(1);
  return;
}

=item B<_dbunlock>

Unlock the system. This will allow access to the database tables and
file system.

For a transaction based database this is a nullop since the lock
is automatically released when the transaction is committed.

NOT IMPLEMENTED.

=cut

sub _dbunlock {
  my $self = shift;
  if ($self->_locked()) {
    $self->_locked(0);
  }
}

=item B<_db_findmax>

Find the maximum value of a column in the specified table using
the supplied WHERE clause.

  $max = $db->_db_findmax( $table, $column, $clause);

The WHERE clause is optional (and should not include the "WHERE").

=cut

sub _db_findmax {
  my $self = shift;
  my $table = shift;
  my $column = shift;
  my $clause = shift;

  # Construct the SQL
  my $sql = "SELECT max($column) FROM $table ";
  $sql .= "WHERE $clause" if $clause;

#  OMP::General->log_message( "FindingMax: $sql", OMP__LOG_DEBUG );

  # Now run the query
  my $dbh = $self->_dbhandle;
  croak "Database handle not valid" unless defined $dbh;

  my $sth = $dbh->prepare( $sql )
    or croak "Error preparing max SQL statment";

  $sth->execute
    or croak "DB Error executing max SQL: $DBI::errstr";

  my $max = ($sth->fetchrow_array)[0];
#  OMP::General->log_message( "FoundMax: ". (defined $max ? $max:0), OMP__LOG_DEBUG );

  return  ( defined $max ? $max : 0 );

}

=item B<_db_insert_data>

Insert an array of data values into a database table.

  $db->_db_insert_data( $table, @data );

It is assumed that the data is in the array in the same order
it appears in the database table [this method does not support
named inserts].

If an entry in the data array contains a reference to a hash
(rather than a scalar) it is assumed that this indicates
a TEXT field (which must be inserted in a different manner
to normal fields) and must have the following keys:

  TEXT => the text to be inserted
  COLUMN  => the name of the column

=cut

sub _db_insert_data {
  my $self = shift;
  my $table = shift;
  my @data = @_;

  # Now go through the data array building up the placeholder sql
  # deciding which fields can be stored immediately and which must be
  # insert as text fields

  # Sybase has a special routine for storing large text fields
  # Otherwise try to use the actual INSERT command
  my $has_write_text = $self->db->has_writetext;

  # Some dummy text field that we can replace later
  # Have something that ends in a number so that ++ will
  # work for us in a logical way
  my $dummytext = 'pwned!1';

  # The insert place holder SQL
  my $placeholder = '';

  # Data to store now
  my @toinsert;

  # Data to store later
  my @textfields;
  for my $column (@data) {

    # Prepend a comma
    # if we have already stored something in the variable
    $placeholder .= "," if $placeholder;

    # Plain text
    if (not ref($column)) {

      # the data we will insert immediately
      push(@toinsert, $column);

      # Add a placeholder (the comma should be in already)
      $placeholder .= "?";

    } elsif (ref($column) eq "HASH"
	     && exists $column->{TEXT}
	     && exists $column->{COLUMN}) {

			if ($has_write_text) {
        # Use the optimized non-truncating writetext function

        # Add the dummy text to the hash
        $column->{DUMMY} = $dummytext;

        # store the information for later
        # including the dummy string
        push(@textfields, $column);

        # Update the SQL placeholder
        $placeholder .= "'$dummytext'";

        # Update the dummy string for next time
        $dummytext++;

      } else {
        # Put this in the INSERT directly
        push(@toinsert, $column->{TEXT});
        $placeholder .= "?";
      }

    } else {
      croak "Do not understand how to insert data of class '".
        ref($column) ."' into a database";
    }
  }

  # Construct the SQL
  my $sql = "INSERT INTO $table VALUES ($placeholder)";

#  OMP::General->log_message( "Inserting DB data and retrieving handle",
#           OMP__LOG_DEBUG );

  # Get the database handle
  my $dbh = $self->_dbhandle or croak "Database handle not valid";

#  OMP::General->log_message( "Inserting DB data: $sql", OMP__LOG_DEBUG );

  # Insert the easy data
  $dbh->do($sql,undef,@toinsert)
    or croak "Error inserting data into table $table [$sql]: $DBI::errstr";

#  OMP::General->log_message( "Inserted easy data.", OMP__LOG_DEBUG );

  # Now the text data
  for my $textdata ( @textfields ) {
    my $text = $textdata->{TEXT};
    my $dummy = $textdata->{DUMMY};
    my $col = $textdata->{COLUMN};

#    OMP::General->log_message( "Inserting DB text data column: $col",
#             OMP__LOG_DEBUG );

    # Need to double up quotes to escape them in SQL
    # Since we are quoting $text with a single quote
    # we need to double up single quotes
    $text =~ s/\'/\'\'/g;

    # Now replace the dummy text using writetext
    $dbh->do("declare \@val varbinary(16)
select \@val = textptr($col) from $table where $col like \"$dummy\"
writetext $table.$col \@val '$text'")
      or croak "Error inserting text data into table '$table', column '$col' into database: ". $dbh->errstr;

#    OMP::General->log_message( "Text data inserted.", OMP__LOG_DEBUG );

  }

#  OMP::General->log_message( "Inserted DB data", OMP__LOG_DEBUG );
}

=item B<_db_retrieve_data_ashash>

Retrieve data from a database table as a reference to
an array containing references to hashes for each row retrieved.
Requires the SQL to be used for the query.

 $ref = $db->_db_retrieve_data_ashash( $sql );

Additional arguments are assumed to be "bind values" and are
passed to the DBI method directly.

 $ref = $db->_db_retrieve_data_ashash( $sql, @bind_values );

=cut

sub _db_retrieve_data_ashash {
  my $self = shift;
  my $sql = shift;

  # Get the handle
  my $dbh = $self->_dbhandle
    or croak "Database handle not valid";

#  OMP::General->log_message( "SQL retrieval: $sql", OMP__LOG_DEBUG );

  # Run query
  my $ref = $dbh->selectall_arrayref( $sql, { Columns=>{} },@_)
    or croak "Error retrieving data using [$sql]:" . $dbh->errstr;

  # Check to see if we only got a partial return array
  croak ( "Only retrieved partial dataset: " . $dbh->errstr )
    if $dbh->err;

#  OMP::General->log_message("Data retrieved: " . (scalar @$ref) .
#			    " rows match", OMP__LOG_DEBUG);

  # Return the results
  return $ref;
}

=item B<_db_update_data>

Update the values of specified columns in the table given the
supplied clause.

  $db->_db_update_data( $table, \%new, $clause);

The table name must be supplied. The second argument contains a hash
where the keywords should match the columns to be changed and the
values should be the new values to insert.  The WHERE clause should be
supplied as SQL (no attempt is made to automatically generate this
information from a hash [yet) and should not include the "WHERE". The
WHERE clause can be undefined if you want the update to apply to all
columns.

=cut

sub _db_update_data {
  my $self = shift;

  my $table = shift;
  my $change = shift;
  my $clause = shift;

  # Add WHERE
  $clause = "WHERE ". $clause if $clause;

  # Get the handle
  my $dbh = $self->_dbhandle or croak "Database handle not valid";

  # Loop over each key
  for my $col (keys %$change) {

    # check for text and quote if needed
    # If "undef" we need to use NULL
    if (defined $change->{$col}) {
      $change->{$col} = "'" . $change->{$col} . "'"
      if $change->{$col} =~ /[A-Za-z:]/;
    } else {
      $change->{$col} = "NULL";
    }

    # Construct the SQL
    my $sql = "UPDATE $table SET $col = " . $change->{$col} . " $clause ";

#    OMP::General->log_message( "Updating DB row: $sql", OMP__LOG_DEBUG );

    # Execute the SQL
    $dbh->do($sql)
      or croak ("Error updating [$sql]: " .$dbh->errstr);

#    OMP::General->log_message("Row updated.", OMP__LOG_DEBUG);

  }

}

=item B<_db_delete_data>

Delete the rows in the table given the
supplied clause.

  $db->_db_delete_data( $table, $clause);

The table name must be supplied. The WHERE clause should be
supplied as SQL (no attempt is made to automatically generate this
information from a hash [yet) and should not include the "WHERE". The WHERE
clause is not optional.

=cut

sub _db_delete_data {
  my $self = shift;

  my $table = shift;
  my $clause = shift;
  croak ("db_delete_data: Must supply a WHERE clause") unless $clause;

  # Add WHERE
  $clause = "WHERE ". $clause;

  # Get the handle
  my $dbh = $self->_dbhandle
    or croak ("Database handle not valid");

  # Construct the SQL
  my $sql = "DELETE FROM $table $clause";

#  OMP::General->log_message( "Deleting DB data: $sql", OMP__LOG_DEBUG );

  # Execute the SQL
  $dbh->do($sql) or croak("Error deleting [$sql]: " .$dbh->errstr);

#  OMP::General->log_message("Row deleted.", OMP__LOG_DEBUG );

}

=item B<_db_delete_project_data>

Delete all rows associated with the current project
from the specified tables.

  $db->_db_delete_project_data( @TABLES );

It is assumed that the current project is stored in table column
"projectid".  This is a thin wrapper for C<_db_delete_data> but
without having to specify the SQL.

Returns immediately if no project id is defined.

=cut

sub _db_delete_project_data {
  my $self = shift;

  # Get the project id
  my $proj = $self->projectid;
  return unless defined $proj;

  # Loop over each table
  for (@_) {
    $self->_db_delete_data( $_, "projectid = '$proj'");
  }

}


=back

=item B<DESTROY>

When this object is destroyed we need to roll back the transactions
started by this object. Since we do not know whether we are being
destroyed because we have simply gone out of scope (eg this class
instantiated a new DB class for a short while) or because of an error,
only rollback transactions if the internal count of transactions in
this class matches the active transaction count in the
C<OMP::DBbackend> object referenced by this object.

This relies on that object still being in existence (in which
case a rollback here is too late anyway).

If the counts do not match (hopefully because it has more than we
know about) set our count to zero and decrement the C<OMP::DBbackend>
count by the required amount.

=cut

sub DESTROY {
  my $self = shift;

  # Get the OMP::DBbackend
  my $db = $self->db;

  # it may not exist by now (depending on object destruction
  # order)
  if ($db) {

    # Now get the internal count
    my $thiscount = $self->_intrans;

    # Get the external count
    my $thatcount = $db->trans_count;

    if ($thiscount == $thatcount) {
      # fair enough. Rollback (doesnt matter if both == 0)
#      OMP::General->log_message("DESTROY: Rollback transaction $thiscount",
#       OMP__LOG_DEBUG);
      $self->_db_rollback_trans;

    } elsif ($thiscount < $thatcount) {

      # Simply decrement this and that until we hit zero
      while ($thiscount > 0) {
        $self->_dectrans;
        $db->_dectrans;
        $thiscount--;
      }

    } else {

      die "Somehow the internal transaction count ($thiscount) is bigger than the DB handle count ($thatcount). This is scary.\n";
    }
  }
}

=back

=head1 SEE ALSO

For related classes see C<OMP::MSBDB>, C<OMP::ProjDB> and
C<OMP::FeedbackDB>.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>
Based on Joint Astronomy Centre Observation Management Project code
written by Tim Jenness (E<lt>t.jenness@jach.hawaii.eduE<gt>).

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
