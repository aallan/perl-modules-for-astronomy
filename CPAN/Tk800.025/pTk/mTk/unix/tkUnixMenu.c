/*
 * tkUnixMenu.c --
 *
 *	This module implements the UNIX platform-specific features of menus.
 *
 * Copyright (c) 1996-1997 by Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkUnixMenu.c,v 1.1 2003/09/28 14:55:01 aa Exp $
 */

#include "tkPort.h"
#include "default.h"
#include "tkInt.h"
#include "tkUnixInt.h"
#include "tkMenu.h"

/*
 * Constants used for menu drawing.
 */

#define MENU_MARGIN_WIDTH	2
#define MENU_DIVIDER_HEIGHT	2

/*
 * Platform specific flags for Unix.
 */

#define ENTRY_HELP_MENU		ENTRY_PLATFORM_FLAG1

/*
 * Procedures used internally.
 */

static void		SetHelpMenu _ANSI_ARGS_((TkMenu *menuPtr));
static void		DrawMenuEntryAccelerator _ANSI_ARGS_((
			    TkMenu *menuPtr, TkMenuEntry *mePtr,
			    Drawable d, GC gc, Tk_Font tkfont,
			    CONST Tk_FontMetrics *fmPtr,
			    Tk_3DBorder activeBorder, int x, int y,
			    int width, int height, int drawArrow));
static void		DrawMenuEntryBackground _ANSI_ARGS_((
			    TkMenu *menuPtr, TkMenuEntry *mePtr,
			    Drawable d, Tk_3DBorder activeBorder,
			    Tk_3DBorder bgBorder, int x, int y,
			    int width, int heigth));
static void		DrawMenuEntryIndicator _ANSI_ARGS_((
			    TkMenu *menuPtr, TkMenuEntry *mePtr,
			    Drawable d, GC gc, GC indicatorGC,
			    Tk_Font tkfont,
			    CONST Tk_FontMetrics *fmPtr, int x, int y,
			    int width, int height));
static void		DrawMenuEntryLabel _ANSI_ARGS_((
			    TkMenu * menuPtr, TkMenuEntry *mePtr, Drawable d,
			    GC gc, Tk_Font tkfont,
			    CONST Tk_FontMetrics *fmPtr, int x, int y,
			    int width, int height));
static void		DrawMenuSeparator _ANSI_ARGS_((TkMenu *menuPtr,
			    TkMenuEntry *mePtr, Drawable d, GC gc,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr,
			    int x, int y, int width, int height));
static void		DrawTearoffEntry _ANSI_ARGS_((TkMenu *menuPtr,
			    TkMenuEntry *mePtr, Drawable d, GC gc,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr,
			    int x, int y, int width, int height));
static void		DrawMenuUnderline _ANSI_ARGS_((TkMenu *menuPtr,
			    TkMenuEntry *mePtr, Drawable d, GC gc,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr, int x,
			    int y, int width, int height));
static void		GetMenuAccelGeometry _ANSI_ARGS_((TkMenu *menuPtr,
			    TkMenuEntry *mePtr, Tk_Font tkfont,
			    CONST Tk_FontMetrics *fmPtr, int *widthPtr,
			    int *heightPtr));
static void		GetMenuLabelGeometry _ANSI_ARGS_((TkMenuEntry *mePtr,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr,
			    int *widthPtr, int *heightPtr));
static void		GetMenuIndicatorGeometry _ANSI_ARGS_((
			    TkMenu *menuPtr, TkMenuEntry *mePtr,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr,
			    int *widthPtr, int *heightPtr));
static void		GetMenuSeparatorGeometry _ANSI_ARGS_((
			    TkMenu *menuPtr, TkMenuEntry *mePtr,
			    Tk_Font tkfont, CONST Tk_FontMetrics *fmPtr,
			    int *widthPtr, int *heightPtr));
static void		GetTearoffEntryGeometry _ANSI_ARGS_((TkMenu *menuPtr,
			    TkMenuEntry *mePtr, Tk_Font tkfont,
			    CONST Tk_FontMetrics *fmPtr, int *widthPtr,
			    int *heightPtr));


/*
 *----------------------------------------------------------------------
 *
 * TkpNewMenu --
 *
 *	Gets the platform-specific piece of the menu. Invoked during idle
 *	after the generic part of the menu has been created.
 *
 * Results:
 *	Standard TCL error.
 *
 * Side effects:
 *	Allocates any platform specific allocations and places them
 *	in the platformData field of the menuPtr.
 *
 *----------------------------------------------------------------------
 */

