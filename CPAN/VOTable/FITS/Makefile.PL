use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::FITS',
	      'VERSION_FROM' => 'FITS.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'FITS.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
