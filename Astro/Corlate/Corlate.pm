package Astro::Corlate;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Corlate

#  Purposes:
#    Object orientated interface to Astro::Corlate::Wrapper

#  Language:
#    Perl module

#  Description:
#    This module is an object-orientated interface to the 
#    Astro::Corlate::Wrapper module, which in turn wraps the
#    Fortran 95 CORLATE sub-routine

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Corlate.pm,v 1.1 2001/12/07 00:01:27 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Corlate - Object a catalog corelation

=head1 SYNOPSIS

  $corlate = new Astro::Corlate( Catalog     =>  $catalog,
                                 Observation =>  $observation );

  my $status = $corlate->run_corrlate();
  
  my $log_file = $corlate->logfile();
  my $variables_file = $corlate->variables();
  my $fit_data_file = $corlate->fitdata();
  my $fit_to_data_file = $corlate->fit();
  my $histogram_file = $corlate->histogram();
  my $output_file = $corlate->output();

=head1 DESCRIPTION

This module is an object-orientated interface to the Astro::Corlate::Wrapper
module, which in turn wraps the Fortran 95 CORLATE sub-routine

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::Corlate::Wrapper qw / corlate /;
use Carp;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Corlate.pm,v 1.1 2001/12/07 00:01:27 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::Corlate( );

returns a reference to an Corlate object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless {  }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# R U N  M E T H O D --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<run_corlate>

Runs the catalog corelation subroutine

   $status = $corlate->run_corlate();

returns a status value

   0 = success
  -1 = failed to open catalog file
  -2 = failed to open observation file
  -3 = Too few stars paired between catalogues

=cut

sub run_corlate {
  my $self = shift;


}

# O T H E R   M E T H O D S ------------------------------------------------


# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $corlate->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# L A S T  O R D E R S ------------------------------------------------------

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# T I M E   A T   T H E   B A R  --------------------------------------------

1;                                                                  

__END__
