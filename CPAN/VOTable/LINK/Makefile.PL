use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::LINK',
	      'VERSION_FROM' => 'LINK.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'LINK.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
