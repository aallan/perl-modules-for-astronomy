#============================================================= -*-perl-*-
#
# t/image.t
#
# Tests the Image plugin.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 2002 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: image.t,v 1.1 2004/03/03 02:43:05 aa Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Cwd;
use File::Spec;
$^W = 1;

eval "use Image::Info";
if ($@) {
    eval "use Image::Size";
    skip_all('Neither Image::Info nor Image::Size installed') if $@;
}

my $dir  = -d 't' ? 'images' : File::Spec->catfile(File::Spec->updir(), 'images');
my $vars = {
    dir  => $dir,
    file => {
        logo  => File::Spec->catfile($dir, 'ttdotorg.gif'),
        power => File::Spec->catfile($dir, 'tt2power.gif'),
    },
};


test_expect(\*DATA, undef, $vars);

__DATA__
-- test --
[% USE Image(file.logo) -%]
file: [% Image.file %]
size: [% Image.size.join(', ') %]
width: [% Image.width %]
height: [% Image.height %]
-- expect --
-- process --
file: [% file.logo %]
size: 110, 60
width: 110
height: 60

-- test --
[% USE image( name = file.power) -%]
name: [% image.name %]
file: [% image.file %]
width: [% image.width %]
height: [% image.height %]
size: [% image.size.join(', ') %]
-- expect --
-- process --
name: [% file.power %]
file: [% file.power %]
width: 78
height: 47
size: 78, 47

-- test --
[% USE image file.logo -%]
attr: [% image.attr %]
-- expect --
attr: width="110" height="60"

-- test --
[% USE image file.logo -%]
tag: [% image.tag %]
tag: [% image.tag(class="myimage") %]
-- expect --
-- process --
tag: <img src="[% file.logo %]" width="110" height="60" />
tag: <img src="[% file.logo %]" width="110" height="60" class="myimage" />



