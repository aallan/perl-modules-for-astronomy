package Tk::widgets;
use Carp;

use vars qw($VERSION);
$VERSION = '3.011'; # $Id: widgets.pm,v 1.1 2003/09/28 14:54:56 aa Exp $

sub import
{
 my $class = shift;
 foreach (@_)
  {
   local $SIG{__DIE__} = \&Carp::croak;
   # carp "$_ already loaded" if (exists $INC{"Tk/$_.pm"});
   require "Tk/$_.pm";
  }
}

1;
__END__

=cut
