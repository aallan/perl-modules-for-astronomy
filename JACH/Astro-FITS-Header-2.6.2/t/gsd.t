#!perl
# Testing GSD read of fits headers

use strict;
use File::Spec;

use Test;
BEGIN { plan tests => 3 };

eval "use Astro::FITS::Header::GSD;";
if ($@) {
  for (1..3) {
    skip("Skip GSD module not available", 1);
  }
  exit;
}

ok(1);

# Read-only
# Try to work out whether the file is in the t directory or the parent
my $gsdfile = "test.gsd";

$gsdfile = File::Spec->catfile("t","test.gsd")
  unless -e $gsdfile;

my $hdr = new Astro::FITS::Header::GSD( File => $gsdfile );
ok( $hdr );

# Get the telescope name
my $item = $hdr->itembyname( 'C1TEL' );
ok( $item->value, "JCMT");
