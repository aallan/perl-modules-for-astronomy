package eSTAR::IO::Server;

require 5.005_62;
use strict;
use vars qw($VERSION);
use warnings;
use Carp;
use AutoLoader qw(AUTOLOAD);

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );
'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

bootstrap eSTAR::IO::Server $VERSION;


1;
__END__
