use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::TABLE',
	      'VERSION_FROM' => 'TABLE.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'TABLE.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
