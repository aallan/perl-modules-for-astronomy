# This Makefile is for the libwww-perl extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.03 (Revision: 1.63) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#
#   MakeMaker Parameters:

#     EXE_FILES => [q[bin/lwp-request], q[bin/lwp-mirror], q[bin/lwp-rget], q[bin/lwp-download], q[bin/GET], q[bin/HEAD], q[bin/POST]]
#     NAME => q[libwww-perl]
#     PREREQ_PM => { Net::FTP=>q[2.58], URI=>q[1.10], MIME::Base64=>q[2.1], Digest::MD5=>q[0], HTML::HeadParser=>q[0] }
#     VERSION_FROM => q[lib/LWP.pm]
#     clean => { FILES=>q[bin/GET bin/HEAD bin/POST] }
#     dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /home/perl/lib/5.8.0/i686-linux-thread-multi/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS = -fpic
CCDLFLAGS = -rdynamic
DLEXT = so
DLSRC = dl_dlopen.xs
LD = gcc
LDDLFLAGS = -shared -L/usr/local/lib
LDFLAGS =  -L/usr/local/lib
LIBC = /lib/libc-2.2.5.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.4.7-10smp
RANLIB = :
SO = so
EXE_EXT = 
FULL_AR = /usr/bin/ar


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = libwww-perl
DISTNAME = libwww-perl
NAME_SYM = libwww_perl
VERSION = 5.69
VERSION_SYM = 5_69
XS_VERSION = 5.69
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INSTALLDIRS = site
PREFIX = /home/perl
SITEPREFIX = /home/perl
VENDORPREFIX = 
INSTALLPRIVLIB = /home/perl/lib/5.8.0
INSTALLSITELIB = /home/perl/lib/site_perl/5.8.0
INSTALLVENDORLIB = 
INSTALLARCHLIB = /home/perl/lib/5.8.0/i686-linux-thread-multi
INSTALLSITEARCH = /home/perl/lib/site_perl/5.8.0/i686-linux-thread-multi
INSTALLVENDORARCH = 
INSTALLBIN = /home/perl/bin
INSTALLSITEBIN = /home/perl/bin
INSTALLVENDORBIN = 
INSTALLSCRIPT = /home/perl/bin
PERL_LIB = /home/perl/lib/5.8.0
PERL_ARCHLIB = /home/perl/lib/5.8.0/i686-linux-thread-multi
SITELIBEXP = /home/perl/lib/site_perl/5.8.0
SITEARCHEXP = /home/perl/lib/site_perl/5.8.0/i686-linux-thread-multi
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE
PERL = /home/perl/bin/perl
FULLPERL = /home/perl/bin/perl
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERL = $(PERL)
ABSPERLRUN = $(ABSPERL)
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULL_AR = /usr/bin/ar
PERL_CORE = 0
NOOP = $(SHELL) -c true
NOECHO = @

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc

MAKEMAKER = /home/perl/lib/5.8.0/ExtUtils/MakeMaker.pm
MM_VERSION = 6.03

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = libwww-perl
BASEEXT = perl
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = lib/LWP.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= 
C_FILES = 
O_FILES = 
H_FILES = 
MAN1PODS = bin/GET \
	bin/HEAD \
	bin/POST \
	bin/lwp-download \
	bin/lwp-mirror \
	bin/lwp-request \
	bin/lwp-rget
MAN3PODS = lib/Bundle/LWP.pm \
	lib/File/Listing.pm \
	lib/HTML/Form.pm \
	lib/HTTP/Cookies.pm \
	lib/HTTP/Cookies/Microsoft.pm \
	lib/HTTP/Cookies/Netscape.pm \
	lib/HTTP/Daemon.pm \
	lib/HTTP/Date.pm \
	lib/HTTP/Headers.pm \
	lib/HTTP/Headers/Util.pm \
	lib/HTTP/Message.pm \
	lib/HTTP/Negotiate.pm \
	lib/HTTP/Request.pm \
	lib/HTTP/Request/Common.pm \
	lib/HTTP/Response.pm \
	lib/HTTP/Status.pm \
	lib/LWP.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	lib/LWP/DebugFile.pm \
	lib/LWP/MediaTypes.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	lib/Net/HTTP.pm \
	lib/Net/HTTP/NB.pm \
	lib/WWW/RobotRules.pm \
	lib/WWW/RobotRules/AnyDBM_File.pm \
	lwpcook.pod \
	lwptut.pod
INST_MAN1DIR = blib/man1
MAN1EXT = 1
INSTALLMAN1DIR = /home/perl/man/man1
INSTALLSITEMAN1DIR = /home/perl/man/man$(MAN1EXT)
INST_MAN3DIR = blib/man3
MAN3EXT = 3
INSTALLMAN3DIR = /home/perl/man/man3
INSTALLSITEMAN3DIR = /home/perl/man/man$(MAN3EXT)
PERM_RW = 644
PERM_RWX = 755

# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h

# Where to put things:
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =

EXPORT_LIST = 

PERL_ARCHIVE = 

PERL_ARCHIVE_AFTER = 

TO_INST_PM = lib/Bundle/LWP.pm \
	lib/File/Listing.pm \
	lib/HTML/Form.pm \
	lib/HTTP/Cookies.pm \
	lib/HTTP/Cookies/Microsoft.pm \
	lib/HTTP/Cookies/Netscape.pm \
	lib/HTTP/Daemon.pm \
	lib/HTTP/Date.pm \
	lib/HTTP/Headers.pm \
	lib/HTTP/Headers/Auth.pm \
	lib/HTTP/Headers/ETag.pm \
	lib/HTTP/Headers/Util.pm \
	lib/HTTP/Message.pm \
	lib/HTTP/Negotiate.pm \
	lib/HTTP/Request.pm \
	lib/HTTP/Request/Common.pm \
	lib/HTTP/Response.pm \
	lib/HTTP/Status.pm \
	lib/LWP.pm \
	lib/LWP/Authen/Basic.pm \
	lib/LWP/Authen/Digest.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	lib/LWP/DebugFile.pm \
	lib/LWP/MediaTypes.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	lib/LWP/Protocol/GHTTP.pm \
	lib/LWP/Protocol/data.pm \
	lib/LWP/Protocol/file.pm \
	lib/LWP/Protocol/ftp.pm \
	lib/LWP/Protocol/gopher.pm \
	lib/LWP/Protocol/http.pm \
	lib/LWP/Protocol/http10.pm \
	lib/LWP/Protocol/https.pm \
	lib/LWP/Protocol/https10.pm \
	lib/LWP/Protocol/mailto.pm \
	lib/LWP/Protocol/nntp.pm \
	lib/LWP/Protocol/nogo.pm \
	lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	lib/LWP/media.types \
	lib/Net/HTTP.pm \
	lib/Net/HTTP/Methods.pm \
	lib/Net/HTTP/NB.pm \
	lib/Net/HTTPS.pm \
	lib/WWW/RobotRules.pm \
	lib/WWW/RobotRules/AnyDBM_File.pm \
	lwpcook.pod \
	lwptut.pod

