#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "src/estar_io.h"

# define HANDLE (&globus_io_handle_t)

MODULE = eSTAR::IO   PACKAGE = eSTAR::IO   PREFIX eSTAR_IO_		

globus_io_handle_t *
HANDLE()
  CODE:
    RETVAL = HANDLE;
  OUTPUT:
    RETVAL 

void
Error()

int
Write_Message( handle, message )
    char * message
    globus_io_handle_t * handle

int
Read_Message( handle, message )
    AV * message;
  PREINIT:
    char ** array;    
