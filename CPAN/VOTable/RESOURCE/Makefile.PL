use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::RESOURCE',
	      'VERSION_FROM' => 'RESOURCE.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'RESOURCE.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
