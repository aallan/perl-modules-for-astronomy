/**
 * perl-libxml-mm.c
 * $Id: perl-libxml-mm.c,v 1.1 2003/07/17 21:56:18 aa Exp $
 *
 * Basic concept:
 * perl varies in the implementation of UTF8 handling. this header (together
 * with the c source) implements a few functions, that can be used from within
 * the core module inorder to avoid cascades of c pragmas
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <stdlib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libxml/parser.h>
#include <libxml/tree.h>

#ifdef XML_LIBXML_GDOME_SUPPORT

#include <libgdome/gdome.h>
#include <libgdome/gdome-libxml-util.h>

#endif

#include "perl-libxml-sax.h"

#ifdef __cplusplus
}
#endif

#ifdef XS_WARNINGS
#define xs_warn(string) warn(string) 
#else
#define xs_warn(string)
#endif

/**
 * this is a wrapper function that does the type evaluation for the 
 * node. this makes the code a little more readable in the .XS
 * 
 * the code is not really portable, but i think we'll avoid some 
 * memory leak problems that way.
 **/
const char*
PmmNodeTypeName( xmlNodePtr elem ){
    const char *name = "XML::LibXML::Node";

    if ( elem != NULL ) {
        char * ptrHlp;
        switch ( elem->type ) {
        case XML_ELEMENT_NODE:
            name = "XML::LibXML::Element";   
            break;
        case XML_TEXT_NODE:
            name = "XML::LibXML::Text";
            break;
        case XML_COMMENT_NODE:
            name = "XML::LibXML::Comment";
            break;
        case XML_CDATA_SECTION_NODE:
            name = "XML::LibXML::CDATASection";
            break;
        case XML_ATTRIBUTE_NODE:
            name = "XML::LibXML::Attr"; 
            break;
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
            name = "XML::LibXML::Document";
            break;
        case XML_DOCUMENT_FRAG_NODE:
            name = "XML::LibXML::DocumentFragment";
            break;
        case XML_NAMESPACE_DECL:
            name = "XML::LibXML::Namespace";
            break;
        case XML_DTD_NODE:
            name = "XML::LibXML::Dtd";
            break;
        case XML_PI_NODE:
            name = "XML::LibXML::PI";
            break;
        default:
            name = "XML::LibXML::Node";
            break;
        };
        return name;
    }
    return "";
}

/*
 * @node: Reference to the node the structure proxies
 * @owner: libxml defines only the document, but not the node owner
 *         (in case of document fragments, they are not the same!)
 * @count: this is the internal reference count!
 * @encoding: this value is missing in libxml2's doc structure
 *
 * Since XML::LibXML will not know, is a certain node is already
 * defined in the perl layer, it can't shurely tell when a node can be
 * safely be removed from the memory. This structure helps to keep
 * track how intense the nodes of a document are used and will not
 * delete the nodes unless they are not refered from somewhere else.
 */
struct _ProxyNode {
    xmlNodePtr node;
    xmlNodePtr owner;
    int count;
    int encoding; 
};

/* helper type for the proxy structure */
typedef struct _ProxyNode ProxyNode;

/* pointer to the proxy structure */
typedef ProxyNode* ProxyNodePtr;

/* this my go only into the header used by the xs */
#define SvPROXYNODE(x) ((ProxyNodePtr)SvIV(SvRV(x)))
#define SvNAMESPACE(x) ((xmlNsPtr)SvIV(SvRV(x)))

#define PmmREFCNT(node)      node->count
#define PmmREFCNT_inc(node)  node->count++
#define PmmNODE(thenode)     thenode->node
#define PmmOWNER(node)       node->owner
#define PmmOWNERPO(node)     ((node && PmmOWNER(node)) ? (ProxyNodePtr)PmmOWNER(node)->_private : node)

#define PmmENCODING(node)    node->encoding
#define PmmNodeEncoding(node) ((ProxyNodePtr)(node->_private))->encoding

/* creates a new proxy node from a given node. this function is aware
 * about the fact that a node may already has a proxy structure.
 */
