package PreLoad;

use vars qw($VERSION);
$VERSION = '3.005'; # $Id: PreLoad.pm,v 1.1 2003/09/28 14:54:56 aa Exp $

require AutoLoader;

my @todo = ();

*AutoLoader::import = \&queue_load;

INIT
 {
  while (@todo)
   {
    my ($pack,$path) = splice(@todo,0,2);
    do_load($pack,$path);
   }
 }

END
 {
  while (@todo)
   {
    my ($pack,$path) = splice(@todo,0,2);
    do_load($pack,$path);
   }
 }



sub do_load
{
 my ($callpkg,$path) = @_;
 local $_;
 # Try absolute path name.
 local *IX;
 if (open(IX,$path))
  {
   while (<IX>)
    {
     if (/^sub\s+(\S+)\s*;/)
      {
       my $sub = $1;
       warn "Preload $callpkg\::$sub\n";
       unless (defined &{$callpkg.'::'.$sub})
        {
         (my $al = $path) =~ s#autosplit.ix$#$sub.al#;
         require $al;
        }
      }
    }
  }
}

sub queue_load
{
 my $callpkg = caller;
 (my $calldir = $callpkg) =~ s#::#/#g;
 my $path = $INC{$calldir . '.pm'};
 if (defined($path))
  {
   $path =~ s#^(.*)$calldir\.pm$#$1auto/$calldir/autosplit.ix#;
   push(@todo, $callpkg,$path);
  }
}

1;
__END__
