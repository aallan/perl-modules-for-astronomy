use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable',
	      'VERSION_FROM' => 'VOTable.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'VOTable.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
