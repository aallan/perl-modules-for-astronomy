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

#+

# Name:
#   catalogs.pl

# Language:
#   Perl

# Purpose:
#   Generate a series of colour magnitude diagrams

# Description
#   Script parses the target list and generates a number of colour magnitude
#   diagrams using the SuperCOSMOS catalogues pulled from ATC using the
#   Astro::Aladin wrapper module. 
# 
#   Passed RA and Dec values must be in the form RR RR RR.RR SDD DD DD.DD
#   but may be aribitarly precise.

# External Modules:
# File::Spec
# File::Copy
# Getopt::Long
# Carp
# Time::localtime
# Data::Dumper
# PGPLOT
# Astro::DSS
# Astro::Catalog
# Astro::Catalog::USNOA2::Query
# Astro::Catalog::GSC::Query
# Astro::Catalog::SuperCOSMOS::Query
# PDL
# PDL::Version
# PDL::IO::Pic;
# PDL::Graphics::LUT
# PDL::Graphics::PGPLOT
# PDL::Graphics::PGPLOT::Window
# PDL::Graphics::PGPLOTOptions 

# Authors:
#   AA: Alasdair Allan (University of Exeter)

# History
#   21-FEB-2003 (AA):
#      Added SuperCOSMOS catalogue and Colour Magnitude Diagram
#   20-FEB-2003 (AA):
#      targets.pl split into two seperate programs.
#   19-FEB-2003 (AA):
#      Original version

# Copyright:
#   Copyright (C) 2003 University of Exeter. All Rights Reserved.

#-

# P O D  D O C U M E N T A T I O N ------------------------------------------

=head1 NAME

   catalogs.pl

=head1 SYNOPSIS

   targets.pl [-file <target list>] [-dev <pgplot device>] [-ident]

There are no required command line arguements. By default the script will
look for a target list in the current directory called C<targets.dat> and
generate a finding chart and colour magniude daiagram for the targets 
contained in that file. These will be displayed side by side in the graphics
device.

If the C<-ident> switch is invoked the script will identify the catalogue
stars on the finding chart displayed in the left hand graphics pane.

=head1 DESCRIPTION

C<catlogs.pl> is a script making use of the Astro::Aladin and Astro::Catalog
modules to generate a colour magnitude diagram, and associated cluster 
catalogues.

=head1 REVISION

$Id: catalogs.PL,v 1.1 2003/02/24 22:31:09 aa Exp $

=head1 AUTHORS

Alasdair Allan (aa@astro.ex.ac.uk)

=head1 COPYRIGHT

Copyright (C) 2003 University of Exeter. All Rights Reserved.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;

#
# General Modules
#
use POSIX qw/:sys_wait_h/;
use Errno qw/EAGAIN/;
use File::Spec;
use File::Copy;
use Getopt::Long;
use Carp;
use Time::localtime;
use Data::Dumper;

# PGPLOT Modules
use PGPLOT;

#
# Astronomy Modules
#
use Astro::DSS;
use Astro::Catalog;
use Astro::Catalog::USNOA2::Query;
use Astro::Catalog::SuperCOSMOS::Query;

# 
# PDL modules
#
use PDL;
use PDL::Version;
use PDL::IO::Pic;
use PDL::Graphics::LUT;
use PDL::Graphics::PGPLOT;
use PDL::Graphics::PGPLOT::Window;
use PDL::Graphics::PGPLOTOptions qw /set_pgplot_options/;

# I N I T A L I S E --------------------------------------------------------

print "Colour Magnitude Diagrams v1.0.2\n";
print "\n  " . ctime() . "\n";
   
print "  PDL Version   : " . PDL->VERSION . "\n";

# G L O B A L   V A R I A B L E S ------------------------------------------

# RA, Dec and Identifier lists
my ( @ra, @dec, @id );

# field of view
my @fov;

# meta info
my ( $runid, $piname, $survey, $north, $east );

# O P T I O N S   H A N D L I N G ------------------------------------------

