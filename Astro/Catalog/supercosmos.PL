#!/usr/bin/perl -w

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
        if \$running_under_some_shell;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use Data::Dumper;
use Getopt::Long;
use Carp;

use Astro::Catalog::SuperCOSMOS::Query;

$ENV{"ALADIN_JAR"} = "/home/aa/aladin/Aladin.jar" 
                   unless defined $ENV{"ALADIN_JAR"};

$ENV{"ALADIN_MEM"} = "256m" unless defined $ENV{"ALADIN_MEM"};

# I N I T A L I S E --------------------------------------------------------

print "  SuperCOSMOS Retrieval Script v1.0\n";
print "\n  JAR File   " . $ENV{"ALADIN_JAR"} . "\n";
print "  Max Memory " . $ENV{"ALADIN_MEM"} . "\n";

# O P T I O N S   H A N D L I N G ------------------------------------------

my ( %opt );
my $status = GetOptions( "id=s"     => \$opt{"id"}, 
                         "ra=s"     => \$opt{"ra"}, 
                         "dec=s"    => \$opt{"dec"},
                         "radius=s" => \$opt{"radius"} );

my $id = $opt{"id"};
my $ra = $opt{"ra"};
my $dec = $opt{"dec"};
my $radius = $opt{"radius"};

print "  Target $id  RA $ra, Dec $dec, Radius $radius\n";

# G R A B   S U P E R C O S M O S   C A T A L O G --------------------------

my $supercosmos = new Astro::Catalog::SuperCOSMOS::Query( 
                      RA => $ra, Dec => $dec, Radius => $radius );
     
# query the ESO/ECF-ST archive   
print "\n  Connecting to Edinburgh using CDS Aladin...\n";
print "  Asking for stars within $radius arcmins of target RA & Dec\n";
my $cosmos = $supercosmos->querydb();   

# grab returned catalog size 
my $cosmos_size = $cosmos->sizeof();
print "  SuperCOSMOS: " . $cosmos_size . " stars returned\n"; 
   
# work out file name
my $sss_id = $id; 
$sss_id =~ s/\s+//g;
$sss_id = $sss_id . "_sss.cat";
my $sss_file = File::Spec->catfile(File::Spec->curdir(), $sss_id );
   
# write out file
print "  SuperCOSMOS: Writing catalogue to $sss_file\n";
$cosmos->write_catalog( $sss_file );  

exit;

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
