package GTop;

use DynaLoader ();

use strict;

{
    no strict;
    $VERSION = '0.10';

    *dl_load_flags = DynaLoader->can('dl_load_flags');
    do {
	__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap;
    }->(__PACKAGE__, $VERSION);
}

1;
__END__
