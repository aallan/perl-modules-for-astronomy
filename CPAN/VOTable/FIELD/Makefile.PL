use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::FIELD',
	      'VERSION_FROM' => 'FIELD.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'FIELD.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
