/*
 * default.h --
 *
 *	This file defines the defaults for all options for all of
 *	the Tk widgets.
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: default.h,v 1.1 2003/09/28 14:54:57 aa Exp $
 */

#ifndef _DEFAULT
#define _DEFAULT

#if defined(__WIN32__) || defined(_WIN32)
#   include "tkWinDefault.h"
#else
#   if defined(MAC_TCL)
#	include "tkMacDefault.h"
#   else
#      ifdef __PM__
#         include "tkOS2Default.h"
#      else
#         include "tkUnixDefault.h"
#      endif
#   endif
#endif

#endif /* _DEFAULT */
