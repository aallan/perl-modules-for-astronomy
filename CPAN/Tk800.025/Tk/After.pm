# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tk::After;
use Carp;

use vars qw($VERSION);
$VERSION = '3.019'; # $Id: After.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

sub _cancelAll
{
 my $w = shift;
 my $h = delete $w->{_After_};
 foreach my $obj (values %$h)
  {
   # carp "Auto cancel ".$obj->[1]." for ".$obj->[0]->PathName;
   $obj->cancel;
  }
}

sub submit
{
 my $obj     = shift;
 my $w       = $obj->[0];
 my $id      = $obj->[1];
 my $t       = $obj->[2];
 my $method  = $obj->[3];
 delete($w->{_After_}{$id}) if (defined $id);
 $id  = $w->Tk::after($t,[$method => $obj]);
 unless (exists $w->{_After_})
  {
   $w->{_After_} = {};
   $w->OnDestroy([\&_cancelAll, $w]);
  }
 $w->{_After_}{$id} = $obj;
 $obj->[1] = $id;
 return $obj;
}

sub DESTROY
{
 my $obj = shift;
 @{$obj} = ();
}

sub new
{
 my ($class,$w,$t,$method,@cb) = @_;
 my $cb    = (@cb == 1) ? shift(@cb) : [@cb];
 my $obj   = bless [$w,undef,$t,$method,Tk::Callback->new($cb)],$class;
 return $obj->submit;
}

sub cancel
{
 my $obj = shift;
 my $id  = $obj->[1];
 my $w   = $obj->[0];
 if ($id)
  {
   $w->Tk::after('cancel'=> $id);
   delete $w->{_After_}{$id} if exists $w->{_After_};
   $obj->[1] = undef;
  }
 return $obj;
}

sub repeat
{
 my $obj = shift;
 $obj->submit;
 local $Tk::widget = $obj->[0];
 $obj->[4]->Call;
}

sub once
{
 my $obj = shift;
 my $w   = $obj->[0];
 my $id  = $obj->[1];
 delete $w->{_After_}{$id};
 local $Tk::widget = $w;
 $obj->[4]->Call;
}

sub time {
    my $obj = shift;
    my $delay = shift;
    if (defined $delay) {
	$obj->cancel if $delay == 0;
	$obj->[2] = $delay;
    }
    $obj->[2];
}

1;
__END__

