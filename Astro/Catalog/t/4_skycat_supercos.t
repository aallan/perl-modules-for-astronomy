#!perl
# Astro::Catalog::Query::SuperCOSMOS

# strict
use strict;

#load test
use Test::More tests => 4066;
use File::Spec;
use Data::Dumper;

BEGIN {
  # load modules
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog");
  use_ok("Astro::Catalog::Query::SuperCOSMOS");
}

use Astro::Flux;
use Astro::FluxColor;
use Astro::Fluxes;
use Number::Uncertainty;

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# T E S T   H A R N E S S --------------------------------------------------

# Grab GSC sample from the DATA block
# -----------------------------------
my @buffer = <DATA>;
chomp @buffer;

# test catalog
my $catalog_read = new Astro::Catalog( Format => 'TST', Data => \@buffer,
      Origin => "SuperCOSMOS catalog - blue (UKJ) southern survey" );

# Grab each star in the catalog and add some value to it
my $catalog_data = new Astro::Catalog( );
$catalog_data->origin( $catalog_read->origin() );
$catalog_data->set_coords( $catalog_read->get_coords() ) 
                          if defined $catalog_read->get_coords(); 

my ( @oldstars, @newstars ); 
@oldstars = $catalog_read->allstars(); 
my ( @mags, @cols );
foreach my $i ( 0 ... $#oldstars ) {
  my ($cval, $err, $mag, $col );

  my $star = $oldstars[$i];  
  #print Dumper( $star );

  # if we have a non-zero quality, set the quality to 1 (this sucks!)
  $star->quality(1) if( $star->quality() != 0 ); 
    
    # calulate the errors
    
    $err = 0.04;
    if ( $star->get_magnitude( "BJ" ) != 99.999 ) {
       $err = 0.04 if $star->get_magnitude( "BJ" ) > 15.0;
       $err = 0.05 if $star->get_magnitude( "BJ" ) > 17.0;
       $err = 0.06 if $star->get_magnitude( "BJ" ) > 19.0;
       $err = 0.07 if $star->get_magnitude( "BJ" ) > 20.0;
       $err = 0.12 if $star->get_magnitude( "BJ" ) > 21.0;
       $err = 0.08 if $star->get_magnitude( "BJ" ) > 22.0;  
    } else {
       $err = 99.999;
    }
    $mag = new Astro::Flux( new Number::Uncertainty( 
          Value => $star->get_magnitude("BJ"), Error => $err ), 'mag', 'BJ' );
    push @mags, $mag;	  

    $err = 0.06;      
    if ( $star->get_magnitude( "R1" ) != 99.999 ) {
       $err = 0.06 if $star->get_magnitude( "R1" ) > 11.0;
       $err = 0.03 if $star->get_magnitude( "R1" ) > 12.0;
       $err = 0.09 if $star->get_magnitude( "R1" ) > 13.0;
       $err = 0.10 if $star->get_magnitude( "R1" ) > 14.0;
       $err = 0.12 if $star->get_magnitude( "R1" ) > 18.0;
       $err = 0.18 if $star->get_magnitude( "R1" ) > 19.0;
    } else {
       $err = 99.999;
    }
    $mag = new Astro::Flux( new Number::Uncertainty( 
          Value => $star->get_magnitude("R1"), Error => $err ), 'mag', 'R1' );
    push @mags, $mag;	
    
    $err = 0.02;
    if ( $star->get_magnitude( "R2" ) != 99.999 ) {
       $err = 0.02 if $star->get_magnitude( "R2" ) > 12.0;
       $err = 0.03 if $star->get_magnitude( "R2" ) > 13.0;
       $err = 0.04 if $star->get_magnitude( "R2" ) > 15.0;
       $err = 0.05 if $star->get_magnitude( "R2" ) > 17.0;
       $err = 0.06 if $star->get_magnitude( "R2" ) > 18.0;
       $err = 0.11 if $star->get_magnitude( "R2" ) > 19.0;
       $err = 0.16 if $star->get_magnitude( "R2" ) > 20.0;
    } else {
       $err = 99.999;
    }
    $mag = new Astro::Flux( new Number::Uncertainty( 
          Value => $star->get_magnitude("R2"), Error => $err ), 'mag', 'R2' );
    push @mags, $mag;
     
    $err = 0.05;   
    if ( $star->get_magnitude( "I" ) != 99.999 ) {
       $err = 0.05 if $star->get_magnitude( "I" ) > 15.0;
       $err = 0.06 if $star->get_magnitude( "I" ) > 16.0;
       $err = 0.09 if $star->get_magnitude( "I" ) > 17.0;
       $err = 0.16 if $star->get_magnitude( "I" ) > 18.0;
    } else {
       $err = 99.999;
    }
    $mag = new Astro::Flux( new Number::Uncertainty( 
          Value => $star->get_magnitude("I"), Error => $err ), 'mag', 'I' );
    push @mags, $mag;
        
    # calculate colours UKST Bj - UKST R, UKST Bj - UKST I
    
    if ( $star->get_magnitude( "BJ" ) != 99.999 &&
         $star->get_magnitude( "R2" ) != 99.999  ) {
    
       my $bj_minus_r2 = $star->get_magnitude( "BJ" ) -
                         $star->get_magnitude( "R2" );
       $bj_minus_r2 =  sprintf("%.4f", $bj_minus_r2 );
       
       my $delta_bjmr = ( ( $star->get_errors( "BJ" ) )**2.0 +
                          ( $star->get_errors( "R2" ) )**2.0     )** (1/2);
       $delta_bjmr = sprintf("%.4f", $delta_bjmr ); 
       
       $cval = $bj_minus_r2;
       $err = $delta_bjmr;                 
       
    } else {
       $cval = 99.999;
       $err = 99.999;
    }                              
    $col = new Astro::FluxColor( upper => 'BJ', lower => "R2",
       quantity => new Number::Uncertainty( Value => $cval, Error => $err ) );
    push @cols, $col;
    
    if ( $star->get_magnitude( "BJ" ) != 99.999 &&
         $star->get_magnitude( "I" ) != 99.999  ) {
          
       my $bj_minus_i = $star->get_magnitude( "BJ" ) - 
                        $star->get_magnitude( "I" );   
       $bj_minus_i =  sprintf("%.4f", $bj_minus_i );
       
       my $delta_bjmi = ( ( $star->get_errors( "BJ" ) )**2.0 +
                          ( $star->get_errors( "I" ) )**2.0     )** (1/2);
       $delta_bjmi = sprintf("%.4f", $delta_bjmi );                  

       $cval = $bj_minus_i;
       $err = $delta_bjmi; 
              
    } else {
       $cval = 99.999;
       $err = 99.999;
    }                                  
    $col = new Astro::FluxColor( upper => 'BJ', lower => "I",
       quantity => new Number::Uncertainty( Value => $cval, Error => $err ) );
    push @cols, $col;
        
    # Push the data back into the star object, overwriting ther previous
    # values we got from the initial Skycat query. This isn't a great 
    # solution, but it wasn't easy in version 3 syntax either, so I guess
    # your milage may vary.
    
    my $fluxes = new Astro::Fluxes( @mags, @cols );
    $star->fluxes( $fluxes, 1 );  # the 1 means overwrite the previous values
     
  
  # push it onto the stack
  $newstars[$i] = $star if defined $star;
  
  
}
$catalog_data->pushstar( @newstars );  

