package Video::Frequencies;

=head1 NAME

Video::Frequencies - Many, many frequency constants and lists.

=head1 SYNOPSIS

   use Video::Frequencies;

   while (my($name,$list) = each %CHANLIST) {
      print "$name\n";
      while (my($channel,$freq) = each %$list) {
         printf "   %-4s %9d\n", $channel, $freq;
      }
      print "\n";
   }

=head1 DESCRIPTION

This module exports (yes, exports!) frequency constants as well as hashes
with channel => frequency relations for digital and analog video and audio
broadcast. Another, shorter way to put it is "worldwide channel/frequency
list". All frequencies are given in kHz.

It's a good idea to use C<perldoc -m Video::Frequencies> to get an idea
on how the various constants and lists look like.

=head1 Exported Audio Carrier Frequencies

   NTSC_AUDIO_CARRIER
   PAL_AUDIO_CARRIER_I
   PAL_AUDIO_CARRIER_BGHN
   PAL_AUDIO_CARRIER_MN
   PAL_AUDIO_CARRIER_D
   SEACAM_AUDIO_DKK1L
   SEACAM_AUDIO_BG	
   NICAM728_PAL_BGH
   NICAM728_PAL_I

NICAM 728 32-kHz, 14-bit digital stereo audio is transmitted in 1ms frames
containing 8 bits frame sync, 5 bits control, 11 bits additional data,
and 704 bits audio data.  The bit rate is reduced by transmitting only
10 bits plus parity of each 14 bit sample, the largest sample in a frame
determines which 10 bits are transmitted.  The parity bits for audio
samples also specify the scaling factor used for that channel during that
frame.  The companeded audio data is interleaved to reduce the influence
of dropouts and the whole frame except for sync bits is scrambled for
spectrum shaping.  Data is modulated using QPSK, at below following
subcarrier freqs

=head1 Broadcast Format by Country

=over 4

=item (M) NTSC

Antigua, Aruba, Bahamas, Barbados, Belize, Bermuda, Bolivia, Burma,
Canada, Chile, Colombia, Costa Rica, Cuba, Curacao, Dominican Republic,
Ecuador, El Salvador, Guam Guatemala, Honduras, Jamaica, Japan, South
Korea, Mexico, Montserrat, Myanmar, Nicaragua, Panama, Peru, Philippines,
Puerto Rico, St Christopher and Nevis, Samoa, Suriname, Taiwan,
Trinidad/Tobago, United States, Venezuela, Virgin Islands

=item (B) PAL

Albania, Algeria, Australia, Austria, Bahrain, Bangladesh, Belgium,
Bosnia-Herzegovinia, Brunei Darussalam, Cambodia, Cameroon, Croatia,
Cyprus, Denmark, Egypt, Ethiopia, Equatorial Guinea, Finland, Germany,
Ghana, Gibraltar, Greenland, Iceland, India, Indonesia, Israel, Italy,
Jordan, Kenya, Kuwait, Liberia, Libya, Luxembourg, Malaysa, Maldives,
Malta, Nepal, Netherlands, New Zeland, Nigeria, Norway, Oman, Pakistan,
Papua New Guinea, Portugal, Qatar, Sao Tome and Principe, Saudi Arabia,
Seychelles, Sierra Leone, Singapore, Slovenia, Somali, Spain, Sri Lanka,
Sudan, Swaziland, Sweden, Switzeland, Syria, Thailand, Tunisia, Turkey,
Uganda, United Arab Emirates, Yemen

=item (N) PAL

Argentina (Combination N), Paraguay, Uruguay

=item (M) PAL (525/60, 3.57MHz burst)

Brazil

=item (G) PAL

