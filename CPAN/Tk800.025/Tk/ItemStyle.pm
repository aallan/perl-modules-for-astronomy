package Tk::ItemStyle;

use vars qw($VERSION);
$VERSION = '3.006'; # $Id: ItemStyle.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

require Tk;
use base  qw(Tk);
require Tk::Widget;
Construct Tk::Widget 'ItemStyle';

Tk::Methods ('delete');

sub new
{
 my $package = shift;
 my $widget  = shift;
 my $type    = shift;
 my %args    = @_;
 $args{'-refwindow'} = $widget unless exists $args{'-refwindow'};
 $package->InitClass($widget);
 my $obj = $widget->itemstyle($type, %args);
 return bless $obj,$package;
}

sub Install
{
 # Dynamically loaded image types can install standard images here
 my ($class,$mw) = @_;
}

sub ClassInit
{
 # Carry out class bindings (or whatever)
 my ($package,$mw) = @_;
 return $package;
}

1;
