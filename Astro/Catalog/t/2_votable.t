#!perl

# Astro::Catalog test harness
use Test::More tests => 63;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");
require_ok("Astro::Catalog::Star");

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


# WRITE IT OUT TO DISK
# ====================
my $tempfile = File::Spec->catfile( File::Spec->tmpdir(), "catalog.test" );

ok( $catalog->write_catalog( Format => 'VOTable', File => $tempfile ),
  "Check catalog write");
 
# READ THE VOTABLE BACK FROM DISK INTO AN ARRAY
# =============================================

ok( open( CATALOG, $tempfile ), "Read catalog from disk" );
my @file = <CATALOG>;
chomp @file;
close(CATALOG); 


# READ COMPARISON CATALOG FROM __DATA__
# =====================================

my @buffer = <DATA>;
chomp @buffer;

# COMPARE @file and @data
# =======================

foreach my $i ( 0 .. $#buffer ) {
   print $buffer[$i] . "\n";
   print $file[$i] . "\n";
   ok( $buffer[$i] eq $file[$i], "Line $i in \@buffer ok" );
}

# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

END {
  #unlink "$tempfile";
}


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0"?>
<VOTABLE>
  <RESOURCE>
    <TABLE>
      <FIELD name="ID_MAIN"/>
      <FIELD name="POS_EQ_RA_MAIN"/>
      <FIELD name="POS_EQ_DEC_MAIN"/>
      <FIELD name="PHOT_MAG_B"/>
      <FIELD name="B_ERROR"/>
      <FIELD name="PHOT_MAG_R"/>
      <FIELD name="R_ERROR"/>
      <FIELD name="PHOT_MAG_V"/>
      <FIELD name="V_ERROR"/>
      <FIELD name="PHOT_CI_B-R"/>
      <FIELD name="B-R_ERROR"/>
      <FIELD name="PHOT_CI_B-V"/>
      <FIELD name="B-V_ERROR"/>
      <FIELD name="CODE_QUALITY"/>
      <DATA>
        <TABLEDATA>
          <TR>
            <TD>U1500_01194794</TD>
            <TD>09 55 39.00</TD>
            <TD>+60 07 23.60</TD>
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
            <TD>10 44 57.00</TD>
            <TD>+12 34 53.50</TD>
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
