#!perl

# Test that we can read a catalogue that is not rigid about its
# columns

use strict;
use Test::More tests => 11;

require_ok( 'Astro::Coords' );
require_ok( 'SrcCatalog' );
require_ok( 'SrcCatalog::JCMT' );

# test sources
my @input = (
	     {
	      ra => '03:25:27.1',
	      dec => '30:45:11',
	      type => 'j2000',
	      name => 'a space',
	      comment => 'with comment'
	     },
	     {
	      ra => '13:25:27.1',
	      dec => '-30:45:11',
	      type => 'b1950',
	      name => 'test',
	     },
	     {
	      long => '03:26:30.0',
	      lat => '-1:45:0',
	      type => 'galactic',
	      name => 'gal 2',
	     }

	    );

# Start by having some test coordinates
# convert test sources to Astro::Coords and randomly
my @ref = map {
  new Astro::Coords( units => 'sex', %$_ );
} @input;

use Data::Dumper;
print Dumper(\@ref);

isa_ok( $ref[0], "Astro::Coords::Equatorial");

# Generate a catalogue manually
my @lines = ("* a comment\n");
for my $c (@ref) {
  my $line = $c->name;
  my $ra = $c->ra(format => 's');
  my $dec = $c->dec( format => 's');
  $ra =~ s/:/ /g;
  $dec =~ s/:/ /g;

  $line .= "$ra $dec ";

  # Always RJ
  $line .= "rj ";

  if (rand(1) < 0.5) {
    # add some extra stuff
    my $vel = (rand(1)<0.5 ? "- 35." : "N/A");
    my $flux = (rand(1)<0.5 ? "42.4" : "n/a");
    my $range = 'n/a';
    my $frame = "LSR";
    my $veldef = "RADIO";
    my $comment = ($c->comment ? $c->comment : "ooh");

    $line .= " $vel $flux $range $frame $veldef $comment";
  }
  $line .= "\n";

  push(@lines, $line);

}

# Read the data array
my $cat = new SrcCatalog::JCMT( join("",@lines) );

# Get the source list and remove planets
my $sources = $cat->sources;
my @filter = grep { $_->isa("Astro::Coords::Equatorial") } @$sources;

is($#filter, $#ref, "Compare size");

# Now compare
for my $i (0..$#ref) {
  is($filter[$i]->name, $ref[$i]->name, "Compare names");
  ok($ref[$i]->distance( $filter[$i]) < 0.1, "Compare distance");
}


#$cat->writeCatalog( \*STDOUT );

