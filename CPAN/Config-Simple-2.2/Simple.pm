package Config::Simple;

require 5.003;

use warnings;
use strict;
use Carp;
use File::Copy;
use Fcntl qw(:DEFAULT :flock);

require Exporter;

use vars qw($VERSION @ISA @EXPORT $MD5 $errstr);

@ISA = qw(Exporter);

$VERSION = "2.2";

eval {
    for ( @Fcntl::EXPORT ) {
        /^(O_|LOCK_)/   or next;
        push @EXPORT, $_;
    }
    Fcntl->import(@EXPORT);
};


$MD5 = 1;

eval {  require Digest::MD5 };

if ( $@ ) {
    $MD5 = 0;
    carp "Please install Digest::MD5 from your nearest CPAN mirror: perl -MCPAN -e 'install Digest::MD5')";
}








sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $self = {
        _options    =>  {
            filename    => undef,
            mode        => O_RDONLY|O_CREAT,
            lockfile    => "",
            c           => 1,
            @_,
        },
        _cfg        => {},
        _checksum   => undef,
    };

    # deciding a name for a lock file
    unless ( $self->{_options}{lockfile} ) {
        $self->{_options}{lockfile} = $self->{_options}{filename} . ".lock";
    }

	$self->{_options}{filename} ||=$self->{_options}{_filename};


    # creating a digest of the file...
    if ( $MD5 and -e $self->{_options}{filename} ) {
        open (CHECKSUM, '<' . $self->{_options}{filename}) or carp "Couldn't open $self->{_options}{filename}, $!";
        flock (CHECKSUM, LOCK_SH|LOCK_NB) or carp "Couldn't acquire a lock on $self->{_options}{filename}, $!";

        my $md5 = Digest::MD5->new();
        $md5->addfile(*CHECKSUM);
        $self->{_checksum} = $md5->hexdigest();

        close CHECKSUM;
    }

    bless $self => $class;

    $self->_init() or return undef;

    return $self;
}




sub DESTROY {   }



sub _init {
    my $self = shift;

    my $mode = $self->{_options}->{mode};
    my $file = $self->{_options}{filename};


    sysopen(FH, $file, $mode) or $errstr = "Couldn't open $file, $!", return undef;
    flock (FH, LOCK_SH|LOCK_NB) or $errstr = "Couldn't get lock on $file, $!", return undef;

    my $title = "";
    my $after_dot = 0;
    local $/ = "\n";
    while ( <FH> ) {

        $after_dot  and $self->{'.'} .= $_, next;
        /^(;|\n|\#)/    and next;   # deal with \n and comments
        /^\[([^\]]+)\]/ and $title = $1, next;
        /^([^=]+)=(.+)/ and $self->{_cfg}->{$title}{$1} = $2, next;
        /^\./           and $after_dot = 1, next;   # don't read anything after the sole dot (.)

        chomp ($_);
        my $msg = "Syntax error in line $. of $file: \"$_\"";
        $self->{_options}{c}    and croak $msg;

    }

    close FH;
    return 1;
}




sub _get_block {
    my $self = shift;

    my ($block) =  @_;
    my %hash = ();

    for my $key ( keys %{ $self->{_cfg}{$block} } ) {
        $hash{$key} = $self->_get_single_param($block, $key)
    }

    return \%hash;
}


sub _create_block {
    my $self = shift;
    my ($block, $values) = @_;

    for my $key ( keys %{$values} ) {
        $self->_set_single_param($block, $key, $values->{$key});
    }

}



sub _get_single_param {
    my $self = shift;
    my ($block, $key) = @_;

    my $value = $self->{_cfg}->{$block}->{$key} || "";
    $value =~ s/\\n/\n/g;

    return $value;
}



sub _set_single_param {
    my $self = shift;

    my ($block, $key, $value) = @_;

    $value =~ s/\n/\\n/g;
    $self->{_cfg}->{$block}->{$key} = $value;

}


