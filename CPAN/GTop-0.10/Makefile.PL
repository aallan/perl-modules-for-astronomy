use 5.005;
use ExtUtils::MakeMaker;

use strict;

my %interface = (
    'cpu' => [qw(flags total user nice sys idle frequency)],
    'mem' => [qw(flags total used free shared buffer cached user locked)],
    'proc_mem'  => [qw(flags size vsize resident share rss rss_rlim)],
    'proc_time' => [qw(flags start_time rtime utime stime cutime cstime
		       timeout it_real_value frequency)],
    'proc_map' => [qw(flags number total size)],
    'proc_args' => [qw(flags size)],
    'proc_uid' => [qw(flags uid:int euid:int gid:int egid:int pid:int 
		      ppid:int pgrp:int session:int tty:int
		      tpgid:int priority:int nice:int)],
    'map_entry' => [],
    'swap' => [qw(flags total used free pagein pageout)],
    'proc_segment' => [qw(flags text_rss shlib_rss data_rss stack_rss 
			  dirty_size start_code end_code start_stack)],
    'proc_state' => [qw(flags)],
    'netload' => [qw(flags if_flags mtu subnet address packets_in 
		     packets_out packets_total bytes_in bytes_out 
		     bytes_total errors_in errors_out errors_total
		     collisions)],
    'mountlist' => [qw(flags number total size)],
    'proclist' => [qw(flags number total size)],
    'mountentry' => [],
    'fsusage' => [qw(flags blocks bfree bavail files ffree)],
    'uptime' => [qw(flags)],
    'loadavg' => [qw(flags nr_running nr_tasks last_pid)],
);

open TYPEMAP, ">typemap.gtop" or die $!;
open BOOTINC, ">gtop.boot" or die $!;
open BOOTXS, ">gtopxs.boot" or die $!;
open XS, ">xs.gtop" or die $!;
open POD, ">GTop.pod" or die $!;
open TEST, ">test.gtop" or die $!;

print BOOTXS "static void boot_GTop_interface(void)\n{\n";

print TEST <<'EOF';
use strict;
use ExtUtils::testlib;
use GTop ();

my $gtop = GTop->new;

EOF

print POD <<EOF;
=head1 NAME

GTop - Perl interface to libgtop

=head1 SYNOPSIS

 use GTop ();
 my \$gtop = GTop->new;

=head1 DESCRIPTION

Perl interface to libgtop:

 http://home-of-linux.org/gnome/libgtop/

=head1 CLASSES

EOF

my %constructors = map {$_,1} qw(mountlist proclist proc_map mountentry 
				 proc_args map_entry);
my %notunion = map {$_,1} qw(mountentry map_entry);
use constant IS_SOLARIS => $^O eq 'solaris';

