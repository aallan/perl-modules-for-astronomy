#!perl

# Test TST format read

# Astro::Catalog test harness
use Test::More tests => 2;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'TST', Data => \*DATA );

isa_ok( $cat, "Astro::Catalog" );

$cat->write_catalog( Format => 'Simple', File => \*STDOUT );

exit;

# D A T A   B L O C K --------------------------------------------------------

__DATA__
Simple TST example; stellar photometry catalogue.

A.C. Davenhall (Edinburgh) 26/7/00.

Catalogue of U,B,V colours.
UBV photometry from Mount Pumpkin Observatory,
see Sage, Rosemary and Thyme (1988).

# Start of parameter definitions.
EQUINOX: J2000.0
EPOCH: J1996.35
# End of parameter definitions.

#column-units: 	Hours 	Degrees 	Magnitudes 	Magnitudes 	Magnitudes
#column-types: CHAR*6 	DOUBLE 	DOUBLE 	REAL 	REAL 	REAL
#column-formats: A6 	D13.6 	D13.6 	F6.2 	F6.2 	F6.2

Id	ra	dec	V	B_V	U_B
--	--	---	-	---	---
Obj. 1	 5:09:08.7	 -8:45:15	  4.27	  -0.19	  -0.90
Obj. 2	 5:07:50.9	 -5:05:11	  2.79	  +0.13	  +0.10
Obj. 3	 5:01:26.3	 -7:10:26	  4.81	  -0.19	  -0.74
Obj. 4	 5:17:36.3	 -6:50:40	  3.60	  -0.11	  -0.47
