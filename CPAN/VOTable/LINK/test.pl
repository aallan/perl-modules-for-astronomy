# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use VOTable::LINK;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;

# Subroutine prototypes
sub test_set_content_role();

#########################

# Test.
ok(test_set_content_role, 1);

#########################

sub test_set_content_role()
{

    # Local variables

    # Reference to test LINK object.
    my($link);

    # Current content_role value.
    my($content_role);

    # Valid content_role attribute values.
    my(@valids) = qw(query hints doc);

    #--------------------------------------------------------------------------

    # Create the object.
    $link = new VOTable::LINK or return(0);

    # Try each of the valid values.
    foreach $content_role (@valids) {
	$link->set_content_role($content_role);
	$link->get_content_role eq $content_role or return(0);
    }

    # Make sure bad values fail.
    eval { $link->set_content_role('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}