my ( %opt );
my $status = GetOptions( "proxy=s"   => \$opt{"proxy"},
                         "file=s"    => \$opt{"file"},
                         "dev=s"     => \$opt{"dev"},
                         "ident!"    => \$opt{"ident"},
                         "multi=s"   => \$opt{"multi"} ); 

# Default filename
$opt{"file"} = "targets.dat" unless defined $opt{"file"};

# Default PGPLOT device
$opt{"dev"} = "/xs" unless defined $opt{"dev"};

# Default proxy is null
$opt{"proxy"} = "" unless defined $opt{"proxy"};

# Default finder multipler
$opt{"multi"} = 2.0 unless defined $opt{"multi"};

print "  Input File    : $opt{file}\n";
print "  PGPLOT Device : $opt{dev}\n\n";
 
# R E A D   T A R G E T S   F I L E  ---------------------------------------

unless ( open( TARGET, "+<$opt{file}" ) ) {
       croak("targets.pl: Cannot open target list $opt{file}");
} 
   
# slurp contents
my @buffer = <TARGET>;
chomp @buffer;   

# close file
close(TARGET);
   
# P A R S E   T A R G E T S   F I L E --------------------------------------

# number of targets
my $number = 0;

foreach my $line ( 0 ... $#buffer ) {

  # META-DATA
  # ---------
  
  # Does the buffer line contain meta-data?
  if( $buffer[$line] =~ "%" ) {
    
      # RunID
      if( lc( substr( $buffer[$line], 0, 6 ) ) eq lc( "%RunID" ) ) {
          $runid = substr( $buffer[$line], 7 );
          $runid =~ s/^\s+//;
          $runid =~ s/\s+$//;
      }
      
      # PIName
      if( lc( substr( $buffer[$line], 0, 7 ) ) eq lc( "%PIName" ) ) {
          $piname = substr( $buffer[$line], 8 );
          $piname =~ s/^\s+//;
          $piname =~ s/\s+$//;
      } 
               
      # Survey
      if( lc( substr( $buffer[$line], 0, 7 ) ) eq lc( "%Survey" ) ) {
          $survey = uc(substr( $buffer[$line], 8 ));
          $survey =~ s/^\s+//;
          $survey =~ s/\s+$//;
      } 
                       
      # Field of View
      if( lc( substr( $buffer[$line], 0, 4 ) ) eq lc( "%FoV" ) ) {
          
          # split the line into its x and y parts
          my $string = substr( $buffer[$line], 5 );
          my @split = split( /\s+/,$string);
          
          # Grab Field of View
          $fov[0] = $split[0];
          $fov[1] = $split[1];
      }
      
      # Direction of east
      if( lc( substr( $buffer[$line], 0, 5 ) ) eq lc( "%East" ) ) {
          $east = uc(substr( $buffer[$line], 6 ));
          $east =~ s/^\s+//;
          $east =~ s/\s+$//;
      }       
      
      # Direction of north
      if( lc( substr( $buffer[$line], 0, 6 ) ) eq lc( "%North" ) ) {
          $north = uc(substr( $buffer[$line], 7 ));
          $north =~ s/^\s+//;
          $north =~ s/\s+$//;
      }           
      
      # unrecorgnised meta-data, ignore it
      next; 
          
  }
  
  # TARGET
  # ------
    
  # split the line into its component parts
  my @target = split( /\s+/,$buffer[$line]);
  my $size = scalar(@target);
  
  # parse the line from the end, whatever is left is the identifier
  
  # Dec
  $dec[$number] = $target[$size-3] . " " . $target[$size-2] . 
                " " . $target[$size-1];
  
  # RA
  $ra[$number] = $target[$size-6] . " " . $target[$size-5] . 
                " " . $target[$size-4];
                
  # Identifier
  for ( my $i = 0; $i < $size-6; $i++ ) {
  
     # remove leading and trailing spaces
     $target[$i] =~ s/^\s+//;
     $target[$i] =~ s/\s+$//;
     
     # add to id string
     $id[$number] = $id[$number] . " " . $target[$i];
  }
 
  # remove leading and trailing spaces
  $id[$number] =~ s/^\s+//;
  $id[$number] =~ s/\s+$//;
              
  #print "  " . $id[$number] . "\n";
  #print "  RA " . $ra[$number] . " Dec " . $dec[$number] . "\n\n";

  # increment the target counter
  $number = $number + 1;
  
}

