package Astro::ADS;

=head1 NAME

Astro::ADS - An object orientated interface to NASA's ADS database

=head1 DESCRIPTION

This module does nothing, and is here as a placeholder in case of need. The
user interface to the goodness wrapped in the ADS package can be found in
the L<Astro::ADS::Query> module.

=head1 REVISION

$Id: ADS.pm,v 1.3 2004/01/28 09:04:42 aa Exp $

=head1 METHODS

The Astro::ADS module itself has no methods, and is just a placeholder
module, see L<Astro::ADS::Query> for the actual interface.

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=head1 BUGS

=over

=item Followup queries using default URL

When an B<Astro::ADS::Query> object has set the url to a non-default server, 
the B<Astro::ADS::Result::Paper> objects it returns use the default URL in the
B<references>, B<citations>, B<alsoread> and B<tableofcontents> methods.  This
is likely not what you want if you are doing a lot of followup queries.

You can re-use the original query with the followup method or use v1.21.0 or
above which turns the URL from an object variable to a class variable.

=back


=cut

use strict;
use vars qw/ $VERSION /;
$VERSION = '1.21.0';

1;