PM_TO_BLIB = lib/LWP/RobotUA.pm \
	blib/lib/LWP/RobotUA.pm \
	lib/LWP/Authen/Ntlm.pm \
	blib/lib/LWP/Authen/Ntlm.pm \
	lib/HTTP/Headers/ETag.pm \
	blib/lib/HTTP/Headers/ETag.pm \
	lib/LWP.pm \
	blib/lib/LWP.pm \
	lib/LWP/Protocol.pm \
	blib/lib/LWP/Protocol.pm \
	lib/HTTP/Request/Common.pm \
	blib/lib/HTTP/Request/Common.pm \
	lwptut.pod \
	blib/lib/lwptut.pod \
	lib/HTTP/Message.pm \
	blib/lib/HTTP/Message.pm \
	lib/LWP/Protocol/ftp.pm \
	blib/lib/LWP/Protocol/ftp.pm \
	lib/HTML/Form.pm \
	blib/lib/HTML/Form.pm \
	lib/HTTP/Cookies/Netscape.pm \
	blib/lib/HTTP/Cookies/Netscape.pm \
	lib/LWP/Authen/Digest.pm \
	blib/lib/LWP/Authen/Digest.pm \
	lib/LWP/Protocol/gopher.pm \
	blib/lib/LWP/Protocol/gopher.pm \
	lib/HTTP/Status.pm \
	blib/lib/HTTP/Status.pm \
	lib/Net/HTTP/NB.pm \
	blib/lib/Net/HTTP/NB.pm \
	lib/Net/HTTPS.pm \
	blib/lib/Net/HTTPS.pm \
	lib/HTTP/Headers/Util.pm \
	blib/lib/HTTP/Headers/Util.pm \
	lib/LWP/Authen/Basic.pm \
	blib/lib/LWP/Authen/Basic.pm \
	lib/HTTP/Cookies/Microsoft.pm \
	blib/lib/HTTP/Cookies/Microsoft.pm \
	lib/LWP/Protocol/nntp.pm \
	blib/lib/LWP/Protocol/nntp.pm \
	lib/LWP/UserAgent.pm \
	blib/lib/LWP/UserAgent.pm \
	lib/LWP/Protocol/http.pm \
	blib/lib/LWP/Protocol/http.pm \
	lib/LWP/Protocol/https10.pm \
	blib/lib/LWP/Protocol/https10.pm \
	lib/LWP/Protocol/mailto.pm \
	blib/lib/LWP/Protocol/mailto.pm \
	lib/LWP/MemberMixin.pm \
	blib/lib/LWP/MemberMixin.pm \
	lib/HTTP/Headers/Auth.pm \
	blib/lib/HTTP/Headers/Auth.pm \
	lib/LWP/Debug.pm \
	blib/lib/LWP/Debug.pm \
	lib/Net/HTTP.pm \
	blib/lib/Net/HTTP.pm \
	lib/LWP/media.types \
	blib/lib/LWP/media.types \
	lib/HTTP/Daemon.pm \
	blib/lib/HTTP/Daemon.pm \
	lib/HTTP/Cookies.pm \
	blib/lib/HTTP/Cookies.pm \
	lib/LWP/ConnCache.pm \
	blib/lib/LWP/ConnCache.pm \
	lib/File/Listing.pm \
	blib/lib/File/Listing.pm \
	lib/WWW/RobotRules/AnyDBM_File.pm \
	blib/lib/WWW/RobotRules/AnyDBM_File.pm \
	lwpcook.pod \
	blib/lib/lwpcook.pod \
	lib/LWP/MediaTypes.pm \
	blib/lib/LWP/MediaTypes.pm \
	lib/HTTP/Date.pm \
	blib/lib/HTTP/Date.pm \
	lib/LWP/Protocol/file.pm \
	blib/lib/LWP/Protocol/file.pm \
	lib/LWP/Protocol/http10.pm \
	blib/lib/LWP/Protocol/http10.pm \
	lib/LWP/Protocol/GHTTP.pm \
	blib/lib/LWP/Protocol/GHTTP.pm \
	lib/HTTP/Negotiate.pm \
	blib/lib/HTTP/Negotiate.pm \
	lib/HTTP/Request.pm \
	blib/lib/HTTP/Request.pm \
	lib/LWP/DebugFile.pm \
	blib/lib/LWP/DebugFile.pm \
	lib/WWW/RobotRules.pm \
	blib/lib/WWW/RobotRules.pm \
	lib/LWP/Protocol/data.pm \
	blib/lib/LWP/Protocol/data.pm \
	lib/LWP/Protocol/nogo.pm \
	blib/lib/LWP/Protocol/nogo.pm \
	lib/HTTP/Response.pm \
	blib/lib/HTTP/Response.pm \
	lib/HTTP/Headers.pm \
	blib/lib/HTTP/Headers.pm \
	lib/LWP/Simple.pm \
	blib/lib/LWP/Simple.pm \
	lib/LWP/Protocol/https.pm \
	blib/lib/LWP/Protocol/https.pm \
	lib/Bundle/LWP.pm \
	blib/lib/Bundle/LWP.pm \
	lib/Net/HTTP/Methods.pm \
	blib/lib/Net/HTTP/Methods.pm


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERLRUN) -e 'use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:

SHELL = /bin/sh
CHMOD = chmod
CP = cp
LD = gcc
MV = mv
NOOP = $(SHELL) -c true
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1

# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERLRUN) "-MExtUtils::Command" -e mkpath

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERLRUN) "-MExtUtils::Command" -e eqtime

# Here we warn users that an old packlist file was found somewhere,
# and that they should call some uninstall routine
WARN_IF_OLD_PACKLIST = $(PERL) -we 'exit unless -f $$ARGV[0];' \
-e 'print "WARNING: I have found an old package in\n";' \
-e 'print "\t$$ARGV[0].\n";' \
-e 'print "Please make sure the two installations are not conflicting\n";'

UNINST=0
VERBINST=0

MOD_INSTALL = $(PERL) "-I$(INST_LIB)" "-I$(PERL_LIB)" "-MExtUtils::Install" \
-e "install({@ARGV},'$(VERBINST)',0,'$(UNINST)');"

DOC_INSTALL = $(PERL) -e '$$\="\n\n";' \
-e 'print "=head2 ", scalar(localtime), ": C<", shift, ">", " L<", $$arg=shift, "|", $$arg, ">";' \
-e 'print "=over 4";' \
-e 'while (defined($$key = shift) and defined($$val = shift)){print "=item *";print "C<$$key: $$val>";}' \
-e 'print "=back";'

UNINSTALL =   $(PERLRUN) "-MExtUtils::Install" \
-e 'uninstall($$ARGV[0],1,1); print "\nUninstall is deprecated. Please check the";' \
-e 'print " packlist above carefully.\n  There may be errors. Remove the";' \
-e 'print " appropriate files manually.\n  Sorry for the inconveniences.\n"'


