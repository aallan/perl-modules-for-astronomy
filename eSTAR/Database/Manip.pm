package eSTAR::Database::Manip;

=head1 NAME

eSTAR::Database::Manip - eSTAR object database manipulation

=head1 SYNOPSIS

  use eSTAR::Database::Manip;

  $db = new eSTAR::Database::Manip( DB => new eSTAR::Database::DBbackend );

  $db->add_catalog( $catalog );
  $catalog = $db->cone_search( coords => $coords,
                               radius => $radius,
                               date_range => $range );

  $catalog = $db->queryDB( $query );

=head1 DESCRIPTION

=cut

use 5.006;
use warnings;
use strict;

use Carp;

use eSTAR::Database::Query;

use Astro::Catalog;

use base qw/ eSTAR::Database::BaseDB /;

our $VERSION = '0.01';
our $OBJECTTABLE = 'tblObject';
our $MEASUREMENTTABLE = 'tblMeasurement';
our $OBSERVATIONTABLE = 'tblObservation';
our $MEASOBSJOINTABLE = 'tblMeasObs';

our %primary_keys = ( $OBJECTTABLE => 'pkintObject',
                      $MEASUREMENTTABLE => 'pkintMeasurement',
                      $OBSERVATIONTABLE => 'pkintObservation',
                      $MEASOBSJOINTABLE => 'pkintMeasObs',
                    );

=head1 METHODS

=head2 Public Methods

=over 4

=item B<add_catalog>

Adds a catalog to the database.

  $db->add_catalog( $catalog );

The supplied parameter is an C<Astro::Catalog> object.

=cut

sub add_catalog {
  my $self = shift;
print "in add_catalog\n";
  my $catalog = shift;

  # Make sure our catalog is okay.
  if( ! defined( $catalog ) ) {
    print "catalog not defined\n";
    return;
  }
  if( ! UNIVERSAL::isa( $catalog, "Astro::Catalog" ) ) {
    croak "Argument to eSTAR::Database::Manip->add_catalog() must be an Astro::Catalog object";
  }

  # Lock the database (since we are writing)
print "beginning transaction\n";
  $self->_db_begin_trans;
print "locking db\n";
  $self->_dblock;

  # Write the catalog to database.
print "storing catalog\n";
  $self->_store_catalog( $catalog );

  # End the transaction.
print "unlocking db\n";
  $self->_dbunlock;
print "committing transaction\n";
  $self->_db_commit_trans;
}

=item B<cone_search>

Retrieve all objects within a given radius of a given RA and Dec.

  $catalog = $db->cone_search( coords => $coords,
                               radius => $radius,
                               date_range => $date_range );

The named parameter coords must be defined and must be an
C<Astro::Coords> object. The named parameter C<radius> must
be defined and be in units of arcseconds. The named parameter
C<date_range> is optional but must be a C<DateTime::Span> object.

This method returns an C<Astro::Catalog> object.

=cut

sub cone_search {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'coords'} ) ||
      ! UNIVERSAL::isa( $args{'coords'}, "Astro::Coords" ) ) {
    croak "coords parameter to eSTAR::Database::Manip->cone_search must be defined as an Astro::Coords object";
  }
  my $coords = $args{'coords'};

  if( ! defined( $args{'radius'} ) ) {
    croak "radius parameter to eSTAR::Database::Manip->cone_search must be defined in arcseconds";
  }
  my $radius = $args{'radius'};

  my $date_range = $args{'date_range'};

  my $catalog;

  return $catalog;
}


=item B<queryDB>

Query the database using the supplied query (supplied as a
C<eSTAR::Database::Query> object). Results are returned as
an C<Astro::Catalog> object.

  $catalog = $db->queryDB( $query );

=cut

sub queryDB {
  my $self = shift;
  my $query = shift;

  # Get the SQL.
  my $sql = $query->sql();

  # Use this SQL to query the database, returning the results
  # in an array reference.
  my $ref = $self->_db_retrieve_data_ashash( $sql );

  # Convert the data to an Astro::Catalog object.
  my $catalog = $self->_reorganize_results( $ref );

  # And return the catalog.
  return $catalog;
}

=item B<_add_item>

Add an C<Astro::Catalog::Item> object to the database. This
only adds the information to the tblObject table.

  $db->_add_item( $item );

