package Astro::Catalog::Transport::REST;

=head1 NAME

Astro::Catalog::Transport::REST - A base class for REST query modules

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::Transport::REST /;


=head1 DESCRIPTION

This class forms a base class for all the query classes provided
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::Query::GSC>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::BaseQuery /;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

=head1 REVISION

$Id: REST.pm,v 1.1 2003/07/29 00:10:40 aa Exp $

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