sub param {
    my $self = shift;

    # @b = $config->param();
    unless ( scalar(@_) ) {
        return keys %{$self->{_cfg}};
    }

    # $config->param('author.f_name');
    if ( scalar(@_) == 1 ) {
        my ($block, $key) = split /\./, $_[0];
        return $self->_get_single_param($block, $key);
    }


    # implementing verion 2.0 API
    my $args = {};
    if ( scalar(@_) == 2 ) {
        # $config->param('author.f_name', 'Shezrod');
        my ($block, $key) = split /\./, $_[0];
        if ( $block && $key ) {
            $self->_set_single_param($block, $key, $_[1]);
        }

        $args = {
            -block  => "",
            -name   => "",
            @_,
        };

        # $config->param(-block=>'author');
        if ( $args->{'-block'} ) {
            return $self->_get_block($args->{'-block'});
        }

        # $config->param(-name=>'author.f_name');
        if ( $args->{'-name'} ) {
            my ($block, $key) = split /\./, $args->{'-name'};
            if ($block && $key) {
                return $self->_get_single_param($block, $key);
            }
        }
    }


    $args = {
        -block  => "",
        -values => {},
        -name   => "",
        -value  => "",
        @_,
    };

    if ( $args->{'-block'} and $args->{'-values'} ) {
        # checking if `-values` is actually a hashref
        unless ( ref( $args->{'-values'} ) eq 'HASH' ) {
            croak "'-values' option requires a hash reference";
        }
        $self->_create_block($args->{'-block'}, $args->{'-values'});
        return 1;
    }


    if ( $args->{'-name'} && $args->{'-value'} ) {
        my ($block, $key) = split /\./, $args->{'-name'};
        if ( $block && $key) {
            $self->_set_single_param($block, $key, $args->{'-value'});
            return 1;
        }
    }
}






# for backward compatability...
sub set_param {
    my $self = shift;

    my ($name, $value) = @_;
    my ($block, $key) = split /\./, $name;
    $self->_set_single_param($block, $key, $value);

}



sub param_hash {
    my $self = shift;

    my %hash = ();
    for my $block ( keys %{$self->{_cfg}} ) {
        $block =~ m/^\./    and next;
        for my $key ( keys %{ $self->{_cfg}{$block} } ) {
            $hash{ $block . '.' . $key } = $self->_get_single_param($block, $key);
        }
    }

    return %hash;
}



sub write {
    my $self = shift;

    my $new_file = $_[0];
    my $file = $self->{_options}{filename};
    my $lock = $self->{_options}{lockfile};

    # checking if anything was changed manually while
    # program was running...
    if ( $MD5 and !$new_file ) {

        open (CHECKSUM, '<' . $self->{_options}{filename}) or carp "Couldn't open $self->{_options}{filename} for reading, $!";
        flock (CHECKSUM, LOCK_SH|LOCK_NB) or carp "Couldn't acquire lock on $self->{_options}{filename}, $!";

        my $md5 = Digest::MD5->new();
        $md5->addfile(*CHECKSUM);

        close CHECKSUM;

        if ( $self->{_checksum} ne $md5->hexdigest ) {
            carp "File's contents have been modified by the third party. Creating a backup copy of the old one";
            copy($file, $file . ".bk");
        }
    }

    sysopen (LCK, $lock, O_RDONLY|O_CREAT) or $errstr = "Couldn't access $lock, $!", return undef;
    flock(LCK, LOCK_EX) or $errstr = "Couldn't get exclusive lock on $lock, $!", return undef;

    $file = $new_file || $file;

    open FH, '>' . $file or $errstr = "Couldn't open $file for writing, $!", return undef;
    select (FH);

    print "; Maintained by Config::Simple/$VERSION\n";
    print "; Get the latest version from http://www.CPAN.org or your nearest CPAN mirror\n";
    print "; ", "-" x 70, "\n\n";

    while ( my($block, $values) = each %{ $self->{_cfg} } ) {

        print "[$block]\n";
        while ( my ($key, $value) = each %{$values} ) {
            print "$key=$value\n";
        }
        print "\n";
    }

    if ( defined $self->{'.'} )  {
        print ".\n";
        print $self->{'.'};
    }

    select (STDOUT);
    close FH;   close LCK;

}




sub load {
    my $self = shift;

    # $config->load($cgi);
    if ( scalar @_ == 1 ) {
        unless ( ref($_[0]) ) {
            $errstr = "load() didn't get expected CGI object";
            return undef;
        }

        my $cgi = $_[0];
        while ( my ($block, $values) = each %{ $self->{_cfg} } ) {
            for my $key ( keys %{$values} ) {
                $cgi->param(-name=>$block . '.' . $key, -value=>$values->{$key});
            }
        }
        return $cgi;
    }

    # $config->load($cgi, $block);
    if ( scalar @_== 2 ) {

        unless ( ref ($_[0]) ) {
            $errstr =  "load() didn't get expcted CGI object as the first argument";
            return undef;
        }

        my $cgi = $_[0];
        while ( my ($key, $value) = each %{$self->{_cfg}{$_[1]} } ) {
            $cgi->param(-name=>$_[1] . '.' . $key, -value=>$value);
        }
        return $cgi;
    }

    $errstr = "Didn't understand the usage. Please refer to online docs of Config::Simple";
    return undef;
}