print "  Run ID             = " . $runid . "\n";
print "  PI Name            = " . $piname . "\n";
print "  Survey             = " . $survey . "\n";
print "  Field of View      = " . $fov[0] . "x" . $fov[1] . " arcmin\n";
print "  East               = " . $east . "\n";
print "  North              = " . $north . "\n";
print "  Number of Targets  = " . $number . "\n\n";

# C H E C K   F I E L D   O F   V I E W ------------------------------------

# Grab size for finding chart   
my $xsize = $opt{"multi"}*$fov[0]; 
my $ysize = $opt{"multi"}*$fov[1];

# ESO-ECF maximum field size is 40x40 arcmin
if ( $xsize > 40 ) {
  print " %Astro::DSS, Maximum chart size exceeded in X-dimension.\n";
  $xsize = 40; 
}

if ( $ysize > 40 ) {
  print " %Astro::DSS, Maximum chart size exceeded in Y-dimension.\n";
  $ysize = 40; 
}

# Check the FoV as well  
if ( $fov[0] > 40 ) {
  print " %Astro::DSS, Field of view too large, set to 40 arcmin in X.\n";
  $fov[0] = 40; 
}

if ( $fov[1] > 40 ) {
  print " %Astro::DSS, Field of view too large, set to 40 arcmin in Y.\n";
  $fov[1] = 40; 
}  

# Grab aspect ratio from FoV numbers
my $aspect = $fov[1]/$fov[0];
print " %PGPLOT, aspect ratio is $aspect\n";

# L O O P   O V E R   A L L   T A R G E T S  -------------------------------

# directory for temporary caching survey images
if ( opendir(TMP, File::Spec->tmpdir() ) ) {
   $ENV{"ESTAR_DATA"} = File::Spec->tmpdir();
   closedir TMP;
} else {
   # Shouldn't happen?
   croak("Cannot open temporary directory for incoming files.");
}

# G R A B   S U R V E Y   I M A G E ----------------------------------------

