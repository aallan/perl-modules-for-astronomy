use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::Document',
	      'VERSION_FROM' => 'Document.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'Document.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
