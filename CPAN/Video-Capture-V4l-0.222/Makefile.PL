use ExtUtils::MakeMaker;

sub MY::postamble {
<<'EOF';

tr-101-231.txt: tr-101-231.pdf
	gs -q -dNODISPLAY -dNOBIND -dSIMPLE -dWRITESYSTEMDICT ps2txt.ps $< quit.ps > $@

EOF
}

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text V4l/V4l.pm | tee README > $(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Video::Frequencies',
    DISTNAME	=> 'Video-Capture-V4l',
    'VERSION_FROM' => 'V4l/V4l.pm',
    linkext	=> {LINKTYPE => ''},
    DIR		=> ['V4l','VBI','RTjpeg'],
);
