use ExtUtils::MakeMaker;

# Write the Makefile.
WriteMakefile(
	      'NAME' => 'VOTable::VOTABLE',
	      'VERSION_FROM' => 'VOTABLE.pm',
	      'PREREQ_PM' => {},
	      'ABSTRACT_FROM' => 'VOTABLE.pm',
	      'AUTHOR' => 'Eric Winter <Eric.L.Winter.1@gsfc.nasa.gov>',
	      );