int
TkpNewMenu(menuPtr)
    TkMenu *menuPtr;
{
    SetHelpMenu(menuPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpDestroyMenu --
 *
 *	Destroys platform-specific menu structures. Called when the
 *	generic menu structure is destroyed for the menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All platform-specific allocations are freed up.
 *
 *----------------------------------------------------------------------
 */

void
TkpDestroyMenu(menuPtr)
    TkMenu *menuPtr;
{
    /*
     * Nothing to do.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * TkpDestroyMenuEntry --
 *
 *	Cleans up platform-specific menu entry items. Called when entry
 *	is destroyed in the generic code.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All platform specific allocations are freed up.
 *
 *----------------------------------------------------------------------
 */

void
TkpDestroyMenuEntry(mEntryPtr)
    TkMenuEntry *mEntryPtr;
{
    /*
     * Nothing to do.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * TkpConfigureMenuEntry --
 *
 *	Processes configuration options for menu entries. Called when
 *	the generic options are processed for the menu.
 *
 * Results:
 *	Returns standard TCL result. If TCL_ERROR is returned, then
 *	interp->result contains an error message.
 *
 * Side effects:
 *	Configuration information get set for mePtr; old resources
 *	get freed, if any need it.
 *
 *----------------------------------------------------------------------
 */

int
TkpConfigureMenuEntry(mePtr)
    register TkMenuEntry *mePtr;	/* Information about menu entry;  may
					 * or may not already have values for
					 * some fields. */
{
    /*
     * If this is a cascade menu, and the child menu exists, check to
     * see if the child menu is a help menu.
     */

    if ((mePtr->type == CASCADE_ENTRY) && (mePtr->name != NULL)) {
	TkMenuReferences *menuRefPtr;

	menuRefPtr = TkFindMenuReferences(mePtr->menuPtr->interp,
		LangString(mePtr->name));
	if ((menuRefPtr != NULL) && (menuRefPtr->menuPtr != NULL)) {
	    SetHelpMenu(menuRefPtr->menuPtr);
	}
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpMenuNewEntry --
 *
 *	Called when a new entry is created in a menu. Fills in platform
 *	specific data for the entry. The platformEntryData field
 *	is used to store the indicator diameter for radio button
 *	and check box entries.
 *
 * Results:
 * 	Standard TCL error.
 *
 * Side effects:
 *	None on Unix.
 *
 *----------------------------------------------------------------------
 */

int
TkpMenuNewEntry(mePtr)
    TkMenuEntry *mePtr;
{
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpSetWindowMenuBar --
 *
 *	Sets up the menu as a menubar in the given window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Recomputes geometry of given window.
 *
 *----------------------------------------------------------------------
 */

void
TkpSetWindowMenuBar(tkwin, menuPtr)
    Tk_Window tkwin;			/* The window we are setting */
    TkMenu *menuPtr;			/* The menu we are setting */
{
    if (menuPtr == NULL) {
	TkUnixSetMenubar(tkwin, NULL);
    } else {
	TkUnixSetMenubar(tkwin, menuPtr->tkwin);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkpSetMainMenuBar --
 *
 *	Called when a toplevel widget is brought to front. On the
 *	Macintosh, sets up the menubar that goes accross the top
 *	of the main monitor. On other platforms, nothing is necessary.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Recompute geometry of given window.
 *
 *----------------------------------------------------------------------
 */

void
TkpSetMainMenubar(interp, tkwin, menuName)
    Tcl_Interp *interp;
    Tk_Window tkwin;
    char *menuName;
{
    /*
     * Nothing to do.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * GetMenuIndicatorGeometry --
 *
 *	Fills out the geometry of the indicator in a menu item. Note
 *	that the mePtr->height field must have already been filled in
 *	by GetMenuLabelGeometry since this height depends on the label
 *	height.
 *
 * Results:
 *	widthPtr and heightPtr point to the new geometry values.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
GetMenuIndicatorGeometry(menuPtr, mePtr, tkfont, fmPtr, widthPtr, heightPtr)
    TkMenu *menuPtr;			/* The menu we are drawing. */
    TkMenuEntry *mePtr;			/* The entry we are interested in. */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalculated metrics */
    int *widthPtr;			/* The resulting width */
    int *heightPtr;			/* The resulting height */
{
    if (!mePtr->hideMargin && mePtr->indicatorOn &&
	    ((mePtr->type == CHECK_BUTTON_ENTRY)
	    || (mePtr->type == RADIO_BUTTON_ENTRY))) {
        if ((mePtr->image != NULL) || (mePtr->bitmap != None)) {
            *widthPtr = (14 * mePtr->height) / 10;
            *heightPtr = mePtr->height;
            if (mePtr->type == CHECK_BUTTON_ENTRY) {
    		mePtr->platformEntryData =
			(TkMenuPlatformEntryData) ((65 * mePtr->height) / 100);
	    } else {
    	    	mePtr->platformEntryData =
			(TkMenuPlatformEntryData) ((75 * mePtr->height) / 100);
    	    }	
        } else {
            *widthPtr = *heightPtr = mePtr->height;
	    if (mePtr->type == CHECK_BUTTON_ENTRY) {
		mePtr->platformEntryData = (TkMenuPlatformEntryData)
			((80 * mePtr->height) / 100);
	    } else {
		mePtr->platformEntryData = (TkMenuPlatformEntryData)
			mePtr->height;
	    }
	}
    } else {
        *heightPtr = 0;
        *widthPtr = menuPtr->borderWidth;
    }
}


/*
 *----------------------------------------------------------------------
 *
 * GetMenuAccelGeometry --
 *
 *	Get the geometry of the accelerator area of a menu item.
 *
 * Results:
 *	heightPtr and widthPtr are set.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
GetMenuAccelGeometry(menuPtr, mePtr, tkfont, fmPtr, widthPtr, heightPtr)
    TkMenu *menuPtr;		/* The menu was are drawing */
    TkMenuEntry *mePtr;		/* The entry we are getting the geometry for */
    Tk_Font tkfont;		/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;/* The precalculated font metrics */
    int *widthPtr;		/* The width of the acclerator area */
    int *heightPtr;		/* The height of the accelerator area */
{
    *heightPtr = fmPtr->linespace;
    if (mePtr->type == CASCADE_ENTRY) {
    	*widthPtr = 2 * CASCADE_ARROW_WIDTH;
    } else if ((menuPtr->menuType != MENUBAR) && (mePtr->accel != NULL)) {
    	*widthPtr = Tk_TextWidth(tkfont, mePtr->accel, mePtr->accelLength);
    } else {
    	*widthPtr = 0;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuEntryBackground --
 *
 *	This procedure draws the background part of a menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuEntryBackground(menuPtr, mePtr, d, activeBorder, bgBorder, x, y,
	width, height)
    TkMenu *menuPtr;		/* The menu we are drawing */
    TkMenuEntry *mePtr;		/* The entry we are drawing. */
    Drawable d;			/* The drawable we are drawing into */
    Tk_3DBorder activeBorder;	/* The border for an active item */
    Tk_3DBorder bgBorder;	/* The background border */
    int x;			/* Left coordinate of entry rect */
    int y;			/* Right coordinate of entry rect */
    int width;			/* Width of entry rect */
    int height;			/* Height of entry rect */
{
    if (mePtr->state == TK_STATE_ACTIVE) {
	int relief;
    	bgBorder = activeBorder;

	if ((menuPtr->menuType == MENUBAR)
		&& ((menuPtr->postedCascade == NULL)
		|| (menuPtr->postedCascade != mePtr))) {
	    relief = TK_RELIEF_FLAT;
	} else {
	    relief = TK_RELIEF_RAISED;
	}
	
	Tk_Fill3DRectangle(menuPtr->tkwin, d, bgBorder, x, y, width, height,
		menuPtr->activeBorderWidth, relief);
    } else {
	Tk_Fill3DRectangle(menuPtr->tkwin, d, bgBorder, x, y, width, height,
		0, TK_RELIEF_FLAT);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuEntryAccelerator --
 *
 *	This procedure draws the background part of a menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuEntryAccelerator(menuPtr, mePtr, d, gc, tkfont, fmPtr, activeBorder,
	x, y, width, height, drawArrow)
    TkMenu *menuPtr;			/* The menu we are drawing */
    TkMenuEntry *mePtr;			/* The entry we are drawing */
    Drawable d;				/* The drawable we are drawing into */
    GC gc;				/* The precalculated gc to draw with */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalculated metrics */
    Tk_3DBorder activeBorder;		/* The border for an active item */
    int x;				/* Left coordinate of entry rect */
    int y;				/* Top coordinate of entry rect */
    int width;				/* Width of entry */
    int height;				/* Height of entry */
    int drawArrow;			/* Whether or not to draw arrow. */
{
    XPoint points[3];

    /*
     * Draw accelerator or cascade arrow.
     */

    if (menuPtr->menuType == MENUBAR) {
	return;
    }

    if ((mePtr->type == CASCADE_ENTRY) && drawArrow) {
    	points[0].x = x + width - menuPtr->borderWidth
	        - menuPtr->activeBorderWidth - CASCADE_ARROW_WIDTH;
    	points[0].y = y + (height - CASCADE_ARROW_HEIGHT)/2;
    	points[1].x = points[0].x;
    	points[1].y = points[0].y + CASCADE_ARROW_HEIGHT;
    	points[2].x = points[0].x + CASCADE_ARROW_WIDTH;
    	points[2].y = points[0].y + CASCADE_ARROW_HEIGHT/2;
    	Tk_Fill3DPolygon(menuPtr->tkwin, d, activeBorder, points, 3,
		DECORATION_BORDER_WIDTH,
	    	(menuPtr->postedCascade == mePtr)
	    	? TK_RELIEF_SUNKEN : TK_RELIEF_RAISED);
    } else if (mePtr->accel != NULL) {
	int left = x + mePtr->labelWidth + menuPtr->activeBorderWidth
	        + mePtr->indicatorSpace;
	if (menuPtr->menuType == MENUBAR) {
	    left += 5;
	}
    	Tk_DrawChars(menuPtr->display, d, gc, tkfont, mePtr->accel,
		mePtr->accelLength, left,
		(y + (height + fmPtr->ascent - fmPtr->descent) / 2));
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuEntryIndicator --
 *
 *	This procedure draws the background part of a menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuEntryIndicator(menuPtr, mePtr, d, gc, indicatorGC, tkfont, fmPtr,
	x, y, width, height)
    TkMenu *menuPtr;			/* The menu we are drawing */
    TkMenuEntry *mePtr;			/* The entry we are drawing */
    Drawable d;				/* The drawable to draw into */
    GC gc;				/* The gc to draw with */
    GC indicatorGC;			/* The gc that indicators draw with */
    Tk_Font tkfont;			/* The font to draw with */
    CONST Tk_FontMetrics *fmPtr;	/* The font metrics of the font */
    int x;				/* The left of the entry rect */
    int y;				/* The top of the entry rect */
    int width;				/* Width of menu entry */
    int height;				/* Height of menu entry */
{

    /*
     * Draw check-button indicator.
     */

    if ((mePtr->type == CHECK_BUTTON_ENTRY)
	    && mePtr->indicatorOn) {
    	int dim, top, left;
	
	dim = (int) mePtr->platformEntryData;
    	left = x + menuPtr->activeBorderWidth
		+ (mePtr->indicatorSpace - dim)/2;
	if (menuPtr->menuType == MENUBAR) {
	    left += 5;
	}
    	top = y + (height - dim)/2;
    	Tk_Fill3DRectangle(menuPtr->tkwin, d, menuPtr->border, left, top, dim,
		dim, DECORATION_BORDER_WIDTH, TK_RELIEF_SUNKEN);
    	left += DECORATION_BORDER_WIDTH;
    	top += DECORATION_BORDER_WIDTH;
    	dim -= 2*DECORATION_BORDER_WIDTH;
    	if ((dim > 0) && (mePtr->entryFlags
	    	& ENTRY_SELECTED)) {
	    XFillRectangle(menuPtr->display, d, indicatorGC, left, top,
		    (unsigned int) dim, (unsigned int) dim);
    	}
    }

    /*
     * Draw radio-button indicator.
     */

    if ((mePtr->type == RADIO_BUTTON_ENTRY)
	    && mePtr->indicatorOn) {
    	XPoint points[4];
    	int radius;

	radius = ((int) mePtr->platformEntryData)/2;
    	points[0].x = x + (mePtr->indicatorSpace
		- (int) mePtr->platformEntryData)/2;
	points[0].y = y + (height)/2;
    	points[1].x = points[0].x + radius;
    	points[1].y = points[0].y + radius;
    	points[2].x = points[1].x + radius;
    	points[2].y = points[0].y;
    	points[3].x = points[1].x;
    	points[3].y = points[0].y - radius;
    	if (mePtr->entryFlags & ENTRY_SELECTED) {
	    XFillPolygon(menuPtr->display, d, indicatorGC, points, 4, Convex,
		    CoordModeOrigin);
    	} else {
	    Tk_Fill3DPolygon(menuPtr->tkwin, d, menuPtr->border, points, 4,
		    DECORATION_BORDER_WIDTH, TK_RELIEF_FLAT);
    	}
        Tk_Draw3DPolygon(menuPtr->tkwin, d, menuPtr->border, points, 4,
	        DECORATION_BORDER_WIDTH, TK_RELIEF_SUNKEN);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuSeparator --
 *
 *	This procedure draws a separator menu item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuSeparator(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, y, width, height)
    TkMenu *menuPtr;			/* The menu we are drawing */
    TkMenuEntry *mePtr;			/* The entry we are drawing */
    Drawable d;				/* The drawable we are using */
    GC gc;				/* The gc to draw into */
    Tk_Font tkfont;			/* The font to draw with */
    CONST Tk_FontMetrics *fmPtr;	/* The font metrics from the font */
    int x;
    int y;
    int width;
    int height;
{
    XPoint points[2];
    int margin;

    if (menuPtr->menuType == MENUBAR) {
	return;
    }

    margin = (fmPtr->ascent + fmPtr->descent)/2;
    points[0].x = x;
    points[0].y = y + height/2;
    points[1].x = width - 1;
    points[1].y = points[0].y;
    Tk_Draw3DPolygon(menuPtr->tkwin, d, menuPtr->border, points, 2, 1,
	    TK_RELIEF_RAISED);
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuEntryLabel --
 *
 *	This procedure draws the label part of a menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuEntryLabel(
    menuPtr,			/* The menu we are drawing */
    mePtr,			/* The entry we are drawing */
    d,				/* What we are drawing into */
    gc,				/* The gc we are drawing into */
    tkfont,			/* The precalculated font */
    fmPtr,			/* The precalculated font metrics */
    x,				/* left edge */
    y,				/* right edge */
    width,			/* width of entry */
    height)			/* height of entry */
    TkMenu *menuPtr;
    TkMenuEntry *mePtr;
    Drawable d;
    GC gc;
    Tk_Font tkfont;
    CONST Tk_FontMetrics *fmPtr;
    int x, y, width, height;
{
    int baseline;
    int indicatorSpace =  mePtr->indicatorSpace;
    int leftEdge = x + indicatorSpace + menuPtr->activeBorderWidth;
    int imageHeight, imageWidth;

    if (menuPtr->menuType == MENUBAR) {
	leftEdge += 5;
    }

    /*
     * Draw label or bitmap or image for entry.
     */

    baseline = y + (height + fmPtr->ascent - fmPtr->descent) / 2;
    if (mePtr->image != NULL) {
    	Tk_SizeOfImage(mePtr->image, &imageWidth, &imageHeight);
    	if ((mePtr->selectImage != NULL)
	    	&& (mePtr->entryFlags & ENTRY_SELECTED)) {
	    Tk_RedrawImage(mePtr->selectImage, 0, 0,
		    imageWidth, imageHeight, d, leftEdge,
	            (int) (y + (mePtr->height - imageHeight)/2));
    	} else {
	    Tk_RedrawImage(mePtr->image, 0, 0, imageWidth,
		    imageHeight, d, leftEdge,
		    (int) (y + (mePtr->height - imageHeight)/2));
    	}
    } else if (mePtr->bitmap != None) {
    	int width, height;

        Tk_SizeOfBitmap(menuPtr->display,
	        mePtr->bitmap, &width, &height);
    	XCopyPlane(menuPtr->display,
	    	mePtr->bitmap, d,
	    	gc, 0, 0, (unsigned) width, (unsigned) height, leftEdge,
	    	(int) (y + (mePtr->height - height)/2), 1);
    } else {
    	if (mePtr->labelLength > 0) {
	    Tk_DrawChars(menuPtr->display, d, gc,
		    tkfont, mePtr->label, mePtr->labelLength,
		    leftEdge, baseline);
	    DrawMenuUnderline(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, y,
		    width, height);
    	}
    }

    if (mePtr->state == TK_STATE_DISABLED) {
	if (menuPtr->disabledFg == NULL) {
	    XFillRectangle(menuPtr->display, d, menuPtr->disabledGC, x, y,
		    (unsigned) width, (unsigned) height);
	} else if ((mePtr->image != NULL)
		&& (menuPtr->disabledImageGC != None)) {
	    XFillRectangle(menuPtr->display, d, menuPtr->disabledImageGC,
		    leftEdge,
		    (int) (y + (mePtr->height - imageHeight)/2),
		    (unsigned) imageWidth, (unsigned) imageHeight);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DrawMenuUnderline --
 *
 *	On appropriate platforms, draw the underline character for the
 *	menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawMenuUnderline(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, y, width, height)
    TkMenu *menuPtr;			/* The menu to draw into */
    TkMenuEntry *mePtr;			/* The entry we are drawing */
    Drawable d;				/* What we are drawing into */
    GC gc;				/* The gc to draw into */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalculated font metrics */
    int x;
    int y;
    int width;
    int height;
{
    int indicatorSpace = mePtr->indicatorSpace;
    if (mePtr->underline >= 0) {
	int leftEdge = x + indicatorSpace + menuPtr->activeBorderWidth;
	if (menuPtr->menuType == MENUBAR) {
	    leftEdge += 5;
	}
	
    	Tk_UnderlineChars(menuPtr->display, d, gc, tkfont, mePtr->label,
    		leftEdge, y + (height + fmPtr->ascent - fmPtr->descent) / 2,
		mePtr->underline, mePtr->underline + 1);
    }		
}

/*
 *----------------------------------------------------------------------
 *
 * TkpPostMenu --
 *
 *	Posts a menu on the screen
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The menu is posted and handled.
 *
 *----------------------------------------------------------------------
 */

int
TkpPostMenu(interp, menuPtr, x, y)
    Tcl_Interp *interp;
    TkMenu *menuPtr;
    int x;
    int y;
{
    return TkPostTearoffMenu(interp, menuPtr, x, y);
}

/*
 *----------------------------------------------------------------------
 *
 * GetMenuSeparatorGeometry --
 *
 *	Gets the width and height of the indicator area of a menu.
 *
 * Results:
 *	widthPtr and heightPtr are set.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
GetMenuSeparatorGeometry(menuPtr, mePtr, tkfont, fmPtr, widthPtr,
	heightPtr)
    TkMenu *menuPtr;			/* The menu we are measuring */
    TkMenuEntry *mePtr;			/* The entry we are measuring */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalcualted font metrics */
    int *widthPtr;			/* The resulting width */
    int *heightPtr;			/* The resulting height */
{
    *widthPtr = 0;
    *heightPtr = fmPtr->linespace;
}

/*
 *----------------------------------------------------------------------
 *
 * GetTearoffEntryGeometry --
 *
 *	Gets the width and height of the indicator area of a menu.
 *
 * Results:
 *	widthPtr and heightPtr are set.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
GetTearoffEntryGeometry(menuPtr, mePtr, tkfont, fmPtr, widthPtr, heightPtr)
    TkMenu *menuPtr;			/* The menu we are drawing */
    TkMenuEntry *mePtr;			/* The entry we are measuring */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalculated font metrics */
    int *widthPtr;			/* The resulting width */
    int *heightPtr;			/* The resulting height */
{
    if (menuPtr->menuType != MASTER_MENU) {
	*heightPtr = 0;
	*widthPtr = 0;
    } else {
	*heightPtr = fmPtr->linespace;
	*widthPtr = Tk_TextWidth(tkfont, "W", -1);
    }
}

/*
 *--------------------------------------------------------------
 *
 * TkpComputeMenubarGeometry --
 *
 *	This procedure is invoked to recompute the size and
 *	layout of a menu that is a menubar clone.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Fields of menu entries are changed to reflect their
 *	current positions, and the size of the menu window
 *	itself may be changed.
 *
 *--------------------------------------------------------------
 */

void
TkpComputeMenubarGeometry(menuPtr)
    TkMenu *menuPtr;		/* Structure describing menu. */
{
    Tk_Font tkfont;
    Tk_FontMetrics menuMetrics, entryMetrics, *fmPtr;
    int width, height;
    int i, j;
    int x, y, currentRowHeight, currentRowWidth, maxWidth;
    int maxWindowWidth;
    int lastRowBreak;
    int helpMenuIndex = -1;
    TkMenuEntry *mePtr;
    int lastEntry;
    int lastSeparator = menuPtr->numEntries;
    int rightWidth = 0;
    int maxEntryWidth = 0;
    int maxEntryHeight = 0;
    int totalWidth = 0;

    if (menuPtr->tkwin == NULL) {
	return;
    }

    maxWidth = 0;
    if (menuPtr->numEntries == 0) {
	height = 0;
    } else {
	maxWindowWidth = Tk_Width(menuPtr->tkwin);
	if (maxWindowWidth <= 1) {
	    maxWindowWidth = 0x7ffffff;
	}
	currentRowHeight = 0;
	x = y = menuPtr->borderWidth;
	lastRowBreak = 0;
	currentRowWidth = 0;
	
	/*
	 * On the Mac especially, getting font metrics can be quite slow,
	 * so we want to do it intelligently. We are going to precalculate
	 * them and pass them down to all of the measureing and drawing
	 * routines. We will measure the font metrics of the menu once,
	 * and if an entry has a font set, we will measure it as we come
	 * to it, and then we decide which set to give the geometry routines.
	 */
	
	Tk_GetFontMetrics(menuPtr->tkfont, &menuMetrics);
	
	for (i = 0; i < menuPtr->numEntries; i++) {
	    mePtr = menuPtr->entries[i];
	    mePtr->entryFlags &= ~ENTRY_LAST_COLUMN;
	    tkfont = mePtr->tkfont;
	    if (tkfont == NULL) {
		tkfont = menuPtr->tkfont;
		fmPtr = &menuMetrics;
	    } else {
		Tk_GetFontMetrics(tkfont, &entryMetrics);
		fmPtr = &entryMetrics;
	    }
	
	    if ((mePtr->type == SEPARATOR_ENTRY)
		    || (mePtr->type == TEAROFF_ENTRY)) {
		mePtr->height = mePtr->width = 0;
		if (mePtr->type == SEPARATOR_ENTRY) {
		    lastSeparator = i;
		    rightWidth = 0;
		}
	    } else {
		
		GetMenuLabelGeometry(mePtr, tkfont, fmPtr,
			&width, &height);
		mePtr->height = height + 2 * menuPtr->activeBorderWidth + 10;
		mePtr->width = width;
		
		GetMenuIndicatorGeometry(menuPtr, mePtr,
			tkfont, fmPtr, &width, &height);
		mePtr->indicatorSpace = width;
		if (width > 0) {
		    mePtr->width += width;
		}
		mePtr->width += 2 * menuPtr->activeBorderWidth + 10;
		if (mePtr->width > maxEntryWidth)
		    maxEntryWidth = mePtr->width;
		if (mePtr->height > maxEntryHeight)
		    maxEntryHeight = mePtr->height;
		if (lastSeparator < menuPtr->numEntries) {
		    rightWidth += mePtr->width;
		}
		totalWidth += mePtr->width;

		if (mePtr->entryFlags & ENTRY_HELP_MENU) {
		    helpMenuIndex = i;
		}
	    }
	}      

	/* If width of "right" items is more than window forget it
	 * and just layout in multicolumns
	 */
	if (rightWidth >= maxWindowWidth) {
	    rightWidth = 0;
	    lastSeparator = menuPtr->numEntries;
	}

	/* If there is a help entry in the left portion we will not display 
	 * it there so allow room for it in the right portion
	 */
	if (helpMenuIndex >= 0 && helpMenuIndex < lastSeparator) {
	    rightWidth += menuPtr->entries[helpMenuIndex]->width;
	}

	maxWindowWidth -= rightWidth;
	
	for (i = 0; i < lastSeparator; i++) {
	    mePtr = menuPtr->entries[i];
	    mePtr->entryFlags &= ~ENTRY_LAST_COLUMN;
	    /*
	     * For every entry, we need to check to see whether or not we
	     * wrap. If we do wrap, then we have to adjust all of the previous
	     * entries' height and y position, because when we see them
	     * the first time, we don't know how big its neighbor might
	     * be.
	     */
	    if (i == helpMenuIndex) 
		continue;
	    /* We retain this contorted logic for now to simplify merges 
	     * with Tcl/Tk 
	     */
	    if (x + mePtr->width + menuPtr->borderWidth  > maxWindowWidth) {
		if (i == lastRowBreak) {
		    mePtr->y = y;
		    mePtr->x = x;
		    lastRowBreak++;
		    y += mePtr->height;
		    currentRowHeight = 0;
		} else {
		    x = menuPtr->borderWidth;
		    for (j = lastRowBreak; j < i; j++) {
			menuPtr->entries[j]->y = y + currentRowHeight
			        - menuPtr->entries[j]->height;
			menuPtr->entries[j]->x = x;
			x += menuPtr->entries[j]->width;
		    }
		    lastRowBreak = i;
		    y += currentRowHeight;
		    currentRowHeight = mePtr->height;
		}
		if (x > maxWidth) {
		    maxWidth = x;
		}
		x = menuPtr->borderWidth;
	    } else {
		x += mePtr->width;
		if (mePtr->height > currentRowHeight) {
		    currentRowHeight = mePtr->height;
		}
	    }
	}

	lastEntry = lastSeparator - 1;
	if (helpMenuIndex == lastEntry) {
	    lastEntry--;
	}
	if ((lastEntry >= 0) && (x + menuPtr->entries[lastEntry]->width
		+ menuPtr->borderWidth > maxWidth)) {
	    maxWidth = x + menuPtr->entries[lastEntry]->width
		    + menuPtr->borderWidth;
	}

	x = menuPtr->borderWidth;
	for (j = lastRowBreak; j < menuPtr->numEntries; j++) {
	    if (j == helpMenuIndex) {
		continue;
	    }
	    menuPtr->entries[j]->y = y + currentRowHeight
		    - menuPtr->entries[j]->height;
	    menuPtr->entries[j]->x = x;
	    x += menuPtr->entries[j]->width;
	}

	/* Set height as height of left portion */
	height = y + currentRowHeight + menuPtr->borderWidth;

	/* Now do the "right" entries (if any) - these only exist
	 * if they are known not to wrap
	 */
	maxWindowWidth += rightWidth;

	x = maxWindowWidth - menuPtr->borderWidth - rightWidth;
	y = menuPtr->borderWidth;
	currentRowHeight = 0;

	for (i = lastSeparator; i < menuPtr->numEntries; i++) {
	    if (i == helpMenuIndex) 
		continue;
	    mePtr = menuPtr->entries[i];
	    mePtr->entryFlags &= ~ENTRY_LAST_COLUMN;
	    mePtr->y = y;
	    mePtr->x = x;
	    x += mePtr->width;
	    if (mePtr->height > currentRowHeight) {
		currentRowHeight = mePtr->height;
	    }
	}    

	/* Finally if there is a help entry anywere draw that */

	if (helpMenuIndex >= 0) {
	    mePtr = menuPtr->entries[helpMenuIndex];
	    mePtr->entryFlags &= ~ENTRY_LAST_COLUMN;
	    mePtr->x = x;
	    mePtr->y = y;
	    if (mePtr->height > currentRowHeight) {
		currentRowHeight = mePtr->height;
	    }
	}

	if (y + currentRowHeight + menuPtr->borderWidth > height) {
	   height = y + currentRowHeight + menuPtr->borderWidth;
	}
    }
    width = Tk_Width(menuPtr->tkwin);

    /*
     * The X server doesn't like zero dimensions, so round up to at least
     * 1 (a zero-sized menu should never really occur, anyway).
     */

    if (width <= 0) {
	width = 1;
    }
    if (height <= 0) {
	height = 1;
    }
    menuPtr->totalWidth = maxWidth + rightWidth;
    menuPtr->totalHeight = height;
}

/*
 *----------------------------------------------------------------------
 *
 * DrawTearoffEntry --
 *
 *	This procedure draws the background part of a menu.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the menu in its
 *	current mode.
 *
 *----------------------------------------------------------------------
 */

static void
DrawTearoffEntry(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, y, width, height)
    TkMenu *menuPtr;			/* The menu we are drawing */
    TkMenuEntry *mePtr;			/* The entry we are drawing */
    Drawable d;				/* The drawable we are drawing into */
    GC gc;				/* The gc we are drawing with */
    Tk_Font tkfont;			/* The font we are drawing with */
    CONST Tk_FontMetrics *fmPtr;	/* The metrics we are drawing with */
    int x;
    int y;
    int width;
    int height;
{
    XPoint points[2];
    int margin, segmentWidth, maxX;

    if (menuPtr->menuType != MASTER_MENU) {
	return;
    }

    margin = (fmPtr->ascent + fmPtr->descent)/2;
    points[0].x = x;
    points[0].y = y + height/2;
    points[1].y = points[0].y;
    segmentWidth = 6;
    maxX  = width - 1;

    while (points[0].x < maxX) {
	points[1].x = points[0].x + segmentWidth;
	if (points[1].x > maxX) {
	    points[1].x = maxX;
	}
	Tk_Draw3DPolygon(menuPtr->tkwin, d, menuPtr->border, points, 2, 1,
		TK_RELIEF_RAISED);
	points[0].x += 2*segmentWidth;
    }
}

/*
 *--------------------------------------------------------------
 *
 * TkpInitializeMenuBindings --
 *
 *	For every interp, initializes the bindings for Windows
 *	menus. Does nothing on Mac or XWindows.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	C-level bindings are setup for the interp which will
 *	handle Alt-key sequences for menus without beeping
 *	or interfering with user-defined Alt-key bindings.
 *
 *--------------------------------------------------------------
 */

void
TkpInitializeMenuBindings(interp, bindingTable)
    Tcl_Interp *interp;		    /* The interpreter to set. */
    Tk_BindingTable bindingTable;   /* The table to add to. */
{
    /*
     * Nothing to do.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * SetHelpMenu --
 *
 *	Given a menu, check to see whether or not it is a help menu
 *	cascade in a menubar. If it is, the entry that points to
 *	this menu will be marked.
 *
 * RESULTS:
 *	None.
 *
 * Side effects:
 *	Will set the ENTRY_HELP_MENU flag appropriately.
 *
 *----------------------------------------------------------------------
 */

static void
SetHelpMenu(menuPtr)
     TkMenu *menuPtr;		/* The menu we are checking */
{
    TkMenuEntry *cascadeEntryPtr;

    for (cascadeEntryPtr = menuPtr->menuRefPtr->parentEntryPtr;
	    cascadeEntryPtr != NULL;
	    cascadeEntryPtr = cascadeEntryPtr->nextCascadePtr) {
	if ((cascadeEntryPtr->menuPtr->menuType == MENUBAR)
		&& (cascadeEntryPtr->menuPtr->masterMenuPtr->tkwin != NULL)
		&& (menuPtr->masterMenuPtr->tkwin != NULL)) {
	    TkMenu *masterMenuPtr = cascadeEntryPtr->menuPtr->masterMenuPtr;
	    char *helpMenuName = ckalloc(strlen(Tk_PathName(
		    masterMenuPtr->tkwin)) + strlen(".help") + 1);

	    strcpy(helpMenuName, Tk_PathName(masterMenuPtr->tkwin));
	    strcat(helpMenuName, ".help");
	    if (strcmp(helpMenuName,
		    Tk_PathName(menuPtr->masterMenuPtr->tkwin)) == 0) {
		cascadeEntryPtr->entryFlags |= ENTRY_HELP_MENU;
	    } else {
		cascadeEntryPtr->entryFlags &= ~ENTRY_HELP_MENU;
	    }
	    ckfree(helpMenuName);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkpDrawMenuEntry --
 *
 *	Draws the given menu entry at the given coordinates with the
 *	given attributes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	X Server commands are executed to display the menu entry.
 *
 *----------------------------------------------------------------------
 */

void
TkpDrawMenuEntry(mePtr, d, tkfont, menuMetricsPtr, x, y, width, height,
	strictMotif, drawArrow)
    TkMenuEntry *mePtr;		    /* The entry to draw */
    Drawable d;			    /* What to draw into */
    Tk_Font tkfont;		    /* Precalculated font for menu */
    CONST Tk_FontMetrics *menuMetricsPtr;
				    /* Precalculated metrics for menu */
    int x;			    /* X-coordinate of topleft of entry */
    int y;			    /* Y-coordinate of topleft of entry */
    int width;			    /* Width of the entry rectangle */
    int height;			    /* Height of the current rectangle */
    int strictMotif;		    /* Boolean flag */
    int drawArrow;		    /* Whether or not to draw the cascade
				     * arrow for cascade items. Only applies
				     * to Windows. */
{
    GC gc, indicatorGC;
    TkMenu *menuPtr = mePtr->menuPtr;
    Tk_3DBorder bgBorder, activeBorder;
    CONST Tk_FontMetrics *fmPtr;
    Tk_FontMetrics entryMetrics;
    int padY = (menuPtr->menuType == MENUBAR) ? 3 : 0;
    int adjustedY = y + padY;
    int adjustedHeight = height - 2 * padY;

    /*
     * Choose the gc for drawing the foreground part of the entry.
     */

    if ((mePtr->state == TK_STATE_ACTIVE)
	    && !strictMotif) {
	gc = mePtr->activeGC;
	if (gc == NULL) {
	    gc = menuPtr->activeGC;
	}
    } else {
    	TkMenuEntry *cascadeEntryPtr;
    	int parentDisabled = 0;
    	
    	for (cascadeEntryPtr = menuPtr->menuRefPtr->parentEntryPtr;
    		cascadeEntryPtr != NULL;
    		cascadeEntryPtr = cascadeEntryPtr->nextCascadePtr) {
    	    if (strcmp(LangString(cascadeEntryPtr->name),
    	    	    Tk_PathName(menuPtr->tkwin)) == 0) {
    	    	if (cascadeEntryPtr->state == TK_STATE_DISABLED) {
    	    	    parentDisabled = 1;
    	    	}
    	    	break;
    	    }
    	}

	if (((parentDisabled || (mePtr->state == TK_STATE_DISABLED)))
		&& (menuPtr->disabledFg != NULL)) {
	    gc = mePtr->disabledGC;
	    if (gc == NULL) {
		gc = menuPtr->disabledGC;
	    }
	} else {
	    gc = mePtr->textGC;
	    if (gc == NULL) {
		gc = menuPtr->textGC;
	    }
	}
    }
    indicatorGC = mePtr->indicatorGC;
    if (indicatorGC == NULL) {
	indicatorGC = menuPtr->indicatorGC;
    }
	
    bgBorder = mePtr->border;
    if (bgBorder == NULL) {
	bgBorder = menuPtr->border;
    }
    if (strictMotif) {
	activeBorder = bgBorder;
    } else {
	activeBorder = mePtr->activeBorder;
	if (activeBorder == NULL) {
	    activeBorder = menuPtr->activeBorder;
	}
    }

    if (mePtr->tkfont == NULL) {
	fmPtr = menuMetricsPtr;
    } else {
	tkfont = mePtr->tkfont;
	Tk_GetFontMetrics(tkfont, &entryMetrics);
	fmPtr = &entryMetrics;
    }

    /*
     * Need to draw the entire background, including padding. On Unix,
     * for menubars, we have to draw the rest of the entry taking
     * into account the padding.
     */

    DrawMenuEntryBackground(menuPtr, mePtr, d, activeBorder,
	    bgBorder, x, y, width, height);

    if (mePtr->type == SEPARATOR_ENTRY) {
	DrawMenuSeparator(menuPtr, mePtr, d, gc, tkfont,
		fmPtr, x, adjustedY, width, adjustedHeight);
    } else if (mePtr->type == TEAROFF_ENTRY) {
	DrawTearoffEntry(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, adjustedY,
		width, adjustedHeight);
    } else {
	DrawMenuEntryLabel(menuPtr, mePtr, d, gc, tkfont, fmPtr, x, adjustedY,
		width, adjustedHeight);
	DrawMenuEntryAccelerator(menuPtr, mePtr, d, gc, tkfont, fmPtr,
		activeBorder, x, adjustedY, width, adjustedHeight, drawArrow);
	if (!mePtr->hideMargin) {
	    DrawMenuEntryIndicator(menuPtr, mePtr, d, gc, indicatorGC, tkfont,
		    fmPtr, x, adjustedY, width, adjustedHeight);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * GetMenuLabelGeometry --
 *
 *	Figures out the size of the label portion of a menu item.
 *
 * Results:
 *	widthPtr and heightPtr are filled in with the correct geometry
 *	information.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
GetMenuLabelGeometry(mePtr, tkfont, fmPtr, widthPtr, heightPtr)
    TkMenuEntry *mePtr;			/* The entry we are computing */
    Tk_Font tkfont;			/* The precalculated font */
    CONST Tk_FontMetrics *fmPtr;	/* The precalculated metrics */
    int *widthPtr;			/* The resulting width of the label
					 * portion */
    int *heightPtr;			/* The resulting height of the label
					 * portion */
{
    TkMenu *menuPtr = mePtr->menuPtr;

    if (mePtr->image != NULL) {
    	Tk_SizeOfImage(mePtr->image, widthPtr, heightPtr);
    } else if (mePtr->bitmap != (Pixmap) NULL) {
    	Tk_SizeOfBitmap(menuPtr->display, mePtr->bitmap, widthPtr, heightPtr);
    } else {
    	*heightPtr = fmPtr->linespace;
    	
    	if (mePtr->label != NULL) {
    	    *widthPtr = Tk_TextWidth(tkfont, mePtr->label, mePtr->labelLength);
    	} else {
    	    *widthPtr = 0;
    	}
    }
    *heightPtr += 1;
}

/*
 *--------------------------------------------------------------
 *
 * TkpComputeStandardMenuGeometry --
 *
 *	This procedure is invoked to recompute the size and
 *	layout of a menu that is not a menubar clone.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Fields of menu entries are changed to reflect their
 *	current positions, and the size of the menu window
 *	itself may be changed.
 *
 *--------------------------------------------------------------
 */

void
TkpComputeStandardMenuGeometry(
    menuPtr)		/* Structure describing menu. */
    TkMenu *menuPtr;
{
    Tk_Font tkfont;
    Tk_FontMetrics menuMetrics, entryMetrics, *fmPtr;
    int x, y, height, width, indicatorSpace, labelWidth, accelWidth;
    int windowWidth, windowHeight, accelSpace;
    int i, j, lastColumnBreak = 0;
    TkMenuEntry *mePtr;

    if (menuPtr->tkwin == NULL) {
	return;
    }

    x = y = menuPtr->borderWidth;
    indicatorSpace = labelWidth = accelWidth = 0;
    windowHeight = windowWidth = 0;

    /*
     * On the Mac especially, getting font metrics can be quite slow,
     * so we want to do it intelligently. We are going to precalculate
     * them and pass them down to all of the measuring and drawing
     * routines. We will measure the font metrics of the menu once.
     * If an entry does not have its own font set, then we give
     * the geometry/drawing routines the menu's font and metrics.
     * If an entry has its own font, we will measure that font and
     * give all of the geometry/drawing the entry's font and metrics.
     */

    Tk_GetFontMetrics(menuPtr->tkfont, &menuMetrics);
    accelSpace = Tk_TextWidth(menuPtr->tkfont, "M", 1);

    for (i = 0; i < menuPtr->numEntries; i++) {
	mePtr = menuPtr->entries[i];
    	tkfont = mePtr->tkfont;
    	if (tkfont == NULL) {
    	    tkfont = menuPtr->tkfont;
    	    fmPtr = &menuMetrics;
    	} else {
    	    Tk_GetFontMetrics(tkfont, &entryMetrics);
    	    fmPtr = &entryMetrics;
    	}
    	
	if ((i > 0) && mePtr->columnBreak) {
	    if (accelWidth != 0) {
		labelWidth += accelSpace;
	    }
	    for (j = lastColumnBreak; j < i; j++) {
		menuPtr->entries[j]->indicatorSpace = indicatorSpace;
		menuPtr->entries[j]->labelWidth = labelWidth;
		menuPtr->entries[j]->width = indicatorSpace + labelWidth
			+ accelWidth + 2 * menuPtr->activeBorderWidth;
		menuPtr->entries[j]->x = x;
		menuPtr->entries[j]->entryFlags &= ~ENTRY_LAST_COLUMN;
	    }
	    x += indicatorSpace + labelWidth + accelWidth
		    + 2 * menuPtr->activeBorderWidth;
	    windowWidth = x;
	    indicatorSpace = labelWidth = accelWidth = 0;
	    lastColumnBreak = i;
	    y = menuPtr->borderWidth;
	}

	if (mePtr->type == SEPARATOR_ENTRY) {
	    GetMenuSeparatorGeometry(menuPtr, mePtr, tkfont,
	    	    fmPtr, &width, &height);
	    mePtr->height = height;
	} else if (mePtr->type == TEAROFF_ENTRY) {
	    GetTearoffEntryGeometry(menuPtr, mePtr, tkfont,
	    	    fmPtr, &width, &height);
	    mePtr->height = height;
	    labelWidth = width;
	} else {
	
	    /*
	     * For each entry, compute the height required by that
	     * particular entry, plus three widths:  the width of the
	     * label, the width to allow for an indicator to be displayed
	     * to the left of the label (if any), and the width of the
	     * accelerator to be displayed to the right of the label
	     * (if any).  These sizes depend, of course, on the type
	     * of the entry.
	     */
	
	    GetMenuLabelGeometry(mePtr, tkfont, fmPtr, &width,
	    	    &height);
	    mePtr->height = height;
	    if (!mePtr->hideMargin) {
		width += MENU_MARGIN_WIDTH;
	    }
	    if (width > labelWidth) {
	    	labelWidth = width;
	    }
	
	    GetMenuAccelGeometry(menuPtr, mePtr, tkfont,
		    fmPtr, &width, &height);
	    if (height > mePtr->height) {
	    	mePtr->height = height;
	    }
	    if (!mePtr->hideMargin) {
		width += MENU_MARGIN_WIDTH;
	    }
	    if (width > accelWidth) {
	    	accelWidth = width;
	    }

	    GetMenuIndicatorGeometry(menuPtr, mePtr, tkfont,
	    	    fmPtr, &width, &height);
	    if (height > mePtr->height) {
	    	mePtr->height = height;
	    }
	    if (!mePtr->hideMargin) {
		width += MENU_MARGIN_WIDTH;
	    }
	    if (width > indicatorSpace) {
	    	indicatorSpace = width;
	    }

	    mePtr->height += 2 * menuPtr->activeBorderWidth +
	    	    MENU_DIVIDER_HEIGHT;
    	}
        mePtr->y = y;
	y += mePtr->height;
	if (y > windowHeight) {
	    windowHeight = y;
	}
    }

    if (accelWidth != 0) {
	labelWidth += accelSpace;
    }
    for (j = lastColumnBreak; j < menuPtr->numEntries; j++) {
	menuPtr->entries[j]->indicatorSpace = indicatorSpace;
	menuPtr->entries[j]->labelWidth = labelWidth;
	menuPtr->entries[j]->width = indicatorSpace + labelWidth
		+ accelWidth + 2 * menuPtr->activeBorderWidth;
	menuPtr->entries[j]->x = x;
	menuPtr->entries[j]->entryFlags |= ENTRY_LAST_COLUMN;
    }
    windowWidth = x + indicatorSpace + labelWidth + accelWidth
	    + 2 * menuPtr->activeBorderWidth + 2 * menuPtr->borderWidth;


    windowHeight += menuPtr->borderWidth;

    /*
     * The X server doesn't like zero dimensions, so round up to at least
     * 1 (a zero-sized menu should never really occur, anyway).
     */

    if (windowWidth <= 0) {
	windowWidth = 1;
    }
    if (windowHeight <= 0) {
	windowHeight = 1;
    }
    menuPtr->totalWidth = windowWidth;
    menuPtr->totalHeight = windowHeight;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpMenuNotifyToplevelCreate --
 *
 *	This routine reconfigures the menu and the clones indicated by
 *	menuName becuase a toplevel has been created and any system
 *	menus need to be created. Not applicable to UNIX.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An idle handler is set up to do the reconfiguration.
 *
 *----------------------------------------------------------------------
 */

void
TkpMenuNotifyToplevelCreate(interp, menuName)
    Tcl_Interp *interp;			/* The interp the menu lives in. */
    char *menuName;			/* The name of the menu to
					 * reconfigure. */
{
    /*
     * Nothing to do.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * TkpMenuInit --
 *
 *	Does platform-specific initialization of menus.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkpMenuInit()
{
    /*
     * Nothing to do.
     */
}
