use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::MIN',
	      'VERSION_FROM' => 'MIN.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'MIN.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
