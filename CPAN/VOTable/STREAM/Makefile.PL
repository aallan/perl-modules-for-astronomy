use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::STREAM',
	      'VERSION_FROM' => 'STREAM.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'STREAM.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
