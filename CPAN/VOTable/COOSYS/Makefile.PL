use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::COOSYS',
	      'VERSION_FROM' => 'COOSYS.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'COOSYS.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
