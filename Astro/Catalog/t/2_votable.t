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
my %mags1 = ( R => '16.1', B => '16.4', V => '16.3' );
my %mag_error1 = ( R => '0.1', B => '0.4', V => '0.3' );
my %colours1 = ( 'B-V' => '0.1', 'B-R' => '0.3' );
my %col_error1 = ( 'B-V' => '0.02', 'B-R' => '0.05' );

# create a star
$star[0] = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                      RA         => '09 55 39',
                                      Dec        => '+60 07 23.6',
                                      Magnitudes => \%mags1,
                                      MagErr     => \%mag_error1,
                                      Colours    => \%colours1,
                                      ColErr     => \%col_error1,
                                      Quality    => '0',
                                      GSC        => 'FALSE',
                                      Distance   => '0.09',
                                      PosAngle   => '50.69',
                                      Field      => '00080' );

isa_ok( $star[0], "Astro::Catalog::Star");

# STAR 2
# ------

# magnitude and colour hashes
my %mags2 = ( R => '9.5', B => '9.3', V => '9.1' );
my %mag_error2 = ( R => '0.6', B => '0.2', V => '0.1' );
my %colours2 = ( 'B-V' => '-0.2', 'B-R' => '0.2' );
my %col_error2 = ( 'B-V' => '0.05', 'B-R' => '0.07' );

# create a star
$star[1] = new Astro::Catalog::Star( ID         => 'U1500_01194795',
                                     RA         => '10 44 57',
                                     Dec        => '+12 34 53.5',
                                     Magnitudes => \%mags2,
                                     MagErr     => \%mag_error2,
                                     Colours    => \%colours2,
                                     ColErr     => \%col_error2,
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

  skip "VOTable module not found", 125 unless $hasvo;

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
my %mags3 = ( R => '16.1', B => '16.4', V => '16.3' );
my %colours3 = ( 'B-V' => '0.1', 'B-R' => '0.3' );

# create a star
$star2[0] = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                      RA         => '09 55 39',
                                      Dec        => '+60 07 23.6',
                                      Magnitudes => \%mags3,
                                      Colours    => \%colours3,
                                      Quality    => '0' );
isa_ok( $star2[0], "Astro::Catalog::Star");

# STAR 3
# ------

# magnitude and colour hashes
my %mags4 = ( R => '9.5', B => '9.3', V => '9.1' );
my %colours4 = ( 'B-V' => '-0.2', 'B-R' => '0.2' );

# create a star
$star2[1] = new Astro::Catalog::Star( ID         => 'U1500_01194795',
                                     RA         => '10 44 57',
                                     Dec        => '+12 34 53.5',
                                     Magnitudes => \%mags2,
                                     Colours    => \%colours2,
                                     Quality    => '0' );

isa_ok( $star2[1], "Astro::Catalog::Star");

# Create Catalog Object
# ---------------------

my $catalog2 = new Astro::Catalog( Stars  => \@star2 );

isa_ok($catalog2, "Astro::Catalog");


# COMPARE CATALOGUES
# ==================
compare_catalog( $read_catalog, $catalog2 );

};

# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

END {
  unlink "$tempfile" if defined $tempfile;
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
      <FIELD name="B Magnitude" ucd="PHOT_MAG_B" datatype="double" unit="mag"/>
      <FIELD name="B Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="R Magnitude" ucd="PHOT_MAG_R" datatype="double" unit="mag"/>
      <FIELD name="R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="V Magnitude" ucd="PHOT_MAG_V" datatype="double" unit="mag"/>
      <FIELD name="V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-R Colour" ucd="PHOT_CI_B-R" datatype="double" unit="mag"/>
      <FIELD name="B-R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-V Colour" ucd="PHOT_CI_B-V" datatype="double" unit="mag"/>
      <FIELD name="B-V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="Quality" ucd="CODE_QUALITY" datatype="int" unit=""/>
      <DATA>
        <TABLEDATA>
          <TR>
            <TD>U1500_01194794</TD>
            <TD> 09:55:39.00</TD>
            <TD> 60:07:23.60</TD>
            <TD>16.4</TD>
            <TD>0.4</TD>
            <TD>16.1</TD>
            <TD>0.1</TD>
            <TD>16.3</TD>
            <TD>0.3</TD>
            <TD>0.3</TD>
            <TD>0.05</TD>
            <TD>0.1</TD>
            <TD>0.02</TD>
            <TD>0</TD>
          </TR>
          <TR>
            <TD>U1500_01194795</TD>
            <TD> 10:44:57.00</TD>
            <TD> 12:34:53.50</TD>
            <TD>9.3</TD>
            <TD>0.2</TD>
            <TD>9.5</TD>
            <TD>0.6</TD>
            <TD>9.1</TD>
            <TD>0.1</TD>
            <TD>0.2</TD>
            <TD>0.07</TD>
            <TD>-0.2</TD>
            <TD>0.05</TD>
            <TD>0</TD>
          </TR>
        </TABLEDATA>
      </DATA>
    </TABLE>
  </RESOURCE>
</VOTABLE>