ProxyNodePtr
PmmNewNode(xmlNodePtr node)
{
    ProxyNodePtr proxy = NULL;

    if ( node == NULL ) {
        warn( "no node found\n" );
        return NULL;
    }

    if ( node->_private == NULL ) {
        proxy = (ProxyNodePtr)malloc(sizeof(struct _ProxyNode)); 
        /* proxy = (ProxyNodePtr)Newz(0, proxy, 0, ProxyNode);  */
        if (proxy != NULL) {
            proxy->node  = node;
            proxy->owner   = NULL;
            proxy->count   = 0;
            node->_private = (void*) proxy;
        }
    }
    else {
        proxy = (ProxyNodePtr)node->_private;
    }

    return proxy;
}

ProxyNodePtr
PmmNewFragment(xmlDocPtr doc) 
{
    ProxyNodePtr retval = NULL;
    xmlNodePtr frag = NULL;

    xs_warn("new frag\n");
    frag   = xmlNewDocFragment( doc );
    retval = PmmNewNode(frag);

    if ( doc != NULL ) {
        xs_warn("inc document\n");
        /* under rare circumstances _private is not set correctly? */
        if ( doc->_private != NULL ) {
            PmmREFCNT_inc(((ProxyNodePtr)doc->_private));
        }
        retval->owner = (xmlNodePtr)doc;
    }

    return retval;
}

/* frees the node if nessecary. this method is aware, that libxml2
 * has several diffrent nodetypes.
 */
void
PmmFreeNode( xmlNodePtr node )
{  
    switch( node->type ) {
    case XML_DOCUMENT_NODE:
    case XML_HTML_DOCUMENT_NODE:
        xs_warn("PFN: XML_DOCUMENT_NODE\n");
        xmlFreeDoc( (xmlDocPtr) node );
        break;
    case XML_ATTRIBUTE_NODE:
        xs_warn("PFN: XML_ATTRIBUTE_NODE\n");
        if ( node->parent == NULL ) {
            xs_warn( "free node!\n");
            node->ns = NULL;
            xmlFreeProp( (xmlAttrPtr) node );
        }
        break;
    case XML_DTD_NODE:
        if ( node->doc != NULL ) {
            if ( node->doc->extSubset != (xmlDtdPtr)node 
                 && node->doc->intSubset != (xmlDtdPtr)node ) {
                xs_warn( "PFN: XML_DTD_NODE\n");
                node->doc = NULL;
                xmlFreeDtd( (xmlDtdPtr)node );
            }
        }
        break;
    case XML_DOCUMENT_FRAG_NODE:
        xs_warn("PFN: XML_DOCUMENT_FRAG_NODE\n");
    default:
        xs_warn( "PFN: normal node" );
        xmlFreeNode( node);
        break;
    }
}

/* decrements the proxy counter. if the counter becomes zero or less,
   this method will free the proxy node. If the node is part of a
   subtree, PmmREFCNT_def will fix the reference counts and delete
   the subtree if it is not required any more.
 */
int
PmmREFCNT_dec( ProxyNodePtr node ) 
{ 
    xmlNodePtr libnode = NULL;
    ProxyNodePtr owner = NULL;  
    int retval = 0;

    if ( node != NULL ) {
        retval = PmmREFCNT(node)--;
        if ( PmmREFCNT(node) <= 0 ) {
            xs_warn( "NODE DELETATION\n" );

            libnode = PmmNODE( node );
            if ( libnode != NULL ) {
                if ( libnode->_private != node ) {
                    xs_warn( "lost node\n" );
                    libnode = NULL;
                }
                else {
                    libnode->_private = NULL;
                }
            }

            PmmNODE( node ) = NULL;
            if ( PmmOWNER(node) && PmmOWNERPO(node) ) {
                xs_warn( "DOC NODE!\n" );
                owner = PmmOWNERPO(node);
                PmmOWNER( node ) = NULL;
                if( libnode != NULL && libnode->parent == NULL ) {
                    /* this is required if the node does not directly
                     * belong to the document tree
                     */
                    xs_warn( "REAL DELETE" );
                    PmmFreeNode( libnode );
                }
                xs_warn( "decrease owner" );
                PmmREFCNT_dec( owner );
            }
            else if ( libnode != NULL ) {
                xs_warn( "STANDALONE REAL DELETE" );
                
                PmmFreeNode( libnode );
            }
            /* Safefree( node ); */
            free( node );
        }
    }
    else {
        xs_warn("lost node" );
    }
    return retval;
}

