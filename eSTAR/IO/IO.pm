package eSTAR::IO;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw / Exporter DynaLoader /;

our %EXPORT_TAGS = ( 'all' => [ qw / / ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw / /;
our $VERSION = '0.01';

bootstrap IO $VERSION;


1;
__END__