The sole argument is mandatory and must be an
C<Astro::Catalog::Item> object.

=cut

sub _add_item {
  my $self = shift;

  my $item = shift;
  if( ! defined( $item ) ||
      ! UNIVERSAL::isa( $item, "Astro::Catalog::Star" ) ) {
    croak "Item parameter to eSTAR::Database::Manip->_add_item must be defined as an Astro::Catalog::Item object, not " . ref( $item ) . "\n";
  }

  my $radius = 5;

  my $ret_item = $self->_retrieve_item( $item->coords, $radius );
  my $item_key;
  if( defined( $ret_item ) ) {
    $item_key = $ret_item->id;
  } else {
    $item_key = $self->_retrieve_next_key( $OBJECTTABLE,
                                           $primary_keys{$OBJECTTABLE} );
    $self->_insert_item( $item, $item_key );
  }

  foreach my $fluxes ( $item->fluxes ) {

    # $fluxes is an Astro::Fluxes object. We want the Astro::Flux objects
    # that originally went into it.

    my %obsid_hash = (); # A list of all of the obsid IDs we've added
                         # to the database.

    foreach my $obsid ( $flux->obsids ) {

      # Check to see if this obsid already exists in the DB. If it
      # does, then keep its key around for future use. If it doesn't,
      # generate its key and insert it in the database.
      my $obsid_key = $self->_retrieve_obsid( $obsid );
      if( defined( $obsid_key ) ) {
        $obsid_hash{$obsid_key}++;
      } else {
        $obsid_key = $self->_retrieve_next_key( $OBSERVATIONTABLE,
                                                $primary_keys{$OBSERVATIONTABLE} );
        $self->_insert_obsid( $obsid, $obsid_key );
        $obsid_hash{$obsid_key}++;
      }
    } # All done with the obsids.

    # Retrieve the next flux ID, then insert the current flux
    # with that ID into the database, and keep the ID around
    # for future use.
    my $flux_key = $self->_retrieve_next_key( $MEASUREMENTTABLE,
                                              $primary_keys{$MEASUREMENTTABLE} );
    $self->_insert_flux( $flux, $flux_key, $item_key );

    # Now let's link them up.
    foreach my $obsid_key ( keys %obsid_hash ) {

      $self->_insert_fluxobs( $flux_key, $obsid_key );

    }
  } # Done with the fluxes.

}

=item B<_insert_flux>

Insert an C<Astro::Flux> object into the database.

  $db->_insert_flux( $flux, $flux_key, $item_key );

This method takes three mandatory arguments: the C<Astro::Flux>
object, the primary key for that object, and the primary key
of the related C<Astro::Catalog::Item> object.

=cut

sub _insert_flux {
  my $self = shift;

  my $flux = shift;
  if( ! defined( $flux ) ||
      ! UNIVERSAL::isa( $flux, "Astro::Flux" ) ) {
    croak "Must supply flux object to eSTAR::Database::Manip->_insert_flux() as an Astro::Flux object";
  }

  my $flux_key = shift;
  if( ! defined( $flux_key ) ) {
    croak "Must supply flux primary key to eSTAR::Database::Manip->_insert_flux()";
  }

  my $item_key;
  if( ! defined( $item_key ) ) {
    croak "Must supply item primary key to eSTAR::Database::Manip->_insert_flux()";
  }

  print "Will insert flux object with primary key $flux_key into database.\n";

}

=item B<_insert_fluxobs>

Insert a record to the join table joining flux measurements to
observations.

  $db->_insert_fluxobs( $flux_key, $obsid_key );

This method takes two mandatory arguments, the primary key of the
flux measurement and the primary key of the observation.

=cut

sub _insert_fluxobs {
  my $self = shift;

  my $flux_key = shift;
  if( ! defined( $flux_key ) ) {
    croak "Must supply flux primary key to eSTAR::Database::Manip->_insert_fluxobs()";
  }

  my $obsid_key = shift;
  if( ! defined( $obsid_key ) ) {
    croak "Must supply obsid primary key to eSTAR::Database::Manip->_insert_fluxobs()";
  }

  print "Will insert flux primary key $flux_key and obsid primary key $obsid_key to database.\n";

}

=item B<_insert_item>

