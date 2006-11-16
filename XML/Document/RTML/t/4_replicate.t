# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More tests => 56;

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# read from data block
my @buffer = <DATA>;
chomp @buffer;  

my $xml = "";
foreach my $i ( 0 ... $#buffer ) {
   $xml = $xml . $buffer[$i];
}   

my $object;
ok ( $object = new XML::Document::RTML( XML => $xml ), "Created the object okay" );
#print Dumper( $object);

my $document;
ok( $document = $object->build( Type => "observation" ), "Build document without error" );
#print Dumper( $document );

my @copy = split "\n", $document;
foreach my $j ( 0 ... $#buffer ) {
   $buffer[$j] =~ s/^\s*//;
   $buffer[$j] =~ s/\s*$//;
   $copy[$j] =~ s/^\s*//;
   $copy[$j] =~ s/\s*$//;   
#   is( $buffer[$j], $copy[$j], "Comparing line $j of $#buffer\n$buffer[$j]\n$copy[$j]\n" );
   is( $buffer[$j], $copy[$j], "Comparing line $j of $#buffer" );
}

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE RTML SYSTEM "http://www.estar.org.uk/documents/rtml2.2.dtd">

<RTML version="2.2" type="observation">
    <Contact PI="true">
        <Name>Alasdair Allan</Name>
        <User>PATT/keith.horne</User>
        <Institution>eSTAR Project</Institution>
        <Email>aa@astro.ex.ac.uk</Email>
    </Contact>
    <Project>PL04B17</Project>
    <Telescope />
    <IntelligentAgent host="144.173.229.22" port="2048">001147:UA:v1-24:run#6:user#aa</IntelligentAgent>
    <Observation status="ok">
        <Target type="normal" ident="ExoPlanetMonitor">
            <TargetName>OB06515</TargetName>
            <Coordinates type="equitorial">
                <RightAscension format="hh mm ss.ss" units="hms">18 11 48.20</RightAscension>
                <Declination format="sdd mm ss.ss" units="dms">-28 18 59.10</Declination>
                <Equinox>J2000</Equinox>
            </Coordinates>
        </Target>
        <Device type="camera">
            <Filter>
                <FilterType>R</FilterType>
            </Filter>
        </Device>
        <Schedule priority="3">
            <Exposure type="time" units="seconds">
                <Count>3</Count>30.0            
            </Exposure>
            <TimeConstraint>
                <StartDateTime>2006-09-10T11:12:51+0100</StartDateTime>
                <EndDateTime>2006-09-12T00:12:51+0100</EndDateTime>
            </TimeConstraint>
        </Schedule>
        <ImageData type="FITS16" delivery="url" reduced="true">
            <FITSHeader type="all">HEADER 1</FITSHeader>
            <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_1.votable</ObjectList>        http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_2.fits    
        </ImageData>
        <ImageData type="FITS16" delivery="url" reduced="true">
            <FITSHeader type="all">HEADER 2</FITSHeader>
            <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_2_1_1.votable</ObjectList>        http://161.72.57.3/~estar/data/c_e_20060910_36_2_1_2.fits    
        </ImageData>
        <ImageData type="FITS16" delivery="url" reduced="true">
            <FITSHeader type="all">HEADER 3</FITSHeader>
            <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_3_1_1.votable</ObjectList>        http://161.72.57.3/~estar/data/c_e_20060910_36_3_1_2.fits    
        </ImageData>
    </Observation>
    <Score>0.10720720720720721</Score>
    <CompletionTime>2006-09-12T00:12:51+0100</CompletionTime>
</RTML>
