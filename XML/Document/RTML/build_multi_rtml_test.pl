#!/usr/bin/perl

use strict;
use warnings;

#use lib $ENV{ESTAR_PERL5LIB};
use lib '/home/saunders/perl_modules';
use XML::Document::RTML::RTML;

my $raformat  = "hh mm ss.ss";
my $raunits   = "hms";

my $decformat = "sdd mm ss.ss";
my $decunits  = "dms";

my $exp_type  = "time";
my $exp_units = "s";



my $req = new XML::Document::RTML();

# Set up document-wide tags...
$req->user("test");
$req->project('expired');
$req->host("ltobs9");
$req->port("8080");
$req->id("rtml://test-miat-document-1218632198993");

my $obs_block_id;

##### 1ST OBSERVATION #####
# Set up observation specific tags...
$obs_block_id = 0;
$req->observation($obs_block_id);
$req->target_type("normal");
$req->target_ident("test");
$req->target('MarkA_R');

$req->raformat($raformat);
$req->raunits($raunits);
$req->ra('20 43 59.00');

$req->decformat($decformat);
$req->decunits($decunits);
$req->dec('-10 47 42.00');

$req->equinox(2000);

$req->region("optical");
$req->device_type("camera");
$req->filter_type("R");

$req->priority(2);
$req->exposure_type($exp_type);
$req->exposure_units($exp_units);
$req->exposure_time("10.0");


$req->time_constraint(["2008-08-13T12:00:00+0100",
                       "2008-08-14T12:00:00+0100"]);


##### 2ND OBSERVATION #####
# Set up observation specific tags...
$obs_block_id = 1;
$req->observation($obs_block_id);
$req->target_type("normal");
$req->target_ident("test");
$req->target('MarkAOffset');

$req->raformat($raformat);
$req->raunits($raunits);
$req->ra('20 43 59.00');
$req->ra_offset_units("arcseconds");
$req->ra_offset("20.0");

$req->decformat($decformat);
$req->decunits($decunits);
$req->dec('-10 47 42.00');
$req->dec_offset_units("arcseconds");
$req->dec_offset("20.0");


$req->equinox(2000);

$req->region("optical");
$req->device_type("camera");
$req->filter_type("R");

$req->priority(2);
$req->exposure_type($exp_type);
$req->exposure_units($exp_units);
$req->exposure_time("10.0");


$req->time_constraint(["2008-08-13T12:00:00+0100",
                       "2008-08-14T12:00:00+0100"]);


##### 3RD OBSERVATION #####
# Set up observation specific tags...
$obs_block_id = 2;
$req->observation($obs_block_id);
$req->target_type("normal");
$req->target_ident("test");
$req->target('MarkA_V');

$req->raformat($raformat);
$req->raunits($raunits);
$req->ra('20 43 59.00');

$req->decformat($decformat);
$req->decunits($decunits);
$req->dec('-10 47 42.00');

$req->equinox(2000);

$req->region("optical");
$req->device_type("camera");
$req->filter_type("V");

$req->priority(2);
$req->exposure_type($exp_type);
$req->exposure_units($exp_units);
$req->exposure_time("10.0");


$req->time_constraint(["2008-08-13T12:00:00+0100",
                       "2008-08-14T12:00:00+0100"]);






$req->build_multi("score");
print $req->dump_rtml;