Albania, Algeria, Austria, Bahrain, Bosnia/Herzegovinia, Cambodia,
Cameroon, Croatia, Cyprus, Denmark, Egypt, Ethiopia, Equatorial Guinea,
Finland, Germany, Gibraltar, Greenland, Iceland, Israel, Italy, Jordan,
Kenya, Kuwait, Liberia, Libya, Luxembourg, Malaysia, Monaco, Mozambique,
Netherlands, New Zealand, Norway, Oman, Pakistan, Papa New Guinea,
Portugal, Qatar, Romania, Sierra Leone, Singapore, Slovenia, Somalia,
Spain, Sri Lanka, Sudan, Swaziland, Sweeden, Switzerland, Syria, Thailand,
Tunisia, Turkey, United Arab Emirates, Yemen, Zambia, Zimbabwe

=item (D) PAL

China, North Korea, Romania, Czech Republic

=item (H) PAL

Belgium

=item (I) PAL

Angola, Botswana, Gambia, Guinea-Bissau, Hong Kong, Ireland, Lesotho,
Malawi, Nambia, Nigeria, South Africa, Tanzania, United Kingdom, Zanzibar

=item (B) SECAM

Djibouti, Greece, Iran, Iraq, Lebanon, Mali, Mauritania, Mauritus, Morocco

=item (D) SECAM

Afghanistan, Armenia, Azerbaijan, Belarus, Bulgaria, Estonia, Georgia,
Hungary, Zazakhstan, Lithuania, Mongolia, Moldova, Poland, Russia, Slovak
Republic, Ukraine, Vietnam

=item (G) SECAM

Greece, Iran, Iraq, Mali, Mauritus, Morocco, Saudi Arabia

=item (K) SECAM

Armenia, Azerbaijan, Bulgaria, Estonia, Georgia, Hungary, Kazakhstan,
Lithuania, Madagascar, Moldova, Poland, Russia, Slovak Republic, Ukraine,
Vietnam

=item (K1) SECAM

Benin, Burkina Faso, Burundi, Chad, Cape Verde, Central African Republic,
Comoros, Congo, Gabon, Madagascar, Niger, Rwanda, Senegal, Togo, Zaire

=item (L) SECAM

France

=back

=head1 Channel->Frequency Relations

The Channel->Frequency relations are stored in the following hashes. The
keys are the Channel names, the values are the corresponding frequency in
kHz. For example, "arte" is channel "SE6" in the town in Germany I live
in, so, consequently, $PAL_EUROPE{SE6} equals 140250, the frequency I have
to tune my receiver.

   US broadcast          %NTSC_BCAST
   US cable              %NTSC_CABLE
   US HRC                %NTSC_HRC
   JP broadcast          %NTSC_BCAST_JP
   JP cable              %NTSC_CABLE_JP
   Australia             %PAL_AUSTRALIA
   Europe                %PAL_EUROPE
   Europe East           %PAL_EUROPE_EAST
   Italy                 %PAL_ITALY
   Ireland               %PAL_IRELAND
   Newzealand            %PAL_NEWZEALAND

   CCIR frequencies      %FREQ_CCIR_I_III
                         %FREQ_CCIR_SL_SH
                         %FREQ_CCIR_H
   OIRT frequencies      %FREQ_OIRT_I_III
                         %FREQ_OIRT_SL_SH
                         %FREQ_UHF

=head1 The List of Lists

The hash %CHANLIST contains name => channel-list pairs, e.g.
$CHANLIST{"ntsc-bcast"} contains a reference to %NTSC_BCAST.

=head1 AUTHOR

Nathan Laredo (laredo@broked.net), adapted to perl by Marc Lehmann
<pcg@goof.com>

=cut

require Exporter;
@ISA = 'Exporter';
$VERSION = 0.01;

