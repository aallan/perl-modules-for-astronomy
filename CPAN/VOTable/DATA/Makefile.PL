use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::DATA',
	      'VERSION_FROM' => 'DATA.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'DATA.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
