use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::TR',
	      'VERSION_FROM' => 'TR.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'TR.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