@EXPORT = qw(
   NTSC_AUDIO_CARRIER
   PAL_AUDIO_CARRIER_I     PAL_AUDIO_CARRIER_BGHN  PAL_AUDIO_CARRIER_MN PAL_AUDIO_CARRIER_D
   SEACAM_AUDIO_DKK1L      SEACAM_AUDIO_BG         
   NICAM728_PAL_BGH        NICAM728_PAL_I

   %NTSC_BCAST          %NTSC_CABLE             %NTSC_HRC
   %NTSC_BCAST_JP       %NTSC_CABLE_JP
   %FREQ_CCIR_I_III     %FREQ_CCIR_SL_SH        %FREQ_CCIR_H
   %FREQ_OIRT_I_III     %FREQ_OIRT_SL_SH        %FREQ_UHF
   %PAL_AUSTRALIA       %PAL_EUROPE             %PAL_EUROPE_EAST
   %PAL_ITALY           %PAL_IRELAND            %PAL_NEWZEALAND

   %CHANLIST
);

sub NTSC_AUDIO_CARRIER()	{4500}
sub PAL_AUDIO_CARRIER_I()	{6000}
sub PAL_AUDIO_CARRIER_BGHN()	{5500}
sub PAL_AUDIO_CARRIER_MN()	{4500}
sub PAL_AUDIO_CARRIER_D()	{6500}
sub SEACAM_AUDIO_DKK1L()	{6500}
sub SEACAM_AUDIO_BG()		{5500}
sub NICAM728_PAL_BGH()		{5850}
sub NICAM728_PAL_I()		{6552}

%NTSC_BCAST = (
      "2",	 55250,
      "3",	 61250,
      "4",	 67250,
      "5",	 77250,
      "6",	 83250,
      "7",	175250,
      "8",	181250,
      "9",	187250,
      "10",	193250,
      "11",	199250,
      "12",	205250,
      "13",	211250,
      "14",	471250,
      "15",	477250,
      "16",	483250,
      "17",	489250,
      "18",	495250,
      "19",	501250,
      "20",	507250,
      "21",	513250,
      "22",	519250,
      "23",	525250,
      "24",	531250,
      "25",	537250,
      "26",	543250,
      "27",	549250,
      "28",	555250,
      "29",	561250,
      "30",	567250,
      "31",	573250,
      "32",	579250,
      "33",	585250,
      "34",	591250,
      "35",	597250,
      "36",	603250,
      "37",	609250,
      "38",	615250,
      "39",	621250,
      "40",	627250,
      "41",	633250,
      "42",	639250,
      "43",	645250,
      "44",	651250,
      "45",	657250,
      "46",	663250,
      "47",	669250,
      "48",	675250,
      "49",	681250,
      "50",	687250,
      "51",	693250,
      "52",	699250,
      "53",	705250,
      "54",	711250,
      "55",	717250,
      "56",	723250,
      "57",	729250,
      "58",	735250,
      "59",	741250,
      "60",	747250,
      "61",	753250,
      "62",	759250,
      "63",	765250,
      "64",	771250,
      "65",	777250,
      "66",	783250,
      "67",	789250,
      "68",	795250,
      "69",	801250,

      "70",	807250,
      "71",	813250,
      "72",	819250,
      "73",	825250,
      "74",	831250,
      "75",	837250,
      "76",	843250,
      "77",	849250,
      "78",	855250,
      "79",	861250,
      "80",	867250,
      "81",	873250,
      "82",	879250,
      "83",	885250,
);