# field centre
$catalog_data->fieldcentre( RA => '12 52 24.40', 
                            Dec => '-29 14 56.70', 
                            Radius => '1' );
$catalog_data->sort_catalog( "ra" );

# Grab comparison from ROE Archive Site
# -------------------------------------
my $supercos = new Astro::Catalog::Query::SuperCOSMOS( 
						    RA      => '12 52 24.40',
						    Dec     => '-29 14 56.70',
						    Radius  => '1',
						    Colour  => 'UKJ',
                                                    Timeout => '60'
						  );
print "# Reseting \$cfg_file to local copy in ./etc \n";
my $file = File::Spec->catfile( '.', 'etc', 'sss.cfg' );
$supercos->cfg_file( $file );                                                  
                                                     
print "# Connecting to SSScat_UKJ\@WFAU \n";
my $catalog = $supercos->querydb();
print "# Continuing tests\n";

# sort by RA
$catalog->sort_catalog( "ra" );

# C O M P A R I S O N ------------------------------------------------------

# check sizes
print "# DAT has " . $catalog_data->sizeof() . " stars\n";
print "# NET has " . $catalog->sizeof() . " stars\n";


# and compare content
compare_catalog( $catalog, $catalog_data );

# quitting time
exit;

# D A T A   B L O C K  -----------------------------------------------------
__DATA__
QueryResult
 
# Config entry for catalogue:
serv_type: local
symbol: {PA A_I B_I AREA} {ellipse white {double($B_I)/double($A_I)} {($PA)} {} {}} {{sqrt(7.0*$AREA*double($B_I)/(22.0*double($A_I)))} {}}
# End config entry
 
# CURSA extensions for info and readability:
#column-units: none 	DEGREES{IHMS.3}	DEGREES{+IDMS.2}	year            	mas/yr          	mas/yr          	mas/yr          	mas/yr          	magnitude       	magnitude       	magnitude       	magnitude       	pixels          	0.01 um         	0.01 um         	degrees         	                	sigma           	                	                	                 
#column-types: INTEGER	DOUBLE	DOUBLE	REAL	REAL	REAL	REAL	REAL	REAL	REAL	REAL	REAL	INTEGER	INTEGER	INTEGER	INTEGER	INTEGER	REAL	INTEGER	INTEGER	INTEGER 
#column-formats: I6	F11.7	F11.7	F9.3 	E12.4	E12.4	E12.4	E12.4	F7.3 	F7.3 	F7.3 	F7.3 	I9   	I7   	I7   	I3   	I2   	F8.3 	I6   	I10  	I5    
 