/* @node: the node that should be wrapped into a SV
 * @owner: perl instance of the owner node (may be NULL)
 *
 * This function will create a real perl instance of a given node.
 * the function is called directly by the XS layer, to generate a perl
 * instance of the node. All node reference counts are updated within
 * this function. Therefore this function returns a node that can
 * directly be used as output.
 *
 * if @ower is NULL or undefined, the node is ment to be the root node
 * of the tree. this node will later be used as an owner of other
 * nodes.
 */
SV*
PmmNodeToSv( xmlNodePtr node, ProxyNodePtr owner ) 
{
    ProxyNodePtr dfProxy= NULL;
    SV * retval = &PL_sv_undef;
    const char * CLASS = "XML::LibXML::Node";

    if ( node != NULL ) {
        /* find out about the class */
        CLASS = PmmNodeTypeName( node );
        xs_warn(" return new perl node\n");
        xs_warn( CLASS );

        if ( node->_private != NULL ) { 
            dfProxy = PmmNewNode(node);
        }
        else {
            dfProxy = PmmNewNode(node);
            if ( dfProxy != NULL ) {
                if ( owner != NULL ) {
                    dfProxy->owner = PmmNODE( owner );
                    PmmREFCNT_inc( owner );
                }
                else {
                   xs_warn("node contains himself");
                }
            }
            else {
                xs_warn("proxy creation failed!\n");
            }
        }

        retval = NEWSV(0,0);
        sv_setref_pv( retval, CLASS, (void*)dfProxy );
        PmmREFCNT_inc(dfProxy); 

        switch ( node->type ) {
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
        case XML_DOCB_DOCUMENT_NODE:
            if ( ((xmlDocPtr)node)->encoding != NULL ) {
                dfProxy->encoding = (int)xmlParseCharEncoding( (const char*)((xmlDocPtr)node)->encoding );
            }
            break;
        default:
            break;
        }
    }
    else {
        xs_warn( "no node found!" );
    }

    return retval;
}

xmlNodePtr
PmmCloneNode( xmlNodePtr node, int recursive )
{
    xmlNodePtr retval = NULL;
    
    if ( node != NULL ) {
        switch ( node->type ) {
        case XML_ELEMENT_NODE:
		case XML_TEXT_NODE:
		case XML_CDATA_SECTION_NODE:
		case XML_ENTITY_REF_NODE:
		case XML_PI_NODE:
		case XML_COMMENT_NODE:
		case XML_DOCUMENT_FRAG_NODE:
		case XML_ENTITY_DECL: 
            retval = xmlCopyNode( node, recursive );
            break;
		case XML_ATTRIBUTE_NODE:
            retval = (xmlNodePtr) xmlCopyProp( NULL, (xmlAttrPtr) node );
            break;
        case XML_DOCUMENT_NODE:
		case XML_HTML_DOCUMENT_NODE:
            retval = (xmlNodePtr) xmlCopyDoc( (xmlDocPtr)node, recursive );
            break;
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DTD_NODE:
            retval = (xmlNodePtr) xmlCopyDtd( (xmlDtdPtr)node );
            break;
        case XML_NAMESPACE_DECL:
            retval = ( xmlNodePtr ) xmlCopyNamespace( (xmlNsPtr) node );
            break;
        default:
            break;
        }
    }

    return retval;
}

/* extracts the libxml2 node from a perl reference
 */

