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

our %EXPORT_TAGS = ( 'all' => [ qw(
                                    GLOBUS_SUCCESS GLOBUS_FAILURE
                                    GLOBUS_TRUE GLOBUS_FALSE GLOBUS_NULL 
                                    module_activate module_deactivate
                                    report_error read_message write_message
                                   ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( module_activate module_deactivate report_error 
                  read_message write_message );
                  
'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

bootstrap eSTAR::IO $VERSION;

# Error Constants
use constant GLOBUS_SUCCESS => 0;
use constant GLOBUS_FAILURE => 1;

# Logic Constants
use constant GLOBUS_TRUE    => 1;
use constant GLOBUS_FALSE   => 0;
use constant GLOBUS_NULL    => 0;

1;
__END__
