#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"
#include "estar_io.h"
#include "client.h"

MODULE = eSTAR::IO   PACKAGE = eSTAR::IO  PREFIX = eSTAR_IO_
    
void
eSTAR_IO_report_error()
  CODE:
    eSTAR_IO_Error();

int
eSTAR_IO_write_message( handle, message )
    globus_io_handle_t * handle
    char * message
  PREINIT: 
    int status;
  CODE:  
    printf("write_messageXS globus_io_handle %p\n", handle);
    printf("write_messageXS handle->fd = %i\n", handle->fd);
    RETVAL = eSTAR_IO_Write_Message( handle, message );
    printf("write_messageXS globus_io_handle %p\n", handle);
    printf("write_messageXS handle->fd = %i\n", handle->fd);
  OUTPUT:
    RETVAL         


AV *
eSTAR_IO_read_message( handle )
     globus_io_handle_t * handle
   PREINIT:
     int status;
     char ** message;
     char ** index;
     AV * array;
   CODE:
     printf("read_messageXS globus_io_handle %p\n", handle);
     printf("read_messageXS handle->fd = %i\n", handle->fd);
     printf("read_messageXS char** %p\n", message);
     status = eSTAR_IO_Read_Message( handle, message );
     printf("read_messageXS globus_io_handle %p\n", handle);
     printf("read_messageXS handle->fd = %i\n", handle->fd);
     printf("read_messageXS char** %p\n", message);
     printf("read_messageXS return status %i (should be 1)\n", status);
     if (status == GLOBUS_FALSE ) 
       XSRETURN_UNDEF;
              
     array = newAV();
     index = message;
     while (*index) {
       av_push( array, newSVpv( *index, 0));
       index++;
     }
     RETVAL = array;
   OUTPUT:
     RETVAL
