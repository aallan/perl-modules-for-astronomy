#Override these values if need be

# Location of pgplot include files
my $PGPLOT_INC_LOCATION = ""; # e.g. -I/usr/local/pgplot/include

# Location of pgplot directories. Defaults to $PGPLOT_DIR
my $PGPLOT_LIB_LOCATION = ""; # e.g. -L/usr/local/pgplot/lib

# Location of X11 libraries
my $X11_LIB_LOCATION = "-L/usr/openwin/lib -L/usr/X11R6/lib";

#######################################################
# There should be no need to edit the rest of this file
#######################################################

use Tk::MMutil;

use ExtUtils::F77;

if ($PGPLOT_LIB_LOCATION eq "" && defined $ENV{PGPLOT_DIR}) {
  $PGPLOT_LIB_LOCATION =  "-L$ENV{PGPLOT_DIR}";
}
if ($PGPLOT_INC_LOCATION eq "" && defined $ENV{PGPLOT_DIR}) {
  $PGPLOT_INC_LOCATION =  "-I$ENV{PGPLOT_DIR}";
}

Tk::MMutil::TkExtMakefile(
    NAME         => 'Tk::Pgplot',
    INC          => "$PGPLOT_INC_LOCATION",
    LIBS         => "$PGPLOT_LIB_LOCATION $X11_LIB_LOCATION ".
			  "-lptkpgplot -lcpgplot -lpgplot -lX11 ".
			  ExtUtils::F77->runtime,
    VERSION_FROM => 'Pgplot.pm',
    MYEXTLIB     => '',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);