Insert an C<Astro::Catalog::Item> object into the database.

  $db->_insert_item( $item, $item_key );

This method takes two mandatory arguments, the C<Astro::Catalog::Item>
object to insert and that item's primary key.

=cut

sub _insert_item {
  my $self = shift;

  my $item = shift;
  if( ! defined( $item ) ||
      ! UNIVERSAL::isa( $item, "Astro::Catalog::Item" ) ) {
    croak "Must supply item object to eSTAR::Database::Manip->_insert_item() as an Astro::Catalog::Item object";
  }

  my $item_key = shift;
  if( ! defined( $item_key ) ) {
    croak "Must supply item primary key to eSTAR::Database::Manip->_insert_item()";
  }

  print "Will insert item with primary key $item_key into database.\n";
}

=item B<_insert_obsid>

Insert an obsid into the database.

  $db->_insert_obsid( $obsid, $key );

This method takes two mandatory arguments, the obsid and its primary
key.

=cut

sub _insert_obsid {
  my $self = shift;

  my $obsid = shift;
  if( ! defined( $obsid ) ) {
    croak "Must supply obsid to eSTAR::Database::Manip->_insert_obsid()";
  }

  my $obsid_key = shift;
  if( ! defined( $obsid_key ) ) {
    croak "Must supply obsid primary key to eSTAR::Database::Manip->_insert_obsid()";
  }

  print "Will insert obsid $obsid with primary key $obsid_key into database.\n";
}

=item B<_retrieve_item>

Retrieve an C<Astro::Catalog::Item> object from the database.

  $item = $db->_retrieve_item( $coords, $radius );

This method takes two mandatory arguments. The first must be an
C<Astro::Coords> object denoting the centre of the search, and the
second is a radius in arcseconds.

This method returns one C<Astro::Catalog::Item> object, and will
be the one closest to the centre of the search if multiple items
happen to fall within the search radius.

=cut

sub _retrieve_item {
  my $self = shift;

  my $coords = shift;
  if( ! defined( $coords ) ||
      ! UNIVERSAL::isa( $coords, "Astro::Coords" ) ) {
    croak "Coords parameter to eSTAR::Database::Manip->_retrieve_item must be defined as an Astro::Coords object";
  }

  my $radius = shift;
  if( ! defined( $radius ) ) {
    croak "Radius parameter to eSTAR::Database::Manip->_retrieve_item must be defined in arcseconds";
  }

  my $item;

  print "Will retrieve Astro::Catalog::Item from database.\n";

  return $item;
}

=item B<_retrieve_next_key>

Returns the next available primary key for a given table.

  my $key = $db->_retrieve_next_key( $table );

Assumes that keys are integers and increment monotonically.

=cut

sub _retrieve_next_key {
  my $self = shift;

  my $table = shift;

#  my $max = $self->_db_findmax( $table, $primary_keys{$table} );
  my $max = 1;
  $max++;

  return $max;
}

=item B<_retrieve_obsid_key>

Returns the obsid's primary key if it exists in the database.

  my $key = $db->_retrieve_obsid_key( $obsid );

If the obsid doesn't exist in the database, this method returns
0.

=cut

sub _retrieve_obsid_key {
  my $self = shift;

  my $obsid = shift;
  if( ! defined( $obsid ) ) {
    return 0;
  }

  my $key;

  print "Will retrieve key for obsid $obsid\n";

  return $key;
}

=item B<_reorganize_archive>

Given the results from a database query (returned as a row
per flux measurement per object), convert this output to an
C<Astro::Catalog> object.

  $catalog = $db->_reorganize_results( $query_output );

=cut

sub _reorganize_archive {
  my $self = shift;
  my $rows = shift;

  for my $row ( @$rows ) {

    # Convert the keys to upper-case.
    my $newrow;
    for my $key ( keys %$row ) {
      my $uckey = uc( $key );
      $newrow->{$uckey} = $row->{$key};
    }

  }

}

=item B<_store_catalog>

Store the given C<Astro::Catalog> object in the database.

  $db->_store_catalog( $catalog );

=cut

sub _store_catalog {
  my $self = shift;

  my $catalog = shift; # Astro::Catalog;

  foreach my $item ( $catalog->stars ) {

    $self->_add_item( $item );

  }
}

1;
