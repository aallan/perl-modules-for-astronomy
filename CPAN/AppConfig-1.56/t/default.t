#========================================================================
#
# t/default.t 
#
# AppConfig::File test file.  Tests the '-option' syntax which is used 
# to reset variables to their default values.
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
use lib qw( ../lib ./lib );
$^W = 1;

BEGIN { 
    $| = 1; 
    print "1..19\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    my ($ok, $msg) = @_;

    $msg = defined $msg ? " - $msg" : '';
    if ($ok) {
	print "ok ", $ok_count++, "$msg\n";
    }
    else {
	print STDERR "FAILED $ok_count: $msg\n" if defined $msg;
	print "not ok ", $ok_count++, "$msg\n";
    }
}

use AppConfig qw(:expand :argcount);
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
# create new AppConfig
#

my $BAZDEF = "all_bar_none";
my $BAZNEW = "new_bar";

my $config = AppConfig->new( { GLOBAL => { ARGCOUNT => 0 } },
	'foo', 
	'bar', 
	'baz'  => { ARGCOUNT => 1, DEFAULT => $BAZDEF },
	'qux'  => { ARGCOUNT => 1 },
        'list' => { ARGCOUNT => ARGCOUNT_LIST,
                    DEFAULT  => [ 2, 3, 5, 7, 9 ], },
        'hash' => { ARGCOUNT => ARGCOUNT_HASH,
                    DEFAULT  => { two   => 2, 
                                  three => 3, 
                                  five  => 5 }, },
    );

#2: test config got instantiated correctly
ok( defined $config );

#3 - #4: set some dummy values
ok( $config->foo(1)        );
ok( $config->baz($BAZNEW) );

#5 - #6: test them
ok( $config->foo() == 1       );
ok( $config->baz() eq $BAZNEW );

#------------------------------------------------------------------------
# list 
#------------------------------------------------------------------------

my $list = $config->list();
ok( $list, 'got default list' );
ok( $list->[0] == 2, 'first item two' );
ok( $list->[2] == 5, 'third item five' );


#------------------------------------------------------------------------
# hash 
#------------------------------------------------------------------------

my $hash = $config->hash();
ok( $hash, 'got default hash' );
ok( $hash->{ two } == 2, 'item two' );
ok( $hash->{ five } == 5, 'item five' );



#7: read the config from __DATA__
ok( $config->file(\*DATA) );

#8 - #9: test foo and baz got reset to defaults correctly
ok( $config->foo() == 0       );
ok( $config->baz() eq $BAZDEF );

#10 - #11: test that "+bar" and "+qux" worked
ok( $config->bar() ==  1  );
ok( $config->qux() eq '1' );

#12 - #15: test that list and hash are set
ok( $config->bar() ==  1  );
ok( $config->qux() eq '1' );

__DATA__
-foo
+bar
-baz
+qux

