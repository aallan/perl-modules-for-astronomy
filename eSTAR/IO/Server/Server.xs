#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "../src/estar_io.h"

MODULE = eSTAR::IO::Server  PACKAGE = eSTAR::IO::Server	  PREFIX = eSTAR_IO_	

int
Close_Server()