# --- MakeMaker dist section:
ZIPFLAGS = -r
TO_UNIX = @$(NOOP)
TAR = tar
POSTOP = @$(NOOP)
ZIP = zip
DIST_DEFAULT = tardist
CI = ci -u
SHAR = shar
COMPRESS = gzip -9f
DIST_CP = best
PREOP = @$(NOOP)
TARFLAGS = cvf
DISTVNAME = $(DISTNAME)-$(VERSION)
SUFFIX = gz
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIB="$(LIB)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"\
	PASTHRU_DEFINE="$(PASTHRU_DEFINE)"\
	PASTHRU_INC="$(PASTHRU_INC)"


# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:

all :: pure_all manifypods
	@$(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	@$(NOOP)

subdirs :: $(MYEXTLIB)
	@$(NOOP)

config :: Makefile $(INST_LIBDIR)/.exists
	@$(NOOP)

config :: $(INST_ARCHAUTODIR)/.exists
	@$(NOOP)

config :: $(INST_AUTODIR)/.exists
	@$(NOOP)

$(INST_AUTODIR)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_AUTODIR)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_AUTODIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_LIBDIR)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_LIBDIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)

config :: $(INST_MAN1DIR)/.exists
	@$(NOOP)


$(INST_MAN1DIR)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_MAN1DIR)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_MAN1DIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_MAN1DIR)

config :: $(INST_MAN3DIR)/.exists
	@$(NOOP)


$(INST_MAN3DIR)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_MAN3DIR)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_MAN3DIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_MAN3DIR)

