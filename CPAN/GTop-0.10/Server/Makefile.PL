use ExtUtils::MakeMaker;

my $GTOP_LIB = "";
if (my $path = $ENV{GTOP_LIB}) {
    $GTOP_LIB = "-L$path ";
}
my $GTOP_INCLUDE = "";
if (my $path = $ENV{GTOP_INCLUDE}) {
    $GTOP_INCLUDE = "-I$path ";
}

chomp(my $ginc = `glib-config --cflags`);

open FH, ">server_config_flags.h" or die "open server_config.h : $!";
open CONST, ">constants.c" or die "open constants.c: $!";

my @flags = qw(NONE INIT DEBUG VERBOSE NO_DAEMON NO_FORK CHANGED_UID);
my $bits = 0;
for my $flag (@flags) {
    print FH <<EOF;
#define GTOP_Sf_${flag} $bits
#define GTOP_S_${flag}     (glibtop_server_config->flags & GTOP_Sf_$flag)
#define GTOP_S_${flag}_on  (glibtop_server_config->flags |= GTOP_Sf_$flag)
#define GTOP_S_${flag}_off (glibtop_server_config->flags &= ~GTOP_Sf_$flag)

EOF
    print CONST qq{   newCONSTSUB(stash, "$flag", newSViv(GTOP_Sf_${flag}));\n};
    if ($bits < 2) {
	$bits++;
    }
    else {
	$bits *= 2;
    }
}

close FH;
close CONST;

WriteMakefile(
    NAME => "GTop::Server",
    VERSION_FROM => "Server.pm",
    INC => $GTOP_INCLUDE . $ginc,
    LIBS => [$GTOP_LIB . "-lgtop -lgtop_sysdeps -lgtop_common -lglib"],
    OBJECT => 'io.o main.o gnuserv.o version.o access.o Server.o',
    clean   => {
       FILES => "server_config_flags.h constants.c",
    },
);
