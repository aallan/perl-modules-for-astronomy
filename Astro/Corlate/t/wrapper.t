# Astro::Corlate::Wrapper test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 2 };

# load modules
use Astro::Corlate::Wrapper qw / corlate /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# define filenames
my $file_name_1='archive.cat';
my $file_name_2='new.cat';
my $file_name_3='corlate.log';
my $file_name_4='corlate.cat';
my $file_name_5='colfit.cat';
my $file_name_6='colfit.fit';
my $file_name_7='hist.dat';
my $file_name_8='info.dat';

my $status = corlate( $file_name_1, $file_name_2, $file_name_3,
                      $file_name_4, $file_name_5, $file_name_6, 
                      $file_name_7, $file_name_8 );

ok( $status, 0 );

exit;
