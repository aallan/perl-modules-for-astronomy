package Video::Capture::VBI;

=head1 NAME

Video::Capture::VBI - Functions to manipulate vbi fields & lines.

=head1 SYNOPSIS

   use Video::Capture::VBI;

=head1 DESCRIPTION

=over 4

=item new

Create a new VBI decoder object. VBI decoding often requires state, which
this object represents

=item reset (NYI)

Reset the state (e.g. after switching a channel).

=back

=cut

BEGIN {
   require Exporter;
   require DynaLoader;
   @ISA = ('Exporter', 'DynaLoader');
   $VERSION = 0.05;
   @EXPORT = qw(
         decode_field decode_vtpage decode_ansi bcd2dec

         VBI_VT VBI_VPS VBI_VC VBI_VDAT VBI_EMPTY VBI_OTHER
         VTX_COLMASK VTX_GRSEP VTX_HIDDEN VTX_BOX VTX_FLASH VTX_DOUBLE1 VTX_DOUBLE2 VTX_INVERT VTX_DOUBLE

         VTX_SUB VTX_S1 VTX_S2 VTX_S3 VTX_S4
         VTX_C4 VTX_C5 VTX_C6 VTX_C7 VTX_C8 VTX_C9 VTX_C10 VTX_C11
         VTX_NOC VTX_C12 VTX_C13 VTX_C14

   );
   @EXPORT_OK = qw(
         %VPS_CNI %VT_NI
   );
   bootstrap Video::Capture::VBI $VERSION;
}

use Fcntl;

=head1 CONSTANTS / MASK OPERATORS

The following constants are available (see ETS 300 706 for a more thorough
definition).

   VTX_SUB 0x003f7f # S1..S4 field mask

   VTX_C4  0x000080 # erase page
   VTX_C5  0x004000 # newsflash
   VTX_C6  0x008000 # subtitle
   VTX_C7  0x010000 # suppress header
   VTX_C8  0x020000 # update indicator
   VTX_C9  0x040000 # interrupted sequence
   VTX_C10 0x080000 # inhibit display
   VTX_C11 0x100000 # magazine serial

   VTX_C12 0x200000 # ... option ...
   VTX_C13 0x400000 # ... character ...
   VTX_C14 0x800000 # ... set

The following mask functions all take a single "CTRL" bitfield and return
the corresponding subfield:

   VTX_S1  (shift    )&15 } # S1
   VTX_S2  (shift>> 4)& 7 } # S2
   VTX_S3  (shift>> 8)&15 } # S3
   VTX_S4  (shift>>12)& 3 } # S4
   VTX_NOC (shift>>21)& 7 } # national character set...

=cut

sub VTX_SUB (){ 0x003f7f }
sub VTX_S1  ($){ (shift    )&15 }
sub VTX_S2  ($){ (shift>> 4)& 7 }
sub VTX_S3  ($){ (shift>> 8)&15 }
sub VTX_S4  ($){ (shift>>12)& 3 }

sub VTX_C4  (){ 0x000080 } # erase page
sub VTX_C5  (){ 0x004000 } # newsflash
sub VTX_C6  (){ 0x008000 } # subtitle
sub VTX_C7  (){ 0x010000 } # suppress header
sub VTX_C8  (){ 0x020000 } # update indicator
sub VTX_C9  (){ 0x040000 } # interrupted sequence
sub VTX_C10 (){ 0x080000 } # inhibit display
sub VTX_C11 (){ 0x100000 } # magazine serial

sub VTX_NOC ($){ (shift>>21)& 7 } # national ...
sub VTX_C12 (){ 0x200000 } # ... option ...
sub VTX_C13 (){ 0x400000 } # ... character ...
sub VTX_C14 (){ 0x800000 } # ... set

