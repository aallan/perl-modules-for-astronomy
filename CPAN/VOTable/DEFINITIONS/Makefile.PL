use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::DEFINITIONS',
	      'VERSION_FROM' => 'DEFINITIONS.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'DEFINITIONS.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
