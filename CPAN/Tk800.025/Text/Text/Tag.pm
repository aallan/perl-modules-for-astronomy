package Tk::Text::Tag;
require Tk::Text;

use overload '""' => \&name;


use vars qw($VERSION);
$VERSION = '3.007'; # $Id: Tag.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

sub _apply
{
 my $self = shift;
 my $meth = shift;
 $self->widget->tag($meth => $self->name,@_);
}

sub name
{
 return shift->[0];
}

sub widget
{
 return shift->[1];
}

BEGIN
{
 my $meth;
 foreach $meth (qw(cget configure bind add))
  {
   *{$meth} = sub { shift->_apply($meth,@_) }
  }
}

sub new
{
 my $class  = shift;
 my $widget = shift;
 my $name   = shift;
 my $obj    = bless [$name,$widget],$class;
 $obj->configure(@_) if (@_);
 return $obj;
}

1;
