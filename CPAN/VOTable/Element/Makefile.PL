use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::Element',
	      'VERSION_FROM' => 'Element.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'Element.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