# not sure if it's the right way. Let me know
sub clone {
    my $self = shift;

    return bless $self, ref($self);
}





sub error {
    my $self = shift;

    return $errstr;

}




sub dump {
    my $self = shift;

    require Data::Dumper;
    return Data::Dumper::Dumper($self);
}

1;

=pod

=head1 NAME

Config::Simple - Simple Configuration Class

=head1 SYNPOSIS

in the app.cfg configuration file:

    [mysql]
    host=ultracgis.com
    login=sherzodr
    password=secret

    [profile]
    first name=Sherzod
    last name=Ruzmetov
    email=sherzodr@cpan.org


in your Perl application:

    use Config::Simple;
    my $cfg = new Config::Simple(filename=>"app.cfg");

    print "MySQL host: ", $config->param("mysql.host"), "\n";
    print "MySQL login: ", $config->param("mysql.login"), "\n";

    # to get just [mysql] block:
    my $mysql = $cfg->param(-block=>"mysql");

    print "MySQL host: ", $mysql->{host}, "\n";
    print "MySQL login: ", $mysql->{login}, "\n";


=head1 NOTE

This documentation refers to version 2.0 of Config::Simple. If you have a version
older than this, please update it to the latest release ASAP (before you get burned).

=head1 DESCRIPTION

This Perl5 library  makes it very easy to parse INI-styled configuration files
and create once on the fly. It optionally requires L<Digest::MD5|Digest::MD5> module

=head2 CONFIGURATION FILE

Configuration file that Config::Simple uses is similar to Window's *.ini file syntax.
Example.,

    ; sample.cfg

    [block1]
    key1=value1
    key2=value2
    ...

    [block2]
    key1=value1
    key2=value2
    ...

It can have infinite number of blocks and infinite number of key/value pairs in each block.
Block and key names are case sensitive. i.e., [block1] and [Block1] are two completely different
blocks. But this might change in the subsequent releases of the library. So please use with caution!

Lines that start with either ';' (semi colon) or '#' (pound) are assumed to be comments
till the end of the line. If a line consists of a sole '.' (dot), then all the lines
till eof are ignored (it's like __END__ Perl token)

When you create Config::Simple object with $cfg = new Config::Simple(filename=>"sample.cfg")
syntax, it reads the above sample.cfg config file, parses the contents, and creates
required data structure, which you can access through its public L<methods|/"METHODS">.

In this documenation when I mention "name", I'll be refering to block name and key delimited with a dot (.).
Forexample, from the above sample.cfg file, following names could be retrieved:
block1.key1, block1.key2, block2.key1 and block2.key2 etc.

Here is the configuration file that I use in most of my CGI applications, and I'll be using it
in most of the examples throughout this manual:

    ;app.cfg

    [mysql]
    host=ultracgis
    login=sherzodr
    password=secret
    db_name=test
    RaiseError=1
    PrintError=1

=head2 fcntl.h Constants

by default Config::Simple exports C<O_RDONLY>, C<O_RDWR>, C<O_CREAT>, C<O_EXCL> L<fcnl.h|Fcntl> (file control) constants.
When you create Config::Simple object by passing it a filename, it will try to read the file.
If it fails it creats the file. This is a default behaviour. If you want to control this behavior,
you'll need to pass mode with your desired fcntl O_* constants to the constructor:

    $config = new Config::Simple(filename=>"app.cfg", mode=>O_RDONLY);
    $config = new Config::Simple(filename=>"app.cfg", mode=>O_RDONLY|O_CREAT); # default
    $config = new Config::Simple(filename=>"app.cfg", mode=>O_EXCL);

fcntl constants:

    +===========+============================================================+
    | constant  |   description                                              |
    +===========+============================================================+
    | O_RDONLY  |  opens a file for reading only, failes if doesn't exist    |
    +-----------+------------------------------------------------------------+
    | O_RDWR    |  opens a file for reading and writing                      |
    +-----------+------------------------------------------------------------+
    | O_CREAT   |  creates a file                                            |
    +-----------+------------------------------------------------------------+
    | O_EXCL    |  creates a file if it doesn't already exist                |
    +-----------+------------------------------------------------------------+

=head1 METHODS

=over 2

=item new( filename=>$scalar [, mode=>O_*] [, lockfile=>$scalar] [,c=>$boolean] )

Constructor method. Requires filename to be present and picks up defaults for the rest
if omitted. mode is used while opening the file, lockfile while updating the file.

It returns Config::Simple object if successfull. If it fails, sets the error message to
$Config::Simple::errstr variable, and returns undef.

mode can accept any of the above described L<fcntl|Fcntl> constants. Default is C<O_RDONLY E<verbar> O_CREAT>.
Default lockfile is the name of the configuration file with ".lock" extension

If you set the value of C<c> to 1 (true), then it checks the configuration file for proper
syntax, and throws an exception if it finds a syntax error. Error message looks
something like C<Syntax error in line 2 of sample.cfg: "this is just wrong" at t/default.t line 11>.
If you set it to 0 (false), those lines will just be ignored.

=item param([args])

If called without any arguments, returns the list of all the available blocks in the
config. file.

If called with arguments, this method suports several  different syntaxes,
and we'll discuss them all seperately.

=over 4

=item param($name))

