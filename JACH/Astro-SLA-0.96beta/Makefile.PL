use ExtUtils::MakeMaker;
use strict;

# A makefile can be generated for either the C or Fortran version of
# SLALIB. It does not yet determine the C/Fortran-ness of your library
# automatically.

# Change this flag to control the behaviour of the build.
# This controls whether we are using the Fortran version (1),
# the C version (0) or the Starlink Fortran version (-1)
my $use_fortran = -1;

# Default location for the library. This is used if we fail to find
# starlink fortran (in which case it is assumed to be a C library)
# or use_fortran is set to 0 or 1
# If you have an explicit non-standard path prepend -L/wherever
my $sla_lib = ' -L/usr/local/lib -lsla ';

# Same for include files [only relevant for C version] [use -I]
my $sla_inc = '-I/usr/local/include';

# Check valid range for the fortran switch
if ($use_fortran != 0 && $use_fortran != -1 && $use_fortran != 1) {
  print "use_fortran variable set to strange value. Assuming -1 [Starlink]\n";
}

# Starlink
if ($use_fortran == -1) {
  use vars qw/ %StarConfig /;

  # See if we can find a starlink system
  # $STARLINK env overrides everything
  if (exists $ENV{STARLINK} && defined $ENV{STARLINK}) {
    print "Using STARLINK environment variable: $ENV{STARLINK}\n";
    %StarConfig = (
		   Star_Inc => $ENV{STARLINK}."/include",
		   Star_Lib => $ENV{STARLINK}."/lib",
		   Star_Bin => $ENV{STARLINK}."/bin",
                  );
  } else {
    # Must look for it
    eval "use Starlink::Config";
    if ($@) {
      # do not have a Starlink configuration so guess /star
      %StarConfig = (
  		     Star_Inc => '/star/include',
		     Star_Lib => '/star/lib',
		     Star_Bin => '/star/bin',
		    );
    } else {
      print "Found Starlink configuration. Using $StarConfig{Star}\n";
    }
  }

  # This assumes unix - Starlink only works on unix
  my $lib = $StarConfig{Star_Lib} . "/libsla.a";

  if (-e $lib) {
    print "Located Starlink SLALIB library in $StarConfig{Star_Lib}\n";
    $sla_lib = " -L$StarConfig{Star_Lib} -lsla ";

    # See if we can find the version
    eval { require Starlink::Versions; };
    if (!$@) {
      print "It seems to be SLA version " . 
	Starlink::Versions::starversion_string('sla') ."\n";
    }

  } else {
    # Assume the C fallback
    $use_fortran = 0;
  }


}



# The #defines, libraries and any additional prerequisites
my ($defines, $libs, %prereqs);
if ($use_fortran) {
  print "Attempting to build against a Fortran SLALIB: $sla_lib\n";

  # Must switch modes
  $defines = " -DUSE_FORTRAN";

  # Must include fortran libraries but we do not want to force
  # ExtUtils::F77 on an unsuspecting C user
  $prereqs{'ExtUtils::F77'} = 0;

  # use eval here since we are listing ExtUtils as a prerequisite
  # anyway and so if this does not work we'll still get a message
  # later
  my $flibs = '';
  eval { require ExtUtils::F77; ExtUtils::F77->import };
  if ($@) {
    print "Error determining Fortran library requirements\n";
  } else {
    $flibs = ExtUtils::F77->runtime;
    $defines .= " -DHAS_UNDERSCORE"
      if ExtUtils::F77->trail_;
  }

  $libs = "$sla_lib $flibs";

} else {
  print "Attempting to build against a C SLALIB library: $sla_lib\n";

  # no special defines for the C version
  $defines = '';

  # Just need the math library
  $libs = "$sla_lib -lm";
}

WriteMakefile(
	      'NAME'      => 'Astro::SLA',
	      'VERSION_FROM'   => 'SLA.pm',
              'EXE_FILES' => [ 'stime' ],
	      'LIBS'      => [ $libs ],
	      'DEFINE'    => $defines,
              'PREREQ_PM' => {
			      'Test' => 0,
			      %prereqs,
			     },
	      'INC'       => $sla_inc,
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'SLA.pm',
		AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
	     );

