# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use VOTable::MAX;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;

# Subroutine prototypes
sub test_set_inclusive();

#########################

# Test.
ok(test_set_inclusive, 1);

#########################

sub test_set_inclusive()
{

    # Local variables

    # Reference to test MAX object.
    my($max);

    # Current inclusive value.
    my($inclusive);

    # Valid inclusive attribute values.
    my(@valids) = qw(yes no);

    #--------------------------------------------------------------------------

    # Create the object.
    $max = new VOTable::MAX or return(0);

    # Try each of the valid values.
    foreach $inclusive (@valids) {
	$max->set_inclusive($inclusive);
	$max->get_inclusive eq $inclusive or return(0);
    }

    # Make sure bad values fail.
    eval { $max->set_inclusive('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}
