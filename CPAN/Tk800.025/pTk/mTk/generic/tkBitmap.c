/*
 * tkBitmap.c --
 *
 *	This file maintains a database of read-only bitmaps for the Tk
 *	toolkit.  This allows bitmaps to be shared between widgets and
 *	also avoids interactions with the X server.
 *
 * Copyright (c) 1990-1994 The Regents of the University of California.
 * Copyright (c) 1994-1996 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkBitmap.c,v 1.1 2003/09/28 14:54:57 aa Exp $
 */

#include "tkPort.h"
#include "tkInt.h"

/*
 * The includes below are for pre-defined bitmaps.
 *
 * Platform-specific issue: Windows complains when the bitmaps are
 * included, because an array of characters is being initialized with
 * integers as elements.  For lint purposes, the following pragmas
 * temporarily turn off that warning message.
 */

#if (defined(__WIN32__) || defined(_WIN32)) && !defined(__GNUC__)
#pragma warning (disable : 4305)
#endif

#include "error.bmp"
#include "gray12.bmp"
#include "transpnt.bmp"
#include "gray25.bmp"
#include "gray50.bmp"
#include "gray75.bmp"
#include "hourglass.bmp"
#include "info.bmp"
#include "questhead.bmp"
#include "question.bmp"
#include "warning.bmp"
#include "tk.bmp"

#if (defined(__WIN32__) || defined(_WIN32)) && !defined(__GNUC__)
#pragma warning (default : 4305)
#endif

/*
 * One of the following data structures exists for each bitmap that is
 * currently in use.  Each structure is indexed with both "idTable" and
 * "nameTable".
 */

typedef struct {
    Pixmap bitmap;		/* X identifier for bitmap.  None means this
				 * bitmap was created by Tk_DefineBitmap
				 * and it isn't currently in use. */
    int width, height;		/* Dimensions of bitmap. */
    Display *display;		/* Display for which bitmap is valid. */
    int refCount;		/* Number of active uses of bitmap. */
    Tcl_HashEntry *hashPtr;	/* Entry in nameTable for this structure
				 * (needed when deleting). */
} TkBitmap;

/*
 * Hash table to map from a textual description of a bitmap to the
 * TkBitmap record for the bitmap, and key structure used in that
 * hash table:
 */

static Tcl_HashTable nameTable;
typedef struct {
    Tk_Uid name;		/* Textual name for desired bitmap. */
    Screen *screen;		/* Screen on which bitmap will be used. */
} NameKey;

/*
 * Hash table that maps from <display + bitmap id> to the TkBitmap structure
 * for the bitmap.  This table is used by Tk_FreeBitmap.
 */

static Tcl_HashTable idTable;
typedef struct {
    Display *display;		/* Display for which bitmap was allocated. */
    Pixmap pixmap;		/* X identifier for pixmap. */
} IdKey;

/*
 * Hash table create by Tk_DefineBitmap to map from a name to a
 * collection of in-core data about a bitmap.  The table is
 * indexed by the address of the data for the bitmap, and the entries
 * contain pointers to TkPredefBitmap structures.
 */

Tcl_HashTable tkPredefBitmapTable;

/*
 * Hash table used by Tk_GetBitmapFromData to map from a collection
 * of in-core data about a bitmap to a Tk_Uid giving an automatically-
 * generated name for the bitmap:
 */

static Tcl_HashTable dataTable;
typedef struct {
    char *source;		/* Bitmap bits. */
    int width, height;		/* Dimensions of bitmap. */
} DataKey;

static int initialized = 0;	/* 0 means static structures haven't been
				 * initialized yet. */

/*
 * Forward declarations for procedures defined in this file:
 */

static void		BitmapInit _ANSI_ARGS_((void));