help:
	perldoc ExtUtils::MakeMaker


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	@$(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make dynamic"
#dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT)
	@$(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
#static :: Makefile $(INST_STATIC) $(INST_PM)
static :: Makefile $(INST_STATIC)
	@$(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:
POD2MAN_EXE = /home/perl/bin/pod2man --release libwww-perl-5.69
POD2MAN = $(PERL) -we '%m=@ARGV;for (keys %m){' \
-e 'next if -e $$m{$$_} && -M $$m{$$_} < -M $$_ && -M $$m{$$_} < -M "Makefile";' \
-e 'print "Manifying $$m{$$_}\n";' \
-e 'system(q[$(PERLRUN) $(POD2MAN_EXE) ].qq[$$_>$$m{$$_}])==0 or warn "Couldn\047t install $$m{$$_}\n";' \
-e 'chmod(oct($(PERM_RW)), $$m{$$_}) or warn "chmod $(PERM_RW) $$m{$$_}: $$!\n";}'

manifypods : pure_all bin/GET \
	bin/POST \
	bin/HEAD \
	bin/lwp-mirror \
	bin/lwp-download \
	bin/lwp-rget \
	bin/lwp-request \
	lib/LWP/RobotUA.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP.pm \
	lib/LWP/Protocol.pm \
	lib/HTTP/Request/Common.pm \
	lwptut.pod \
	lib/HTTP/Message.pm \
	lib/HTML/Form.pm \
	lib/HTTP/Cookies/Netscape.pm \
	lib/Net/HTTP/NB.pm \
	lib/HTTP/Status.pm \
	lib/HTTP/Headers/Util.pm \
	lib/HTTP/Cookies/Microsoft.pm \
	lib/LWP/UserAgent.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Debug.pm \
	lib/Net/HTTP.pm \
	lib/HTTP/Daemon.pm \
	lib/HTTP/Cookies.pm \
	lib/LWP/ConnCache.pm \
	lib/File/Listing.pm \
	lib/WWW/RobotRules/AnyDBM_File.pm \
	lib/LWP/MediaTypes.pm \
	lwpcook.pod \
	lib/HTTP/Date.pm \
	lib/WWW/RobotRules.pm \
	lib/LWP/DebugFile.pm \
	lib/HTTP/Request.pm \
	lib/HTTP/Negotiate.pm \
	lib/HTTP/Response.pm \
	lib/LWP/Simple.pm \
	lib/HTTP/Headers.pm \
	lib/Bundle/LWP.pm
	@$(POD2MAN) \
	bin/GET \
	$(INST_MAN1DIR)/GET.$(MAN1EXT) \
	bin/POST \
	$(INST_MAN1DIR)/POST.$(MAN1EXT) \
	bin/HEAD \
	$(INST_MAN1DIR)/HEAD.$(MAN1EXT) \
	bin/lwp-mirror \
	$(INST_MAN1DIR)/lwp-mirror.$(MAN1EXT) \
	bin/lwp-download \
	$(INST_MAN1DIR)/lwp-download.$(MAN1EXT) \
	bin/lwp-rget \
	$(INST_MAN1DIR)/lwp-rget.$(MAN1EXT) \
	bin/lwp-request \
	$(INST_MAN1DIR)/lwp-request.$(MAN1EXT) \
	lib/LWP/RobotUA.pm \
	$(INST_MAN3DIR)/LWP::RobotUA.$(MAN3EXT) \
	lib/LWP/Authen/Ntlm.pm \
	$(INST_MAN3DIR)/LWP::Authen::Ntlm.$(MAN3EXT) \
	lib/LWP.pm \
	$(INST_MAN3DIR)/LWP.$(MAN3EXT) \
	lib/LWP/Protocol.pm \
	$(INST_MAN3DIR)/LWP::Protocol.$(MAN3EXT) \
	lib/HTTP/Request/Common.pm \
	$(INST_MAN3DIR)/HTTP::Request::Common.$(MAN3EXT) \
	lwptut.pod \
	$(INST_MAN3DIR)/lwptut.$(MAN3EXT) \
	lib/HTTP/Message.pm \
	$(INST_MAN3DIR)/HTTP::Message.$(MAN3EXT) \
	lib/HTML/Form.pm \
	$(INST_MAN3DIR)/HTML::Form.$(MAN3EXT) \
	lib/HTTP/Cookies/Netscape.pm \
	$(INST_MAN3DIR)/HTTP::Cookies::Netscape.$(MAN3EXT) \
	lib/Net/HTTP/NB.pm \
	$(INST_MAN3DIR)/Net::HTTP::NB.$(MAN3EXT) \
	lib/HTTP/Status.pm \
	$(INST_MAN3DIR)/HTTP::Status.$(MAN3EXT) \
	lib/HTTP/Headers/Util.pm \
	$(INST_MAN3DIR)/HTTP::Headers::Util.$(MAN3EXT) \
	lib/HTTP/Cookies/Microsoft.pm \
	$(INST_MAN3DIR)/HTTP::Cookies::Microsoft.$(MAN3EXT) \
	lib/LWP/UserAgent.pm \
	$(INST_MAN3DIR)/LWP::UserAgent.$(MAN3EXT) \
	lib/LWP/MemberMixin.pm \
	$(INST_MAN3DIR)/LWP::MemberMixin.$(MAN3EXT) \
	lib/LWP/Debug.pm \
	$(INST_MAN3DIR)/LWP::Debug.$(MAN3EXT) \
	lib/Net/HTTP.pm \
	$(INST_MAN3DIR)/Net::HTTP.$(MAN3EXT) \
	lib/HTTP/Daemon.pm \
	$(INST_MAN3DIR)/HTTP::Daemon.$(MAN3EXT) \
	lib/HTTP/Cookies.pm \
	$(INST_MAN3DIR)/HTTP::Cookies.$(MAN3EXT) \
	lib/LWP/ConnCache.pm \
	$(INST_MAN3DIR)/LWP::ConnCache.$(MAN3EXT) \
	lib/File/Listing.pm \
	$(INST_MAN3DIR)/File::Listing.$(MAN3EXT) \
	lib/WWW/RobotRules/AnyDBM_File.pm \
	$(INST_MAN3DIR)/WWW::RobotRules::AnyDBM_File.$(MAN3EXT) \
	lib/LWP/MediaTypes.pm \
	$(INST_MAN3DIR)/LWP::MediaTypes.$(MAN3EXT) \
	lwpcook.pod \
	$(INST_MAN3DIR)/lwpcook.$(MAN3EXT) \
	lib/HTTP/Date.pm \
	$(INST_MAN3DIR)/HTTP::Date.$(MAN3EXT) \
	lib/WWW/RobotRules.pm \
	$(INST_MAN3DIR)/WWW::RobotRules.$(MAN3EXT) \
	lib/LWP/DebugFile.pm \
	$(INST_MAN3DIR)/LWP::DebugFile.$(MAN3EXT) \
	lib/HTTP/Request.pm \
	$(INST_MAN3DIR)/HTTP::Request.$(MAN3EXT) \
	lib/HTTP/Negotiate.pm \
	$(INST_MAN3DIR)/HTTP::Negotiate.$(MAN3EXT) \
	lib/HTTP/Response.pm \
	$(INST_MAN3DIR)/HTTP::Response.$(MAN3EXT) \
	lib/LWP/Simple.pm \
	$(INST_MAN3DIR)/LWP::Simple.$(MAN3EXT) \
	lib/HTTP/Headers.pm \
	$(INST_MAN3DIR)/HTTP::Headers.$(MAN3EXT) \
	lib/Bundle/LWP.pm \
	$(INST_MAN3DIR)/Bundle::LWP.$(MAN3EXT)

# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

$(INST_SCRIPT)/.exists :: /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h
	@$(MKPATH) $(INST_SCRIPT)
	@$(EQUALIZE_TIMESTAMP) /home/perl/lib/5.8.0/i686-linux-thread-multi/CORE/perl.h $(INST_SCRIPT)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)

EXE_FILES = bin/lwp-request bin/lwp-mirror bin/lwp-rget bin/lwp-download bin/GET bin/HEAD bin/POST

FIXIN = $(PERLRUN) "-MExtUtils::MY" \
    -e "MY->fixin(shift)"

pure_all :: $(INST_SCRIPT)/GET $(INST_SCRIPT)/POST $(INST_SCRIPT)/HEAD $(INST_SCRIPT)/lwp-mirror $(INST_SCRIPT)/lwp-download $(INST_SCRIPT)/lwp-rget $(INST_SCRIPT)/lwp-request
	@$(NOOP)

realclean ::
	rm -f $(INST_SCRIPT)/GET $(INST_SCRIPT)/POST $(INST_SCRIPT)/HEAD $(INST_SCRIPT)/lwp-mirror $(INST_SCRIPT)/lwp-download $(INST_SCRIPT)/lwp-rget $(INST_SCRIPT)/lwp-request

$(INST_SCRIPT)/GET: bin/GET Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/GET
	cp bin/GET $(INST_SCRIPT)/GET
	$(FIXIN) $(INST_SCRIPT)/GET
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/GET

$(INST_SCRIPT)/POST: bin/POST Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/POST
	cp bin/POST $(INST_SCRIPT)/POST
	$(FIXIN) $(INST_SCRIPT)/POST
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/POST

$(INST_SCRIPT)/HEAD: bin/HEAD Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/HEAD
	cp bin/HEAD $(INST_SCRIPT)/HEAD
	$(FIXIN) $(INST_SCRIPT)/HEAD
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/HEAD

$(INST_SCRIPT)/lwp-mirror: bin/lwp-mirror Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/lwp-mirror
	cp bin/lwp-mirror $(INST_SCRIPT)/lwp-mirror
	$(FIXIN) $(INST_SCRIPT)/lwp-mirror
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-mirror

$(INST_SCRIPT)/lwp-download: bin/lwp-download Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/lwp-download
	cp bin/lwp-download $(INST_SCRIPT)/lwp-download
	$(FIXIN) $(INST_SCRIPT)/lwp-download
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-download

$(INST_SCRIPT)/lwp-rget: bin/lwp-rget Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/lwp-rget
	cp bin/lwp-rget $(INST_SCRIPT)/lwp-rget
	$(FIXIN) $(INST_SCRIPT)/lwp-rget
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-rget

$(INST_SCRIPT)/lwp-request: bin/lwp-request Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/lwp-request
	cp bin/lwp-request $(INST_SCRIPT)/lwp-request
	$(FIXIN) $(INST_SCRIPT)/lwp-request
	-@$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-request


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf bin/GET bin/HEAD bin/POST ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c tmon.out mon.out so_locations pm_to_blib *$(OBJ_EXT) *$(LIB_EXT) perl.exe perl perl$(EXE_EXT) $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def lib$(BASEEXT).def $(BASEEXT).exp $(BASEEXT).x core core.*perl.*.? *perl.core
	-mv Makefile Makefile.old $(DEV_NULL)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -rf $(DISTVNAME)
	rm -f  blib/lib/LWP/RobotUA.pm blib/lib/LWP/Authen/Ntlm.pm
	rm -f blib/lib/HTTP/Headers/ETag.pm blib/lib/LWP.pm blib/lib/LWP/Protocol.pm
	rm -f blib/lib/HTTP/Request/Common.pm blib/lib/lwptut.pod blib/lib/HTTP/Message.pm
	rm -f blib/lib/LWP/Protocol/ftp.pm blib/lib/HTML/Form.pm
	rm -f blib/lib/HTTP/Cookies/Netscape.pm blib/lib/LWP/Authen/Digest.pm
	rm -f blib/lib/LWP/Protocol/gopher.pm blib/lib/HTTP/Status.pm blib/lib/Net/HTTP/NB.pm
	rm -f blib/lib/Net/HTTPS.pm blib/lib/HTTP/Headers/Util.pm blib/lib/LWP/Authen/Basic.pm
	rm -f blib/lib/HTTP/Cookies/Microsoft.pm blib/lib/LWP/Protocol/nntp.pm
	rm -f blib/lib/LWP/UserAgent.pm blib/lib/LWP/Protocol/http.pm
	rm -f blib/lib/LWP/Protocol/https10.pm blib/lib/LWP/Protocol/mailto.pm
	rm -f blib/lib/LWP/MemberMixin.pm blib/lib/HTTP/Headers/Auth.pm blib/lib/LWP/Debug.pm
	rm -f blib/lib/Net/HTTP.pm blib/lib/LWP/media.types blib/lib/HTTP/Daemon.pm
	rm -f blib/lib/HTTP/Cookies.pm blib/lib/LWP/ConnCache.pm blib/lib/File/Listing.pm
	rm -f blib/lib/WWW/RobotRules/AnyDBM_File.pm blib/lib/lwpcook.pod
	rm -f blib/lib/LWP/MediaTypes.pm blib/lib/HTTP/Date.pm blib/lib/LWP/Protocol/file.pm
	rm -f blib/lib/LWP/Protocol/http10.pm blib/lib/LWP/Protocol/GHTTP.pm
	rm -f blib/lib/HTTP/Negotiate.pm blib/lib/HTTP/Request.pm blib/lib/LWP/DebugFile.pm
	rm -f blib/lib/WWW/RobotRules.pm blib/lib/LWP/Protocol/data.pm
	rm -f blib/lib/LWP/Protocol/nogo.pm blib/lib/HTTP/Response.pm blib/lib/HTTP/Headers.pm
	rm -f blib/lib/LWP/Simple.pm blib/lib/LWP/Protocol/https.pm blib/lib/Bundle/LWP.pm
	rm -f blib/lib/Net/HTTP/Methods.pm
	rm -rf Makefile Makefile.old


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ *.orig */*~ */*.orig



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT)
	@$(PERL) -le 'print "Warning: Makefile possibly out of date with $$vf" if ' \
	    -e '-e ($$vf="$(VERSION_FROM)") and -M $$vf < -M "Makefile";'

tardist : $(DISTVNAME).tar$(SUFFIX)

zipdist : $(DISTVNAME).zip

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) \
		$(DISTVNAME).tar$(SUFFIX) > \
		$(DISTVNAME).tar$(SUFFIX)_uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker dist_dir section:
distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"



# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)


# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
		-e "@all = keys %{ maniread() };" \
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \
		-e 'print("Executing $(RCS_LABEL) ...\n"); system("$(RCS_LABEL) @all");'


# --- MakeMaker install section:

install :: all pure_install doc_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_vendor :: all pure_vendor_install doc_vendor_install

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install
	@echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod

pure__install : pure_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	@$(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(INSTALLARCHLIB) \
		$(INST_BIN) $(INSTALLBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_MAN1DIR) $(INSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install ::
	@$(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLSITELIB) \
		$(INST_ARCHLIB) $(INSTALLSITEARCH) \
		$(INST_BIN) $(INSTALLSITEBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_MAN1DIR) $(INSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLSITEMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install ::
	@$(MOD_INSTALL) \
		$(INST_LIB) $(INSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(INSTALLVENDORARCH) \
		$(INST_BIN) $(INSTALLVENDORBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_MAN1DIR) $(INSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLVENDORMAN3DIR)

doc_perl_install ::
	-@$(MKPATH) $(INSTALLARCHLIB)
	-@$(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLARCHLIB)/perllocal.pod

doc_site_install ::
	-@$(MKPATH) $(INSTALLARCHLIB)
	-@$(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLSITEARCH)/perllocal.pod

doc_vendor_install ::


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	@$(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	@$(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	@$(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile : Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@$(RM_F) Makefile.old
	-@$(MV) Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean $(DEV_NULL) || $(NOOP)
	$(PERLRUN) Makefile.PL 
	@echo "==> Your Makefile has been rebuilt. <=="
	@echo "==> Please rerun the make command.  <=="
	false



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /home/perl/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	@echo Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	@$(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"$(DISTNAME)\" VERSION=\"5,69,0,0\">\n\t<TITLE>$(DISTNAME)</TITLE>\n\t<ABSTRACT></ABSTRACT>\n\t<AUTHOR></AUTHOR>\n}" > $(DISTNAME).ppd
	@$(PERL) -e "print qq{\t<IMPLEMENTATION>\n\t\t<DEPENDENCY NAME=\"Digest-MD5\" VERSION=\"0,0,0,0\" />\n\t\t<DEPENDENCY NAME=\"HTML-HeadParser\" VERSION=\"0,0,0,0\" />\n\t\t<DEPENDENCY NAME=\"MIME-Base64\" VERSION=\"2,1,0,0\" />\n\t\t<DEPENDENCY NAME=\"Net-FTP\" VERSION=\"2,58,0,0\" />\n\t\t<DEPENDENCY NAME=\"URI\" VERSION=\"1,10,0,0\" />\n}" >> $(DISTNAME).ppd
	@$(PERL) -e "print qq{\t\t<OS NAME=\"$(OSNAME)\" />\n\t\t<ARCHITECTURE NAME=\"i686-linux-thread-multi\" />\n\t\t<CODEBASE HREF=\"\" />\n\t</IMPLEMENTATION>\n</SOFTPKG>\n}" >> $(DISTNAME).ppd

# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/RobotUA.pm blib/lib/LWP/RobotUA.pm lib/LWP/Authen/Ntlm.pm blib/lib/LWP/Authen/Ntlm.pm lib/LWP.pm blib/lib/LWP.pm lib/HTTP/Headers/ETag.pm blib/lib/HTTP/Headers/ETag.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Protocol.pm blib/lib/LWP/Protocol.pm lwptut.pod blib/lib/lwptut.pod lib/HTTP/Request/Common.pm blib/lib/HTTP/Request/Common.pm lib/HTTP/Message.pm blib/lib/HTTP/Message.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Protocol/ftp.pm blib/lib/LWP/Protocol/ftp.pm lib/HTML/Form.pm blib/lib/HTML/Form.pm lib/HTTP/Cookies/Netscape.pm blib/lib/HTTP/Cookies/Netscape.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Authen/Digest.pm blib/lib/LWP/Authen/Digest.pm lib/LWP/Protocol/gopher.pm blib/lib/LWP/Protocol/gopher.pm lib/HTTP/Status.pm blib/lib/HTTP/Status.pm lib/Net/HTTP/NB.pm blib/lib/Net/HTTP/NB.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/Net/HTTPS.pm blib/lib/Net/HTTPS.pm lib/HTTP/Headers/Util.pm blib/lib/HTTP/Headers/Util.pm lib/LWP/Authen/Basic.pm blib/lib/LWP/Authen/Basic.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/HTTP/Cookies/Microsoft.pm blib/lib/HTTP/Cookies/Microsoft.pm lib/LWP/Protocol/nntp.pm blib/lib/LWP/Protocol/nntp.pm lib/LWP/UserAgent.pm blib/lib/LWP/UserAgent.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Protocol/mailto.pm blib/lib/LWP/Protocol/mailto.pm lib/LWP/Protocol/https10.pm blib/lib/LWP/Protocol/https10.pm lib/LWP/Protocol/http.pm blib/lib/LWP/Protocol/http.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/MemberMixin.pm blib/lib/LWP/MemberMixin.pm lib/HTTP/Headers/Auth.pm blib/lib/HTTP/Headers/Auth.pm lib/LWP/Debug.pm blib/lib/LWP/Debug.pm lib/Net/HTTP.pm blib/lib/Net/HTTP.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/media.types blib/lib/LWP/media.types lib/HTTP/Daemon.pm blib/lib/HTTP/Daemon.pm lib/HTTP/Cookies.pm blib/lib/HTTP/Cookies.pm lib/LWP/ConnCache.pm blib/lib/LWP/ConnCache.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/File/Listing.pm blib/lib/File/Listing.pm lib/WWW/RobotRules/AnyDBM_File.pm blib/lib/WWW/RobotRules/AnyDBM_File.pm lib/LWP/MediaTypes.pm blib/lib/LWP/MediaTypes.pm lwpcook.pod blib/lib/lwpcook.pod}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Protocol/http10.pm blib/lib/LWP/Protocol/http10.pm lib/LWP/Protocol/file.pm blib/lib/LWP/Protocol/file.pm lib/HTTP/Date.pm blib/lib/HTTP/Date.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/LWP/Protocol/GHTTP.pm blib/lib/LWP/Protocol/GHTTP.pm lib/WWW/RobotRules.pm blib/lib/WWW/RobotRules.pm lib/LWP/DebugFile.pm blib/lib/LWP/DebugFile.pm lib/HTTP/Request.pm blib/lib/HTTP/Request.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/HTTP/Negotiate.pm blib/lib/HTTP/Negotiate.pm lib/LWP/Protocol/data.pm blib/lib/LWP/Protocol/data.pm lib/LWP/Protocol/nogo.pm blib/lib/LWP/Protocol/nogo.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/HTTP/Response.pm blib/lib/HTTP/Response.pm lib/LWP/Simple.pm blib/lib/LWP/Simple.pm lib/HTTP/Headers.pm blib/lib/HTTP/Headers.pm lib/LWP/Protocol/https.pm blib/lib/LWP/Protocol/https.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(PERLRUNINST) "-MExtUtils::Install" \
	-e "pm_to_blib({qw{lib/Net/HTTP/Methods.pm blib/lib/Net/HTTP/Methods.pm lib/Bundle/LWP.pm blib/lib/Bundle/LWP.pm}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(TOUCH) $@

# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