# loop through all the targets
foreach my $i ( 0 ... $#id ) {

   # open pgplot window with two panels
   my $window = new PDL::Graphics::PGPLOT::Window( Device  => $opt{"dev"},
                                                   NXPanel => 2  );
                                                   
   # go to panel 1
   $window->panel(0);                                                

   # kludge to set the background colour, for some reason PDL won't
   # set the background colour correctly no matter what. Odd huh?
   if( uc($opt{"dev"}) =~ "PS" ) {
      pgscr (1, 0,0,0); 
   }
       
   # Grab the image from the ESO-ECF archive
   print "\n  Connecting to ESO-ECF Archive ...\n";
   print "  " . $id[$i] . ": RA " . $ra[$i] . " Dec " . $dec[$i] . 
         " FoV " . $xsize ."x" . $ysize . "\n";

   my $dss = new Astro::DSS( RA     => $ra[$i],
                             Dec    => $dec[$i],
                             Xsize  => $xsize,
                             Ysize  => $ysize,
                             Survey => $survey,
                             Format => 'FITS',
                             Proxy  => $opt{"proxy"} );

   my $filename = $dss->querydb();
   print "  Retrieved image: " . $filename . "\n";
       
   # load image into PGPLOT
   print "  Loading image into PGPLOT...\n";
   my $image = PDL->rfits( $filename );

   # clean up
   unlink( $filename );     

   # Grab statistics
   my ($mean,$rms,$median,$min,$max) = stats($image);
    
   # Work out image size
   my @dimensions = dims( $image );
   print "  Image is $dimensions[0] x $dimensions[1] pixels\n";
   
   # plot the image
   $window->env( 0, $dimensions[0], 0, $dimensions[1],
                { PIX => 1, JUSTIFY => 1, AXIS => -2, AXISCOLOUR => 1 } );

   # use a reversed colour table
   my ( $levels, $red, $green, $blue ) = lut_data( 'heat', 1 );
   $window->ctab( $levels, $red, $green, $blue );
      
   $window->hold();
   $window->imag( $image, 
                  { PIX => 1, MIN => $mean-$rms, MAX => $mean+(2*$rms)});
  
   # Work out pixel scales (in arcmin)
   my $x_pixel_scale = $xsize/$dimensions[0];
   my $y_pixel_scale = $ysize/$dimensions[1];
  
   print "  Image is $xsize x $ysize arcmin\n";
   print "  X Pixel Scale is $x_pixel_scale arcmin/pixel\n";
   print "  Y Pixel Scale is $y_pixel_scale arcmin/pixel\n";
  
   # Draw a cross at the centre of the image
   my $x_centre = $dimensions[0]/2.0;
   my $y_centre = $dimensions[1]/2.0;
   $window->points( $x_centre, $y_centre , 
      { SYMBOL => 'CROSS', CHARSIZE => 4, COLOUR => 2, LINEWIDTH => 2 } );
                                             
   # Work out size of scale bar
   my $x_start = $dimensions[0]/25.0;
   my $y_start = $dimensions[1]/25.0;
   
   my $x_end = $x_start + ($fov[0]/3.0)/$x_pixel_scale;
   
   # Check that the scale bar is smaller than 10 arcmin     
   my $length = ($x_end - $x_start)*$x_pixel_scale;
   if ( $length > 10.0 ) {
      $length = 10.0;
      $x_end = $x_start + 10.0/$x_pixel_scale;
   }    
    
   # convert to piddles
   my $pdlx = pdl [ $x_start, $x_end ];
   my $pdly = pdl [ $y_start, $y_start ];
                                        
   # Draw FoV/3 scale bar in X (10.0 arcmin max)
   $window->line( $pdlx, $pdly,
                  { COLOUR => 2, CHARSIZE => 1.0,  LINEWIDTH => 2 } );
   
   # Label the scale bar
   $length = sprintf( '%.2f', $length );
   
   my $abit = $dimensions[0]/100.0;
   $window->text( "$length arcmin", $x_start+$abit, $y_start+$abit,
                  { COLOUR => 2, CHARSIZE => 1.5,  LINEWIDTH => 1 } );
      
   # check the finder isn't actually smaller than the field of view
   
   if( $opt{"multi"} > 1.1 && $fov[0] < 40 && $fov[1] < 40  ) {

      my $x_fov_length = $fov[0]/$x_pixel_scale;
      my $y_fov_length = $fov[1]/$y_pixel_scale;
      $x_fov_length = sprintf( '%.0f', $x_fov_length );
      $y_fov_length = sprintf( '%.0f', $y_fov_length );

      print "  Field of view is $x_fov_length x $y_fov_length pixels\n";
      print "  Field of view is $fov[0] x $fov[1] arcmin\n";
                        
      # Work of the FoV (we're going clockwise from SW corner)
      my $fovx = pdl [ $x_centre - ( $fov[0]/2.0 )/$x_pixel_scale,
                       $x_centre - ( $fov[0]/2.0 )/$x_pixel_scale,            
                       $x_centre + ( $fov[0]/2.0 )/$x_pixel_scale,
                       $x_centre + ( $fov[0]/2.0 )/$x_pixel_scale, 
                       $x_centre - ( $fov[0]/2.0 )/$x_pixel_scale];
                    
      my $fovy = pdl [ $y_centre - ( $fov[1]/2.0 )/$y_pixel_scale,
                       $y_centre + ( $fov[1]/2.0 )/$y_pixel_scale,            
                       $y_centre + ( $fov[1]/2.0 )/$y_pixel_scale,
                       $y_centre - ( $fov[1]/2.0 )/$y_pixel_scale,
                       $y_centre - ( $fov[1]/2.0 )/$y_pixel_scale];
                                         
      # Draw the FoV into the plot
      $window->line( $fovx, $fovy,
                     { COLOUR => 2, LINESTYLE => 2,  LINEWIDTH => 2 } );
                  
      # Label the Fov
      $window->text( "Field of View", 
                     $x_centre - ( $fov[0]/2.0 )/$x_pixel_scale, 
                     $y_centre + $abit + ( $fov[1]/2.0 )/$y_pixel_scale,
                     { COLOUR => 2, CHARSIZE => 1.5,  LINEWIDTH => 1 } );
   }
                    
   # Kludge! For some reason PDL doesn't do LEGEND colouring correctly, 
   # so I have to drop down to native interface to get things to work
   pgsci(2);
   pgslw(1);

   # Another kludge, PDL makes it really difficult for us to do text 
   # positioning relative to the viewport. So I'm dropping down and 
   # using the native interface (again)
   pgsch(1.5);
   pgmtxt( 'LV', 0.0, 1.03, 0.0, $id[$i] );
   pgmtxt( 'LV', 0.0, -0.03, 0.0, "Image from $survey survey" );
 
   # Draw the direction arrows onto the finder
   my ( $north_line_xstart, $north_line_ystart);
   my ( $east_line_xstart, $east_line_ystart);
   my ( $x_length, $y_length );
      
   # Line lengths 1/2 length of scale bar
   $x_length = $length/(2.0*$x_pixel_scale);
   $y_length = $length/(2.0*$y_pixel_scale);
   
   # We're plotting the arrows in the bottom right corner, if the East
   # & North variables are unknown things default to EAST TO THE LEFT
   # and NORTH TO TOP. Doh!
   
   $east_line_xstart = $dimensions[0] - $dimensions[0]/30.0 - $abit;
   if( $north eq uc("BOTTOM") ) {
      $east_line_ystart = 
          $dimensions[1]/30.0 + $y_length - $abit;
   } else {
      $east_line_ystart = 
          $dimensions[1]/30.0 - $abit;
   }
   
   $north_line_ystart = $dimensions[1]/30.0 - $abit;
   if( $east eq uc("RIGHT") ) {
      $north_line_xstart = 
           $dimensions[0] - $dimensions[0]/30.0 - $x_length - $abit;
   } else {
      $north_line_xstart = 
           $dimensions[0] - $dimensions[0]/30.0 - $abit;
   }   
   
   # Draw the direction arrows
   print "  Drawing Orientation Arrows...\n";
  
   my $eastx = pdl [ $east_line_xstart, $east_line_xstart - $x_length ];
   my $easty = pdl [ $east_line_ystart, $east_line_ystart ];
   my $northx = pdl [ $north_line_xstart, $north_line_xstart  ];
   my $northy = pdl [ $north_line_ystart, $north_line_ystart + $y_length ];   

   $window->line( $eastx, $easty,
                  { COLOUR => 4, LINESTYLE => 1, LINEWIDTH => 2 } );
   $window->line( $northx, $northy,
                  { COLOUR => 4, LINESTYLE => 1, LINEWIDTH => 2 } );
   
   # annotate them...
   my ( $north_xtext, $north_ytext, $east_xtext, $east_ytext );
   if( $north eq uc("BOTTOM") ) {
     $north_xtext = $north_line_xstart + $abit;       
     $north_ytext = $north_line_ystart;
   } else {
     $north_xtext = $north_line_xstart - 1.5*$abit;       
     $north_ytext = $north_line_ystart + $y_length + $abit;       
   }
   
   if( $east eq uc("RIGHT") ) {
      $east_xtext = $east_line_xstart; 
      $east_ytext = $east_line_ystart + $abit;     
   } else {
      $east_xtext = $east_line_xstart - $x_length; 
      $east_ytext = $east_line_ystart + $abit;
   }  
   
   # Tag the north and east directions
   $window->text( "N", $north_xtext, $north_ytext,
                  { COLOUR => 4, CHARSIZE => 1.2,  LINEWIDTH => 1 } );
   $window->text( "E", $east_xtext, $east_ytext,
                  { COLOUR => 4, CHARSIZE => 1.2,  LINEWIDTH => 1 } );

# G R A B   U S N O - A 2   C A T A L O G ----------------------------------
   
   # work out unknown parameter
   my $radius;
   if ( $fov[0] > $fov[1] ) {
     $radius = $fov[0];
   } else {
     $radius = $fov[1];
   }
   $radius = sprintf ( '%.2f', $radius );
      
   # grab catalogue, make repeated attempts until we have less than
   # the maximum allowed number of stars (i.e. we have a full sample
   # inside the radius we've ask for).
   
   my $maxxed_out = 9999;
   my $counter = 1;
   
   my ( $catalog, $catalog_size );
   while( $maxxed_out == 9999 ) {
   
     print "\n  Connecting to ESO-ECF Archive [$counter]...\n";
     print "  Asking for stars within $radius arcmins of target RA & Dec\n";
     my $usno = new Astro::Catalog::USNOA2::Query( RA     => $ra[$i],
                                                   Dec    => $dec[$i],
                                                   Radius => $radius,
                                                   Number => 9999,
                                                   Proxy  => $opt{"proxy"},
                                                   Bright => 0.0,
                                                   Faint  => 100.0 );
     # query the ESO/ECF-ST archive   
     $catalog = $usno->querydb();    
     $catalog_size = $catalog->sizeof();
     print "  USNO-A2: " . $catalog_size . " stars returned\n"; 
     
     $maxxed_out = $catalog_size;
     $counter = $counter + 1;
     if ( $maxxed_out == 9999 ) {
        print "  Exceeded maximum catalog size, reducing field size...\n";
        $radius = sprintf ( '%.2f', $radius*0.9 );
     }
   }
      
   # work out file name
   my $file_id = $id[$i]; 
   $file_id =~ s/\s+//g;
   $file_id = $file_id . "_usnoa2.cat";
   my $cat_file = File::Spec->catfile(File::Spec->curdir(), $file_id );
      
   # write out file
   print "  USNO-A2: Writing catalogue to $cat_file\n";
   $catalog->write_catalog( $cat_file );                     

# G R A B   S U P E R C O S M O S   C A T A L O G --------------------------

   # reset the radius
   my $radius;
   if ( $fov[0] > $fov[1] ) {
     $radius = $fov[0];
   } else {
     $radius = $fov[1];
   }
   $radius = sprintf ( '%.2f', $radius );
  
   my ( $dead, $pid );

   my $start_client = sub {
      $dead = waitpid ($pid, &WNOHANG);
      #  $dead = $pid when the process dies
      #  $dead = -1 if the process doesn't exist
      #  $dead = 0 if the process isn't dead yet
      if ( $dead != 0 ) {
        FORK: { 
          if ($pid = fork) {
             return;
          } elsif ( defined $pid ) { 
      	     exec ( "$^X ./supercosmos.pl" .
                    " -id \"$id[$i]\" -ra \"$ra[$i]\" ".
                    " -dec \"$dec[$i]\" -radius $radius" );
          } elsif ($! == EAGAIN ) {
             print("Recoverable fork() error, hang on...\n");
       	     sleep 5;
	     redo FORK;
          } else {
	     croak( "Unable to fork SuperCOSMOS retrieval script\n");
          }
        }
      }
   };
  
   # fork the client process
   print "\n  Forking client...\n";
   my $istat = &$start_client;
   print "  PID = $pid\n"; 
  
   # wait for process to die
   do {
      $dead = waitpid( $pid, &WNOHANG );
   } until ( $dead == $pid ); 

   # work out file name
   my $sss_id = $id[$i]; 
   $sss_id =~ s/\s+//g;
   $sss_id = $sss_id . "_sss.cat";
   my $sss_file = File::Spec->catfile(File::Spec->curdir(), $sss_id );
    
   # read the  catalogue back in 
   my $cosmos = new Astro::Catalog( Cluster => $sss_file ); 
   my $cosmos_size = $cosmos->sizeof(); 
    
   #print Dumper($cosmos); 
    
# C O L O U R   M A G N I T U D E   D I A G R A M  -------------------------
      
   # do we want a colour magnitde diagram
   if( -f $sss_file ) {
      
      # We're ploting the USNO-A2 stars on the FINDING CHART
      # ----------------------------------------------------
      my ( $centre_ra, $centre_dec );
      if( $opt{"ident"} ) {    
      
         # convert field centre to decimal RA and Dec in armin
         my @centre_splitra = split( /\s+/, $ra[$i] );
         $centre_ra = $centre_splitra[0]*60.0 + 
                      $centre_splitra[1] + 
                      $centre_splitra[2]/60.0;                
            
         my @centre_splitdec = split( /\s+/, $dec[$i] );
         $centre_dec = abs($centre_splitdec[0]*60.0) + 
                           $centre_splitdec[1] + 
                           $centre_splitdec[2]/60.0;                
            
         # add the -ve sign back in
         if( $centre_splitdec[0] =~ "-" ) {
            $centre_dec = -$centre_dec;
         }
                        
         print "\n  SuperCOSMOS: Plotting $cosmos_size stars on chart...\n";
         print "  Field Centre: RA $ra[$i], Dec $dec[$i]\n";
      }          

                
      # loop through each star in the catalogue
      my ( @r_mag, @b_mag, @br_col, @quality );
      foreach my $s ( 0 ... $cosmos_size-1 ) {
            
         # Generic between COLOUR-MAG and PLOT routines
         # --------------------------------------------
            
         # pop star off catalogue object
         my $star = $cosmos->popstar();
           
         my $cat_id = $star->id();
         my $cat_ra = $star->ra();
         my $cat_dec = $star->dec(); 
         $r_mag[$s] = $star->get_magnitude( 'R2' );
         $b_mag[$s] = $star->get_magnitude( 'Bj' );
         $br_col[$s] = $star->get_colour( 'Bj-R2' );
         $quality[$s] = $star->quality();
               
         # Plot SuperCOSMOS Stars on the FINDING CHART
         # -------------------------------------------
               
         # plot it on the Finding Chart, not much use for large charts!  
         if( $opt{"ident"} ) {

            # convert sextuple RA to decminal RA and then into arcmin 
            my @split_ra = split( /\s+/, $cat_ra );
            my $decimal_ra = 
                 $split_ra[0]*60.0 + $split_ra[1] + $split_ra[2]/60.0;

            my @split_dec = split( /\s+/, $cat_dec );
            my $decimal_dec = 
                 abs($split_dec[0]*60.0) + $split_dec[1] + $split_dec[2]/60.0;

            # add the -ve sign back in
            if( $split_dec[0] =~ "-" ) {
               $decimal_dec = -$decimal_dec;
            }   
                              
            # 15cos(dec) factor!? Huh?
            my $piover = (atan2(1,1)*4.0)/180.0;
            my $cosine = abs($split_dec[0]) + 
                         $split_dec[1]/60.0 + 
                         $split_dec[2]/3600.0; 
            $cosine = -$cosine if( $split_dec[0] =~ "-" );            
            $cosine = cos( $cosine*$piover );
               
            # offset from field centre is
            my $y_offset = -($centre_dec - $decimal_dec);
            my $x_offset = ($centre_ra - $decimal_ra)*15.0*$cosine;
              
            # convert to pixels
            $x_offset = $x_offset/$x_pixel_scale;
            $y_offset = $y_offset/$y_pixel_scale;
              
            # convert to absolute x,y
            my $abs_x = $x_centre + $x_offset;
            my $abs_y = $y_centre + $y_offset;
             
            #print "$s: RA $cat_ra  Dec $cat_dec\n";
            #print "$s: RA $centre_ra  Dec $centre_dec\n";
            #print "$s: RA $decimal_ra  Dec $decimal_dec\n";
            #print "$s: ($abs_x, $abs_y)\n\n"; 
               
            # mark it on the finder
            $window->points( $abs_x, $abs_y, {SYMBOL => 'CIRCLE', 
                             CHARSIZE => 2, COLOUR => 4, LINEWIDTH => 2.0});
         }
      }
            
      # Generate COLOUR-MAGNITUDE Diagram
      # ---------------------------------
                    
      # open next panel
      $window->panel(1);
      print "\n  Drawing Colour-Magnitude Diagram...\n";

      # Loop round the mag and colour values and find min/max
      # remember we're in magnitude space so its all reversed
      my $rmag_max = 100.0;
      my $rmag_min = 0.0;
      for my $m ( 0 .. $#r_mag ) {
         if($quality[$m] == 0 && $r_mag[$m] != 99.999 && $b_mag[$m] != 99.999){
            if( $r_mag[$m] < $rmag_max ) {
               $rmag_max = $r_mag[$m];
            }  
            if( $r_mag[$m] > $rmag_min ) {
               $rmag_min = $r_mag[$m];
            }
         }   
      }
            
      # add a fudge factor
      $rmag_min = $rmag_min+0.005*$rmag_min;
      $rmag_min = 22.0 if( $rmag_min > 22.0 );
      $rmag_max = $rmag_max-0.005*$rmag_min;
            
      print "  Y Maximum $rmag_max, Y Minimum $rmag_min\n";
               
      my $brcol_max = -100000.0;
      my $brcol_min = 100000.0;
      for my $n ( 0 .. $#r_mag ) {
         if($quality[$n] == 0 && $r_mag[$n] != 99.999 && $b_mag[$n] != 99.999){
            if ( $br_col[$n] > $brcol_max ) {
               $brcol_max = $br_col[$n];
            }
            if ( $br_col[$n] < $brcol_min ) {  
                $brcol_min = $br_col[$n];
            } 
         }     
      }              
           
      # add a fudge factor
      $brcol_min = $brcol_min-0.005*abs($brcol_max);
      $brcol_max = $brcol_max+0.005*abs($brcol_max);
           
      print "  X Maximum $brcol_max, X Minimum $brcol_min\n";
 
      # setup the graph
      $window->env( $brcol_min, $brcol_max, $rmag_min, $rmag_max,
                    { AXIS => 0, AXISCOLOUR => 1 } );
      #$window->env( -10, 10, 20, 3,
      #              { PIX => 1, JUSTIFY => 1, AXIS => 0, AXISCOLOUR => 1 } ); 

      my $chopped = sprintf( '%.1f', $radius );
      $window->label_axes("B-R Colour", "R Magnitude", 
                          "CM diagram for $chopped arcmin around $id[$i]",
                          { COLOUR => 2, CHARSIZE => 1.5,  LINEWIDTH => 2 });
                                       
      # plot all the points
      print "  Plotting points...\n";
      for my $k ( 0 .. $#r_mag ) {
      
         if($quality[$k] == 0 && $r_mag[$k] != 99.999 && $b_mag[$k] != 99.999){
            $window->points( $br_col[$k], $r_mag[$k],
              { SYMBOL => 'DOT', COLOUR => 1,  LINEWIDTH => 1.0 } );
         }     
      }              
                          
      # Another kludge, PDL makes it really difficult for us to do text 
      # positioning relative to the viewport. So I'm dropping down and 
      # using the native interface (again)
      pgsch( 1.5 );
      pgmtxt( 'LV', -0.5, 0.95, 0.00, "$catalog_size Stars" );                    
                          

   }

# E N D   O F   T A R G E T   L O  O P  ------------------------------------
                 
   # close the PGPLOT device
   $window->release();
   $window->close();
   $window = undef;
   
   # If we have postscript output rename the temporary output file
   if( uc($opt{"dev"}) =~ "PS" ) {
      if( -s File::Spec->catfile( File::Spec->curdir(), "pgplot.ps" ) ) {
       
          # Move pgplot.ps file to $id.ps
          my $file_id = $id[$i]; 
          $file_id =~ s/\s+//g;
          print "\n  Saving plot: " . $file_id . ".ps\n";
          rename( File::Spec->catfile( File::Spec->curdir(), "pgplot.ps" ),
                  File::Spec->catfile( File::Spec->curdir(), "$file_id.ps" ));
      } else {              
          croak("targets.pl: Cannot open PGPLOT output file ./pgplot.ps");
      }
   }
      
   # If we've just plotted it in an X Window, pause for thought
   if( uc($opt{"dev"}) =~ "X" ) {
      sleep(5);
   }      

}                  


# L A S T   O R D E R S ----------------------------------------------------

# tidy up
END {
   print "\n Exiting...\n";
}
exit;

# T I M E   A T   T H E   B A R  -------------------------------------------

1;                      

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