for my $if (sort keys %interface) {
    local *FH;
    (my $leaf = $if) =~ s/_(.)/uc $1/e;
    my $class = sprintf "GTop::%s", ucfirst $leaf;
    (my $typedef = $class) =~ s/:/_/g;

    print BOOTXS "    boot_GTop_$if();\n";

    print TYPEMAP "$class\tT_PTROBJ\n";

    print BOOTINC "typedef glibtop_$if * $typedef;\n";
    print BOOTINC qq(\#include "$if.boot"\n);

    my(@args) = ('','','','()');

    if ($if =~ /^proc_/)  { 
	@args = (', pid', 'pid_t pid', '($pid)', '($$)');
    }
    elsif ($if =~ /^netload/) {
	@args = (', interface', 'char * interface', 
		'($interface)', '(\'eth0\')');
    }
    elsif ($if =~ /^mountlist/) {
	@args = (', all_fs', 'int all_fs', '($all_fs)', '(1)');
    }
    elsif ($if =~ /^fsusage/) {
	@args = (', disk', 'char *disk', '($disk)', '(\'/\')');
    }

    print XS <<EOF unless $constructors{$if};

$class
$if(gtop$args[0])
    GTop gtop
    $args[1]

    CODE:
    RETVAL = (glibtop_$if *)safemalloc(sizeof(*RETVAL));
    trace_malloc(RETVAL);
    Zero(RETVAL, 1, glibtop_$if);
    glibtop_get_$if(RETVAL$args[0]);

    OUTPUT:
    RETVAL

EOF

    print TEST <<EOF unless $notunion{$if};

my \$$if = \$gtop->$if$args[3];
print "$if\\n";
for (qw(@{ $interface{$if} })) {
    s/:\\w+\$//;
    printf "   %s => %d\\n", \$_, \$$if->\$_();
}

EOF

    unless ($notunion{$if}) {
	print POD "\n=head2 $class\n";
	print POD "\n    my \$$if = \$gtop->$if$args[2];\n\n";
	print POD "=over 4\n";
    }

    open FH, ">$if.boot" or die $!;

    if (IS_SOLARIS) {
	for my $entry (@{ $interface{$if} }) {
	    my $type = 'u_int64_t'; 
	    if ($entry =~ s/:(\w+)$//) {
		$type = $1;
	    }
	    my $field = $entry;
	    my $xsname = "XS_glibtop_${if}_$field";
	    print FH <<EOF;
static XS($xsname)
{
    dXSARGS; 

    glibtop_$if *s = (void *)SvIV((SV*)SvRV(ST(0)));

    ST(0) = sv_2mortal(newSVnv((unsigned long)s->$field));

    XSRETURN(1); 
}
EOF
          }
}

    print FH "static void boot_GTop_$if (void)\n{\n";

    for my $entry (@{ $interface{$if} }) {
	my $type = 'u_int64_t'; 
	if ($entry =~ s/:(\w+)$//) {
	    $type = $1;
	}
	my $field = $entry;
	my $method = join '::', $class, $field;
	my $xsname = "XS_glibtop_${if}_$field";
	if (IS_SOLARIS) {
	    print FH qq{   newXS("$method", $xsname, __FILE__);\n};
	}
	else {
	    print FH qq{   newGTopXS_$type("$method", glibtop_$if, $field);\n};
	}

	unless ($notunion{$if}) {
	    print POD "\n=item $field\n\n";
	    print POD "    my \$$field = \$$if->$field;\n";
	}
    }
    print FH qq{   newXS("$class\::DESTROY", XS_GTop_destroy, __FILE__);\n} 
    unless $notunion{$if};

    print FH "\n}\n";

    print POD "\n=back\n" unless $notunion{$if};
}

print BOOTXS "\n}\n";
print POD <<EOF;

=head1 AUTHOR

Doug MacEachern

EOF

close TYPEMAP;
close BOOTINC;
close BOOTXS;
close XS;
close POD;
close TEST;

my $GTOP_LIB = "";
if (my $path = $ENV{GTOP_LIB}) {
    $GTOP_LIB = "-L$path ";
}
my $GTOP_INCLUDE = "";
if (my $path = $ENV{GTOP_INCLUDE}) {
    $GTOP_INCLUDE = "-I$path ";
}

chomp(my $ginc = `glib-config --cflags`);
#needed for remote connection
my $xlibs = "-L/usr/X11/lib -L/usr/X11R6/lib -lXau";

my @insure = ();
if (0) {
    @insure = (
       OPTIMIZE => '-g',
       CC => 'insure gcc',
       LD => 'insure gcc',
    );
}

WriteMakefile(
   @insure,
   NAME => 'GTop',
   VERSION_FROM => 'GTop.pm',
   INC => $GTOP_INCLUDE . $ginc,
   LIBS => [$GTOP_LIB . "-lgtop -lgtop_sysdeps -lgtop_common -lglib $xlibs"],
   TYPEMAPS => [qw(typemap.gtop typemap)],
   clean   => {
       FILES => "@{[<*.boot>, <*.gtop>]}",
   },
   'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
   },
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update GTop.pm VERSION now 
EOF
} 

