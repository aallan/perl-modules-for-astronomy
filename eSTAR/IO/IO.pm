package eSTAR::IO;

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

our @EXPORT = qw( report_error read_message write_message );
'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

bootstrap eSTAR::IO $VERSION;


1;
__END__