xmlNodePtr
PmmSvNodeExt( SV* perlnode, int copy ) 
{
    xmlNodePtr retval = NULL;
    ProxyNodePtr proxy = NULL;

    if ( perlnode != NULL && perlnode != &PL_sv_undef ) {
/*         if ( sv_derived_from(perlnode, "XML::LibXML::Node") */
/*              && SvPROXYNODE(perlnode) != NULL  ) { */
/*             retval = PmmNODE( SvPROXYNODE(perlnode) ) ; */
/*         } */
        xs_warn("   perlnode found\n" );
        if ( sv_derived_from(perlnode, "XML::LibXML::Node")  ) {
            proxy = SvPROXYNODE(perlnode);
            if ( proxy != NULL ) {
                xs_warn( "is a xmlNodePtr structure\n" );
                retval = PmmNODE( proxy ) ;
            }

            if ( retval != NULL
                 && ((ProxyNodePtr)retval->_private) != proxy ) {
                xs_warn( "no node in proxy node" );
                PmmNODE( proxy ) = NULL;
                retval = NULL;
            }
        }
#ifdef  XML_LIBXML_GDOME_SUPPORT
        else if ( sv_derived_from( perlnode, "XML::GDOME::Node" ) ) {
            GdomeNode* gnode = (GdomeNode*)SvIV((SV*)SvRV( perlnode ));
            if ( gnode == NULL ) {
                warn( "no XML::GDOME data found (datastructure empty)" );    
            }
            else {
                retval = gdome_xml_n_get_xmlNode( gnode );
                if ( retval == NULL ) {
                    xs_warn( "no XML::LibXML node found in GDOME object" );
                }
                else if ( copy == 1 ) {
                    retval = PmmCloneNode( retval, 1 );
                }
            }
        }
#endif
    }

    return retval;
}

/* extracts the libxml2 owner node from a perl reference
 */
xmlNodePtr
PmmSvOwner( SV* perlnode ) 
{
    xmlNodePtr retval = NULL;
    if ( perlnode != NULL
         && perlnode != &PL_sv_undef
         && SvPROXYNODE(perlnode) != NULL  ) {
        retval = PmmOWNER( SvPROXYNODE(perlnode) );
    }
    return retval;
}

/* reverse to PmmSvOwner(). sets the owner of the current node. this
 * will increase the proxy count of the owner.
 */
SV* 
PmmSetSvOwner( SV* perlnode, SV* extra )
{
    if ( perlnode != NULL && perlnode != &PL_sv_undef ) {        
        PmmOWNER( SvPROXYNODE(perlnode)) = PmmNODE( SvPROXYNODE(extra) );
        PmmREFCNT_inc( SvPROXYNODE(extra) );
    }
    return perlnode;
}

void
PmmFixOwnerList( xmlNodePtr list, ProxyNodePtr parent )
{
    if ( list != NULL ) {
        xmlNodePtr iterator = list;
        while ( iterator != NULL ) {
            switch ( iterator->type ) {
            case XML_ENTITY_DECL:
            case XML_ATTRIBUTE_DECL:
            case XML_NAMESPACE_DECL:
            case XML_ELEMENT_DECL:
                iterator = iterator->next;
                continue;
                break;
            default:
                break;
            }

            if ( iterator->_private != NULL ) {
                PmmFixOwner( (ProxyNodePtr)iterator->_private, parent );
            }
            else {
                if ( iterator->type != XML_ATTRIBUTE_NODE
                     &&  iterator->properties != NULL ){
                    PmmFixOwnerList( (xmlNodePtr)iterator->properties, parent );
                }
                PmmFixOwnerList(iterator->children, parent);
            }
            iterator = iterator->next;
        }
    }
}

/**
 * this functions fixes the reference counts for an entire subtree.
 * it is very important to fix an entire subtree after node operations
 * where the documents or the owner node may get changed. this method is
 * aware about nodes that already belong to a certain owner node. 
 *
 * the method uses the internal methods PmmFixNode and PmmChildNodes to
 * do the real updates.
 * 
 * in the worst case this traverses the subtree twice durig a node 
 * operation. this case is only given when the node has to be
 * adopted by the document. Since the ownerdocument and the effective 
 * owner may differ this double traversing makes sense.
 */ 