/*
 *----------------------------------------------------------------------
 *
 * Tk_GetBitmap --
 *
 *	Given a string describing a bitmap, locate (or create if necessary)
 *	a bitmap that fits the description.
 *
 * Results:
 *	The return value is the X identifer for the desired bitmap
 *	(i.e. a Pixmap with a single plane), unless string couldn't be
 *	parsed correctly.  In this case, None is returned and an error
 *	message is left in interp->result.  The caller should never
 *	modify the bitmap that is returned, and should eventually call
 *	Tk_FreeBitmap when the bitmap is no longer needed.
 *
 * Side effects:
 *	The bitmap is added to an internal database with a reference count.
 *	For each call to this procedure, there should eventually be a call
 *	to Tk_FreeBitmap, so that the database can be cleaned up when bitmaps
 *	aren't needed anymore.
 *
 *----------------------------------------------------------------------
 */

Pixmap
Tk_GetBitmap(interp, tkwin, string)
    Tcl_Interp *interp;		/* Interpreter to use for error reporting,
				 * this may be NULL. */
    Tk_Window tkwin;		/* Window in which bitmap will be used. */
    Tk_Uid string;		/* Description of bitmap.  See manual entry
				 * for details on legal syntax. */
{
    NameKey nameKey;
    IdKey idKey;
    Tcl_HashEntry *nameHashPtr, *idHashPtr, *predefHashPtr;
    register TkBitmap *bitmapPtr;
    TkPredefBitmap *predefPtr;
    int new;
    Pixmap bitmap;
    int width, height;
    int dummy2;

    if (!initialized) {
	BitmapInit();
    }

    nameKey.name = string;
    nameKey.screen = Tk_Screen(tkwin);
    nameHashPtr = Tcl_CreateHashEntry(&nameTable, (char *) &nameKey, &new);
    if (!new) {
	bitmapPtr = (TkBitmap *) Tcl_GetHashValue(nameHashPtr);
	bitmapPtr->refCount++;
	return bitmapPtr->bitmap;
    }

    /*
     * No suitable bitmap exists.  Create a new bitmap from the
     * information contained in the string.  If the string starts
     * with "@" then the rest of the string is a file name containing
     * the bitmap.  Otherwise the string must refer to a bitmap
     * defined by a call to Tk_DefineBitmap.
     */

    if (*string == '@') {
	Tcl_DString buffer;
	int result;

        if (Tcl_IsSafe(interp)) {
            Tcl_AppendResult(interp, "can't specify bitmap with '@' in a",
                    " safe interpreter", (char *) NULL);
            goto error;
        }

	string = Tcl_TranslateFileName(interp, string + 1, &buffer);
	if (string == NULL) {
	    goto error;
	}
	result = TkReadBitmapFile(interp, Tk_Display(tkwin),
		RootWindowOfScreen(nameKey.screen), string,
		(unsigned int *) &width, (unsigned int *) &height,
		&bitmap, &dummy2, &dummy2);
	if (result != BitmapSuccess) {
	    if (interp != NULL) {
		Tcl_AppendResult(interp, "error reading bitmap file \"", string,
		    "\"", (char *) NULL);
	    }
	    Tcl_DStringFree(&buffer);
	    goto error;
	}
	Tcl_DStringFree(&buffer);
    } else {
	predefHashPtr = Tcl_FindHashEntry(&tkPredefBitmapTable, string);
	if (predefHashPtr == NULL) {
	    /*
	     * The following platform specific call allows the user to
	     * define bitmaps that may only exist during run time.  If
	     * it returns None nothing was found and we return the error.
	     */
	    bitmap = TkpGetNativeAppBitmap(Tk_Display(tkwin), string,
		    &width, &height);
	
	    if (bitmap == None) {
		if (interp != NULL) {
		    Tcl_AppendResult(interp, "bitmap \"", string,
			"\" not defined", (char *) NULL);
		}
		goto error;
	    }
	} else {
	    predefPtr = (TkPredefBitmap *) Tcl_GetHashValue(predefHashPtr);
	    width = predefPtr->width;
	    height = predefPtr->height;
	    if (predefPtr->native) {
		bitmap = TkpCreateNativeBitmap(Tk_Display(tkwin),
		    predefPtr->source);
		if (bitmap == None) {
		    panic("native bitmap creation failed");
		}
	    } else {
		bitmap = XCreateBitmapFromData(Tk_Display(tkwin),
		    RootWindowOfScreen(nameKey.screen), predefPtr->source,
		    (unsigned) width, (unsigned) height);
	    }
	}
    }

    /*
     * Add information about this bitmap to our database.
     */

    bitmapPtr = (TkBitmap *) ckalloc(sizeof(TkBitmap));
    bitmapPtr->bitmap = bitmap;
    bitmapPtr->width = width;
    bitmapPtr->height = height;
    bitmapPtr->display = Tk_Display(tkwin);
    bitmapPtr->refCount = 1;
    bitmapPtr->hashPtr = nameHashPtr;
    idKey.display = bitmapPtr->display;
    idKey.pixmap = bitmap;
    idHashPtr = Tcl_CreateHashEntry(&idTable, (char *) &idKey,
	    &new);
    if (!new) {
	panic("bitmap already registered in Tk_GetBitmap");
    }
    Tcl_SetHashValue(nameHashPtr, bitmapPtr);
    Tcl_SetHashValue(idHashPtr, bitmapPtr);
    return bitmapPtr->bitmap;

    error:
    Tcl_DeleteHashEntry(nameHashPtr);
    return None;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_DefineBitmap --
 *
 *	This procedure associates a textual name with a binary bitmap
 *	description, so that the name may be used to refer to the
 *	bitmap in future calls to Tk_GetBitmap.
 *
 * Results:
 *	A standard Tcl result.  If an error occurs then TCL_ERROR is
 *	returned and a message is left in interp->result.
 *
 * Side effects:
 *	"Name" is entered into the bitmap table and may be used from
 *	here on to refer to the given bitmap.
 *
 *----------------------------------------------------------------------
 */

int
Tk_DefineBitmap(interp, name, source, width, height)
    Tcl_Interp *interp;		/* Interpreter to use for error reporting. */
    Tk_Uid name;		/* Name to use for bitmap.  Must not already
				 * be defined as a bitmap. */
    char *source;		/* Address of bits for bitmap. */
    int width;			/* Width of bitmap. */
    int height;			/* Height of bitmap. */
{
    int new;
    Tcl_HashEntry *predefHashPtr;
    TkPredefBitmap *predefPtr;

    if (!initialized) {
	BitmapInit();
    }

    predefHashPtr = Tcl_CreateHashEntry(&tkPredefBitmapTable, name, &new);
    if (!new) {
        Tcl_AppendResult(interp, "bitmap \"", name,
		"\" is already defined", (char *) NULL);
	return TCL_ERROR;
    }
    predefPtr = (TkPredefBitmap *) ckalloc(sizeof(TkPredefBitmap));
    predefPtr->source = source;
    predefPtr->width = width;
    predefPtr->height = height;
    predefPtr->native = 0;
    Tcl_SetHashValue(predefHashPtr, predefPtr);
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * Tk_NameOfBitmap --
 *
 *	Given a bitmap, return a textual string identifying the
 *	bitmap.
 *
 * Results:
 *	The return value is the string name associated with bitmap.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

Tk_Uid
Tk_NameOfBitmap(display, bitmap)
    Display *display;			/* Display for which bitmap was
					 * allocated. */
    Pixmap bitmap;			/* Bitmap whose name is wanted. */
{
    IdKey idKey;
    Tcl_HashEntry *idHashPtr;
    TkBitmap *bitmapPtr;

    if (!initialized) {
	unknown:
	panic("Tk_NameOfBitmap received unknown bitmap argument");
    }

    idKey.display = display;
    idKey.pixmap = bitmap;
    idHashPtr = Tcl_FindHashEntry(&idTable, (char *) &idKey);
    if (idHashPtr == NULL) {
	goto unknown;
    }
    bitmapPtr = (TkBitmap *) Tcl_GetHashValue(idHashPtr);
    return ((NameKey *) bitmapPtr->hashPtr->key.words)->name;
}

/*
 *--------------------------------------------------------------
 *
 * Tk_SizeOfBitmap --
 *
 *	Given a bitmap managed by this module, returns the width
 *	and height of the bitmap.
 *
 * Results:
 *	The words at *widthPtr and *heightPtr are filled in with
 *	the dimenstions of bitmap.
 *
 * Side effects:
 *	If bitmap isn't managed by this module then the procedure
 *	panics..
 *
 *--------------------------------------------------------------
 */

void
Tk_SizeOfBitmap(display, bitmap, widthPtr, heightPtr)
    Display *display;			/* Display for which bitmap was
					 * allocated. */
    Pixmap bitmap;			/* Bitmap whose size is wanted. */
    int *widthPtr;			/* Store bitmap width here. */
    int *heightPtr;			/* Store bitmap height here. */
{
    IdKey idKey;
    Tcl_HashEntry *idHashPtr;
    TkBitmap *bitmapPtr;

    if (!initialized) {
	unknownBitmap:
	panic("Tk_SizeOfBitmap received unknown bitmap argument");
    }

    idKey.display = display;
    idKey.pixmap = bitmap;
    idHashPtr = Tcl_FindHashEntry(&idTable, (char *) &idKey);
    if (idHashPtr == NULL) {
	goto unknownBitmap;
    }
    bitmapPtr = (TkBitmap *) Tcl_GetHashValue(idHashPtr);
    *widthPtr = bitmapPtr->width;
    *heightPtr = bitmapPtr->height;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_FreeBitmap --
 *
 *	This procedure is called to release a bitmap allocated by
 *	Tk_GetBitmap or TkGetBitmapFromData.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The reference count associated with bitmap is decremented, and
 *	it is officially deallocated if no-one is using it anymore.
 *
 *----------------------------------------------------------------------
 */

void
Tk_FreeBitmap(display, bitmap)
    Display *display;			/* Display for which bitmap was
					 * allocated. */
    Pixmap bitmap;			/* Bitmap to be released. */
{
    Tcl_HashEntry *idHashPtr;
    register TkBitmap *bitmapPtr;
    IdKey idKey;

    if (!initialized) {
	panic("Tk_FreeBitmap called before Tk_GetBitmap");
    }

    idKey.display = display;
    idKey.pixmap = bitmap;
    idHashPtr = Tcl_FindHashEntry(&idTable, (char *) &idKey);
    if (idHashPtr == NULL) {
	panic("Tk_FreeBitmap received unknown bitmap argument");
    }
    bitmapPtr = (TkBitmap *) Tcl_GetHashValue(idHashPtr);
    bitmapPtr->refCount--;
    if (bitmapPtr->refCount == 0) {
	Tk_FreePixmap(bitmapPtr->display, bitmapPtr->bitmap);
	Tcl_DeleteHashEntry(idHashPtr);
	Tcl_DeleteHashEntry(bitmapPtr->hashPtr);
	ckfree((char *) bitmapPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_GetBitmapFromData --
 *
 *	Given a description of the bits for a bitmap, make a bitmap that
 *	has the given properties. *** NOTE:  this procedure is obsolete
 *	and really shouldn't be used anymore. ***
 *
 * Results:
 *	The return value is the X identifer for the desired bitmap
 *	(a one-plane Pixmap), unless it couldn't be created properly.
 *	In this case, None is returned and an error message is left in
 *	interp->result.  The caller should never modify the bitmap that
 *	is returned, and should eventually call Tk_FreeBitmap when the
 *	bitmap is no longer needed.
 *
 * Side effects:
 *	The bitmap is added to an internal database with a reference count.
 *	For each call to this procedure, there should eventually be a call
 *	to Tk_FreeBitmap, so that the database can be cleaned up when bitmaps
 *	aren't needed anymore.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
Pixmap
Tk_GetBitmapFromData(interp, tkwin, source, width, height)
    Tcl_Interp *interp;		/* Interpreter to use for error reporting. */
    Tk_Window tkwin;		/* Window in which bitmap will be used. */
    char *source;		/* Bitmap data for bitmap shape. */
    int width, height;		/* Dimensions of bitmap. */
{
    DataKey nameKey;
    Tcl_HashEntry *dataHashPtr;
    Tk_Uid name;
    int new;
    char string[20];
    static int autoNumber = 0;

    if (!initialized) {
	BitmapInit();
    }

    nameKey.source = source;
    nameKey.width = width;
    nameKey.height = height;
    dataHashPtr = Tcl_CreateHashEntry(&dataTable, (char *) &nameKey, &new);
    if (!new) {
	name = (Tk_Uid) Tcl_GetHashValue(dataHashPtr);
    } else {
	autoNumber++;
	sprintf(string, "_tk%d", autoNumber);
	name = Tk_GetUid(string);
	Tcl_SetHashValue(dataHashPtr, name);
	if (Tk_DefineBitmap(interp, name, source, width, height) != TCL_OK) {
	    Tcl_DeleteHashEntry(dataHashPtr);
	    return TCL_ERROR;
	}
    }
    return Tk_GetBitmap(interp, tkwin, name);
}

/*
 *----------------------------------------------------------------------
 *
 * BitmapInit --
 *
 *	Initialize the structures used for bitmap management.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Read the code.
 *
 *----------------------------------------------------------------------
 */

static void
BitmapInit()
{
    Tcl_Interp *dummy;

    dummy = Tcl_CreateInterp();
    initialized = 1;
    Tcl_InitHashTable(&nameTable, sizeof(NameKey)/sizeof(int));
    Tcl_InitHashTable(&dataTable, sizeof(DataKey)/sizeof(int));
    Tcl_InitHashTable(&tkPredefBitmapTable, TCL_ONE_WORD_KEYS);

    /*
     * The call below is tricky:  can't use sizeof(IdKey) because it
     * gets padded with extra unpredictable bytes on some 64-bit
     * machines.
     */

    Tcl_InitHashTable(&idTable, (sizeof(Display *) + sizeof(Pixmap))
	    /sizeof(int));

    Tk_DefineBitmap(dummy, Tk_GetUid("error"), (char *) error_bits,
	    error_width, error_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("Tk"), (char *) Tkbmp_bits,
	    Tkbmp_width, Tkbmp_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("gray75"), (char *) gray75_bits,
	    gray75_width, gray75_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("gray50"), (char *) gray50_bits,
	    gray50_width, gray50_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("gray25"), (char *) gray25_bits,
	    gray25_width, gray25_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("gray12"), (char *) gray12_bits,
	    gray12_width, gray12_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("hourglass"), (char *) hourglass_bits,
	    hourglass_width, hourglass_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("info"), (char *) info_bits,
	    info_width, info_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("questhead"), (char *) questhead_bits,
	    questhead_width, questhead_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("question"), (char *) question_bits,
	    question_width, question_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("warning"), (char *) warning_bits,
	    warning_width, warning_height);
    Tk_DefineBitmap(dummy, Tk_GetUid("transparent"), (char *) transparent_bits,
	    transparent_width, transparent_height);

    TkpDefineNativeBitmaps();

    Tcl_DeleteInterp(dummy);
}

/*
 *----------------------------------------------------------------------
 *
 * TkReadBitmapFile --
 *
 *	Loads a bitmap image in X bitmap format into the specified
 *	drawable.  This is equivelent to the XReadBitmapFile in X.
 *
 * Results:
 *	Sets the size, hotspot, and bitmap on success.
 *
 * Side effects:
 *	Creates a new bitmap from the file data.
 *
 *----------------------------------------------------------------------
 */

int
TkReadBitmapFile(interp, display, d, filename, width_return, height_return,
	bitmap_return, x_hot_return, y_hot_return)
    Tcl_Interp *interp;
    Display* display;
    Drawable d;
    CONST char* filename;
    unsigned int* width_return;
    unsigned int* height_return;
    Pixmap* bitmap_return;
    int* x_hot_return;
    int* y_hot_return;
{
    char *data;

    data = TkGetBitmapData(interp, NULL, (char *) filename,
	    (int *) width_return, (int *) height_return, x_hot_return,
	    y_hot_return);
    if (data == NULL) {
	return BitmapFileInvalid;
    }

    *bitmap_return = XCreateBitmapFromData(display, d, data, *width_return,
	    *height_return);

    ckfree(data);
    return BitmapSuccess;
}
