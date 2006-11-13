# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More tests => 2;

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# read from data block
#my @buffer = <DATA>;
#chomp @buffer;        

#my $document =         
          
#my @xml = split( /\n/, $document );
#foreach my $i ( 0 ... $#buffer ) {
#   is( $xml[$i], $buffer[$i], "comparing line $i in XML document" );
#}


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