%NTSC_CABLE = (
      "1",	 73250,
      "2",	 55250,
      "3",	 61250,
      "4",	 67250,
      "5",	 77250,
      "6",	 83250,
      "7",	175250,
      "8",	181250,
      "9",	187250,
      "10",	193250,
      "11",	199250,
      "12",	205250,

      "13",	211250,
      "14",	121250,
      "15",	127250,
      "16",	133250,
      "17",	139250,
      "18",	145250,
      "19",	151250,
      "20",	157250,

      "21",	163250,
      "22",	169250,
      "23",	217250,
      "24",	223250,
      "25",	229250,
      "26",	235250,
      "27",	241250,
      "28",	247250,
      "29",	253250,
      "30",	259250,
      "31",	265250,
      "32",	271250,
      "33",	277250,
      "34",	283250,
      "35",	289250,
      "36",	295250,
      "37",	301250,
      "38",	307250,
      "39",	313250,
      "40",	319250,
      "41",	325250,
      "42",	331250,
      "43",	337250,
      "44",	343250,
      "45",	349250,
      "46",	355250,
      "47",	361250,
      "48",	367250,
      "49",	373250,
      "50",	379250,
      "51",	385250,
      "52",	391250,
      "53",	397250,
      "54",	403250,
      "55",	409250,
      "56",	415250,
      "57",	421250,
      "58",	427250,
      "59",	433250,
      "60",	439250,
      "61",	445250,
      "62",	451250,
      "63",	457250,
      "64",	463250,
      "65",	469250,
      "66",	475250,
      "67",	481250,
      "68",	487250,
      "69",	493250,

      "70",	499250,
      "71",	505250,
      "72",	511250,
      "73",	517250,
      "74",	523250,
      "75",	529250,
      "76",	535250,
      "77",	541250,
      "78",	547250,
      "79",	553250,
      "80",	559250,
      "81",	565250,
      "82",	571250,
      "83",	577250,
      "84",	583250,
      "85",	589250,
      "86",	595250,
      "87",	601250,
      "88",	607250,
      "89",	613250,
      "90",	619250,
      "91",	625250,
      "92",	631250,
      "93",	637250,
      "94",	643250,
      "95",	 91250,
      "96",	 97250,
      "97",	103250,
      "98",	109250,
      "99",	115250,
      "100",	649250,
      "101",	655250,
      "102",	661250,
      "103",	667250,
      "104",	673250,
      "105",	679250,
      "106",	685250,
      "107",	691250,
      "108",	697250,
      "109",	703250,
      "110",	709250,
      "111",	715250,
      "112",	721250,
      "113",	727250,
      "114",	733250,
      "115",	739250,
      "116",	745250,
      "117",	751250,
      "118",	757250,
      "119",	763250,
      "120",	769250,
      "121",	775250,
      "122",	781250,
      "123",	787250,
      "124",	793250,
      "125",	799250,

      "T7", 	  8250,
      "T8",	 14250,
      "T9",	 20250,
      "T10",	 26250,
      "T11",	 32250,
      "T12",	 38250,
      "T13",	 44250,
      "T14",	 50250,
);

