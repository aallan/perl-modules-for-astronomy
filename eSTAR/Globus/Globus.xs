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
    printf("# Creation: %s\n", GLOBUS_IO_MODULE->module_name);
    printf("# Returning: %p\n", RETVAL );
  OUTPUT:
    RETVAL 
     
globus_module_descriptor_t *
COMMON()
  CODE:
    RETVAL = GLOBUS_COMMON_MODULE;
    printf("# Creation: %s\n", GLOBUS_COMMON_MODULE->module_name);
    printf("# Returning: %p\n", RETVAL );
  OUTPUT:
    RETVAL

int
globus_module_deactivate_all( )
  CODE:
    printf("# Deactivate: all\n");
    RETVAL = globus_module_deactivate_all();
    printf("# Returning: %i\n", RETVAL );
  OUTPUT:
    RETVAL 
     
MODULE = eSTAR::Globus PACKAGE = globus_module_descriptor_tPtr PREFIX = globus_module_
	
int
globus_module_activate( module )
    globus_module_descriptor_t * module
  CODE:
    printf("# Activate: %s\n", module->module_name);
    printf("# Pointer: %p\n", module);
    RETVAL = globus_module_activate( module );
    printf("# Returning: %i\n", RETVAL );
  OUTPUT:
    RETVAL  
    
int
globus_module_deactivate( module )
    globus_module_descriptor_t * module
  CODE:
    printf("# Deactivate: %s\n", module->module_name);
    printf("# Pointer: %p\n", module);
    RETVAL = globus_module_deactivate( module );
    printf("# Returning: %i\n", RETVAL );
  OUTPUT:
    RETVAL    

