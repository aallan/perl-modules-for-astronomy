#!/home/globus/Perl/bin/perl

  use strict;

  use lib "blib/arch";
  use lib "blib/lib";

  use File::Spec;
  use POSIX qw/sys_wait_h/;
  use Errno qw/EAGAIN/;
  use Carp;
  use threads;
  use threads::shared;

  # load modules
  use Astro::Aladin;
  use Astro::Aladin::LowLevel;
  use Astro::Catalog;
  use Astro::Catalog::Star;
  use Astro::Catalog::SuperCOSMOS::Query;

  # debugging
  use Data::Dumper;

# ---------------------------------------------------------------------------

  my $sss = new Astro::Catalog::SuperCOSMOS::Query( RA     => "15 16 06.9",
                                                    Dec    => "-60 57 26.1",
                                                    Radius => "2" );
                                                  
  print "# Connecting to ROE\n";
  my $catalog = $sss->querydb();
  print "\n# file = $catalog\n#\n\n";

  print "# BUFFER\n#\n\n";
  $sss->_dump_raw();
  my @buffer = $sss->_dump_raw();
  print @buffer;

  exit;  
