#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "estar_io.h"
#include "client.h"

static globus_io_handle_t handle;
    
MODULE = eSTAR::IO::Client   PACKAGE = eSTAR::IO::Client

globus_io_handle_t *
open_client( hostname, port )
    char * hostname
    int port
  PREINIT:
    int status;
  CODE:
    printf("open_clientXS globus_io_handle %p\n", &handle);
    printf("open_clientXS handle->fd = %i\n", handle.fd);
    status = open_client( hostname, port, &handle );
    RETVAL = &handle;  
    printf("open_clientXS globus_io_handle %p\n", &handle);
    printf("open_clientXS handle->fd = %i\n", handle.fd);
  OUTPUT:
    RETVAL 
  CLEANUP:
    if (status == GLOBUS_FALSE ) 
      XSRETURN_UNDEF;           

int
close_client( handle )
    globus_io_handle_t * handle
    

