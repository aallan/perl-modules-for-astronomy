
use strict;

# Loading these here defeats the purpose of the use_ok in
# the caller
use Astro::Catalog::Star; # for DR2AS

=head1 NAME

helper - Test helper routines

=head1 SYNOPSIS

  compare_star( $star1, $star2 );
  compare_catalog( $cat1, $cat2 );


=head1 DESCRIPTION

Help routine for the test suite that are shared amongst more than
one test but that are not useful outside of the context of the test
suite.

=head1 FUNCTIONS

=over 4

=item B<compare_catalog>

Compare 2 catalogs.

  compare_catalog( $cat1, $cat2 );

where $cat1 is the catalogue to be tested, and $cat2 is the
reference catalogue.

Catalogs must be C<Astro::Catalog> objects. Currently simply compares
each star in teh catalog, without forcing a new sort (so order is
important).

=cut

sub main::compare_catalog {
  my ($cmpcat, $refcat) = @_;

  isa_ok( $refcat, "Astro::Catalog", "Check ref catalog type" );
  isa_ok( $cmpcat, "Astro::Catalog", "Check cmp catalog type" );

  # Star count
  is( $cmpcat->sizeof(), $refcat->sizeof(), "compare star count" );

  for my $i (0.. ($refcat->sizeof()-1)) {
    compare_star( $cmpcat->starbyindex($i), $refcat->starbyindex($i));
  }
}

=item B<compare_star>

Compare the contents of two stars. Currently compares position, ID
and filters.

  compare_star( $star1, $star2 );

where $star1 is the star to be tested and $star2 is the
reference star.

=cut

sub compare_star {
  my ($cmpstar, $refstar) = @_;

  isa_ok( $refstar, "Astro::Catalog::Star", "Check ref star type");
  isa_ok( $cmpstar, "Astro::Catalog::Star", "Check cmp star type");

  is( $cmpstar->id(), $refstar->id(), "compare star ID" );

  # Distance is okay if we are within 1 arcsec
  my $maxsec = 1;
  my $radsep = $refstar->coords->distance( $cmpstar->coords );

  if (!defined $radsep) {
    # did not get any value. Too far away
    ok( 0, "Error calculating star separation. Too far?");
  } else {
    # check that DR2AS is defined, at one stage it was not
    my $check = Astro::Catalog::Star::DR2AS;
    die "Error obtaining DR2AS" if not defined $check;
    my $assep = $radsep * Astro::Catalog::Star::DR2AS;
    ok( $assep < $maxsec, "compare distance between stars ($assep<$maxsec arcsec)" );
  }



  is( $cmpstar->ra(), $refstar->ra(), "compare star RA" );
  is( $cmpstar->dec(), $refstar->dec(), "Compare star Dec" );

  my @dat_filters = $cmpstar->what_filters();
  my @net_filters = $refstar->what_filters();
  foreach my $filter ( 0 ... $#net_filters ) {
    is( $dat_filters[$filter], $net_filters[$filter],"compare filter $filter" );
    is( $cmpstar->get_magnitude($dat_filters[$filter]),
	$refstar->get_magnitude($net_filters[$filter]),
	"compare magnitude $filter");
    is( $cmpstar->get_errors($dat_filters[$filter]),
	$refstar->get_errors($net_filters[$filter]),
	"compare magerr $filter");
  }

  my @dat_cols = $cmpstar->what_colours();
  my @net_cols = $refstar->what_colours();
  foreach my $col ( 0 ... $#net_cols ) {
    is( $dat_cols[$col], $net_cols[$col],"compare color $col" );
    is( $cmpstar->get_colour($dat_cols[$col]), 
	$refstar->get_colour($net_cols[$col]),
	"compare value of color $col");
    is( $cmpstar->get_colourerr($dat_cols[$col]), 
	$refstar->get_colourerr($net_cols[$col]),"compare color error $col" );
  }

  is( $cmpstar->quality(), $refstar->quality(), "check quality" );
  is( $cmpstar->field(), $refstar->field(), "check field" );
  is( $cmpstar->gsc(), $refstar->gsc() , "check GSC flag");
  is( $cmpstar->distance(), $refstar->distance() ,"check distance");
  is( $cmpstar->posangle(), $refstar->posangle(), "check posangle" );

}

=back

=head1 USAGE

Requires that your tests are written using C<Test::More>
and that the top of each test includes the code:

 chdir "t" if -d "t";
 do "helper.pl" or die "Error reading test functions: $!";

=head1 SEE ALSO

L<Test::More>

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modificiations Copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;
