package Astro::Corlate;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Corlate

#  Purposes:
#    Object orientated interface to Astro::Corlate::Wrapper module

#  Language:
#    Perl module

#  Description:
#    This module is an object-orientated interface to the 
#    Astro::Corlate::Wrapper module, which in turn wraps the
#    Fortran 95 CORLATE sub-routine

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Corlate.pm,v 1.3 2001/12/12 06:19:19 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Corlate - Object a catalog corelation

=head1 SYNOPSIS

  use Astro::Corlate;
  
  $corlate = new Astro::Corlate( Catalogue   =>  $catalogue,
                                 Observation =>  $observation );

  # run the corelation routine
  my $status = $corlate->run_corrlate();
  
  # get the log file
  my $log = $corlate->logfile();
  
  # get the variable star catalogue
  my $variables = $corlate->variables();
  
  # fitted colour data catalogue
  my $data = $corlate->data();
  
  # fit to the colour data
  my $fit = $corlate->fit();
  
  # get probability histogram file
  my $histogram = $corlate->histogram();
  
  # get the useful information file
  my $information = $corlate->information();

=head1 DESCRIPTION

This module is an object-orientated interface to the Astro::Corlate::Wrapper
module, which in turn wraps the Fortran 95 CORLATE sub-routine. It will save
returned files into the ESTAR_DATA directory or to TMP if the ESTAR_DATA
environment variable is not defined.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::Corlate::Wrapper qw / corlate /;
use File::Spec;
use Carp;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Corlate.pm,v 1.3 2001/12/12 06:19:19 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::Corlate( Reference   =>  $catalogue,
                               Observation =>  $observation );

returns a reference to an Corlate object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DATADIR => undef,
                      FILES   => {} }, $class;

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

   0 = Success
  -1 = Failed to open catalog file
  -2 = Failed to open observation file
  -3 = Too few stars paired between catalogues
  -4 = Observation and Reference catalogues not supplied

=cut

sub run_corlate {
  my $self = shift;


}

# O T H E R   M E T H O D S ------------------------------------------------

sub reference {}
sub observation {}

sub logfile {}
sub variables {}
sub data {}
sub fit {}
sub histogram {}
sub information {}

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

  # CONFIGURE DEFAULTS
  # ------------------
  
  # Grab something for DATA directory
  if ( defined $ENV{"ESTAR_DATA"} ) {
     if ( opendir (DIR, File::Spec->catdir($ENV{"ESTAR_DATA"}) ) ) {
        # default to the ESTAR_DATA directory
        $self->{DATADIR} = File::Spec->catdir($ENV{"ESTAR_DATA"});
        closedir DIR;
     } else {
        # Shouldn't happen?
       croak("Cannot open $ENV{ESTAR_DATA} for incoming files.");
     }        
  } elsif ( opendir(TMP, File::Spec->tmpdir() ) ) {
        # fall back on the /tmp directory
        $self->{DATADIR} = File::Spec->tmpdir();
        closedir TMP;
  } else {
     # Shouldn't happen?
     croak("Cannot open any directory for incoming files.");
  }     
  
  # DEFAULT FILENAMES
  ${$self->{FILES}}{"reference"} = 
             File::Spec->catfile( $self->{DATADIR}, 'archive.cat' );
  ${$self->{FILES}}{"observation"} = 
             File::Spec->catfile( $self->{DATADIR}, 'new.cat' );
  ${$self->{FILES}}{"logfile"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate.log' ); 
  ${$self->{FILES}}{"variables"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate.cat' ); 
  ${$self->{FILES}}{"data"} = 
             File::Spec->catfile( $self->{DATADIR}, 'colfit.cat' );
  ${$self->{FILES}}{"fit"} = 
             File::Spec->catfile( $self->{DATADIR}, 'colfit.fit' );
  ${$self->{FILES}}{"histogram"} = 
             File::Spec->catfile( $self->{DATADIR}, 'hist.dat' ); 
  ${$self->{FILES}}{"information"} = 
             File::Spec->catfile( $self->{DATADIR}, 'info.dat' );       

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Reference Observation / ) {
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