%NTSC_HRC = (
      "1",	  72000,
      "2",	  54000,
      "3",	  60000,
      "4",	  66000,
      "5",	  78000,
      "6",	  84000,
      "7",	 174000,
      "8",	 180000,
      "9",	 186000,
      "10",	 192000,
      "11",	 198000,
      "12",	 204000,

      "13",	 210000,
      "14",	 120000,
      "15",	 126000,
      "16",	 132000,
      "17",	 138000,
      "18",	 144000,
      "19",	 150000,
      "20",	 156000,

      "21",	 162000,
      "22",	 168000,
      "23",	 216000,
      "24",	 222000,
      "25",	 228000,
      "26",	 234000,
      "27",	 240000,
      "28",	 246000,
      "29",	 252000,
      "30",	 258000,
      "31",	 264000,
      "32",	 270000,
      "33",	 276000,
      "34",	 282000,
      "35",	 288000,
      "36",	 294000,
      "37",	 300000,
      "38",	 306000,
      "39",	 312000,
      "40",	 318000,
      "41",	 324000,
      "42",	 330000,
      "43",	 336000,
      "44",	 342000,
      "45",	 348000,
      "46",	 354000,
      "47",	 360000,
      "48",	 366000,
      "49",	 372000,
      "50",	 378000,
      "51",	 384000,
      "52",	 390000,
      "53",	 396000,
      "54",	 402000,
      "55",	 408000,
      "56",	 414000,
      "57",	 420000,
      "58",	 426000,
      "59",	 432000,
      "60",	 438000,
      "61",	 444000,
      "62",	 450000,
      "63",	 456000,
      "64",	 462000,
      "65",	 468000,
      "66",	 474000,
      "67",	 480000,
      "68",	 486000,
      "69",	 492000,

      "70",	 498000,
      "71",	 504000,
      "72",	 510000,
      "73",	 516000,
      "74",	 522000,
      "75",	 528000,
      "76",	 534000,
      "77",	 540000,
      "78",	 546000,
      "79",	 552000,
      "80",	 558000,
      "81",	 564000,
      "82",	 570000,
      "83",	 576000,
      "84",	 582000,
      "85",	 588000,
      "86",	 594000,
      "87",	 600000,
      "88",	 606000,
      "89",	 612000,
      "90",	 618000,
      "91",	 624000,
      "92",	 630000,
      "93",	 636000,
      "94",	 642000,
      "95",	 900000,
      "96",	 960000,
      "97",	 102000,
      "98",	 108000,
      "99",	 114000,
      "100",	 648000,
      "101",	 654000,
      "102",	 660000,
      "103",	 666000,
      "104",	 672000,
      "105",	 678000,
      "106",	 684000,
      "107",	 690000,
      "108",	 696000,
      "109",	 702000,
      "110",	 708000,
      "111",	 714000,
      "112",	 720000,
      "113",	 726000,
      "114",	 732000,
      "115",	 738000,
      "116",	 744000,
      "117",	 750000,
      "118",	 756000,
      "119",	 762000,
      "120",	 768000,
      "121",	 774000,
      "122",	 780000,
      "123",	 786000,
      "124",	 792000,
      "125",	 798000,

      "T7",	   7000,
      "T8",	  13000,
      "T9",	  19000,
      "T10",	  25000,
      "T11",	  31000,
      "T12",	  37000,
      "T13",	  43000,
      "T14",	  49000,
);

%NTSC_BCAST_JP = (
      "1",   91250,
      "2",   97250,
      "3",  103250,
      "4",  171250,
      "5",  177250,
      "6",  183250,
      "7",  189250,
      "8",  193250,
      "9",  199250,
      "10", 205250,
      "11", 211250,
      "12", 217250,

      "13", 471250,
      "14", 477250,
      "15", 483250,
      "16", 489250,
      "17", 495250,
      "18", 501250,
      "19", 507250,
      "20", 513250,
      "21", 519250,
      "22", 525250,
      "23", 531250,
      "24", 537250,
      "25", 543250,
      "26", 549250,
      "27", 555250,
      "28", 561250,
      "29", 567250,
      "30", 573250,
      "31", 579250,
      "32", 585250,
      "33", 591250,
      "34", 597250,
      "35", 603250,
      "36", 609250,
      "37", 615250,
      "38", 621250,
      "39", 627250,
      "40", 633250,
      "41", 639250,
      "42", 645250,
      "43", 651250,
      "44", 657250,

      "45", 663250,
      "46", 669250,
      "47", 675250,
      "48", 681250,
      "49", 687250,
      "50", 693250,
      "51", 699250,
      "52", 705250,
      "53", 711250,
      "54", 717250,
      "55", 723250,
      "56", 729250,
      "57", 735250,
      "58", 741250,
      "59", 747250,
      "60", 753250,
      "61", 759250,
      "62", 765250,
);

