package Astro::ADS::Result;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::ADS::Result

#  Purposes:
#    Perl wrapper for the ADS database

#  Language:
#    Perl module

#  Description:
#    This module wraps the ADS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Result.pm,v 1.1 2001/10/30 17:18:37 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::ADS::Result - Results from an ADS Query

=head1 SYNOPSIS

  $qery = new Astro::ADS::Result( ... );

=head1 DESCRIPTION


=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;


'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Result.pm,v 1.1 2001/10/30 17:18:37 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::ADS::Result( ... );

returns a reference to an ADS query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RESULTS => {} }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

} m,

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as argument

  $result->configure( ... );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

}


# T I E D   I N T E R F A C E -----------------------------------------------

=back

=head1 TIED INTERFACE

The C<Astro::ADS::Result> object can also be tied to a hash

   use Astro::ADS::Query;

   $query = new Astro::ADS::Query( ... );
   $result = $query->querydb();
 
   tie %hash, "Astro::ADS::Result", $result 

   $value = $hash{$keyword};
   $hash{$keyword} = $value;

   print "keyword $keyword is present" if exists $hash{$keyword};

   foreach my $key (keys %hash) {
      print "$key = $hash{$key}\n";
   }


=cut

# constructor
sub TIEHASH {
  my ( $class, $obj, %options ) = @_;
  return bless $obj, $class;  
}

# fetch key and value pair
sub FETCH {
  my ($self, $key) = @_;
  
  
}

# store key and value pair
sub STORE {
  my ($self, $keyword, $value) = @_;
 

}

# reports whether a key is present in the hash
sub EXISTS {
  my ($self, $keyword) = @_;
 
}

# deletes a key and value pair
sub DELETE {
  my ($self, $keyword) = @_;

}

# empties the hash
sub CLEAR {
  my $self = shift; 
  
}

# implements keys() and each()
sub FIRSTKEY {
  my $self = shift;
 
}

# implements keys() and each()
sub NEXTKEY {
  my ($self, $keyword) = @_; 
  
}

# garbage collection
# sub DESTROY { }

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
