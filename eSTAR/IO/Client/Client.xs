#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "../src/estar_io.h"

MODULE = eSTAR::IO::Client   PACKAGE = eSTAR::IO::Client   PREFIX = eSTAR_IO_		
int
Open_Client( hostname, port, handle )
    char * hostname
    int port
    globus_io_handle_t * handle

MODULE = eSTAR::IO::Client   PACKAGE = globus_io_handle_tPtr PREFIX = eSTAR_IO_

int
Close_Client( handle )
    globus_io_handle_t * handle
