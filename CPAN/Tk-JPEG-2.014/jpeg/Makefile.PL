#!perl
use Config;
use File::Copy;
if ($^O eq 'MSWin32')
 {
  copy("jconfig.b32","jconfig.h") 
   || die "Cannot copy jconfig.b32 to jconfig.h:$!";
  my $file;
  if ($Config{'cc'} =~ /gcc/)
   {
    $file = 'makefile.mingw32';
   }
  elsif ($Config{'cc'} =~ /bcc/)
   {
    $file = 'makefile.b32';
   }
  else
   {
    $file = 'makefile.v32';
    warn "Assuming ".$Config{'cc'}." is visual C of some kind\n";
   }
  copy($file,"Makefile")
   || die "Cannot copy $file to Makefile:$!";
 }
else
 {
  system("./configure");
 }
1;
