package GTop::Server;

use DynaLoader ();

use strict;

BEGIN {
    no strict;
    $VERSION = '0.01';
    @ISA = qw(GTop::ServerConfig);

    *dl_load_flags = DynaLoader->can('dl_load_flags');
    do {
	__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap;
    }->(__PACKAGE__, $VERSION);
}

sub read_config {
    my($self, $file) = @_;
    open FH, $file or die "open $file: $!";
    while (<FH>) {
	s/^\s+//; s/\s+$//;
	next if /^\#/;
	next unless $_;
	my($cmd, $rest) = split /\s+/, $_, 2;
	if (my $meth = GTop::ServerConfig->can($cmd)) {
	    $self->$meth($rest);
	}
	else {
	    die "unknown command: `$cmd'";
	}
    }
}

package GTop::ServerConfig;

sub allow {
    my($self, $line) = @_;
    $line =~ s/^from\s+//;
    for (split /\s+/, $line) {
	my $msg = $self->allow($_);
	die $msg if $msg;
    }
}

sub port {
    my($self, $arg) = @_;
    $self->port($arg);
}

sub debug {
    my($self, $arg) = @_;
    $self->flags($self->flags | GTop::Server::DEBUG) if $arg
}

sub no_daemon {
    my($self, $arg) = @_;
    $self->flags($self->flags | GTop::Server::NO_DAEMON) if $arg
}

sub no_fork {
    my($self, $arg) = @_;
    $self->flags($self->flags | GTop::Server::NO_FORK) if $arg
}

1;
__END__
