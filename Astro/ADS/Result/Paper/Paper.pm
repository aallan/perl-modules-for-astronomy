package Astro::ADS::Result::Paper;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::ADS::Result:;Paper

#  Purposes:
#    Perl wrapper for the ADS database

#  Language:
#    Perl module

#  Description:
#    This module wraps the ADS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Paper.pm,v 1.1 2001/10/30 17:18:37 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::ADS::Result::Paper - A individual paper in an Astro::ADS::Result object

=head1 SYNOPSIS

  $query = new Astro::ADS::Result::Paper( Bibcode   => $bibcode,
                                          Title     => $title,
                                          Authors   => @authors,
                                          Affil     => @affil,
                                          Journal   => $journal_refernce,
                                          Published => $published,
                                          Origin    => $journal,
                                          Links     => @associated_links,
                                          URL       => $abstract_url,
                                          Abstract  => $abstract );

=head1 DESCRIPTION

Stores meta-data about an individual paper in the Astro::ADS::Result object
returned by an Astro::ADS::Query object.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;


'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Paper.pm,v 1.1 2001/10/30 17:18:37 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $paper = new Astro::ADS::Result::Paper( Bibcode   => $bibcode,
                                          Title     => $title,
                                          Authors   => @authors,
                                          Affil     => @affil,
                                          Journal   => $journal_refernce,
                                          Published => $published,
                                          Origin    => $journal,
                                          Links     => @outbound_links,
                                          URL       => $abstract_url,
                                          Abstract  => $abstract  );

returns a reference to an ADS paper object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { BIBCODE   => undef,
                      TITLE     => undef,
                      AUTHORS   => [],
                      AFFIL     => [],
                      JOURNAL   => undef,
                      PUBLISHED => undef,
                      ORIGIN    => undef,
                      LINKS     => [],
                      URL       => undef,
                      ABSTRACT  => undef}, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

} m,

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $paper->configure( %options );

Takes a hash as argument with the following keywords:

=over 4

=item B<Bibcode>

The bibcode of the paper (see ADS for details of the article bibcode standard).

=item B<Title>

The title of the paper.

=item B<Authors>

The authors of the paper.

=item B<Affil>

Institute affiliations associated with each author.

=item B<Journal>

The journal reference for the paper, e.g. MNRAS, 279, 1345-1348 (1996)

=item B<Published>

Month and year published, e.g. 4/1996

=item B<Origin>

Origin of citation in ADS archive, this is not necessarily the journal, the
origin of the entry could be AUTHOR, or ADS or SIMBAD for instance.

=item B<Links>

Available type of links relating to the paper, e.g. SIMBAD objects mentioned
in the paper, References, Citations, Table of Contents of the Journal etc.

=item B<URL>

URL of the ADS page of the paper

=item B<Abstract>

Either the abstract text or a URL of the scanned abstract (for older papers).

=back

Does nothing if these keys are not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;
  
  # Loop over the allowed keys storing the values
  # in the object if they exist  
  for my $key (qw / Bibcode Title Authors Affil Journal Published
                   Origin Links URL Abstract /) {
      my $method = lc($key);
      $self->$method( $args{$key}) if exists $args{$key};
  }  

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