returns the value of $name. $name is block and key seperated with a dot. For example,
to retrieve the mysql login name from the app.cfg, we could use the following
syntax:

    $login = $cfg->param("mysql.login");

=item param(-name=>$name)

the same as L</"param($name)">

=item param($name, $value)

updates the value of $name to $value. For example, to set the value of "RaiseError" to 0, and
create an new "AutoCommit" key with a true value:

    $cfg->param("mysql.RaiseError", 0);
    $cfg->param("mysql.AutoCommit", 1);

As I implied above, if either the block or the key does not exist, it will be created for you.
So

    $cfg->param("author.f_name", "Sherzod");

would create an [author] block with "f_name=Sherzod" key/value pair.

=item param(-name=>$name, -value=>$value)

the same as L</"param($name, $value)">

=item param(-block=>$block)

returns the whole block as a hash reference. For example, to get the whole [mysql] block:

    $mysql = $cfg->param(-block=>'mysql');

    $login = $mysql->{login};
    $psswd = $mysql->{password};

=item param(-block=>$block, -values=>{key1=>value1, key2=>value2})

creates a new block with the specified values,
or overrides existing block. For example, to add the [site] block to the above app.cfg with
"title=UltraCgis.com" and "description=The coolest site" key/values we could use the following syntax:

    $cfg->param(-block=>"site", -values=>{
                    title=> "UltraCgis.com",
                    description=>"The coolest site",
                    author=>"Sherzod B. Ruzmetov",
                    });

note that if the [site] block already exists, its contents will be cleared and then re-created with
the new values.

=back

=item set_param($name, $value)

This method is provided for backward compatability with 1.x version of Config::Simple. It is identical
to param($name, $value) syntax.

=item param_hash()

handy method to save the contents of the config. file into a hash variable.

    %Config = $cfg->param_hash();

Structure of %Config looks like the following:

    %Config = (
        'mysql.PrintError'  => 1,
        'mysql.db_name'     => 'test',
        'mysql.login'       => 'sherzodr',
        'mysql.password'    => 'secret',
        'mysql.host'        => 'ultracgis.com',
        'mysql.RaiseError'  => 1,
    );

=item write([$new_filename])

Notice, that all the above manipulations take place in the object's memory, ie, changes you
make with param() and set_param() methods do not reflect in the actual config. file.
To update the config file in the end, you'll need to call L<"write()"> method with no arguments.

If you want to save newly updated/created configuration into a new file, pass the new filename
as the first argument to the write() method, and the original config. file will not be
touched.

If it detects that configuration file was updated by a third party while Config::Simple was working
on the file, it throws a harmless warning to STDERR, and will copy the original file to a new location
with the .bk extension, and updates the configuration file with its own contents.

L<"write()"> returns true if successfull, undef, otherwise. Error message can be accessed either
vi $Config::Simple::errstr variable, or by calling L<"error()"> method.

=item error()

Returns the value of $Config::Simple::errstr

=back

=head1 BUGS

Hopefully none.

Please send them to my email if you detect any with a sample code
that triggers that bug. Even if you don't have any, just let me konw that you are using it.
It just makes me feel good ;-)

=head1 COPYRIGHT

    Copyright (C) 2002  Sherzod Ruzmetov <sherzodr@cpan.org>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself

=head1 AUTHOR

    Sherzod B. Ruzmetov <sherzodr@cpan.org>
    http://www.ultracgis.com

=head1 SEE ALSO

L<perl>


=cut
