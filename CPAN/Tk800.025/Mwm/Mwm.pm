package Tk::Mwm;

use vars qw($VERSION);
$VERSION = '3.013'; # $Id: Mwm.pm,v 1.1 2003/09/28 14:54:55 aa Exp $

use Tk qw($XS_VERSION);
require DynaLoader;

use base  qw(DynaLoader);

bootstrap Tk::Mwm;

package Tk;
use Tk::Submethods ( 'mwm' => [qw(decorations ismwmrunning protocol transientfor)] );
package Tk::Mwm;

1;

