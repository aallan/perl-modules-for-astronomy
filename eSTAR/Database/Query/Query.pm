package eSTAR::Database::Query;

use 5.006;
use strict;
use warnings;

use Carp;

use base qw/ eSTAR::Database::DBQuery /;

our $VERSION = '0.01';

our $OBJECTTABLE = 'tblObject OBJ';
our $MEASUREMENTTABLE = 'tblMeasurement MEA';
our $OBSERVATIONTABLE = 'tblObservation OBS';
our $MEASOBSJOINTABLE = 'tblMeasObs MEAOBS';
my $RAD_TO_DEG = 180 / ( atan2( 1, 1 ) * 4 );

our %primary_keys = ( $OBJECTTABLE => 'pklngObjectID',
                      $MEASUREMENTTABLE => 'pklngMeasurementID',
                      $OBSERVATIONTABLE => 'pklngObservationID',
                      $MEASOBSJOINTABLE => 'pklngMeasObsID',
                    );
our %jointable = ( $OBJECTTABLE => { $MEASUREMENTTABLE => 'OBJ.pklngObjectID = MEA.fklngObjectID' },
                   $MEASUREMENTTABLE => { $MEASOBSJOINTABLE => 'MEA.pklngMeasurementID = MEAOBS.fklngMeasurementID'},
                   $OBSERVATIONTABLE => { $MEASOBSJOINTABLE => 'OBS.pklngObservationID = MEAOBS.fklngObservationID'},
                 );

our %tables = ( all => [ $OBJECTTABLE, $MEASUREMENTTABLE, $OBSERVATIONTABLE, $MEASOBSJOINTABLE ] );

our $DATETIMECOLUMN = 'MEA.datetime';

my %lut = (
           # XML tag -> column name
           HTMid => 'OBJ.HTMid',
           date => 'MEA.datetime',
          );

=head1 METHODS

=head2 General Methods

=over 4

=item B<sql>

Returns an SQL representation of the XML Query using the specified
database table.

  $sql = $query->sql( $with_flux );

Returns undef if the query could not be formed. The only argument
is optional and, if set to false, returns SQL that will only query
the tblObject table. Defaults to true, so that the SQL will query
all tables.

=cut

sub sql {
  my $self = shift;

  croak "sql method invoked with incorrect number of arguments"
    unless scalar( @_ ) <= 1;

  my $with_flux = shift;
  if( ! defined( $with_flux ) ) {
    $with_flux = 1;
  }

  my $subsql;
  if( $with_flux ) {
    $subsql = $self->_qhash_tosql( );
  } else {
    $subsql = $self->_qhash_tosql( [ qw/ date waveband / ] );
  }

  # Replace column names in the subsql with the proper table names.
  foreach my $column ( keys %lut ) {
    $subsql =~ s/$column/$lut{$column}/g if $subsql;
  }
  $subsql = " WHERE " . $subsql if $subsql;

  my $sql;
  if( $with_flux ) {

    # Need to append the join criteria.
    $subsql .= " AND " . $jointable{$OBJECTTABLE}{$MEASUREMENTTABLE};
    $subsql .= " AND " . $jointable{$MEASUREMENTTABLE}{$MEASOBSJOINTABLE};
    $subsql .= " AND " . $jointable{$OBSERVATIONTABLE}{$MEASOBSJOINTABLE};

    # Now generate the SQL.
    $sql = "SELECT *, CONVERT(CHAR, $DATETIMECOLUMN, 109) AS 'longmeasurementdate' FROM $OBJECTTABLE, $MEASUREMENTTABLE, $OBSERVATIONTABLE, $MEASOBSJOINTABLE $subsql";

    # Sort this, first by the object ID and second by the flux measurement
    # timestamp.
    $sql .= " ORDER BY OBJ.pklngObjectID, MEA.datetime";
  } else {
    $sql = "SELECT * FROM $OBJECTTABLE $subsql ORDER BY OBJ.pklngObjectID";
  }

  return "$sql\n";
}

=begin __PRIVATE__METHODS__

=item B<_root_element>

Class method that returns the name of the XML root element to be
located in the query XML.

Returns "Query" by default.

=cut

sub _root_element {
  return "Query";
}

=item B<_post_process_hash>

Do table-specific post processing of the query hash.

  $query->_post_process_hash( \%hash );

=cut

sub _post_process_hash {
  my $self = shift;
  my $hash_ref = shift;

  # Do the generic post-processing.
  $self->SUPER::_post_process_hash( $hash_ref );

  # Loop over each key.
  for my $key ( keys %$hash_ref ) {

    # Skip over private keys.
    next if $key =~ /^_/;

    # We don't have any processing in place yet.
  }

}

=back

=head1 SEE ALSO

L<eSTAR::Database::DBQuery>

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

Based on Joint Astronomy Centre Observation Management Project code written
by Tim Jenness (E<lt>t.jenness@jach.hawaii.eduE<gt>).

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

