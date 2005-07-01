#!perl

# Astro::Catalog test harness
use Test::More tests => 133;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");
require_ok("Astro::Catalog::Star");

if( $@ ) {
  exit "Fatal Error: $@\n";
}  


# Do a private require so that we can skip the tests if VOTable is missing
eval {
  require Astro::VO::VOTable;
};
my $hasvo = ($@ ? 0 : 1);

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# T E S T   H A R N E S S --------------------------------------------------

# GENERATE A CATALOG
# ==================

my @star;

# STAR 1
# ------

# magnitude and colour hashes
my $flux1 = new Astro::Flux( new Number::Uncertainty ( Value => 16.1,
                                                       Error => 0.1 ),  
			     'mag', 'R' );
my $flux2 = new Astro::Flux( new Number::Uncertainty ( Value => 16.4,
                                                       Error => 0.4 ),  
			     'mag', 'B' );
my $flux3 = new Astro::Flux( new Number::Uncertainty ( Value => 16.3,
                                                       Error => 0.3 ),  
			     'mag', 'V' );
my $col1 = new Astro::FluxColor( upper => 'B', lower => 'V',
                     quantity => new Number::Uncertainty ( Value => 0.1,
                                                           Error => 0.02 ) );  			     
my $col2 = new Astro::FluxColor( upper => 'B', lower => 'R',
                     quantity => new Number::Uncertainty ( Value => 0.3,
                                                           Error => 0.05 ) );
my $fluxes1 = new Astro::Fluxes( $flux1, $flux2, $flux3, $col1, $col2 );	


# create a star
$star[0] = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                      RA         => '09 55 39',
                                      Dec        => '+60 07 23.6',
                                      Fluxes     => $fluxes1,
                                      Quality    => '0',
                                      GSC        => 'FALSE',
                                      Distance   => '0.09',
                                      PosAngle   => '50.69',
                                      Field      => '00080' );

isa_ok( $star[0], "Astro::Catalog::Star");

# STAR 2
# ------

# magnitude and colour hashes
my $flux4 = new Astro::Flux( new Number::Uncertainty ( Value => 9.5,
                                                       Error => 0.6 ),  
			     'mag', 'R' );
my $flux5 = new Astro::Flux( new Number::Uncertainty ( Value => 9.3,
                                                       Error => 0.2 ),  
			     'mag', 'B' );
my $flux6 = new Astro::Flux( new Number::Uncertainty ( Value => 9.1,
                                                       Error => 0.1 ),  
			     'mag', 'V' );
my $col3 = new Astro::FluxColor( upper => 'B', lower => 'V',
                     quantity => new Number::Uncertainty ( Value => -0.2,
                                                           Error => 0.05 ) );  			     
my $col4 = new Astro::FluxColor( upper => 'B', lower => 'R',
                     quantity => new Number::Uncertainty ( Value => 0.2,
                                                           Error => 0.07 ) );
my $fluxes2 = new Astro::Fluxes( $flux4, $flux5, $flux6, $col3, $col4 );

# create a star
$star[1] = new Astro::Catalog::Star( ID         => 'U1500_01194795',
                                     RA         => '10 44 57',
                                     Dec        => '+12 34 53.5',
                                     Fluxes     => $fluxes2,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.08',
                                     PosAngle   => '12.567',
                                     Field      => '00081' );

isa_ok( $star[1], "Astro::Catalog::Star");

# Create Catalog Object
# ---------------------

my $catalog = new Astro::Catalog( RA     => '01 10 12.9',
                                  Dec    => '+60 04 35.9',
                                  Radius => '1',
                                  Stars  => \@star );

isa_ok($catalog, "Astro::Catalog");

my $tempfile; # for cleanup
SKIP: {

  skip "VOTable module not found", 128 unless $hasvo;

# WRITE IT OUT TO DISK USING THE VOTABLE WRITER
# =============================================
$tempfile = File::Spec->catfile( File::Spec->tmpdir(), "catalog.test" );

ok( $catalog->write_catalog( Format => 'VOTable', File => $tempfile ),
  "Check catalog write");
ok(-e $tempfile, "Check file exists");


# READ THE VOTABLE BACK FROM DISK INTO AN ARRAY
# =============================================

my $opstat = open(my $CAT, $tempfile);
ok( $opstat, "Read catalog from disk" );
my @file;
@file = <$CAT>;
chomp @file;
ok(close($CAT),"Closing catalog file");


# READ COMPARISON CATALOG FROM __DATA__
# =====================================

my @buffer = <DATA>;
chomp @buffer;

# COMPARE @file and @data
# =======================

foreach my $i ( 0 .. $#buffer ) {
   #print $buffer[$i] . "\n";
   #print $file[$i] . "\n";
   is( $buffer[$i], $file[$i], "Line $i in \@buffer ok" );
}

# READ CATALOG IN FROM TEMPORARY FILE USING THE VOTABLE READER
# ============================================================

my $read_catalog = new Astro::Catalog( Format => 'VOTable', File => $tempfile );
#print Dumper( $read_catalog );

# GENERATE A CATALOG
# ==================

my @star2;

# STAR 3
# ------

# magnitude and colour hashes
my $flux7 = new Astro::Flux( new Number::Uncertainty ( Value => 16.1 ),  
			     'mag', 'R' );
my $flux8 = new Astro::Flux( new Number::Uncertainty ( Value => 16.4  ),  
			     'mag', 'B' );
my $flux9 = new Astro::Flux( new Number::Uncertainty ( Value => 16.3 ),  
			     'mag', 'V' );
my $col5 = new Astro::FluxColor( upper => 'B', lower => 'V',
                     quantity => new Number::Uncertainty ( Value => 0.1) );  			     
my $col6 = new Astro::FluxColor( upper => 'B', lower => 'R',
                     quantity => new Number::Uncertainty ( Value => 0.3 ) );
my $fluxes3 = new Astro::Fluxes( $flux7, $flux8, $flux9, $col5, $col6 );

# create a star
$star2[0] = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                      RA         => '09 55 39',
                                      Dec        => '+60 07 23.6',
                                      Fluxes     => $fluxes3,
                                      Quality    => '0' );
