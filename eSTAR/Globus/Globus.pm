package eSTAR::Globus;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw / GLOBUS_SUCCESS GLOBUS_TRUE 
                                    GLOBUS_FALSE / ] );
                                    
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw / /;
our $VERSION = '0.01';

bootstrap eSTAR::Globus $VERSION;

# Constants
use constant GLOBUS_SUCCESS => 0;
use constant GLOBUS_FALSE => 0;
use constant GLOBUS_TRUE => 0;

1;
__END__

