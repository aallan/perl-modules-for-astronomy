/**
 * perl-libxml-sax.h
 * $Id: perl-libxml-sax.h,v 1.1 2003/07/17 21:56:18 aa Exp $
 */

#ifndef __PERL_LIBXML_SAX_H__
#define __PERL_LIBXML_SAX_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <libxml/tree.h>

#ifdef __cplusplus
}
#endif

/* has to be called in BOOT sequence */
void
PmmSAXInitialize();

void
PmmSAXInitContext( xmlParserCtxtPtr ctxt, SV * parser );

void 
PmmSAXCloseContext( xmlParserCtxtPtr ctxt );

xmlSAXHandlerPtr
PSaxGetHandler();

#endif
