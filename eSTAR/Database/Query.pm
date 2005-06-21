package eSTAR::Database::Query;

use 5.006;
use strict;
use warnings;

use Carp;

use base qw/ eSTAR::Database::DBQuery /;

our $VERSION = '0.01';

=head1 METHODS

=head2 General Methods

=over 4

=item B<sql>

Returns an SQL representation of the XML Query using the specified
database table.

  $sql = $query->sql( $eSTARtable );

Returns undef if the query could not be formed.

=cut

sub sql {
  my $self = shift;

  croak "sql method invoked with incorrect number of arguments"
    unless scalar( @_ ) == 1;

  my $eSTARtable = shift;

  # Generate the WHERE clause from the query hash.
  my $subsql = $self->_qhash_to_sql();

  # If the resulting query contained anything we should prepend
  # an AND so that it fits in with the rest of the SQL. This allows
  # an empty query to work without having a naked "WHERE".
  $subsql = " WHERE " . $subsql if $subsql;

  # Now need to put this SQL into the template query
  my $sql = " SELECT * FROM $eSTARtable E $subsql";

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

