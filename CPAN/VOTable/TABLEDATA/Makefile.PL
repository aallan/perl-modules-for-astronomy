use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::TABLEDATA',
	      'VERSION_FROM' => 'TABLEDATA.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'TABLEDATA.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
