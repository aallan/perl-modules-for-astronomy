use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::MAX',
	      'VERSION_FROM' => 'MAX.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'MAX.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@xgsfc.nasa.gov>',
	      );
