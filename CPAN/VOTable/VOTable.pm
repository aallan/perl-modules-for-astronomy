# VOTable.pm

=pod

=head1 NAME

VOTable - VOTable XML manipulation package

=head1 SYNOPSIS

use VOTable;

=head1 DESCRIPTION

This code will replace the VOTABLE classes.

=head1 WARNINGS

=over 4

=item *

Alpha code. Caveat programmor.

=item *

No testing has been done with Perl prior to version 5.6.1.

=back

=head1 SEE ALSO

=over 4

=item

XML::DOM

=back

=head1 AUTHOR

Eric Winter, NASA GSFC (elwinter@milkyway.gsfc.nasa.gov)

=head1 VERSION

$Id: VOTable.pm,v 1.1 2003/10/13 10:51:22 aa Exp $

=cut

#******************************************************************************

# Revision history

# $Log: VOTable.pm,v $
# Revision 1.1  2003/10/13 10:51:22  aa
# GSFC VOTable module V0.10
#
# Revision 1.1.1.1  2002/10/25 18:30:48  elwinter
# Changed required Perl version to 5.6.0.
#
# Revision 1.1  2002/09/06  19:28:31  elwinter
# Initial revision
#

#******************************************************************************

# Begin the package definition.
package VOTable;

# Specify the minimum acceptable Perl version.
use 5.6.0;

# Turn on strict syntax checking.
use strict;

# Use enhanced diagnostic messages.
use diagnostics;

# Use enhanced warnings.
use warnings;

#******************************************************************************

# Module version.
our $VERSION = '0.01';

#******************************************************************************

# Specify external modules to use.

# Standard modules.

# Third-party modules.

# Project modules.

#******************************************************************************

# Class constants.

#******************************************************************************

# Class variables.

#******************************************************************************

# Method definitions

#******************************************************************************
1;
__END__