int
PmmFixOwner( ProxyNodePtr nodetofix, ProxyNodePtr parent ) 
{
    ProxyNodePtr oldParent = NULL;

    if ( nodetofix != NULL ) {
        switch ( PmmNODE(nodetofix)->type ) {
        case XML_ENTITY_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_NAMESPACE_DECL:
        case XML_ELEMENT_DECL:
        case XML_DOCUMENT_NODE:
            return(0);
        default:
            break;
        }

        if ( PmmOWNER(nodetofix) != NULL ) {
            oldParent = PmmOWNERPO(nodetofix);
        }
        
        /* The owner data is only fixed if the node is neither a
         * fragment nor a document. Also no update will happen if
         * the node is already his owner or the owner has not
         * changed during previous operations.
         */
        if( oldParent != parent ) {
            if ( parent && parent != nodetofix ){
                PmmOWNER(nodetofix) = PmmNODE(parent);
                    PmmREFCNT_inc( parent );
            }
            else {
                PmmOWNER(nodetofix) = NULL;
            }
            
            if ( oldParent != NULL && oldParent != nodetofix )
                PmmREFCNT_dec(oldParent);
            
            if ( PmmNODE(nodetofix)->type != XML_ATTRIBUTE_NODE
                 && PmmNODE(nodetofix)->properties != NULL ) {
                PmmFixOwnerList( (xmlNodePtr)PmmNODE(nodetofix)->properties,
                                 parent );
            }

            if ( parent == NULL || PmmNODE(nodetofix)->parent == NULL ) {
                /* fix to self */
                parent = nodetofix;
            }

            PmmFixOwnerList(PmmNODE(nodetofix)->children, parent);
        }
        else {
            xs_warn( "node doesn't need to get fixed" );
        }
        return(1);
    }
    return(0);
}

void
PmmFixOwnerNode( xmlNodePtr node, ProxyNodePtr parent )
{
    if ( node != NULL && parent != NULL ) {
        if ( node->_private != NULL ) {
            PmmFixOwner( node->_private, parent );
        }
        else {
            PmmFixOwnerList(node->children, parent );
        } 
    }
} 

ProxyNodePtr
PmmNewContext(xmlParserCtxtPtr node)
{
    ProxyNodePtr proxy = NULL;

    proxy = (ProxyNodePtr)xmlMalloc(sizeof(ProxyNode));
    if (proxy != NULL) {
        proxy->node  = (xmlNodePtr)node;
        proxy->owner   = NULL;
        proxy->count   = 1;
    }
    else {
        warn( "empty context" );
    }
    return proxy;
}
 
int
PmmContextREFCNT_dec( ProxyNodePtr node ) 
{ 
    xmlParserCtxtPtr libnode = NULL;
    int retval = 0;
    if ( node != NULL ) {
        retval = PmmREFCNT(node)--;
        if ( PmmREFCNT(node) <= 0 ) {
            xs_warn( "NODE DELETATION\n" );
            libnode = (xmlParserCtxtPtr)PmmNODE( node );
            if ( libnode != NULL ) {
                if (libnode->_private != NULL ) {
                    if ( libnode->_private != (void*)node ) {
                        PmmSAXCloseContext( libnode );
                    }
                    else {
                        xmlFree( libnode->_private );
                    }
                    libnode->_private = NULL;
                }
                PmmNODE( node )   = NULL;
                xmlFreeParserCtxt(libnode);
            }
        }
        xmlFree( node );
    }
    return retval;
}

SV*
PmmContextSv( xmlParserCtxtPtr ctxt )
{
    ProxyNodePtr dfProxy= NULL;
    SV * retval = &PL_sv_undef;
    const char * CLASS = "XML::LibXML::ParserContext";
    void * saxvector = NULL;

    if ( ctxt != NULL ) {
        dfProxy = PmmNewContext(ctxt);

        retval = NEWSV(0,0);
        sv_setref_pv( retval, CLASS, (void*)dfProxy );
        PmmREFCNT_inc(dfProxy); 
    }         
    else {
        xs_warn( "no node found!" );
    }

    return retval;
}

xmlParserCtxtPtr
PmmSvContext( SV * scalar ) 
{
    xmlParserCtxtPtr retval = NULL;

    if ( scalar != NULL
         && scalar != &PL_sv_undef
         && sv_isa( scalar, "XML::LibXML::ParserContext" )
         && SvPROXYNODE(scalar) != NULL  ) {
        retval = (xmlParserCtxtPtr)PmmNODE( SvPROXYNODE(scalar) );
    }
    else {
        if ( scalar == NULL
             && scalar == &PL_sv_undef ) {
            xs_warn( "no scalar!" );
        }
        else if ( ! sv_isa( scalar, "XML::LibXML::ParserContext" ) ) {
            xs_warn( "bad object" );
        }
        else if (SvPROXYNODE(scalar) == NULL) {
            xs_warn( "empty object" );
        }
        else {
            xs_warn( "nothing was wrong!");
        }
    }
    return retval;
}

