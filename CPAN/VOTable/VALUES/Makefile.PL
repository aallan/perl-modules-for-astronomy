use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::VALUES',
	      'VERSION_FROM' => 'VALUES.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'VALUES.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
