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
#   finder.pl

# Language:
#   Perl

# Purpose:
#   Generate a series of finding charts from a list of targets

# Description
#   Script parses the target list and generates a number of finding 
#   charts using the Astro::DSS module. It then uses the PGPLOT module
#   to annotate them and saves them as postscript files. 
# 
#   Passed RA and Dec values must be in the form RR RR RR.RR SDD DD DD.DD
#   but may be aribitarly precise.

# External Modules:
#   File::Spec
#   File::Copy
#   Getopt::Long
#   Carp
#   Time::localtime
#   Data::Dumper
#   PGPLOT
#   Astro::DSS
#   PDL
#   PDL::Version
#   PDL::IO::Pic
#   PDL::Graphics::LUT
#   PDL::Graphics::PGPLOT;
#   PDL::Graphics::PGPLOT::Window
#   PDL::Graphics::PGPLOTOptions

# Authors:
#   AA: Alasdair Allan (University of Exeter)

# History
#   20-FEB-2003 (AA):
#      targets.pl split into two seperate programs.
#   19-FEB-2003 (AA):
#      Original version

# Copyright:
#   Copyright (C) 2003 University of Exeter. All Rights Reserved.

#-

# P O D  D O C U M E N T A T I O N ------------------------------------------

=head1 NAME

   finder.pl

=head1 SYNOPSIS

   finder.pl [-file <target list>] [-multi <float>] [-dev <pgplot device>]

There are no required command line arguements. By default the script will
look for a target list in the current directory called C<targets.dat> and
generate finding charts from the data contained in this file.

The finding chart will be a larger than the field of view specified in the
target file be the factor given in the optional command line arguement 
C<-multi>. By default the field of view is drawn on the finding chart, if
the factor spceified is less than or equal to one the field of view will not
be drawn.

=head1 DESCRIPTION

C<finder.pl> is a script making use of the Astro::DSS to generate a 
series of finding charts.

=head1 REVISION

$Id: finder.PL,v 1.1 2003/02/24 22:31:09 aa Exp $

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

print "Finding Chart Generator v2.0.1\n";
print "\n  " . ctime() . "\n";
   
print "  PDL Version   : " . PDL->VERSION . "\n";

# G L O B A L   V A R I A B L E S ------------------------------------------

# RA, Dec and Identifier lists
my ( @ra, @dec, @id );

# field of view
my @fov;

# meta info
my ( $runid, $piname, $survey, $east, $north );

# O P T I O N S   H A N D L I N G ------------------------------------------

my ( %opt );
my $status = GetOptions( "proxy=s"   => \$opt{"proxy"},
                         "file=s"    => \$opt{"file"},
                         "dev=s"     => \$opt{"dev"},
                         "multi=s"   => \$opt{"multi"} ); 

# Default filename
$opt{"file"} = "targets.dat" unless defined $opt{"file"};

# Default PGPLOT device
$opt{"dev"} = "/ps" unless defined $opt{"dev"};

# Default proxy is null
$opt{"proxy"} = "" unless defined $opt{"proxy"};

# Default finder multipler
$opt{"multi"} = 2.0 unless defined $opt{"multi"};

print "  Input File    : $opt{file}\n";
print "  PGPLOT Device : $opt{dev}\n";
print "  Finder Factor : $opt{multi}\n\n";
 
# R E A D   T A R G E T S   F I L E  ---------------------------------------

unless ( open( TARGET, "+<$opt{file}" ) ) {
       croak("finder.pl: Cannot open target list $opt{file}");
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

   # open pgplot window
   my $window = new PDL::Graphics::PGPLOT::Window( Device => $opt{"dev"}  );

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
      { SYMBOL => 'CROSS', CHARSIZE => 4, COLOUR => 2, LINEWIDTH => 4 } );
                                          
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
                  { COLOUR => 2, CHARSIZE => 1.0,  LINEWIDTH => 4.0 } );
   
   # Label the scale bar
   $length = sprintf( '%.2f', $length );
   
   my $abit = $dimensions[0]/100.0;
   $window->text( "$length arcmin", $x_start+$abit, $y_start+$abit,
                  { COLOUR => 2, CHARSIZE => 1.2,  LINEWIDTH => 4.0 } );
      
   # check the finder isn't actually smaller than the field of view
   
   if( $opt{"multi"} > 1.1 && $fov[0] < 40 && $fov[1] < 40 ) {

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
                     { COLOUR => 2, LINESTYLE => 2,  LINEWIDTH => 4.0 } );
                  
      # Label the Fov
      $window->text( "Field of View", 
                     $x_centre - ( $fov[0]/2.0 )/$x_pixel_scale, 
                     $y_centre + $abit + ( $fov[1]/2.0 )/$y_pixel_scale,
                     { COLOUR => 2, CHARSIZE => 1.2,  LINEWIDTH => 4.0 } );
   }
                    
   # Kludge! For some reason PDL doesn't do LEGEND colouring correctly, 
   # so I have to drop down to native interface to get things to work
   pgsci(2);
   pgslw(4);

   # Another kludge, PDL makes it really difficult for us to do text 
   # positioning relative to the viewport. So I'm dropping down and 
   # using the native interface (again)
   pgmtxt( 'LV', 0.0, 1.11, 0.0, $id[$i] );
   pgmtxt( 'LV', 0.0, 1.07, 0.0, "PI     : $piname" );
   pgmtxt( 'LV', 0.0, 1.03, 0.0, "Run ID: $runid" );
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
                  { COLOUR => 4, LINESTYLE => 1, LINEWIDTH => 4.0 } );
   $window->line( $northx, $northy,
                  { COLOUR => 4, LINESTYLE => 1, LINEWIDTH => 4.0 } );
   
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
                  { COLOUR => 4, CHARSIZE => 1.2,  LINEWIDTH => 4.0 } );
   $window->text( "E", $east_xtext, $east_ytext,
                  { COLOUR => 4, CHARSIZE => 1.2,  LINEWIDTH => 4.0 } );
                  
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
          print "  Saving finding chart: " . $file_id . ".ps\n";
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