xmlChar*
PmmFastEncodeString( int charset,
                     const xmlChar *string,
                     const xmlChar *encoding ) 
{
    xmlCharEncodingHandlerPtr coder = NULL;
    xmlChar *retval = NULL;
    xmlBufferPtr in = NULL, out = NULL;

    if ( charset == 1 ) {
        /* warn("use UTF8 for encoding ... %s ", string); */
        return xmlStrdup( string );
    }

    if ( charset > 1 ) {
        /* warn( "use document encoding %s (%d)", encoding, charset ); */
        coder= xmlGetCharEncodingHandler( charset );
    }
    else if ( charset == XML_CHAR_ENCODING_ERROR ){
        /* warn("no standard encoding %s\n", encoding); */
        coder =xmlFindCharEncodingHandler( (const char *)encoding );
    }
    else {
        xs_warn("no encoding found \n");
    }

    if ( coder != NULL ) {
        xs_warn("coding machine found \n");
        in    = xmlBufferCreate();
        out   = xmlBufferCreate();
        xmlBufferCCat( in, (const char *) string );
        if ( xmlCharEncInFunc( coder, out, in ) >= 0 ) {
            retval = xmlStrdup( out->content );
            /* warn( "encoded string is %s" , retval); */
        }
        else {
            xs_warn( "b0rked encoiding!\n");
        }
        
        xmlBufferFree( in );
        xmlBufferFree( out );
        xmlCharEncCloseFunc( coder );
    }
    return retval;
}

xmlChar*
PmmFastDecodeString( int charset,
                     const xmlChar *string,
                     const xmlChar *encoding) 
{
    xmlCharEncodingHandlerPtr coder = NULL;
    xmlChar *retval = NULL;
    xmlBufferPtr in = NULL, out = NULL;

    if ( charset == 1 ) {

        return xmlStrdup( string );
    }

    if ( charset > 1 ) {
        coder= xmlGetCharEncodingHandler( charset );
    }
    else if ( charset == XML_CHAR_ENCODING_ERROR ){
        coder = xmlFindCharEncodingHandler( (const char *) encoding );
    }
    else {
        xs_warn("no encoding found\n");
    }

    if ( coder != NULL ) {
        /* warn( "do encoding %s", string ); */
        in  = xmlBufferCreate();
        out = xmlBufferCreate();
        
        xmlBufferCat( in, string );        
        if ( xmlCharEncOutFunc( coder, out, in ) >= 0 ) {
            retval = xmlCharStrndup(xmlBufferContent(out), xmlBufferLength(out));
        }
        else {
            xs_warn("decoding error \n");
        }
        
        xmlBufferFree( in );
        xmlBufferFree( out );
        xmlCharEncCloseFunc( coder );
    }
    return retval;
}

/** 
 * encodeString returns an UTF-8 encoded String
 * while the encodig has the name of the encoding of string
 **/ 
xmlChar*
PmmEncodeString( const char *encoding, const xmlChar *string ){
    xmlCharEncoding enc;
    xmlChar *ret = NULL;
    xmlCharEncodingHandlerPtr coder = NULL;
    
    if ( string != NULL ) {
        if( encoding != NULL ) {
            xs_warn( encoding );
            enc = xmlParseCharEncoding( encoding );
            ret = PmmFastEncodeString( enc, string, (const xmlChar *)encoding );
        }
        else {
            /* if utf-8 is requested we do nothing */
            ret = xmlStrdup( string );
        }
    }
    return ret;
}

/**
 * decodeString returns an $encoding encoded string.
 * while string is an UTF-8 encoded string and 
 * encoding is the coding name
 **/
char*
PmmDecodeString( const char *encoding, const xmlChar *string){
    char *ret=NULL;
    xmlCharEncoding enc;
    xmlCharEncodingHandlerPtr coder = NULL;

    if ( string != NULL ) {
        xs_warn( "PmmDecodeString called" );
        if( encoding != NULL ) {
            enc = xmlParseCharEncoding( encoding );
            ret = (char*)PmmFastDecodeString( enc, string, (const xmlChar*)encoding );
            xs_warn( "PmmDecodeString done" );
        }
        else {
            ret = (char*)xmlStrdup(string);
        }
    }
    return ret;
}


