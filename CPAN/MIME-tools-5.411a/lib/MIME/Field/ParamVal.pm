package MIME::Field::ParamVal;


=head1 NAME

MIME::Field::ParamVal - subclass of Mail::Field, for structured MIME fields


=head1 SYNOPSIS

    # Create an object for a content-type field:
    $field = new Mail::Field 'Content-type'; 
     
    # Set some attributes:
    $field->param('_'        => 'text/html');
    $field->param('charset'  => 'us-ascii');
    $field->param('boundary' => '---ABC---');
     
    # Same:
    $field->set('_'        => 'text/html',
		'charset'  => 'us-ascii',
		'boundary' => '---ABC---');
      
    # Get an attribute, or undefined if not present:
    print "no id!"  if defined($field->param('id'));
     
    # Same, but use empty string for missing values:
    print "no id!"  if ($field->paramstr('id') eq '');
                    
    # Output as string:
    print $field->stringify, "\n";


=head1 DESCRIPTION

This is an abstract superclass of most MIME fields.  It handles 
fields with a general syntax like this:

    Content-Type: Message/Partial;
        number=2; total=3;
        id="oc=jpbe0M2Yt4s@thumper.bellcore.com"

Comments are supported I<between> items, like this:

    Content-Type: Message/Partial; (a comment)
        number=2  (another comment) ; (yet another comment) total=3;
        id="oc=jpbe0M2Yt4s@thumper.bellcore.com"


=head1 PUBLIC INTERFACE

=over 4

=cut

#------------------------------

require 5.001;

# Pragmas:
use strict;
use vars qw($VERSION @ISA);

# System modules:


# Other modules:
use Mail::Field;

# Kit modules:
use MIME::Tools qw(:config :msgs);

@ISA = qw(Mail::Field);


#------------------------------
#
# Public globals...
#
#------------------------------

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.1 $, 10;


#------------------------------
#
# Private globals...
#
#------------------------------

# Pattern to match parameter names (like fieldnames, but = not allowed):
my $PARAMNAME = '[^\x00-\x1f\x80-\xff :=]+';

# Pattern to match the first value on the line:
my $FIRST    = '[^\s\;\x00-\x1f\x80-\xff]+';

# Pattern to match an RFC-1521 token:
#
#      token      =  1*<any  (ASCII) CHAR except SPACE, CTLs, or tspecials>
#
my $TSPECIAL = '()<>@,;:\</[]?="';
my $TOKEN    = '[^ \x00-\x1f\x80-\xff' . "\Q$TSPECIAL\E" . ']+';

# Encoded token:
my $ENCTOKEN = "=\\?[^?]*\\?[A-Za-z]\\?[^?]+\\?=";

# Pattern to match spaces or comments:
my $SPCZ     = '(?:\s|\([^\)]*\))*';


#------------------------------
#
# Class init...
#
#------------------------------

#------------------------------

=item set [\%PARAMHASH | KEY=>VAL,...,KEY=>VAL]

I<Instance method.>  Set this field.
The paramhash should contain parameter names
in I<all lowercase>, with the special C<"_"> parameter name
signifying the "default" (unnamed) parameter for the field:

   # Set up to be...
   #
   #     Content-type: Message/Partial; number=2; total=3; id="ocj=pbe0M2"
   #
   $conttype->set('_'       => 'Message/Partial',
		  'number'  => 2,
		  'total'   => 3,
		  'id'      => "ocj=pbe0M2");

Note that a single argument is taken to be a I<reference> to 
a paramhash, while multiple args are taken to be the elements
of the paramhash themselves.

Supplying undef for a hashref, or an empty set of values, effectively
clears the object.

The self object is returned.

=cut

sub set {
    my $self = shift;
    my $params = ((@_ == 1) ? (shift || {}) : {@_});
    %$self = %$params;    # set 'em
    $self;
}

#------------------------------

=item parse_params STRING

I<Class/instance utility method.>
Extract parameter info from a structured field, and return
it as a hash reference.  For example, here is a field with parameters:

    Content-Type: Message/Partial;
        number=2; total=3;
        id="oc=jpbe0M2Yt4s@thumper.bellcore.com"

Here is how you'd extract them:

    $params = $class->parse_params('content-type');
    if ($$params{'_'} eq 'message/partial') {
        $number = $$params{'number'};
        $total  = $$params{'total'};
        $id     = $$params{'id'};
    }

Like field names, parameter names are coerced to lowercase.
The special '_' parameter means the default parameter for the
field.

B<NOTE:> This has been provided as a public method to support backwards
compatibility, but you probably shouldn't use it.

=cut

sub parse_params {
    my ($self, $raw) = @_;
    my %params = ();
    my $param;

    # Get raw field, and unfold it:
    defined($raw) or $raw = '';
    $raw =~ s/\n//g;

    # Extract special first parameter:
    $raw =~ m/\A$SPCZ($FIRST)$SPCZ/og or return {};    # nada!
    $params{'_'} = $1;

    # Extract subsequent parameters.
    # No, we can't just "split" on semicolons: they're legal in quoted strings!
    while (1) {                     # keep chopping away until done...
	$raw =~ m/\G$SPCZ\;$SPCZ/og or last;             # skip leading separator
	$raw =~ m/\G($PARAMNAME)\s*=\s*/og or last;      # give up if not a param
	$param = lc($1);
	$raw =~ m/\G(\"([^\"]+)\")|\G($TOKEN)|\G($ENCTOKEN)/g or last;   # give up if no value
	my ($qstr, $str, $token, $enctoken) = ($1, $2, $3, $4);
	$params{$param} = defined($qstr) ? $str : (defined($token) ? $token : $enctoken);
	debug "   field param <$param> = <$params{$param}>";
    }

    # Done:
    \%params;
}

#------------------------------

=item parse STRING

I<Class/instance method.>
Parse the string into the instance.  Any previous information is wiped.
The self object is returned.

May also be used as a constructor.

=cut

sub parse {
    my ($self, $string) = @_;

    # Allow use as constructor, for MIME::Head:
    ref($self) or $self = bless({}, $self);
    
    # Get params, and stuff them into the self object:
    $self->set($self->parse_params($string));
}

#------------------------------

=item param PARAMNAME,[VALUE]

I<Instance method.>
Return the given parameter, or undef if it isn't there.
With argument, set the parameter to that VALUE.
The PARAMNAME is case-insensitive.  A "_" refers to the "default" parameter.

=cut

sub param {
    my ($self, $paramname, $value) = @_;
    $paramname = lc($paramname);
    $self->{$paramname} = $value if (@_ > 2);
    $self->{$paramname}
}

#------------------------------

=item paramstr PARAMNAME,[VALUE]

I<Instance method.>
Like param(): return the given parameter, or I<empty> if it isn't there.
With argument, set the parameter to that VALUE.
The PARAMNAME is case-insensitive.  A "_" refers to the "default" parameter.

=cut

sub paramstr {
    my $val = shift->param(@_);
    (defined($val) ? $val : '');
}

#------------------------------

=item stringify

I<Instance method.>
Convert the field to a string, and return it.

=cut

sub stringify {
    my $self = shift;
    my ($key, $val);

    my $str = $self->{'_'};                   # default subfield
    foreach $key (sort keys %$self) {
	next if ($key !~ /^[a-z][a-z-_0-9]*$/);  # only lowercase ones!
	defined($val = $self->{$key}) or next;
	$str .= qq{; $key="$val"};
    }
    $str;
}

#------------------------------

=item tag

I<Instance method, abstract.>
Return the tag for this field.

=cut

sub tag { '' }

=back

=cut

#------------------------------
1;
