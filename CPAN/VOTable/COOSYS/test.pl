# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use VOTable::COOSYS;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#########################

# External modules
use English;

# Subroutine prototypes
sub test_new();
sub test_set_system();

#########################

# Test.
ok(test_new, 1);
ok(test_set_system, 1);

#########################

sub test_new()
{

    # Local variables

    # Reference to test COOSYS element object.
    my($coosys);

    #--------------------------------------------------------------------------

    # Test the plain-vanilla constructor.
    $coosys = VOTable::COOSYS->new or return(0);

    # Try creating from a XML::LibXML::Element object.
    $coosys = VOTable::COOSYS->new(new XML::LibXML::Element('COOSYS'))
	or return(0);

    # Make sure the constructor fails when a bad reference is passed
    # in.
    $coosys = eval { VOTable::COOSYS->new(new XML::LibXML::Element('JUNK')) };
    return(0) if not $EVAL_ERROR;
    $coosys = eval { VOTable::COOSYS->new(\0) };
    return(0) if not $EVAL_ERROR;
    $coosys = eval { VOTable::COOSYS->new([]) };
    return(0) if not $EVAL_ERROR;

    #--------------------------------------------------------------------------

    # Return success.
    return(1);

}

sub test_set_system()
{

    # Local variables

    # Reference to test COOSYS object.
    my($coosys);

    # Current system value.
    my($system);

    # Valid system attribute values.
    my(@valids) = qw(eq_FK4 eq_FK5 ICRS ecl_FK4 ecl_FK5 galactic
		     supergalactic xy barycentric geo_app);

    #--------------------------------------------------------------------------

    # Create the object.
    $coosys = new VOTable::COOSYS or return(0);

    # Try each of the valid values.
    foreach $system (@valids) {
	$coosys->set_system($system);
	$coosys->get_system eq $system or return(0);
    }

    # Make sure bad values fail.
    eval { $coosys->set_system('BAD_VALUE!'); };
    return(0) if not $EVAL_ERROR;

    # All tests passed.
    return(1);

}
