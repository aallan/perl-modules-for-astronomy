use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::BINARY',
	      'VERSION_FROM' => 'BINARY.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'BINARY.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