SV*
C2Sv( const xmlChar *string, const xmlChar *encoding )
{
    SV *retval = &PL_sv_undef;
    xmlCharEncoding enc;
    if ( string != NULL ) {
        if ( encoding != NULL ) {
            enc = xmlParseCharEncoding( (const char*)encoding );
        }
        else {
            enc = 0;
        }
        if ( enc == 0 ) {
            /* this happens if the encoding is "" or NULL */
            enc = XML_CHAR_ENCODING_UTF8;
        }

        if ( enc == XML_CHAR_ENCODING_UTF8 ) {
            /* create an UTF8 string. */       
            STRLEN len = 0;
            xs_warn("set UTF8 string");
            len = xmlStrlen( string );
            /* create the SV */
            /* string[len] = 0; */

            retval = NEWSV(0, len+1); 
            sv_setpvn(retval, (const char*) string, len );
#ifdef HAVE_UTF8
            xs_warn("set UTF8-SV-flag");
            SvUTF8_on(retval);
#endif            
        }
        else {
            /* just create an ordinary string. */
            xs_warn("set ordinary string");
            retval = newSVpvn( (const char *)string, xmlStrlen( string ) );
        }
    }

    return retval;
}

xmlChar *
Sv2C( SV* scalar, const xmlChar *encoding )
{
    xmlChar *retval = NULL;

    xs_warn("sv2c start!");
    if ( scalar != NULL && scalar != &PL_sv_undef ) {
        STRLEN len = 0;
        char * t_pv =SvPV(scalar, len);
        xmlChar* ts = NULL;
        xmlChar* string = xmlStrdup((xmlChar*)t_pv);
        if ( xmlStrlen(string) > 0 ) {
            xs_warn( "no undefs" );
#ifdef HAVE_UTF8
            xs_warn( "use UTF8" );
            if( !DO_UTF8(scalar) && encoding != NULL ) {
#else
            if ( encoding != NULL ) {        
#endif
                xs_warn( "domEncodeString!" );
                ts= PmmEncodeString( (const char *)encoding, string );
                xs_warn( "done!" );
                if ( string != NULL ) {
                    xmlFree(string);
                }
                string=ts;
            }
        }
             
        retval = xmlStrdup(string);
        if (string != NULL ) {
            xmlFree(string);
        }
    }
    xs_warn("sv2c end!");
    return retval;
}

SV*
nodeC2Sv( const xmlChar * string,  xmlNodePtr refnode )
{
    /* this is a little helper function to avoid to much redundand
       code in LibXML.xs */
    SV* retval = &PL_sv_undef;
    STRLEN len = 0;

    if ( refnode != NULL ) {
        xmlDocPtr real_doc = refnode->doc;
        if ( real_doc && real_doc->encoding != NULL ) {

            xmlChar * decoded = PmmFastDecodeString( PmmNodeEncoding(real_doc) ,
                                                     (const xmlChar *)string,
                                                     (const xmlChar*)real_doc->encoding);
            len = xmlStrlen( decoded );

            if ( real_doc->charset == XML_CHAR_ENCODING_UTF8 ) {
                /* create an UTF8 string. */       
                xs_warn("set UTF8 string");
                /* create the SV */
                /* warn( "string is %s\n", string ); */

                retval = newSVpvn( (const char *)decoded, len );
#ifdef HAVE_UTF8
                xs_warn("set UTF8-SV-flag");
                SvUTF8_on(retval);
#endif            
            }
            else {
                /* just create an ordinary string. */
                xs_warn("set ordinary string");
                retval = newSVpvn( (const char *)decoded, len );
            }

            /* retval = C2Sv( decoded, real_doc->encoding ); */
            xmlFree( decoded );
        }
        else {
            retval = newSVpvn( (const char *)string, xmlStrlen(string) );
        }
    }
    else {
        retval = newSVpvn( (const char *)string, xmlStrlen(string) );
    }

    return retval;
}

xmlChar *
nodeSv2C( SV * scalar, xmlNodePtr refnode )
{
    /* this function requires conditionized compiling, because we
       request a function, that does not exists in earlier versions of
       perl. in this cases the library assumes, all strings are in
       UTF8. if a programmer likes to have the intelligent code, he
       needs to upgrade perl */
#ifdef HAVE_UTF8        
    if ( refnode != NULL ) {
        xmlDocPtr real_dom = refnode->doc;
        xs_warn("have node!");
        if (real_dom != NULL && real_dom->encoding != NULL ) {
            xs_warn("encode string!");
            /*  speed things a bit up.... */
            if ( scalar != NULL && scalar != &PL_sv_undef ) {
                STRLEN len = 0;
                char * t_pv =SvPV(scalar, len);
                xmlChar* ts = NULL;
                xmlChar* string = xmlStrdup((xmlChar*)t_pv);
                if ( xmlStrlen(string) > 0 ) {
                    xs_warn( "no undefs" );
#ifdef HAVE_UTF8
                    xs_warn( "use UTF8" );
                    if( !DO_UTF8(scalar) && real_dom->encoding != NULL ) {
                        xs_warn( "string is not UTF8\n" );
#else
                    if ( real_dom->encoding != NULL ) {        
#endif
                        xs_warn( "domEncodeString!" );
                        ts= PmmFastEncodeString( PmmNodeEncoding(real_dom),
                                                 string,
                                                 (const xmlChar*)real_dom->encoding );
                        xs_warn( "done!" );
                        if ( string != NULL ) {
                            xmlFree(string);
                        }
                        string=ts;
                    }
                    else {
                        xs_warn( "no encoding set, use UTF8!\n" );
                    }
                }
                if ( string == NULL ) xs_warn( "string is NULL\n" );
                return string;
            }
            else {
                xs_warn( "return NULL" );
                return NULL;
            }
        }
        else {
            xs_warn( "document has no encoding defined! use simple SV extraction\n" );
        }
    }
    xs_warn("no encoding !!");
#endif

    return  Sv2C( scalar, NULL ); 
}

SV * 
PmmNodeToGdomeSv( xmlNodePtr node ) 
{
    SV * retval = &PL_sv_undef;

#ifdef XML_LIBXML_GDOME_SUPPORT
    GdomeNode * gnode = NULL;
    GdomeException exc;
    const char * CLASS = "";

    if ( node != NULL ) {
        gnode = gdome_xml_n_mkref( node );
        if ( gnode != NULL ) {
            switch (gdome_n_nodeType(gnode, &exc)) {
            case GDOME_ELEMENT_NODE:
                CLASS = "XML::GDOME::Element";
                break;
            case GDOME_ATTRIBUTE_NODE:
                CLASS = "XML::GDOME::Attr";
                break;
            case GDOME_TEXT_NODE:
                CLASS = "XML::GDOME::Text"; 
                break;
            case GDOME_CDATA_SECTION_NODE:
                CLASS = "XML::GDOME::CDATASection"; 
                break;
            case GDOME_ENTITY_REFERENCE_NODE:
                CLASS = "XML::GDOME::EntityReference"; 
                break;
            case GDOME_ENTITY_NODE:
                CLASS = "XML::GDOME::Entity"; 
                break;
            case GDOME_PROCESSING_INSTRUCTION_NODE:
                CLASS = "XML::GDOME::ProcessingInstruction"; 
                break;
            case GDOME_COMMENT_NODE:
                CLASS = "XML::GDOME::Comment"; 
                break;
            case GDOME_DOCUMENT_TYPE_NODE:
                CLASS = "XML::GDOME::DocumentType"; 
                break;
            case GDOME_DOCUMENT_FRAGMENT_NODE:
                CLASS = "XML::GDOME::DocumentFragment"; 
                break;
            case GDOME_NOTATION_NODE:
                CLASS = "XML::GDOME::Notation"; 
                break;
            case GDOME_DOCUMENT_NODE:
                CLASS = "XML::GDOME::Document"; 
                break;
            default:
                break;
            }

            retval = NEWSV(0,0);
            sv_setref_pv( retval, CLASS, gnode);
        }
    }
#endif

    return retval;
}
