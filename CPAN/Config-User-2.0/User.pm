package Config::User;


use strict;


require Exporter;

use vars qw(@ISA $VERSION);

$VERSION = '2.0';


# Preloaded methods go here.

sub Home {

  return $ENV{HOME}        if $ENV{HOME};
  return $ENV{USERPROFILE} if $ENV{USERPROFILE};
  return  "";

}

  

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

User - API for locating user information regardless of OS

=head1 SYNOPSIS

  use Config::User;

  my $cfg = Config::IniFiles->new
        (
          -file    => sprintf("%s/%s", Config::User->Home, ".ncfg"),
          -default => 'Default'
        );




=head1 DESCRIPTION

This module is allows applications to retrieve per-user characteristics. At
present, it contains only one method, Home(), which is used to return a 
location that can be expected to be a users "Home" directory on either
Windows or Unix.

While one way of writing this would be to check for operating system
and then check the expected location for an operation system of that type,
I chose to do the following:

 sub Home {

  return $ENV{HOME}        if $ENV{HOME};
  return $ENV{USERPROFILE} if $ENV{USERPROFILE};
  return  "";

 }

In other words, if $HOME is defined in the user's environment, then
that is used. Otherwise $USERPROFILE is used. Otherwise "" is returned.

A contribution for Macintosh (or any other number of OS/arch combinations) is
greatly solicited.

=head2 EXPORT

None by default.


=head1 AUTHOR

T.M. Brannon, tbone@cpan.org

=head1 ACKNOWLEDGEMENTS

I would like to offer profuse thanks to my fellow perl monk at 
www.perlmonks.org, the_slycer, who told me where HOME could be
found on Windows machines.

perl(1).

=cut