%NTSC_CABLE_JP = (
      "13",	109250,
      "14",	115250,
      "15",	121250,
      "16",	127250,
      "17",	133250,
      "18",	139250,
      "19",	145250,
      "20",	151250,

      "21",	157250,
      "22",	165250,
      "23",	223250,
      "24",	231250,
      "25",	237250,
      "26",	243250,
      "27",	249250,
      "28",	253250,
      "29",	259250,
      "30",	265250,
      "31",	271250,
      "32",	277250,
      "33",	283250,
      "34",	289250,
      "35",	295250,
      "36",	301250,
      "37",	307250,
      "38",	313250,
      "39",	319250,
      "40",	325250,
      "41",	331250,
      "42",	337250,
      "43",	343250,
      "44",	349250,
      "45", 	355250,
      "46", 	361250,
      "47", 	367250,
      "48", 	373250,
      "49", 	379250,
      "50", 	385250,
      "51", 	391250,
      "52", 	397250,
      "53", 	403250,
      "54", 	409250,
      "55", 	415250,
      "56", 	421250,
      "57", 	427250,
      "58", 	433250,
      "59", 	439250,
      "60", 	445250,
      "61", 	451250,
      "62", 	457250,
      "63",	463250,
);

%PAL_AUSTRALIA = (
      "0",	 46250,
      "1",	 57250,
      "2",	 64250,
      "3",	 86250,
      "4",  	 95250,
      "5",  	102250,
      "6",  	175250,
      "7",  	182250,
      "8",  	189250,
      "9",  	196250,
      "10", 	209250,
      "11",	216250,
      "28",	527250,
      "29",	534250,
      "30",	541250,
      "31",	548250,
      "32",	555250,
      "33",	562250,
      "34",	569250,
      "35",	576250,
      "39",	604250,
      "40",	611250,
      "41",	618250,
      "42",	625250,
      "43",	632250,
      "44",	639250,
      "45",	646250,
      "46",	653250,
      "47",	660250,
      "48",	667250,
      "49",	674250,
      "50",	681250,
      "51",	688250,
      "52",	695250,
      "53",	702250,
      "54",	709250,
      "55",	716250,
      "56",	723250,
      "57",	730250,
      "58",	737250,
      "59",	744250,
      "60",	751250,
      "61",	758250,
      "62",	765250,
      "63",	772250,
      "64",	779250,
      "65",	786250,
      "66",	793250,
      "67",	800250,
      "68",	807250,
      "69",	814250,
);

%FREQ_CCIR_I_III = (
      "E2",	  48250,
      "E3",	  55250,
      "E4",	  62250,
				
      "S01",	  69250,
      "S02",	  76250,
      "S03",	  83250,
				
      "E5",	 175250,
      "E6",	 182250,
      "E7",	 189250,
      "E8",	 196250,
      "E9",	 203250,
      "E10",	 210250,
      "E11",	 217250,
      "E12",	 224250,
);

%FREQ_CCIR_SL_SH = (
      "SE1",	 105250,
      "SE2",	 112250,
      "SE3",	 119250,
      "SE4",	 126250,
      "SE5",	 133250,
      "SE6",	 140250,
      "SE7",	 147250,
      "SE8",	 154250,
      "SE9",	 161250,
      "SE10",    168250,
				
      "SE11",    231250,
      "SE12",    238250,
      "SE13",    245250,
      "SE14",    252250,
      "SE15",    259250,
      "SE16",    266250,
      "SE17",    273250,
      "SE18",    280250,
      "SE19",    287250,
      "SE20",    294250,
);

%FREQ_CCIR_H = (
      "S21", 303250,
      "S22", 311250,
      "S23", 319250,
      "S24", 327250,
      "S25", 335250,
      "S26", 343250,
      "S27", 351250,
      "S28", 359250,
      "S29", 367250,
      "S30", 375250,
      "S31", 383250,
      "S32", 391250,
      "S33", 399250,
      "S34", 407250,
      "S35", 415250,
      "S36", 423250,
      "S37", 431250,
      "S38", 439250,
      "S39", 447250,
      "S40", 455250,
      "S41", 463250,
);

%FREQ_OIRT_I_III = (
      "R1",       49750,
      "R2",       59250,
				
      "R3",       77250,
      "R4",       84250,
      "R5",       93250,
				
      "R6",	 175250,
      "R7",	 183250,
      "R8",	 191250,
      "R9",	 199250,
      "R10",	 207250,
      "R11",	 215250,
      "R12",	 223250,
);

