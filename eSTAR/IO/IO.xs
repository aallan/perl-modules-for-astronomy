#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "src/estar_io.h"

#define HANDLE (&globus_io_handle_t)

MODULE = eSTAR::IO   PACKAGE = eSTAR::IO   PREFIX eSTAR_IO_		

globus_io_handle_t *
HANDLE()
  CODE:
    RETVAL = HANDLE;
  OUTPUT:
    RETVAL 

void
Error()

MODULE = eSTAR::IO::Client   PACKAGE = globus_io_handle_tPtr PREFIX = eSTAR_IO_

int
Write_Message( handle, message )
    char * message
    globus_io_handle_t * handle

message_array
Read_Message( handle )
    globus_io_handle_t * handle
  PREINIT:
    int status;
    char ** message;
  CODE
    status = eSTAR_IO_Read_Message( handle, message );
    
  OUTPUT:
  
  CLEANUP:
    if (status != GLOBUS_FALSE ) 
      XSRETURN_UNDEF;       
