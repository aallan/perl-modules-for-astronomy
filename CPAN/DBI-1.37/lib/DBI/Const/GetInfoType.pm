# $Id: GetInfoType.pm,v 1.1 2003/07/18 00:20:55 aa Exp $
#
# Copyright (c) 2002  Tim Bunce  Ireland
#
# Constant data describing info type codes for the DBI getinfo function.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

package DBI::Const::GetInfoType;

use strict;

use Exporter ();

use vars qw(@ISA @EXPORT @EXPORT_OK %GetInfoType);

@ISA = qw(Exporter);
@EXPORT = qw(%GetInfoType);

my
$VERSION = sprintf "%d.%02d", '$Revision: 1.1 $ ' =~ /(\d+)\.(\d+)/;

=head1 NAME

  DBI::Const::GetInfoType - Data describing GetInfo type codes

=head1 SYNOPSIS

  use DBI::Const::GetInfoType;

=head1 DESCRIPTION

Imports a %GetInfoType hash which maps names for GetInfo Type Codes
into their corresponding numeric values. For example:

  $database_version = $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );

The interface to this module is new and nothing beyond what is
written here is guaranteed.

=cut

use DBI::Const::GetInfo::ANSI ();	# liable to change
use DBI::Const::GetInfo::ODBC ();	# liable to change

%GetInfoType =
(
  %DBI::Const::GetInfo::ANSI::InfoTypes	# liable to change
, %DBI::Const::GetInfo::ODBC::InfoTypes	# liable to change
);

1;
