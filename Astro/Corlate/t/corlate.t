# Astro::Corlate test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 9 };

# load modules
use Astro::Corlate;

# debugging
#use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# Set the eSTAR data directory to point to /tmp
$ENV{"ESTAR_DATA"} = File::Spec->tmpdir();

# Catalogue Files
my $ref = File::Spec->catfile(File::Spec->curdir(),'t','archive.cat');
my $obs = File::Spec->catfile(File::Spec->curdir(),'t','new.cat');

my $corlate = new Astro::Corlate( Reference   =>  $ref,
                                  Observation =>  $obs );
$corlate->run_corlate();

# grab comparison data
my @info = <DATA>;
chomp @info;

# grab info file
open(FILE, $corlate->information());
my @file = <FILE>;
chomp @file;

# check info file has the right values
for my $i (0 .. $#info) {
   ok( $file[$i], $info[$i] );
}

# CLEAN UP
END {
  # get the log file
  my $log = $corlate->logfile();
  
  # get the variable star catalogue
  my $var = $corlate->variables();
  
  # fitted colour data catalogue
  my $dat = $corlate->data();
  
  # fit to the colour data
  my $fit = $corlate->fit();
  
  # get probability histogram file
  my $his = $corlate->histogram();
  
  # get the useful information file
  my $inf = $corlate->information();
  
  # clean up after ourselves
  print "# Cleaning up temporary files\n";
  print "# Deleting: " . $log ."\n";
  print "# Deleting: " . $var ."\n";
  print "# Deleting: " . $dat ."\n";
  print "# Deleting: " . $fit ."\n";
  print "# Deleting: " . $his ."\n";
  print "# Deleting: " . $inf ."\n";
 
  # unlink the files
  my @list = ( $log, $var, $dat, $fit, $his, $inf );
  unlink(@list); 
}         

exit;

# --------------------------------------------------------------------------

__DATA__
   0.7889522 ! Mean separation in arcsec of stars successfully paired.
 !! Begining of new star description.
 V  ! Filter observed in.
   3.0721891 ! Increase brightness in magnitudes.
   0.1619290 ! Error in above.
   1.6093254E-05 ! False alarm probability.
 1 10  12.9499998 ! Target RA from archive catalogue.
 60 4  36.2500000 ! Target Declination from archive catalogue.
