# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use VOTable::STREAM;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;

# Subroutine prototypes
sub test_set_type();
sub test_set_actuate();
sub test_set_encoding();

#########################

# Test.
ok(test_set_type, 1);
ok(test_set_actuate, 1);
ok(test_set_encoding, 1);

#########################

sub test_set_type()
{

    # Local variables

    # Reference to test STREAM object.
    my($stream);

    # Current type value.
    my($type);

    # Valid type attribute values.
    my(@valids) = qw(locator other);

    #--------------------------------------------------------------------------

    # Create the object.
    $stream = new VOTable::STREAM or return(0);

    # Try each of the valid values.
    foreach $type (@valids) {
	$stream->set_type($type);
	$stream->get_type eq $type or return(0);
    }

    # Make sure bad values fail.
    eval { $stream->set_type('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}

sub test_set_actuate()
{

    # Local variables

    # Reference to test STREAM object.
    my($stream);

    # Current actuate value.
    my($actuate);

    # Valid actuate attribute values.
    my(@valids) = qw(onLoad onRequest other none);

    #--------------------------------------------------------------------------

    # Create the object.
    $stream = new VOTable::STREAM or return(0);

    # Try each of the valid values.
    foreach $actuate (@valids) {
	$stream->set_actuate($actuate);
	$stream->get_actuate eq $actuate or return(0);
    }

    # Make sure bad values fail.
    eval { $stream->set_actuate('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}

sub test_set_encoding()
{

    # Local variables

    # Reference to test STREAM object.
    my($stream);

    # Current encoding value.
    my($encoding);

    # Valid encoding attribute values.
    my(@valids) = qw(gzip base64 dynamic none);

    #--------------------------------------------------------------------------

    # Create the object.
    $stream = new VOTable::STREAM or return(0);

    # Try each of the valid values.
    foreach $encoding (@valids) {
	$stream->set_encoding($encoding);
	$stream->get_encoding eq $encoding or return(0);
    }

    # Make sure bad values fail.
    eval { $stream->set_encoding('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}
