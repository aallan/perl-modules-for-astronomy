use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::PARAM',
	      'VERSION_FROM' => 'PARAM.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'PARAM.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
