use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::TD',
	      'VERSION_FROM' => 'TD.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'TD.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
