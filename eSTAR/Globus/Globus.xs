#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "globus_common.h"
#include "globus_io.h"

#define IO GLOBUS_IO_MODULE
#define COMMON GLOBUS_COMMON_MODULE

MODULE = eSTAR::Globus PACKAGE = eSTAR::Globus PREFIX = globus_module_

globus_module_descriptor_t *
IO()
  CODE:
    RETVAL = GLOBUS_IO_MODULE;
  OUTPUT:
    RETVAL 
     
globus_module_descriptor_t *
COMMON()
  CODE:
    RETVAL = GLOBUS_COMMON_MODULE;
  OUTPUT:
    RETVAL

int
globus_module_deactivate_all( )

MODULE = eSTAR::Globus   PACKAGE = globus_module_descriptor_tPtr PREFIX = globus_module_
	
int
globus_module_activate( module )
   globus_module_descriptor_t * module

int
globus_module_deactivate( module )
   globus_module_descriptor_t * module

void
globus_module_DESTROY( module )
   globus_module_descriptor_t * module 
 CODE:
   globus_module_deactivate( module );

