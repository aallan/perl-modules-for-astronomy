#========================================================================
#
# t/const.t 
#
# AppConfig::Const test file.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use vars qw($loaded);
$^W = 1;

BEGIN { 
    $| = 1; 
    print "1..9\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use AppConfig ':expand';
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
#2 - #5: test that the EXPAND_XXX constants got imported
#

ok( EXPAND_UID );
ok( EXPAND_VAR );
ok( EXPAND_ENV );
ok( EXPAND_ALL == EXPAND_UID | EXPAND_VAR | EXPAND_ENV );


#------------------------------------------------------------------------
#6 - #9: test that the EXPAND_XXX package vars are defined
#

ok( AppConfig::EXPAND_UID );
ok( AppConfig::EXPAND_VAR );
ok( AppConfig::EXPAND_ENV );
ok( AppConfig::EXPAND_ALL == 
    AppConfig::EXPAND_UID 
  | AppConfig::EXPAND_VAR 
  | AppConfig::EXPAND_ENV );

