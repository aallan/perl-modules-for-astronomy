use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::DESCRIPTION',
	      'VERSION_FROM' => 'DESCRIPTION.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'DESCRIPTION.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