id	ra	dec	objepoch	MU_ACOSD	MU_D	SIGMU_A	SIGMU_D	B_J	R_1	R_2	I	AREA	A_I	B_I	PA	CLASS	N_0_1	BLEND	QUALITY	FLDNO 
--	--	---	-----	--------	----	-------	-------	---	---	---	-	----	---	---	--	-----	-----	-----	-------	----- 
000001	193.1122942	-29.2493333	1978.128	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.304	 99.999	 99.999	 99.999	       10	   2562	   1258	 70	1	   1.587	     0	      1024	 443 
000002	193.1080778	-29.2492903	1978.128	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 21.346	 99.999	 99.999	 99.999	       28	   5496	   1742	 91	1	   8.158	     0	      1024	 443 
000003	193.0950717	-29.2489786	1978.128	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 21.235	 99.999	 99.999	 99.999	       30	   7345	   1935	 96	1	  11.113	     0	      1024	 443 
000004	193.0974214	-29.2461116	1978.128	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.489	 99.999	 99.999	 99.999	        8	   2719	   1241	153	1	   1.128	     0	      1024	 443 
000005	193.1043479	-29.2442769	1978.128	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.445	 99.999	 99.999	 99.999	        9	   2793	   1311	  0	1	   1.887	     0	      1024	 443 
000006	193.1026725	-29.2402181	1978.128	 -0.9516E+01	  0.7271E+02	  0.2589E+02	  0.2423E+02	 21.922	 99.999	 21.121	 99.999	       15	   3704	   1386	 38	1	   5.161	     0	      1024	 443 
000007	193.0947273	-29.2635323	1980.206	 -0.1736E+02	 -0.2671E+01	  0.1769E+02	  0.1624E+02	 20.965	 19.728	 19.724	 18.650	       42	   4394	   2821	 82	1	   6.951	     0	         0	 442 
000008	193.1055436	-29.2623245	1980.206	  0.4489E+01	 -0.1493E+02	  0.1330E+02	  0.1206E+02	 20.873	 18.766	 18.982	 17.384	       43	   3636	   2816	110	1	   3.715	     0	         0	 442 
000009	193.0989850	-29.2620782	1980.206	 -0.2115E+02	 -0.2144E+02	  0.9627E+01	  0.7928E+01	 20.791	 18.537	 18.667	 16.662	       37	   2893	   2807	 66	2	  -0.308	     0	         0	 442 
000010	193.1023901	-29.2618650	1980.206	  0.2078E+02	 -0.8061E+01	  0.1486E+02	  0.1348E+02	 20.611	 19.892	 19.965	 19.345	       41	   3423	   2604	 87	2	   1.112	     0	         0	 442 
000011	193.1067004	-29.2575444	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.263	 99.999	 99.999	 99.999	       15	   3879	   2082	 20	1	   2.786	     0	         0	 442 
000012	193.1040058	-29.2550027	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.731	 99.999	 99.999	 99.999	        8	   3191	    787	168	1	   0.217	     0	         0	 442 
000013	193.1016876	-29.2490669	1980.206	 -0.1066E+03	  0.2305E+02	  0.8152E+01	  0.6841E+01	 13.111	 12.796	 12.527	 12.482	      599	   9755	   9264	 76	2	  -0.648	     0	        16	 442 
000014	193.1044705	-29.2474695	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.472	 99.999	 99.999	 99.999	       11	   3029	   1664	134	2	   1.331	     0	         0	 442 
000015	193.0955214	-29.2463533	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 21.674	 99.999	 99.999	 99.999	       20	   5103	   2001	114	1	   8.410	     0	         0	 442 
000016	193.1098500	-29.2458279	1980.206	 -0.9542E+01	 -0.5573E+01	  0.6180E+01	  0.4520E+01	 17.297	 16.472	 16.536	 16.146	      139	   5028	   4397	117	2	  -0.141	     0	         0	 442 
000017	193.1069703	-29.2431425	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.278	 99.999	 99.999	 99.999	       11	   2723	   1471	 79	1	   2.842	     0	         0	 442 
000018	193.1178273	-29.2420029	1980.206	 -0.1900E+02	  0.3419E-02	  0.5929E+01	  0.4378E+01	 17.598	 16.056	 16.096	 15.501	      119	   4728	   3971	100	2	  -1.783	     0	        16	 442 
000019	193.1104882	-29.2402668	1980.206	 -0.1074E+02	 -0.5169E+01	  0.1198E+02	  0.1053E+02	 20.778	 18.913	 19.010	 18.291	       35	   2928	   2624	165	2	  -1.004	     0	         0	 442 
000020	193.1121876	-29.2380655	1980.206	  0.9999E+09	  0.9999E+09	  0.9999E+09	  0.9999E+09	 22.359	 99.999	 99.999	 99.999	        8	   3551	    829	 74	1	   4.184	     0	         0	 442 
[EOD]