%FREQ_OIRT_SL_SH = (
      "SR1",	 111250,
      "SR2",	 119250,
      "SR3",	 127250,
      "SR4",	 135250,
      "SR5",	 143250,
      "SR6",	 151250,
      "SR7",	 159250,
      "SR8",	 167250,
				
      "SR11",    231250,
      "SR12",    239250,
      "SR13",    247250,
      "SR14",    255250,
      "SR15",    263250,
      "SR16",    271250,
      "SR17",    279250,
      "SR18",    287250,
      "SR19",    295250,
);

%FREQ_UHF = (
      "21",  471250,
      "22",  479250,
      "23",  487250,
      "24",  495250,
      "25",  503250,
      "26",  511250,
      "27",  519250,
      "28",  527250,
      "29",  535250,
      "30",  543250,
      "31",  551250,
      "32",  559250,
      "33",  567250,
      "34",  575250,
      "35",  583250,
      "36",  591250,
      "37",  599250,
      "38",  607250,
      "39",  615250,
      "40",  623250,
      "41",  631250,
      "42",  639250,
      "43",  647250,
      "44",  655250,
      "45",  663250,
      "46",  671250,
      "47",  679250,
      "48",  687250,
      "49",  695250,
      "50",  703250,
      "51",  711250,
      "52",  719250,
      "53",  727250,
      "54",  735250,
      "55",  743250,
      "56",  751250,
      "57",  759250,
      "58",  767250,
      "59",  775250,
      "60",  783250,
      "61",  791250,
      "62",  799250,
      "63",  807250,
      "64",  815250,
      "65",  823250,
      "66",  831250,
      "67",  839250,
      "68",  847250,
      "69",  855250,
);

%PAL_EUROPE = (
    %FREQ_CCIR_I_III,
    %FREQ_CCIR_SL_SH,
    %FREQ_CCIR_H,
    %FREQ_UHF
);

%PAL_EUROPE_EAST = (
    %FREQ_OIRT_I_III,
    %FREQ_OIRT_SL_SH,
    %FREQ_CCIR_H,
    %FREQ_UHF
);

%PAL_ITALY = (
      "2",	 53750,
      "3",	 62250,
      "4",	 82250,
      "5",	175250,
      "6",	183750,
      "7",	192250,
      "8",	201250,
      "9",	210250,
      "10",	210250,
      "11",	217250,
      "12",	224250,
);

%PAL_IRELAND = (
      "0",    45750,
      "1",    53750,
      "2",    61750,
      "3",   175250,
      "4",   183250,
      "5",   191250,
      "6",   199250,
      "7",   207250,
      "8",   215250,
    %FREQ_UHF,
);

%PAL_NEWZEALAND = (
      "1", 	  45250,
      "2",	  55250,
      "3",	  62250,
      "4",	 175250,
      "5",	 182250,
      "5A",	 138250,
      "6",	 189250,
      "7",	 196250,
      "8",	 203250,
      "9",	 210250,
      "10",	 217250,
);

%CHANLIST = (
      "ntsc-bcast",      \%NTSC_BCAST,
      "ntsc-cable",      \%NTSC_CABLE,
      "ntsc-cable-hrc",  \%NTSC_HRC,
      "ntsc-bcast-jp",   \%NTSC_BCAST_JP,
      "ntsc-cable-jp",   \%NTSC_CABLE_JP,
      "pal-europe",      \%PAL_EUROPE,
      "pal-europe-east", \%PAL_EUROPE_EAST,
      "pal-italy",	 \%PAL_ITALY,
      "pal-newzealand",  \%PAL_NEWZEALAND,
      "pal-australia",   \%PAL_AUSTRALIA,
      "pal-ireland",     \%PAL_IRELAND,
);

1;