%VPS_CNI = (0xdc1 => 'ARD bundesweit, Erstes Deutsches Fernsehen', 0xdc2 => 'ZDF bundesweit, Zweites Deutsches Fernsehen', 0xdc3 => 'ARD/ZDF / Gemeinsames Vormittagsprogramm', 0xdc4 => 'ARD-TV-Sternpunkt', 0xdc5 => 'ARD-TV-Sternpunkt-Fehlersieb, interne Störfallkennung', 0xdc6 => 'not to be used until 2003', 0xdc7 => 'Satelliten-Programm "3sat"(ARD/ZDF/ORF/SRG common programme)', 0xdc8 => 'Phoenix ARD/ZDF', 0xdc9 => 'Kinderkanal ARD/ZDF', 0xdca => 'BR-1 / Regionalprogramm', 0xdcb => 'BR-3 / landesweit (split at times)', 0xdcc => 'BR-3 / Süd', 0xdcd => 'BR-3 / Nord', 0xdce => 'HR-1 / Regionalprogramm', 0xdcf => 'Hessen 3 / landesweit', 0xdd0 => 'NDR-1 / Landesprogramm dreiländerweit (split at times)', 0xdd1 => 'NDR-1 / Landesprogramm Hamburg', 0xdd2 => 'NDR-1 / Landesprogramm Niedersachsen', 0xdd3 => 'NDR-1 / Landesprogramm Schleswig-Holstein', 0xdd4 => 'Nord-3 (common 3 Programme NDR, SFB, RB, split at times)', 0xdd5 => 'NDR-3 / dreiländerweit', 0xdd6 => 'NDR-3 / Hamburg', 0xdd7 => 'NDR-3 / Niedersachsen', 0xdd8 => 'NDR-3 / Schleswig-Holstein', 0xdd9 => 'RB-1 / Regionalprogramm', 0xdda => 'RB-3 (separation from Nord 3)', 0xddb => 'SFB-1 / Regionalprogramm', 0xddc => 'SFB-3 (separation from Nord 3)', 0xddd => 'SDR-1 + SWF-1 / Regionalprogramm Baden-Württemberg', 0xdde => 'SWF-1 / Regionalprogramm Rheinland-Pfalz', 0xddf => 'SR-1 / Regionalprogramm', 0xde0 => 'SW 3 (Südwest 3), Verbund 3 Programme SDR, SR, SWF', 0xde1 => 'SW 3 / Regionalprogramm Baden-Württemberg', 0xde2 => 'SW 3 / Regionalprogramm Saarland', 0xde3 => 'SW 3 / Regionalprogramm Baden-Württemberg Süd', 0xde4 => 'SW 3 / Regionalprogramm Rheinland-Pfalz', 0xde5 => 'WDR-1 / Regionalprogramm', 0xde6 => 'WDR-3 / landesweit (split at times)', 0xde7 => 'WDR-3 / Bielefeld', 0xde8 => 'WDR-3 / Dortmund', 0xde9 => 'WDR-3 / Düsseldorf', 0xdea => 'WDR-3 / Köln', 0xdeb => 'WDR-3 / Münster', 0xdec => 'SDR -1 / Regionalprogramm', 0xded => 'SW 3 / Regionalprogramm Baden-Württemberg Nord', 0xdee => 'SW 3 / Regionalprogramm Mannheim', 0xdef => 'SDR-1 + SWF-1 / Regionalprogramm Baden-Württemb und Rhld-Pfalz', 0xdf0 => 'SWF-1 / Regionalprogramm', 0xdf1 => 'NDR-1 / Landesprogramm Mecklenburg-Vorpommern', 0xdf2 => 'NDR-3 / Mecklenburg-Vorpommern', 0xdf3 => 'MDR-1 / Landesprogramm Sachsen', 0xdf4 => 'MDR-3 / Sachsen', 0xdf5 => 'MDR / Dresden', 0xdf6 => 'MDR-1 / Landesprogramm Sachsen-Anhalt', 0xdf7 => 'Lokal-Programm WDR-Dortmund', 0xdf8 => 'MDR-3 / Sachsen-Anhalt', 0xdf9 => 'MDR / Magdeburg', 0xdfa => 'MDR-1 / Landesprogramm Thüringen', 0xdfb => 'MDR-3 / Thüringen', 0xdfc => 'MDR / Erfurt', 0xdfd => 'MDR-1 / Regionalprogramm', 0xdfe => 'MDR-3 / landesweit', 0xd81 => 'ORB-1 / Regionalprogramm', 0xd82 => 'ORB-3 / landesweit', 0xd83 => 'not to be used until 2001', 0xd84 => 'not to be used until 2001', 0xd85 => 'Arte', 0xd86 => 'not to be used until 2001', 0xd87 => '1A-Fernsehen', 0xd88 => 'VIVA', 0xd89 => 'VIVA 2', 0xd8a => 'Super RTL', 0xd8b => 'RTL Club', 0xd8c => 'n-tv', 0xd8d => 'Deutsches Sportfernsehen', 0xd8e => 'VOX Fernsehen', 0xd8f => 'RTL 2', 0xd90 => 'RTL 2 / regional', 0xd91 => 'Eurosport', 0xd92 => 'Kabel 1', 0xd93 => 'not to be used until 2003', 0xd94 => 'PRO 7', 0xd95 => 'SAT 1 / Brandenburg', 0xd96 => 'SAT 1 / Thüringen', 0xd97 => 'SAT 1 / Sachsen', 0xd98 => 'SAT 1 / Mecklenburg-Vorpommern', 0xd99 => 'SAT 1 / Sachsen-Anhalt', 0xd9a => 'RTL / Regional', 0xd9b => 'RTL / Schleswig-Holstein', 0xd9c => 'RTL / Hamburg', 0xd9d => 'RTL / Berlin', 0xd9e => 'RTL / Niedersachsen', 0xd9f => 'RTL / Bremen', 0xda0 => 'RTL / Nordrhein-Westfalen', 0xda1 => 'RTL / Hessen', 0xda2 => 'RTL / Rheinland-Pfalz', 0xda3 => 'RTL / Baden-Württemberg', 0xda4 => 'RTL / Bayern', 0xda5 => 'RTL / Saarland', 0xda6 => 'RTL / Sachsen-Anhalt', 0xda7 => 'RTL / Mecklenburg-Vorpommern', 0xda8 => 'RTL / Sachsen', 0xda9 => 'RTL / Thüringen', 0xdaa => 'RTL / Brandenburg', 0xdab => 'RTL Plus', 0xdac => 'Premiere', 0xdad => 'SAT 1 / Regional', 0xdae => 'SAT 1 / Schleswig-Holstein', 0xdaf => 'SAT 1 / Hamburg', 0xdb0 => 'SAT 1 / Berlin', 0xdb1 => 'SAT 1 Niedersachsen', 0xdb2 => 'SAT 1 / Bremen', 0xdb3 => 'SAT 1 Nordrhein-Westfalen', 0xdb4 => 'SAT 1 / Hessen', 0xdb5 => 'SAT 1 / Rheinland-Pfalz', 0xdb6 => 'SAT 1 / Baden-Württemberg', 0xdb7 => 'SAT 1 / Bayern', 0xdb8 => 'SAT 1 / Saarland', 0xdb9 => 'SAT 1', 0xdba => 'TM3 Fernsehen', 0xdbb => 'Deutsche Welle Fernsehen Berlin', 0xdbc => 'not to be used until 2002', 0xdbd => 'Berlin-Offener Kanal', 0xdbe => 'Berlin-Mix-Channel II', 0xdbf => 'Berlin-Mix-Channel 1', 0xd41 => 'FESTIVAL', 0xd42 => 'MUXX', 0xd43 => 'EXTRA', 0xd7c => 'ONYX-TV', 0xd7d => 'QVC-Teleshopping', 0xd7e => 'Nickelodeon', 0xd7f => 'Home order Television', 0x4c1 => 'SRG, Schweizer Fernsehen DRS, SF 1', 0x4c2 => 'SSR, Télévision Suisse Romande, TSR 1', 0x4c3 => 'SSR, Televisione svizzera di lingua italiana, TSI 1', 0x4c4 => 'not to be used until 2004', 0x4c5 => 'not to be used until 2004', 0x4c6 => 'not to be used until 2007', 0x4c7 => 'SRG, Schweizer Fernsehen DRS, SF 2', 0x4c8 => 'SSR, Télévision Suisse Romande, TSR 2', 0x4c9 => 'SSR, Televisione svizzera di lingua italiana, TSI 2', 0x4ca => 'SRG SSR Sat Access', 0x481 => 'TeleZüri', 0x482 => 'Teleclub Abonnements-Fernsehen', 0x483 => '-', 0x484 => 'TeleBern', 0x485 => 'Tele M1', 0x486 => 'Star TV', 0x487 => 'Pro 7', 0x488 => 'TopTV', 0xac1 => 'ORF - FS 1', 0xac2 => 'ORF - FS 2', 0xac3 => 'ORF - FS 3', 0xacb => 'ORF- FS 2 / Lokalprogramm Burgenland', 0xacc => 'ORF- FS 2 / Lokalprogramm Kärnten', 0xacd => 'ORF- FS 2 / Lokalprogramm Niederösterreich', 0xace => 'ORF- FS 2 / Lokalprogramm Oberösterreich', 0xacf => 'ORF- FS 2 / Lokalprogramm Salzburg', 0xad0 => 'ORF- FS 2 / Lokalprogramm Steiermark', 0xad1 => 'ORF- FS 2 / Lokalprogramm Tirol', 0xad2 => 'ORF- FS 2 / Lokalprogramm Vorarlberg', 0xad3 => 'ORF- FS 2 / Lokalprogramm Wien');
%VT_NI = (0x1201 => ['BRTN TV1', 'Belgium', 0x1601, 0x3603], 0x3206 => ['Ka2', 'Belgium', 0x1606, 0x3606], 0x3203 => ['RTBF 1', 'Belgium'], 0x3204 => ['RTBF 2', 'Belgium'], 0x3202 => ['TV2', 'Belgium', 0x1602, 0x3602], 0x0404 => ['VT4', 'Belgium', 0x1604, 0x3604], 0x3205 => ['VTM', 'Belgium', 0x1605, 0x3605], 0x0385 => ['HRT', 'Croatia'], 0x4201 => ['Republic CT 1', 'Czech', 0x32c1, 0x3c21], 0x4202 => ['Republic CT 2', 'Czech', 0x32c2, 0x3c22], 0x4231 => ['Republic CT1 Regional', 'Czech', 0x32f1, 0x3c25], 0x4211 => ['Republic CT1 Regional, Brno', 'Czech', 0x32d1, 0x3b01], 0x4221 => ['Republic CT1 Regional, Ostravia', 'Czech', 0x32e1, 0x3b02], 0x4232 => ['Republic CT2 Regional', 'Czech', 0x32f2, 0x3b03], 0x4212 => ['Republic CT2 Regional, Brno', 'Czech', 0x32d2, 0x3b04], 0x4222 => ['Republic CT2 Regional, Ostravia', 'Czech', 0x32e2, 0x3b05], 0x4203 => ['Republic NOVA TV', 'Czech', 0x32c3, 0x3c23], 0x7392 => ['DR1', 'Denmark', 0x2901, 0x3901], 0x49cf => ['DR2', 'Denmark', 0x2903, 0x3903], 0x4502 => ['TV2', 'Denmark', 0x2902, 0x3902], 0x358f => ['OWL3', 'Finland', 0x260f, 0x3614], 0x3583 => ['YLE future use', 'Finland', 0x2603, 0x3608], 0x3584 => ['YLE future use', 'Finland', 0x2604, 0x3609], 0x3585 => ['YLE future use', 'Finland', 0x2605, 0x360a], 0x3586 => ['YLE future use', 'Finland', 0x2606, 0x360b], 0x3587 => ['YLE future use', 'Finland', 0x2607, 0x360c], 0x3588 => ['YLE future use', 'Finland', 0x2608, 0x360d], 0x3589 => ['YLE future use', 'Finland', 0x2609, 0x360e], 0x358a => ['YLE future use', 'Finland', 0x260a, 0x360f], 0x358b => ['YLE future use', 'Finland', 0x260b, 0x3610], 0x358c => ['YLE future use', 'Finland', 0x260c, 0x3611], 0x358d => ['YLE future use', 'Finland', 0x260d, 0x3612], 0x358e => ['YLE future use', 'Finland', 0x260e, 0x3613], 0x3581 => ['YLE1', 'Finland', 0x2601, 0x3601], 0x3582 => ['YLE2', 'Finland', 0x2602, 0x3607], 0x330a => ['Arte', 'France'], 0xfe01 => ['Euronews', 'France'], 0xf101 => ['Eurosport', 'France'], 0x33f2 => ['France 2', 'France', 0x2f02, 0x3f02], 0x33f3 => ['France 3', 'France', 0x2f03, 0x3f03], 0x33f1 => ['TF1', 'France'], 0xf500 => ['TV5', 'France'], 0x490a => ['Arte', 'Germany'], 0x5c49 => ['QVC D Gmbh', 'Germany'], 0x3004 => ['ET future use', 'Greece', 0x2104, 0x3104], 0x3005 => ['ET future use', 'Greece', 0x2105, 0x3105], 0x3006 => ['ET future use', 'Greece', 0x2106, 0x3106], 0x3007 => ['ET future use', 'Greece', 0x2107, 0x3107], 0x3008 => ['ET future use', 'Greece', 0x2108, 0x3108], 0x3009 => ['ET future use', 'Greece', 0x2109, 0x3109], 0x300a => ['ET future use', 'Greece', 0x210a, 0x310a], 0x300b => ['ET future use', 'Greece', 0x210b, 0x310b], 0x300c => ['ET future use', 'Greece', 0x210c, 0x310c], 0x300d => ['ET future use', 'Greece', 0x210d, 0x310d], 0x300e => ['ET future use', 'Greece', 0x210e, 0x310e], 0x300f => ['ET future use', 'Greece', 0x210f, 0x310f], 0x3001 => ['ET-1', 'Greece', 0x2101, 0x3101], 0x3002 => ['ET-2', 'Greece', 0x2102, 0x3102], 0x3003 => ['ET-3', 'Greece', 0x2103, 0x3103], 0x3601 => ['MTV1', 'Hungary'], 0x3681 => ['MTV1 future use', 'Hungary'], 0x3611 => ['MTV1 regional, Budapest', 'Hungary'], 0x3651 => ['MTV1 regional, Debrecen', 'Hungary'], 0x3661 => ['MTV1 regional, Miskolc', 'Hungary'], 0x3621 => ['MTV1 regional, Pécs', 'Hungary'], 0x3631 => ['MTV1 regional, Szeged', 'Hungary'], 0x3641 => ['MTV1 regional, Szombathely', 'Hungary'], 0x3602 => ['MTV2', 'Hungary'], 0x3682 => ['MTV2 future use', 'Hungary'], 0x3541 => ['Rikisutvarpid-Sjonvarp', 'Iceland'], 0x3532 => ['Network 2', 'Ireland', 0x4202, 0x3202], 0x3534 => ['RTE future use', 'Ireland', 0x4204, 0x3204], 0x3535 => ['RTE future use', 'Ireland', 0x4205, 0x3205], 0x3536 => ['RTE future use', 'Ireland', 0x4206, 0x3206], 0x3537 => ['RTE future use', 'Ireland', 0x4207, 0x3207], 0x3538 => ['RTE future use', 'Ireland', 0x4208, 0x3208], 0x3539 => ['RTE future use', 'Ireland', 0x4209, 0x3209], 0x353a => ['RTE future use', 'Ireland', 0x420a, 0x320a], 0x353b => ['RTE future use', 'Ireland', 0x420b, 0x320b], 0x353c => ['RTE future use', 'Ireland', 0x420c, 0x320c], 0x353d => ['RTE future use', 'Ireland', 0x420d, 0x320d], 0x353e => ['RTE future use', 'Ireland', 0x420e, 0x320e], 0x353f => ['RTE future use', 'Ireland', 0x420f, 0x320f], 0x3531 => ['RTE1', 'Ireland', 0x4201, 0x3201], 0x3533 => ['Teilifis na Gaeilge', 'Ireland', 0x4203, 0x3203], 0x390a => ['Arte', 'Italy'], 0xfa05 => ['Canale 5', 'Italy'], 0xfa06 => ['Italia 1', 'Italy'], 0x3901 => ['RAI 1', 'Italy'], 0x3902 => ['RAI 2', 'Italy'], 0x3903 => ['RAI 3', 'Italy'], 0xfa04 => ['Rete 4', 'Italy'], 0x3904 => ['Rete A', 'Italy'], 0x3997 => ['Tele+1', 'Italy'], 0x3998 => ['Tele+2', 'Italy'], 0x3999 => ['Tele+3', 'Italy'], 0xfa08 => ['TMC', 'Italy'], 0x3910 => ['TRS TV', 'Italy'], 0x3101 => ['Nederland 1', 'Netherlands', 0x4801, 0x3801], 0x3102 => ['Nederland 2', 'Netherlands', 0x4802, 0x3802], 0x3103 => ['Nederland 3', 'Netherlands', 0x4803, 0x3803], 0x3110 => ['NOS future use', 'Netherlands'], 0x3111 => ['NOS future use', 'Netherlands'], 0x3112 => ['NOS future use', 'Netherlands'], 0x3113 => ['NOS future use', 'Netherlands'], 0x3114 => ['NOS future use', 'Netherlands'], 0x3115 => ['NOS future use', 'Netherlands'], 0x3116 => ['NOS future use', 'Netherlands'], 0x3117 => ['NOS future use', 'Netherlands'], 0x3118 => ['NOS future use', 'Netherlands'], 0x3119 => ['NOS future use', 'Netherlands'], 0x311a => ['NOS future use', 'Netherlands'], 0x311b => ['NOS future use', 'Netherlands'], 0x311c => ['NOS future use', 'Netherlands'], 0x311d => ['NOS future use', 'Netherlands'], 0x311e => ['NOS future use', 'Netherlands'], 0x311f => ['NOS future use', 'Netherlands'], 0x3107 => ['NOS future use', 'Netherlands', 0x4807, 0x3807], 0x3108 => ['NOS future use', 'Netherlands', 0x4808, 0x3808], 0x3109 => ['NOS future use', 'Netherlands', 0x4809, 0x3809], 0x310a => ['NOS future use', 'Netherlands', 0x480a, 0x380a], 0x310b => ['NOS future use', 'Netherlands', 0x480b, 0x380b], 0x310c => ['NOS future use', 'Netherlands', 0x480c, 0x380c], 0x310d => ['NOS future use', 'Netherlands', 0x480d, 0x380d], 0x310e => ['NOS future use', 'Netherlands', 0x480e, 0x380e], 0x310f => ['NOS future use', 'Netherlands', 0x480f, 0x380f], 0x3104 => ['RTL 4', 'Netherlands', 0x4804, 0x3804], 0x3105 => ['RTL 5', 'Netherlands', 0x4805, 0x3805], 0x3106 => ['Veronica', 'Netherlands', 0x4806, 0x3806], 0x4701 => ['NRK1', 'Norway'], 0x4703 => ['NRK2', 'Norway'], 0x4702 => ['TV 2', 'Norway'], 0x4810 => ['TV Polonia', 'Poland'], 0x4801 => ['TVP1', 'Poland'], 0x4802 => ['TVP2', 'Poland'], 0x340a => ['Arte', 'Spain'], 0xca33 => ['C33', 'Spain'], 0xba01 => ['ETB 1', 'Spain'], 0x3402 => ['ETB 2', 'Spain'], 0xca03 => ['TV3', 'Spain'], 0x3e00 => ['TVE1', 'Spain'], 0xe100 => ['TVE2', 'Spain'], 0x4601 => ['SVT 1', 'Sweden', 0x4e01, 0x3e01], 0x4602 => ['SVT 2', 'Sweden', 0x4e02, 0x3e02], 0x4603 => ['SVT future use', 'Sweden', 0x4e03, 0x3e03], 0x4604 => ['SVT future use', 'Sweden', 0x4e04, 0x3e04], 0x4605 => ['SVT future use', 'Sweden', 0x4e05, 0x3e05], 0x4606 => ['SVT future use', 'Sweden', 0x4e06, 0x3e06], 0x4607 => ['SVT future use', 'Sweden', 0x4e07, 0x3e07], 0x4608 => ['SVT future use', 'Sweden', 0x4e08, 0x3e08], 0x4609 => ['SVT future use', 'Sweden', 0x4e09, 0x3e09], 0x460a => ['SVT future use', 'Sweden', 0x4e0a, 0x3e0a], 0x460b => ['SVT future use', 'Sweden', 0x4e0b, 0x3e0b], 0x460c => ['SVT future use', 'Sweden', 0x4e0c, 0x3e0c], 0x460d => ['SVT future use', 'Sweden', 0x4e0d, 0x3e0d], 0x460e => ['SVT future use', 'Sweden', 0x4e0e, 0x3e0e], 0x460f => ['SVT future use', 'Sweden', 0x4e0f, 0x3e0f], 0x4600 => ['SVT Test Txmns', 'Sweden', 0x4e00, 0x3e00], 0x4640 => ['TV 4', 'Sweden', 0x4e40, 0x3e40], 0x4641 => ['TV 4 future use', 'Sweden', 0x4e41, 0x3e41], 0x4642 => ['TV 4 future use', 'Sweden', 0x4e42, 0x3e42], 0x4643 => ['TV 4 future use', 'Sweden', 0x4e43, 0x3e43], 0x4644 => ['TV 4 future use', 'Sweden', 0x4e44, 0x3e44], 0x4645 => ['TV 4 future use', 'Sweden', 0x4e45, 0x3e45], 0x4646 => ['TV 4 future use', 'Sweden', 0x4e46, 0x3e46], 0x4647 => ['TV 4 future use', 'Sweden', 0x4e47, 0x3e47], 0x4648 => ['TV 4 future use', 'Sweden', 0x4e48, 0x3e48], 0x4649 => ['TV 4 future use', 'Sweden', 0x4e49, 0x3e49], 0x464a => ['TV 4 future use', 'Sweden', 0x4e4a, 0x3e4a], 0x464b => ['TV 4 future use', 'Sweden', 0x4e4b, 0x3e4b], 0x464c => ['TV 4 future use', 'Sweden', 0x4e4c, 0x3e4c], 0x464d => ['TV 4 future use', 'Sweden', 0x4e4d, 0x3e4d], 0x464e => ['TV 4 future use', 'Sweden', 0x4e4e, 0x3e4e], 0x464f => ['TV 4 future use', 'Sweden', 0x4e4f, 0x3e4f], 0x410a => ['SAT ACCESS', 'Switzerland', 0x24ca, 0x344a], 0x4101 => ['SF 1', 'Switzerland', 0x24c1, 0x3441], 0x4107 => ['SF 2', 'Switzerland', 0x24c7, 0x3447], 0x4103 => ['TSI 1', 'Switzerland', 0x24c3, 0x3443], 0x4109 => ['TSI 2', 'Switzerland', 0x24c9, 0x3449], 0x4102 => ['TSR 1', 'Switzerland', 0x24c2, 0x3442], 0x4108 => ['TSR 2', 'Switzerland', 0x24c8, 0x3448], 0x900a => ['ATV', 'Turkey'], 0x9006 => ['AVRASYA', 'Turkey', 0x4306, 0x3306], 0x900e => ['BRAVO TV', 'Turkey'], 0x9008 => ['Cine 5', 'Turkey'], 0x900d => ['EKO TV', 'Turkey'], 0x900c => ['EURO D', 'Turkey'], 0x9010 => ['FUN TV', 'Turkey'], 0x900f => ['GALAKSI TV', 'Turkey'], 0x900b => ['KANAL D', 'Turkey'], 0x9012 => ['KANAL D future use', 'Turkey'], 0x9013 => ['KANAL D future use', 'Turkey'], 0x9007 => ['Show TV', 'Turkey'], 0x9009 => ['Super Sport', 'Turkey'], 0x9011 => ['TEMPO TV', 'Turkey'], 0x9001 => ['TRT-1', 'Turkey', 0x4301, 0x3301], 0x9002 => ['TRT-2', 'Turkey', 0x4302, 0x3302], 0x9003 => ['TRT-3', 'Turkey', 0x4303, 0x3303], 0x9004 => ['TRT-4', 'Turkey', 0x4304, 0x3304], 0x9005 => ['TRT-INT', 'Turkey', 0x4305, 0x3305], 0xfb9c => ['ANGLIA TV', 'UK', 0x2c1c, 0x3c1c], 0xfb9f => ['ANGLIA TV future use', 'UK', 0x2c1f, 0x3c1f], 0xfb9d => ['ANGLIA TV future use', 'UK', 0x5bcd, 0x3b4d], 0xfb9e => ['ANGLIA TV future use', 'UK', 0x5bce, 0x3b4e], 0x4469 => ['BBC News 24', 'UK', 0x2c69, 0x3c69], 0x4468 => ['BBC Prime', 'UK', 0x2c68, 0x3c68], 0x4457 => ['BBC World', 'UK', 0x2c57, 0x3c57], 0x4458 => ['BBC Worldwide future 01', 'UK', 0x2c58, 0x3c58], 0x4459 => ['BBC Worldwide future 02', 'UK', 0x2c59, 0x3c59], 0x445a => ['BBC Worldwide future 03', 'UK', 0x2c5a, 0x3c5a], 0x445b => ['BBC Worldwide future 04', 'UK', 0x2c5b, 0x3c5b], 0x445c => ['BBC Worldwide future 05', 'UK', 0x2c5c, 0x3c5c], 0x445d => ['BBC Worldwide future 06', 'UK', 0x2c5d, 0x3c5d], 0x445e => ['BBC Worldwide future 07', 'UK', 0x2c5e, 0x3c5e], 0x445f => ['BBC Worldwide future 08', 'UK', 0x2c5f, 0x3c5f], 0x4460 => ['BBC Worldwide future 09', 'UK', 0x2c60, 0x3c60], 0x4461 => ['BBC Worldwide future 10', 'UK', 0x2c61, 0x3c61], 0x4462 => ['BBC Worldwide future 11', 'UK', 0x2c62, 0x3c62], 0x4463 => ['BBC Worldwide future 12', 'UK', 0x2c63, 0x3c63], 0x4464 => ['BBC Worldwide future 13', 'UK', 0x2c64, 0x3c64], 0x4465 => ['BBC Worldwide future 14', 'UK', 0x2c65, 0x3c65], 0x4466 => ['BBC Worldwide future 15', 'UK', 0x2c66, 0x3c66], 0x4467 => ['BBC Worldwide future 16', 'UK', 0x2c67, 0x3c67], 0x447f => ['BBC1', 'UK', 0x2c7f, 0x3c7f], 0x4443 => ['BBC1 future 01', 'UK', 0x2c43, 0x3c43], 0x4445 => ['BBC1 future 02', 'UK', 0x2c45, 0x3c45], 0x4479 => ['BBC1 future 03', 'UK', 0x2c79, 0x3c79], 0x4447 => ['BBC1 future 04', 'UK', 0x2c47, 0x3c47], 0x4477 => ['BBC1 future 05', 'UK', 0x2c77, 0x3c77], 0x4449 => ['BBC1 future 06', 'UK', 0x2c49, 0x3c49], 0x4475 => ['BBC1 future 07', 'UK', 0x2c75, 0x3c75], 0x444b => ['BBC1 future 08', 'UK', 0x2c4b, 0x3c4b], 0x4473 => ['BBC1 future 09', 'UK', 0x2c73, 0x3c73], 0x444d => ['BBC1 future 10', 'UK', 0x2c4d, 0x3c4d], 0x4471 => ['BBC1 future 11', 'UK', 0x2c71, 0x3c71], 0x444f => ['BBC1 future 12', 'UK', 0x2c4f, 0x3c4f], 0x446f => ['BBC1 future 13', 'UK', 0x2c6f, 0x3c6f], 0x4451 => ['BBC1 future 14', 'UK', 0x2c51, 0x3c51], 0x446d => ['BBC1 future 15', 'UK', 0x2c6d, 0x3c6d], 0x4453 => ['BBC1 future 16', 'UK', 0x2c53, 0x3c53], 0x446b => ['BBC1 future 17', 'UK', 0x2c6b, 0x3c6b], 0x4455 => ['BBC1 future 18', 'UK', 0x2c55, 0x3c55], 0x4441 => ['BBC1 NI', 'UK', 0x2c41, 0x3c41], 0x447b => ['BBC1 Scotland', 'UK', 0x2c7b, 0x3c7b], 0x447d => ['BBC1 Wales', 'UK', 0x2c7d, 0x3c7d], 0x4440 => ['BBC2', 'UK', 0x2c40, 0x3c40], 0x447c => ['BBC2 future 01', 'UK', 0x2c7c, 0x3c7c], 0x447a => ['BBC2 future 02', 'UK', 0x2c7a, 0x3c7a], 0x4446 => ['BBC2 future 03', 'UK', 0x2c46, 0x3c46], 0x4478 => ['BBC2 future 04', 'UK', 0x2c78, 0x3c78], 0x4448 => ['BBC2 future 05', 'UK', 0x2c48, 0x3c48], 0x4476 => ['BBC2 future 06', 'UK', 0x2c76, 0x3c76], 0x444a => ['BBC2 future 07', 'UK', 0x2c4a, 0x3c4a], 0x4474 => ['BBC2 future 08', 'UK', 0x2c74, 0x3c74], 0x444c => ['BBC2 future 09', 'UK', 0x2c4c, 0x3c4c], 0x4472 => ['BBC2 future 10', 'UK', 0x2c72, 0x3c72], 0x444e => ['BBC2 future 11', 'UK', 0x2c4e, 0x3c4e], 0x4470 => ['BBC2 future 12', 'UK', 0x2c70, 0x3c70], 0x4450 => ['BBC2 future 13', 'UK', 0x2c50, 0x3c50], 0x446e => ['BBC2 future 14', 'UK', 0x2c6e, 0x3c6e], 0x4452 => ['BBC2 future 15', 'UK', 0x2c52, 0x3c52], 0x446c => ['BBC2 future 16', 'UK', 0x2c6c, 0x3c6c], 0x4454 => ['BBC2 future 17', 'UK', 0x2c54, 0x3c54], 0x446a => ['BBC2 future 18', 'UK', 0x2c6a, 0x3c6a], 0x4456 => ['BBC2 future 19', 'UK', 0x2c56, 0x3c56], 0x447e => ['BBC2 NI', 'UK', 0x2c7e, 0x3c7e], 0x4444 => ['BBC2 Scotland', 'UK', 0x2c44, 0x3c44], 0x4442 => ['BBC2 Wales', 'UK', 0x2c42, 0x3c42], 0xb7f7 => ['BORDER TV', 'UK', 0x2c27, 0x3c27], 0x4405 => ['BRAVO', 'UK', 0x5bef, 0x3b6f], 0x82e2 => ['CARLTON SEL. future use', 'UK', 0x2c06, 0x3c06], 0x82e1 => ['CARLTON SELECT', 'UK', 0x2c05, 0x3c05], 0x82dd => ['CARLTON TV', 'UK', 0x2c1d, 0x3c1d], 0x82de => ['CARLTON TV future use', 'UK', 0x5bcf, 0x3b4f], 0x82df => ['CARLTON TV future use', 'UK', 0x5bd0, 0x3b50], 0x82e0 => ['CARLTON TV future use', 'UK', 0x5bd1, 0x3b51], 0x2f27 => ['CENTRAL TV', 'UK', 0x2c37, 0x3c37], 0x5699 => ['CENTRAL TV future use', 'UK', 0x2c16, 0x3c16], 0xfcd1 => ['CHANNEL 4', 'UK', 0x2c11, 0x3c11], 0x9602 => ['CHANNEL 5 (1)', 'UK', 0x2c02, 0x3c02], 0x1609 => ['CHANNEL 5 (2)', 'UK', 0x2c09, 0x3c09], 0x28eb => ['CHANNEL 5 (3)', 'UK', 0x2c2b, 0x3c2b], 0xc47b => ['CHANNEL 5 (4)', 'UK', 0x2c3b, 0x3c3b], 0xfce4 => ['CHANNEL TV', 'UK', 0x2c24, 0x3c24], 0x4404 => ['CHILDREN\'S CHANNEL', 'UK', 0x5bf0, 0x3b70], 0x01f2 => ['CNNI', 'UK', 0x5bf1, 0x3b71], 0x4407 => ['DISCOVERY', 'UK', 0x5bf2, 0x3b72], 0x44d1 => ['DISNEY CHANNEL UK', 'UK', 0x5bcc, 0x3b4c], 0x4408 => ['FAMILY CHANNEL', 'UK', 0x5bf3, 0x3b73], 0xaddc => ['GMTV', 'UK', 0x5bd2, 0x3b52], 0xaddd => ['GMTV future use', 'UK', 0x5bd3, 0x3b53], 0xadde => ['GMTV future use', 'UK', 0x5bd4, 0x3b54], 0xaddf => ['GMTV future use', 'UK', 0x5bd5, 0x3b55], 0xade0 => ['GMTV future use', 'UK', 0x5bd6, 0x3b56], 0xade1 => ['GMTV future use', 'UK', 0x5bd7, 0x3b57], 0xf33a => ['GRAMPIAN TV', 'UK', 0x2c3a, 0x3c3a], 0x4d5a => ['GRANADA PLUS', 'UK', 0x5bf4, 0x3b74], 0x4d5b => ['GRANADA Timeshare', 'UK', 0x5bf5, 0x3b75], 0xadd8 => ['GRANADA TV', 'UK', 0x2c18, 0x3c18], 0xadd9 => ['GRANADA TV future use', 'UK', 0x5bd8, 0x3b58], 0xfcf4 => ['HISTORY Ch.', 'UK', 0x5bf6, 0x3b76], 0x5aaf => ['HTV', 'UK', 0x2c3f, 0x3c3f], 0xf258 => ['HTV future use', 'UK', 0x2c38, 0x3c38], 0xc8de => ['ITV NETWORK', 'UK', 0x2c1e, 0x3c1e], 0x4406 => ['LEARNING CHANNEL', 'UK', 0x5bf7, 0x3b77], 0x4409 => ['Live TV', 'UK', 0x5bf8, 0x3b78], 0x884b => ['LWT', 'UK', 0x2c0b, 0x3c0b], 0x884c => ['LWT future use', 'UK', 0x5bd9, 0x3b59], 0x884d => ['LWT future use', 'UK', 0x5bda, 0x3b5a], 0x884f => ['LWT future use', 'UK', 0x5bdb, 0x3b5b], 0x8850 => ['LWT future use', 'UK', 0x5bdc, 0x3b5c], 0x8851 => ['LWT future use', 'UK', 0x5bdd, 0x3b5d], 0x8852 => ['LWT future use', 'UK', 0x5bde, 0x3b5e], 0x8853 => ['LWT future use', 'UK', 0x5bdf, 0x3b5f], 0x8854 => ['LWT future use', 'UK', 0x5be0, 0x3b60], 0x10e4 => ['MERIDIAN', 'UK', 0x2c34, 0x3c34], 0xdd50 => ['MERIDIAN future use', 'UK', 0x2c10, 0x3c10], 0xdd51 => ['MERIDIAN future use', 'UK', 0x5be1, 0x3b61], 0xdd52 => ['MERIDIAN future use', 'UK', 0x5be2, 0x3b62], 0xdd53 => ['MERIDIAN future use', 'UK', 0x5be3, 0x3b63], 0xdd54 => ['MERIDIAN future use', 'UK', 0x5be4, 0x3b64], 0xdd55 => ['MERIDIAN future use', 'UK', 0x5be5, 0x3b65], 0xfcfb => ['MOVIE CHANNEL', 'UK', 0x2c1b, 0x3c1b], 0x4d54 => ['MTV', 'UK', 0x2c14, 0x3c14], 0x4d55 => ['MTV future use', 'UK', 0x2c33, 0x3c33], 0x4d56 => ['MTV future use', 'UK', 0x2c36, 0x3c36], 0x8e71 => ['NBC Europe', 'UK', 0x2c31, 0x3c31], 0x5343 => ['NBC Europe future use', 'UK', 0x2c03, 0x3c03], 0x8e79 => ['NBC Europe future use', 'UK', 0x2c23, 0x3c23], 0x8e78 => ['NBC Europe future use', 'UK', 0x2c26, 0x3c26], 0x8e77 => ['NBC Europe future use', 'UK', 0x2c28, 0x3c28], 0x8e76 => ['NBC Europe future use', 'UK', 0x2c29, 0x3c29], 0x8e75 => ['NBC Europe future use', 'UK', 0x2c2a, 0x3c2a], 0x8e74 => ['NBC Europe future use', 'UK', 0x2c2e, 0x3c2e], 0x8e73 => ['NBC Europe future use', 'UK', 0x2c32, 0x3c32], 0x8e72 => ['NBC Europe future use', 'UK', 0x2c35, 0x3c35], 0xa460 => ['Nickelodeon UK', 'UK'], 0xa465 => ['Paramount Comedy Channel UK', 'UK'], 0x5c33 => ['QVC future use', 'UK'], 0x5c34 => ['QVC future use', 'UK'], 0x5c39 => ['QVC future use', 'UK'], 0x5c44 => ['QVC UK', 'UK'], 0xfcf3 => ['RACING Ch.', 'UK', 0x2c13, 0x3c13], 0xb4c7 => ['S4C', 'UK', 0x2c07, 0x3c07], 0xfcf5 => ['SCI FI CHANNEL', 'UK', 0x2c15, 0x3c15], 0xf9d2 => ['SCOTTISH TV', 'UK', 0x2c12, 0x3c12], 0xfcf9 => ['SKY GOLD', 'UK', 0x2c19, 0x3c19], 0xfcfc => ['SKY MOVIES PLUS', 'UK', 0x2c0c, 0x3c0c], 0xfcfd => ['SKY NEWS', 'UK', 0x2c0d, 0x3c0d], 0xfcfe => ['SKY ONE', 'UK', 0x2c0e, 0x3c0e], 0xfcf7 => ['SKY SOAPS', 'UK', 0x2c17, 0x3c17], 0xfcfa => ['SKY SPORTS', 'UK', 0x2c1a, 0x3c1a], 0xfcf8 => ['SKY SPORTS 2', 'UK', 0x2c08, 0x3c08], 0xfcf6 => ['SKY TRAVEL', 'UK', 0x5bf9, 0x3b79], 0xfcff => ['SKY TWO', 'UK', 0x2c0f, 0x3c0f], 0x37e5 => ['SSVC', 'UK', 0x2c25, 0x3c24], 0x44c1 => ['TNT / Cartoon Network', 'UK'], 0xa82c => ['TYNE TEES TV', 'UK', 0x2c2c, 0x3c2c], 0xa82d => ['TYNE TEES TV future use', 'UK', 0x5be6, 0x3b66], 0xa82e => ['TYNE TEES TV future use', 'UK', 0x5be7, 0x3b67], 0x4401 => ['UK GOLD', 'UK', 0x5bfa, 0x3b7a], 0x4411 => ['UK GOLD future use', 'UK', 0x5bfb, 0x3b7b], 0x4412 => ['UK GOLD future use', 'UK', 0x5bfc, 0x3b7c], 0x4413 => ['UK GOLD future use', 'UK', 0x5bfd, 0x3b7d], 0x4414 => ['UK GOLD future use', 'UK', 0x5bfe, 0x3b7e], 0x4415 => ['UK GOLD future use', 'UK', 0x5bff, 0x3b7f], 0x4402 => ['UK LIVING', 'UK', 0x2c01, 0x3c01], 0x833b => ['ULSTER TV', 'UK', 0x2c3d, 0x3c3d], 0x4d58 => ['VH-1', 'UK', 0x2c20, 0x3c20], 0x4d59 => ['VH-1      (German language)', 'UK', 0x2c21, 0x3c21], 0x4d57 => ['VH-1 future use', 'UK', 0x2c22, 0x3c22], 0x25d1 => ['WESTCOUNTRY future use', 'UK', 0x5be8, 0x3b68], 0x25d2 => ['WESTCOUNTRY future use', 'UK', 0x5be9, 0x3b69], 0x25d0 => ['WESTCOUNTRY TV', 'UK', 0x2c30, 0x3c30], 0x4403 => ['WIRE TV', 'UK', 0x2c3c, 0x3c3c], 0xfa2c => ['YORKSHIRE TV', 'UK', 0x2c2d, 0x3c2d], 0xfa2d => ['YORKSHIRE TV future use', 'UK', 0x5bea, 0x3b6a], 0xfa2e => ['YORKSHIRE TV future use', 'UK', 0x5beb, 0x3b6b], 0xfa2f => ['YORKSHIRE TV future use', 'UK', 0x5bec, 0x3b6c], 0xfa30 => ['YORKSHIRE TV future use', 'UK', 0x5bed, 0x3b6d], 0xfa31 => ['YORKSHIRE TV future use', 'UK', 0x5bee, 0x3b6e]);

package Video::Capture::VBI::VT;

use Video::Capture::VBI;

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   $self;
}

sub feed(@) {
   my $self = shift;
   my @r;
   for (@_) {
      if ($_->[0] == VBI_VT) {
         my $y = $_->[2];
         if ($y == 0) {
            if (defined $self->{curpage}{page}) {
               if ($_->[5] & VTX_C11 || ($self->{curpage}->{page} ^ $_->[4]) & 0xf00) {
                  $self->enter_page($self->{curpage}) unless ($self->{curpage}->{page} & 0xff) == 0xff;
               }
            }
            $self->{curpage} = {
               packet => [$_->[3]],
               page   => $_->[4],
               ctrl   => $_->[5],
            };
         } elsif($y<=25) {
            $self->{curpage}{packet}[$y] = $_->[3];
         } elsif($y<=32) {
            $self->enter_packet($_);
         } else {
            #print "P$y: @$_\n";
         }
      } else {
         push @r, $_;
      }
   }
   @r;
}

sub enter_page {}
sub enter_packet {}

1;