isa_ok( $star2[0], "Astro::Catalog::Star");

# STAR 3
# ------

# magnitude and colour hashes
my $flux10 = new Astro::Flux( new Number::Uncertainty ( Value => 9.5 ),  
			     'mag', 'R' );
my $flux11 = new Astro::Flux( new Number::Uncertainty ( Value => 9.3 ),  
			     'mag', 'B' );
my $flux12 = new Astro::Flux( new Number::Uncertainty ( Value => 9.1 ),  
			     'mag', 'V' );
my $col7 = new Astro::FluxColor( upper => 'B', lower => 'V',
                     quantity => new Number::Uncertainty ( Value => -0.2 ) );  			     
my $col8 = new Astro::FluxColor( upper => 'B', lower => 'R',
                     quantity => new Number::Uncertainty ( Value => 0.2 ) );
my $fluxes4 = new Astro::Fluxes( $flux10, $flux11, $flux12, $col7, $col8 );

# create a star
$star2[1] = new Astro::Catalog::Star( ID         => 'U1500_01194795',
                                     RA         => '10 44 57',
                                     Dec        => '+12 34 53.5',
                                     Fluxes     => $fluxes4,
                                     Quality    => '0' );

isa_ok( $star2[1], "Astro::Catalog::Star");

# Create Catalog Object
# ---------------------

my $catalog2 = new Astro::Catalog( Stars  => \@star2 );

isa_ok($catalog2, "Astro::Catalog");

# COMPARE CATALOGUES
# ==================

#print Dumper( $read_catalog, $catalog2 );
compare_catalog( $read_catalog, $catalog2 );

};

# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

END {
  #unlink "$tempfile" if defined $tempfile;
}


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<VOTABLE>
  <DESCRIPTION>Created using Astro::Catalog::IO::VOTable</DESCRIPTION>
  <DEFINITIONS>
    <COOSYS ID="J2000" equinox="2000" epoch="2000" system="eq_FK5"/>
  </DEFINITIONS>
  <RESOURCE>
    <LINK title="eSTAR Project" href="http://www.estar.org.uk/" content-role="doc"/>
    <TABLE>
      <FIELD name="Identifier" ucd="ID_MAIN" datatype="char" unit="" arraysize="*"/>
      <FIELD name="RA" ucd="POS_EQ_RA_MAIN" datatype="char" unit="&quot;h:m:s.ss&quot;" arraysize="*"/>
      <FIELD name="Dec" ucd="POS_EQ_DEC_MAIN" datatype="char" unit="&quot;d:m:s.ss&quot;" arraysize="*"/>
      <FIELD name="R Magnitude" ucd="PHOT_MAG_R" datatype="double" unit="mag"/>
      <FIELD name="R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B Magnitude" ucd="PHOT_MAG_B" datatype="double" unit="mag"/>
      <FIELD name="B Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="V Magnitude" ucd="PHOT_MAG_V" datatype="double" unit="mag"/>
      <FIELD name="V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-V Colour" ucd="PHOT_CI_B-V" datatype="double" unit="mag"/>
      <FIELD name="B-V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-R Colour" ucd="PHOT_CI_B-R" datatype="double" unit="mag"/>
      <FIELD name="B-R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="Quality" ucd="CODE_QUALITY" datatype="int" unit=""/>
      <DATA>
        <TABLEDATA>
          <TR>
            <TD>U1500_01194794</TD>
            <TD>09:55:39.0</TD>
            <TD> 60:07:23.60</TD>
            <TD>16.1</TD>
            <TD>0.1</TD>
            <TD>16.4</TD>
            <TD>0.4</TD>
            <TD>16.3</TD>
            <TD>0.3</TD>
            <TD>0.1</TD>
            <TD>0.02</TD>
            <TD>0.3</TD>
            <TD>0.05</TD>
            <TD>0</TD>
          </TR>
          <TR>
            <TD>U1500_01194795</TD>
            <TD>10:44:57.0</TD>
            <TD> 12:34:53.50</TD>
            <TD>9.5</TD>
            <TD>0.6</TD>
            <TD>9.3</TD>
            <TD>0.2</TD>
            <TD>9.1</TD>
            <TD>0.1</TD>
            <TD>-0.2</TD>
            <TD>0.05</TD>
            <TD>0.2</TD>
            <TD>0.07</TD>
            <TD>0</TD>
          </TR>
        </TABLEDATA>
      </DATA>
    </TABLE>
  </RESOURCE>
</VOTABLE>
