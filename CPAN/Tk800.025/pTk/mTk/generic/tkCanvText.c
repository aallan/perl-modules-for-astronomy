/*
 * tkCanvText.c --
 *
 *	This file implements text items for canvas widgets.
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkCanvText.c,v 1.1 2003/09/28 14:54:57 aa Exp $
 */

#include "tkPort.h"
#include "tkInt.h"
#include "tkCanvases.h"
#include "default.h"

/*
 * The structure below defines the record for each text item.
 */

typedef struct TextItem  {
    Tk_Item header;		/* Generic stuff that's the same for all
				 * types.  MUST BE FIRST IN STRUCTURE. */
    Tk_CanvasTextInfo *textInfoPtr;
				/* Pointer to a structure containing
				 * information about the selection and
				 * insertion cursor.  The structure is owned
				 * by (and shared with) the generic canvas
				 * code. */
    /*
     * Fields that are set by widget commands other than "configure".
     */

    double x, y;		/* Positioning point for text. */
    int insertPos;		/* Insertion cursor is displayed just to left
				 * of character with this index. */

    /*
     * Configuration settings that are updated by Tk_ConfigureWidget.
     */

    Tk_Anchor anchor;		/* Where to anchor text relative to (x,y). */
    Tk_Tile tile;		/* Tile for text. */
    Tk_Tile activeTile;		/* Tile for text if state is active. */
    Tk_Tile disabledTile;	/* Tile for text if state is disabled. */
    Tk_TSOffset tsoffset;
    XColor *color;		/* Color for text. */
    XColor *activeColor;	/* Color for text. */
    XColor *disabledColor;	/* Color for text. */
    Tk_Font tkfont;		/* Font for drawing text. */
    Tk_Justify justify;		/* Justification mode for text. */
    Pixmap stipple;		/* Stipple bitmap for text, or None. */
    Pixmap activeStipple;	/* Stipple bitmap for text, or None. */
    Pixmap disabledStipple;	/* Stipple bitmap for text, or None. */
    char *text;			/* Text for item (malloc-ed). */
    int width;			/* Width of lines for word-wrap, pixels.
				 * Zero means no word-wrap. */

    /*
     * Fields whose values are derived from the current values of the
     * configuration settings above.
     */

    int numChars;		/* Number of non-NULL characters in text. */
    Tk_TextLayout textLayout;	/* Cached text layout information. */
    int leftEdge;		/* Pixel location of the left edge of the
				 * text item; where the left border of the
				 * text layout is drawn. */
    int rightEdge;		/* Pixel just to right of right edge of
				 * area of text item.  Used for selecting up
				 * to end of line. */
    GC gc;			/* Graphics context for drawing text. */
    GC selTextGC;		/* Graphics context for selected text. */
    GC cursorOffGC;		/* If not None, this gives a graphics context
				 * to use to draw the insertion cursor when
				 * it's off.  Used if the selection and
				 * insertion cursor colors are the same.  */
} TextItem;

/*
 * Information used for parsing configuration specs:
 */

static Tk_CustomOption stateOption = {
    Tk_StateParseProc,
    Tk_StatePrintProc, (ClientData) 2
};
static Tk_CustomOption tagsOption = {
    Tk_CanvasTagsParseProc,
    Tk_CanvasTagsPrintProc, (ClientData) NULL
};
static Tk_CustomOption tileOption = {
    Tk_TileParseProc,
    Tk_TilePrintProc, (ClientData) NULL
};
static Tk_CustomOption offsetOption = {
    Tk_OffsetParseProc,
    Tk_OffsetPrintProc, (ClientData) (TK_OFFSET_RELATIVE)
};

static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_COLOR, "-activefill", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, activeColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BITMAP, "-activestipple", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, activeStipple), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-activetile", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, activeTile),
	TK_CONFIG_NULL_OK, &tileOption},
    {TK_CONFIG_ANCHOR, "-anchor", (char *) NULL, (char *) NULL,
	"center", Tk_Offset(TextItem, anchor),
	TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_COLOR, "-disabledfill", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, disabledColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BITMAP, "-disabledstipple", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, disabledStipple), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-disabledtile", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, disabledTile),
	TK_CONFIG_NULL_OK, &tileOption},
    {TK_CONFIG_COLOR, "-fill", (char *) NULL, (char *) NULL,
	"black", Tk_Offset(TextItem, color), TK_CONFIG_NULL_OK},
    {TK_CONFIG_FONT, "-font", (char *) NULL, (char *) NULL,
	DEF_CANVTEXT_FONT, Tk_Offset(TextItem, tkfont), 0},
    {TK_CONFIG_JUSTIFY, "-justify", (char *) NULL, (char *) NULL,
	"left", Tk_Offset(TextItem, justify),
	TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_CUSTOM, "-offset", (char *) NULL, (char *) NULL,
	"0 0", Tk_Offset(TextItem, tsoffset),
	TK_CONFIG_DONT_SET_DEFAULT, &offsetOption},
    {TK_CONFIG_CUSTOM, "-state", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(Tk_Item, state), TK_CONFIG_NULL_OK,
	&stateOption},
    {TK_CONFIG_BITMAP, "-stipple", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, stipple), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-tags", (char *) NULL, (char *) NULL,
	(char *) NULL, 0, TK_CONFIG_NULL_OK, &tagsOption},
    {TK_CONFIG_CUSTOM, "-tile", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(TextItem, tile),
	TK_CONFIG_NULL_OK, &tileOption},
    {TK_CONFIG_STRING, "-text", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TextItem, text), 0},
    {TK_CONFIG_CALLBACK, "-updatecommand", (char *) NULL, (char *) NULL,
	(char *) NULL, Tk_Offset(Tk_Item, updateCmd), TK_CONFIG_NULL_OK},
    {TK_CONFIG_PIXELS, "-width", (char *) NULL, (char *) NULL,
	"0", Tk_Offset(TextItem, width), TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_END, (char *) NULL, (char *) NULL, (char *) NULL,
	(char *) NULL, 0, 0}
};

/*
 * Prototypes for procedures defined in this file:
 */

static void		ComputeTextBbox _ANSI_ARGS_((Tk_Canvas canvas,
			    TextItem *textPtr));
static int		ConfigureText _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr, int argc,
			    char **argv, int flags));
static int		CreateText _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, struct Tk_Item *itemPtr,
			    int argc, char **argv));
static void		DeleteText _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, Display *display));
static void		DisplayCanvText _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, Display *display, Drawable dst,
			    int x, int y, int width, int height));
static int		GetSelText _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, int offset, char *buffer,
			    int maxBytes));
static int		GetTextIndex _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr,
			    Tcl_Obj *obj, int *indexPtr));
static void		ScaleText _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double originX, double originY,
			    double scaleX, double scaleY));
static void		SetTextCursor _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, int index));
static int		TextCoords _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr,
			    int argc, char **argv));
static void		TextDeleteChars _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, int first, int last));
static void		TextInsert _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, int beforeThis, Tcl_Obj *string));
static int		TextToArea _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double *rectPtr));
static double		TextToPoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double *pointPtr));
static int		TextToPostscript _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr, int prepass));
static void		TranslateText _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double deltaX, double deltaY));

/*
 * The structures below defines the rectangle and oval item types
 * by means of procedures that can be invoked by generic item code.
 */

Tk_ItemType tkTextType = {
    "text",				/* name */
    sizeof(TextItem),			/* itemSize */
    CreateText,				/* createProc */
    configSpecs,			/* configSpecs */
    ConfigureText,			/* configureProc */
    TextCoords,				/* coordProc */
    DeleteText,				/* deleteProc */
    DisplayCanvText,			/* displayProc */
    TK_ITEM_VISITOR_SUPPORT|TK_CONFIG_OBJS,/* flags */
    TextToPoint,			/* pointProc */
    TextToArea,				/* areaProc */
    TextToPostscript,			/* postscriptProc */
    ScaleText,				/* scaleProc */
    TranslateText,			/* translateProc */
    GetTextIndex,			/* indexProc */
    SetTextCursor,			/* icursorProc */
    GetSelText,				/* selectionProc */
    TextInsert,				/* insertProc */
    TextDeleteChars,			/* dTextProc */
    (Tk_ItemType *) NULL,		/* nextPtr */
    (Tk_ItemBboxProc *) ComputeTextBbox,/* bboxProc */
    Tk_Offset(Tk_VisitorType, visitText), /* acceptProc */
    (Tk_ItemGetCoordProc *) NULL,	/* getCoordProc */
    (Tk_ItemSetCoordProc *) NULL	/* setCoordProc */
};

/*
 *--------------------------------------------------------------
 *
 * CreateText --
 *
 *	This procedure is invoked to create a new text item
 *	in a canvas.
 *
 * Results:
 *	A standard Tcl return value.  If an error occurred in
 *	creating the item then an error message is left in
 *	interp->result;  in this case itemPtr is left uninitialized
 *	so it can be safely freed by the caller.
 *
 * Side effects:
 *	A new text item is created.
 *
 *--------------------------------------------------------------
 */

static int
CreateText(interp, canvas, itemPtr, argc, argv)
    Tcl_Interp *interp;			/* Interpreter for error reporting. */
    Tk_Canvas canvas;			/* Canvas to hold new item. */
    Tk_Item *itemPtr;			/* Record to hold new item;  header
					 * has been initialized by caller. */
    int argc;				/* Number of arguments in argv. */
    char **argv;			/* Arguments describing rectangle. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int i;

    if (argc==1) {
	i = 1;
    } else {
	char *arg = Tcl_GetStringFromObj(objv[1],NULL);
	if ((argc>1) && (arg[0] == '-')
		&& (arg[1] >= 'a') && (arg[1] <= 'z')) {
	    i = 1;
	} else {
	    i = 2;
	}
    }

    if (argc < i) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		Tk_PathName(Tk_CanvasTkwin(canvas)), " create ",
		itemPtr->typePtr->name, " x y ?options?\"", (char *) NULL);
	return TCL_ERROR;
    }

    /*
     * Carry out initialization that is needed in order to clean
     * up after errors during the the remainder of this procedure.
     */

    textPtr->textInfoPtr = Tk_CanvasGetTextInfo(canvas);

    textPtr->insertPos	= 0;

    textPtr->anchor	= TK_ANCHOR_CENTER;
    textPtr->tile = NULL;
    textPtr->activeTile = NULL;
    textPtr->disabledTile = NULL;
    textPtr->tsoffset.flags = 0;
    textPtr->tsoffset.xoffset = 0;
    textPtr->tsoffset.yoffset = 0;
    textPtr->color	= NULL;
    textPtr->activeColor = NULL;
    textPtr->disabledColor = NULL;
    textPtr->tkfont	= NULL;
    textPtr->justify	= TK_JUSTIFY_LEFT;
    textPtr->stipple	= None;
    textPtr->activeStipple = None;
    textPtr->disabledStipple = None;
    textPtr->text	= NULL;
    textPtr->width	= 0;

    textPtr->numChars	= 0;
    textPtr->textLayout = NULL;
    textPtr->leftEdge	= 0;
    textPtr->rightEdge	= 0;
    textPtr->gc		= None;
    textPtr->selTextGC	= None;
    textPtr->cursorOffGC = None;

    /*
     * Process the arguments to fill in the item record.
     */

    if ((TextCoords(interp, canvas, itemPtr, i, argv) != TCL_OK)) {
	goto error;
    }
    if (ConfigureText(interp, canvas, itemPtr, argc-i, argv+i, 0) == TCL_OK) {
	return TCL_OK;
    }

    error:
    DeleteText(canvas, itemPtr, Tk_Display(Tk_CanvasTkwin(canvas)));
    return TCL_ERROR;
}

/*
 *--------------------------------------------------------------
 *
 * TextCoords --
 *
 *	This procedure is invoked to process the "coords" widget
 *	command on text items.  See the user documentation for
 *	details on what it does.
 *
 * Results:
 *	Returns TCL_OK or TCL_ERROR, and sets interp->result.
 *
 * Side effects:
 *	The coordinates for the given item may be changed.
 *
 *--------------------------------------------------------------
 */

static int
TextCoords(interp, canvas, itemPtr, argc, argv)
    Tcl_Interp *interp;			/* Used for error reporting. */
    Tk_Canvas canvas;			/* Canvas containing item. */
    Tk_Item *itemPtr;			/* Item whose coordinates are to be
					 * read or modified. */
    int argc;				/* Number of coordinates supplied in
					 * argv. */
    char **argv;			/* Array of coordinates: x1, y1,
					 * x2, y2, ... */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    char x[TCL_DOUBLE_SPACE];

    if (argc == 0) {
	Tcl_Obj *obj = Tcl_NewObj();
	Tcl_Obj *subobj = Tcl_NewDoubleObj(textPtr->x);
	Tcl_ListObjAppendElement(interp, obj, subobj);
	subobj = Tcl_NewDoubleObj(textPtr->y);
	Tcl_ListObjAppendElement(interp, obj, subobj);
	Tcl_SetObjResult(interp, obj);
    } else if (argc < 3) {
	if (argc==1) {
	    if (Tcl_ListObjGetElements(interp, objv[0], &argc, &objv) != TCL_OK) {
		return TCL_ERROR;
	    } else if (argc != 2) {
		sprintf(x,"%d",argc);
		Tcl_AppendResult(interp, "wrong # coordinates: expected 2, got ",
		x, (char *) NULL);
		return TCL_ERROR;
	    }
	}
	if ((Tk_CanvasGetCoordFromObj(interp, canvas, objv[0], &textPtr->x) != TCL_OK)
		|| (Tk_CanvasGetCoordFromObj(interp, canvas, objv[1],
  		    &textPtr->y) != TCL_OK)) {
	    return TCL_ERROR;
	}
	ComputeTextBbox(canvas, textPtr);
    } else {
	sprintf(x,"%d",argc);
	Tcl_AppendResult(interp, "wrong # coordinates: expected 0 or 2, got ",
	x, (char *) NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ConfigureText --
 *
 *	This procedure is invoked to configure various aspects
 *	of a text item, such as its border and background colors.
 *
 * Results:
 *	A standard Tcl result code.  If an error occurs, then
 *	an error message is left in interp->result.
 *
 * Side effects:
 *	Configuration information, such as colors and stipple
 *	patterns, may be set for itemPtr.
 *
 *--------------------------------------------------------------
 */

static int
ConfigureText(interp, canvas, itemPtr, argc, argv, flags)
    Tcl_Interp *interp;		/* Interpreter for error reporting. */
    Tk_Canvas canvas;		/* Canvas containing itemPtr. */
    Tk_Item *itemPtr;		/* Rectangle item to reconfigure. */
    int argc;			/* Number of elements in argv.  */
    char **argv;		/* Arguments describing things to configure. */
    int flags;			/* Flags to pass to Tk_ConfigureWidget. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    XGCValues gcValues;
    GC newGC, newSelGC;
    unsigned long mask;
    Tk_Window tkwin;
    Tk_CanvasTextInfo *textInfoPtr = textPtr->textInfoPtr;
    XColor *selBgColorPtr;
    Tk_Tile tile;
    XColor *color;
    Pixmap stipple;
    Tk_State state;
    Pixmap pixmap;

    tkwin = Tk_CanvasTkwin(canvas);
    if (Tk_ConfigureWidget(interp, tkwin, configSpecs, argc, argv,
	    (char *) textPtr, flags|TK_CONFIG_OBJS) != TCL_OK) {
	return TCL_ERROR;
    }

    /*
     * A few of the options require additional processing, such as
     * graphics contexts.
     */

    state = Tk_GetItemState(canvas, itemPtr);

    if (textPtr->activeColor != NULL ||
	    textPtr->activeTile != NULL ||
	    textPtr->activeStipple != None) {
	itemPtr->redraw_flags |= TK_ITEM_STATE_DEPENDANT;
    } else {
	itemPtr->redraw_flags &= ~TK_ITEM_STATE_DEPENDANT;
    }

    tile = textPtr->tile;
    color = textPtr->color;
    stipple = textPtr->stipple;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (textPtr->activeTile!=NULL) {
	    tile = textPtr->activeTile;
	}
	if (textPtr->activeColor!=NULL) {
	    color = textPtr->activeColor;
	}
	if (textPtr->activeStipple!=None) {
	    stipple = textPtr->activeStipple;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (textPtr->disabledTile!=NULL) {
	    tile = textPtr->disabledTile;
	}
	if (textPtr->disabledColor!=NULL) {
	    color = textPtr->disabledColor;
	}
	if (textPtr->disabledStipple!=None) {
	    stipple = textPtr->disabledStipple;
	}
    }

    Tk_SetTileCanvasItem(textPtr->tile, canvas, (Tk_Item *) NULL);
    Tk_SetTileCanvasItem(textPtr->activeTile, canvas, (Tk_Item *) NULL);
    Tk_SetTileCanvasItem(textPtr->disabledTile, canvas, (Tk_Item *) NULL);
    Tk_SetTileCanvasItem(tile, canvas, itemPtr);

    newGC = newSelGC = None;
    if (textPtr->tkfont != NULL) {
	gcValues.font = Tk_FontId(textPtr->tkfont);
	mask = GCFont;
	if ((pixmap = Tk_PixmapOfTile(tile)) != None) {
	    gcValues.fill_style = FillTiled;
	    gcValues.tile = pixmap;
	    newGC = Tk_GetGC(tkwin, GCFont|GCTile|GCFillStyle, &gcValues);
	} else if (color != NULL) {
	    gcValues.foreground = color->pixel;
	    mask |= GCForeground;
	    if (stipple != None) {
		gcValues.stipple = stipple;
		gcValues.fill_style = FillStippled;
		mask |= GCStipple|GCFillStyle;
	    }
	    newGC = Tk_GetGC(tkwin, mask, &gcValues);
	}
	mask &= ~(GCTile|GCFillStyle|GCStipple);
	if (stipple != None) {
	    gcValues.stipple = stipple;
	    gcValues.fill_style = FillStippled;
	    mask |= GCStipple|GCFillStyle;
	}
	gcValues.foreground = textInfoPtr->selFgColorPtr->pixel;
	newSelGC = Tk_GetGC(tkwin, mask|GCForeground, &gcValues);
    }
    if (textPtr->gc != None) {
	Tk_FreeGC(Tk_Display(tkwin), textPtr->gc);
    }
    textPtr->gc = newGC;
    if (textPtr->selTextGC != None) {
	Tk_FreeGC(Tk_Display(tkwin), textPtr->selTextGC);
    }
    textPtr->selTextGC = newSelGC;

    selBgColorPtr = Tk_3DBorderColor(textInfoPtr->selBorder);
    if (Tk_3DBorderColor(textInfoPtr->insertBorder)->pixel
	    == selBgColorPtr->pixel) {
	if (selBgColorPtr->pixel == BlackPixelOfScreen(Tk_Screen(tkwin))) {
	    gcValues.foreground = WhitePixelOfScreen(Tk_Screen(tkwin));
	} else {
	    gcValues.foreground = BlackPixelOfScreen(Tk_Screen(tkwin));
	}
	newGC = Tk_GetGC(tkwin, GCForeground, &gcValues);
    } else {
	newGC = None;
    }
    if (textPtr->cursorOffGC != None) {
	Tk_FreeGC(Tk_Display(tkwin), textPtr->cursorOffGC);
    }
    textPtr->cursorOffGC = newGC;


    /*
     * If the text was changed, move the selection and insertion indices
     * to keep them inside the item.
     */

    textPtr->numChars = strlen(textPtr->text);
    if (textInfoPtr->selItemPtr == itemPtr) {
	if (textInfoPtr->selectFirst >= textPtr->numChars) {
	    textInfoPtr->selItemPtr = NULL;
	} else {
	    if (textInfoPtr->selectLast >= textPtr->numChars) {
		textInfoPtr->selectLast = textPtr->numChars-1;
	    }
	    if ((textInfoPtr->anchorItemPtr == itemPtr)
		    && (textInfoPtr->selectAnchor >= textPtr->numChars)) {
		textInfoPtr->selectAnchor = textPtr->numChars-1;
	    }
	}
    }
    if (textPtr->insertPos >= textPtr->numChars) {
	textPtr->insertPos = textPtr->numChars;
    }

    ComputeTextBbox(canvas, textPtr);
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * DeleteText --
 *
 *	This procedure is called to clean up the data structure
 *	associated with a text item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Resources associated with itemPtr are released.
 *
 *--------------------------------------------------------------
 */

static void
DeleteText(canvas, itemPtr, display)
    Tk_Canvas canvas;			/* Info about overall canvas widget. */
    Tk_Item *itemPtr;			/* Item that is being deleted. */
    Display *display;			/* Display containing window for
					 * canvas. */
{
    TextItem *textPtr = (TextItem *) itemPtr;

    if (textPtr->tile != NULL) {
	Tk_FreeTile(textPtr->tile);
    }
    if (textPtr->activeTile != NULL) {
	Tk_FreeTile(textPtr->activeTile);
    }
    if (textPtr->disabledTile != NULL) {
	Tk_FreeTile(textPtr->disabledTile);
    }
    if (textPtr->color != NULL) {
	Tk_FreeColor(textPtr->color);
    }
    if (textPtr->activeColor != NULL) {
	Tk_FreeColor(textPtr->activeColor);
    }
    if (textPtr->disabledColor != NULL) {
	Tk_FreeColor(textPtr->disabledColor);
    }
    Tk_FreeFont(textPtr->tkfont);
    if (textPtr->stipple != None) {
	Tk_FreeBitmap(display, textPtr->stipple);
    }
    if (textPtr->activeStipple != None) {
	Tk_FreeBitmap(display, textPtr->activeStipple);
    }
    if (textPtr->disabledStipple != None) {
	Tk_FreeBitmap(display, textPtr->disabledStipple);
    }
    if (textPtr->text != NULL) {
	ckfree(textPtr->text);
    }

    Tk_FreeTextLayout(textPtr->textLayout);
    if (textPtr->gc != None) {
	Tk_FreeGC(display, textPtr->gc);
    }
    if (textPtr->selTextGC != None) {
	Tk_FreeGC(display, textPtr->selTextGC);
    }
    if (textPtr->cursorOffGC != None) {
	Tk_FreeGC(display, textPtr->cursorOffGC);
    }
}

/*
 *--------------------------------------------------------------
 *
 * ComputeTextBbox --
 *
 *	This procedure is invoked to compute the bounding box of
 *	all the pixels that may be drawn as part of a text item.
 *	In addition, it recomputes all of the geometry information
 *	used to display a text item or check for mouse hits.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The fields x1, y1, x2, and y2 are updated in the header
 *	for itemPtr, and the linePtr structure is regenerated
 *	for itemPtr.
 *
 *--------------------------------------------------------------
 */

static void
ComputeTextBbox(canvas, textPtr)
    Tk_Canvas canvas;			/* Canvas that contains item. */
    TextItem *textPtr;			/* Item whose bbos is to be
					 * recomputed. */
{
    Tk_CanvasTextInfo *textInfoPtr;
    int leftX, topY, width, height, fudge;
    Tk_State state = Tk_GetItemState(canvas, &textPtr->header);

    Tk_FreeTextLayout(textPtr->textLayout);
    textPtr->textLayout = Tk_ComputeTextLayout(textPtr->tkfont,
	    textPtr->text, textPtr->numChars, textPtr->width,
	    textPtr->justify, 0, &width, &height);

    if (state == TK_STATE_HIDDEN || textPtr->color == NULL) {
	width = height = 0;
    }

    /*
     * Use overall geometry information to compute the top-left corner
     * of the bounding box for the text item.
     */

    leftX = (int) (textPtr->x + 0.5);
    topY = (int) (textPtr->y + 0.5);
    switch (textPtr->anchor) {
	case TK_ANCHOR_NW:
	case TK_ANCHOR_N:
	case TK_ANCHOR_NE:
	    break;

	case TK_ANCHOR_W:
	case TK_ANCHOR_CENTER:
	case TK_ANCHOR_E:
	    topY -= height / 2;
	    break;

	case TK_ANCHOR_SW:
	case TK_ANCHOR_S:
	case TK_ANCHOR_SE:
	    topY -= height;
	    break;
    }
    switch (textPtr->anchor) {
	case TK_ANCHOR_NW:
	case TK_ANCHOR_W:
	case TK_ANCHOR_SW:
	    break;

	case TK_ANCHOR_N:
	case TK_ANCHOR_CENTER:
	case TK_ANCHOR_S:
	    leftX -= width / 2;
	    break;

	case TK_ANCHOR_NE:
	case TK_ANCHOR_E:
	case TK_ANCHOR_SE:
	    leftX -= width;
	    break;
    }

    textPtr->leftEdge  = leftX;
    textPtr->rightEdge = leftX + width;

    /*
     * Last of all, update the bounding box for the item.  The item's
     * bounding box includes the bounding box of all its lines, plus
     * an extra fudge factor for the cursor border (which could
     * potentially be quite large).
     */

    textInfoPtr = textPtr->textInfoPtr;
    fudge = (textInfoPtr->insertWidth + 1) / 2;
    if (textInfoPtr->selBorderWidth > fudge) {
	fudge = textInfoPtr->selBorderWidth;
    }
    textPtr->header.x1 = leftX - fudge;
    textPtr->header.y1 = topY;
    textPtr->header.x2 = leftX + width + fudge;
    textPtr->header.y2 = topY + height;
}

/*
 *--------------------------------------------------------------
 *
 * DisplayCanvText --
 *
 *	This procedure is invoked to draw a text item in a given
 *	drawable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	ItemPtr is drawn in drawable using the transformation
 *	information in canvas.
 *
 *--------------------------------------------------------------
 */

static void
DisplayCanvText(canvas, itemPtr, display, drawable, x, y, width, height)
    Tk_Canvas canvas;			/* Canvas that contains item. */
    Tk_Item *itemPtr;			/* Item to be displayed. */
    Display *display;			/* Display on which to draw item. */
    Drawable drawable;			/* Pixmap or window in which to draw
					 * item. */
    int x, y, width, height;		/* Describes region of canvas that
					 * must be redisplayed (not used). */
{
    TextItem *textPtr;
    Tk_CanvasTextInfo *textInfoPtr;
    int selFirst, selLast;
    short drawableX, drawableY;
    Pixmap stipple;
    Tk_Tile tile;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);

    textPtr = (TextItem *) itemPtr;
    textInfoPtr = textPtr->textInfoPtr;

    stipple = textPtr->stipple;
    tile = textPtr->tile;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (textPtr->activeStipple!=None) {
	    stipple = textPtr->activeStipple;
	}
	if (textPtr->activeTile!=NULL) {
	    tile = textPtr->activeTile;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (textPtr->disabledStipple!=None) {
	    stipple = textPtr->disabledStipple;
	}
	if (textPtr->disabledTile!=NULL) {
	    tile = textPtr->disabledTile;
	}
    }

    if (textPtr->gc == None) {
	return;
    }

    /*
     * If we're stippling, then modify the stipple offset in the GC.  Be
     * sure to reset the offset when done, since the GC is supposed to be
     * read-only.
     */

    if ((tile != NULL) || (stipple != None)) {
	Tk_CanvasSetOffset(canvas, textPtr->gc, &textPtr->tsoffset);
    }

    selFirst = -1;
    selLast = 0;		/* lint. */
    if (textInfoPtr->selItemPtr == itemPtr) {
	selFirst = textInfoPtr->selectFirst;
	selLast = textInfoPtr->selectLast;
	if (selLast >= textPtr->numChars) {
	    selLast = textPtr->numChars - 1;
	}
	if ((selFirst >= 0) && (selFirst <= selLast)) {
	    /*
	     * Draw a special background under the selection.
	     */

	    int xFirst, yFirst, hFirst;
	    int xLast, yLast, wLast;

	    Tk_CharBbox(textPtr->textLayout, selFirst,
		    &xFirst, &yFirst, NULL, &hFirst);
	    Tk_CharBbox(textPtr->textLayout, selLast,
		    &xLast, &yLast, &wLast, NULL);

	    /*
	     * If the selection spans the end of this line, then display
	     * selection background all the way to the end of the line.
	     * However, for the last line we only want to display up to the
	     * last character, not the end of the line.
	     */

	    x = xFirst;
	    height = hFirst;
	    for (y = yFirst ; y <= yLast; y += height) {
		if (y == yLast) {
		    width = (xLast + wLast) - x;
		} else {	
		    width = textPtr->rightEdge - textPtr->leftEdge - x;
		}
		Tk_CanvasDrawableCoords(canvas,
			(double) (textPtr->leftEdge + x
				- textInfoPtr->selBorderWidth),
			(double) (textPtr->header.y1 + y),
			&drawableX, &drawableY);
		Tk_Fill3DRectangle(Tk_CanvasTkwin(canvas), drawable,
			textInfoPtr->selBorder, drawableX, drawableY,
			width + 2 * textInfoPtr->selBorderWidth,
			height, textInfoPtr->selBorderWidth, TK_RELIEF_RAISED);
		x = 0;
	    }
	}
    }

    /*
     * If the insertion point should be displayed, then draw a special
     * background for the cursor before drawing the text.  Note:  if
     * we're the cursor item but the cursor is turned off, then redraw
     * background over the area of the cursor.  This guarantees that
     * the selection won't make the cursor invisible on mono displays,
     * where both are drawn in the same color.
     */

    if ((textInfoPtr->focusItemPtr == itemPtr) && (textInfoPtr->gotFocus)) {
	if (Tk_CharBbox(textPtr->textLayout, textPtr->insertPos,
		&x, &y, NULL, &height)) {
	    Tk_CanvasDrawableCoords(canvas,
		    (double) (textPtr->leftEdge + x
			    - (textInfoPtr->insertWidth / 2)),
		    (double) (textPtr->header.y1 + y),
		    &drawableX, &drawableY);
	    if (textInfoPtr->cursorOn) {
		Tk_Fill3DRectangle(Tk_CanvasTkwin(canvas), drawable,
			textInfoPtr->insertBorder,
			drawableX, drawableY,
			textInfoPtr->insertWidth, height,
			textInfoPtr->insertBorderWidth, TK_RELIEF_RAISED);
	    } else if (textPtr->cursorOffGC != None) {
		/*
		 * Redraw the background over the area of the cursor,
		 * even though the cursor is turned off.  This
		 * guarantees that the selection won't make the cursor
		 * invisible on mono displays, where both may be drawn
		 * in the same color.
		 */

		XFillRectangle(display, drawable, textPtr->cursorOffGC,
			drawableX, drawableY,
			(unsigned) textInfoPtr->insertWidth,
			(unsigned) height);
	    }
	}
    }


    /*
     * Display the text in two pieces: draw the entire text item, then
     * draw the selected text on top of it.  The selected text then
     * will only need to be drawn if it has different attributes (such
     * as foreground color) than regular text.
     */

    Tk_CanvasDrawableCoords(canvas, (double) textPtr->leftEdge,
	    (double) textPtr->header.y1, &drawableX, &drawableY);
    Tk_DrawTextLayout(display, drawable, textPtr->gc, textPtr->textLayout,
	    drawableX, drawableY, 0, -1);

    if ((selFirst >= 0) && (textPtr->selTextGC != textPtr->gc)) {
	Tk_DrawTextLayout(display, drawable, textPtr->selTextGC,
	    textPtr->textLayout, drawableX, drawableY, selFirst,
	    selLast + 1);
    }

    if ((tile != NULL) ||(stipple != None)) {
	XSetTSOrigin(display, textPtr->gc, 0, 0);
    }
}

/*
 *--------------------------------------------------------------
 *
 * TextInsert --
 *
 *	Insert characters into a text item at a given position.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The text in the given item is modified.  The cursor and
 *	selection positions are also modified to reflect the
 *	insertion.
 *
 *--------------------------------------------------------------
 */

static void
TextInsert(canvas, itemPtr, beforeThis, ostring)
    Tk_Canvas canvas;		/* Canvas containing text item. */
    Tk_Item *itemPtr;		/* Text item to be modified. */
    int beforeThis;		/* Index of character before which text is
				 * to be inserted. */
    Tcl_Obj *ostring;		/* New characters to be inserted. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int length = 0;
    char *new;
    Tk_CanvasTextInfo *textInfoPtr = textPtr->textInfoPtr;

    char * string = Tcl_GetStringFromObj(ostring, &length);

    if (length == 0) {
	return;
    }
    if (beforeThis < 0) {
	beforeThis = 0;
    }
    if (beforeThis > textPtr->numChars) {
	beforeThis = textPtr->numChars;
    }

    new = (char *) ckalloc((unsigned) (textPtr->numChars + length + 1));
    strncpy(new, textPtr->text, (size_t) beforeThis);
    strcpy(new+beforeThis, string);
    strcpy(new+beforeThis+length, textPtr->text+beforeThis);
    ckfree(textPtr->text);
    textPtr->text = new;
    textPtr->numChars += length;

    /*
     * Inserting characters invalidates indices such as those for the
     * selection and cursor.  Update the indices appropriately.
     */

    if (textInfoPtr->selItemPtr == itemPtr) {
	if (textInfoPtr->selectFirst >= beforeThis) {
	    textInfoPtr->selectFirst += length;
	}
	if (textInfoPtr->selectLast >= beforeThis) {
	    textInfoPtr->selectLast += length;
	}
	if ((textInfoPtr->anchorItemPtr == itemPtr)
		&& (textInfoPtr->selectAnchor >= beforeThis)) {
	    textInfoPtr->selectAnchor += length;
	}
    }
    if (textPtr->insertPos >= beforeThis) {
	textPtr->insertPos += length;
    }
    ComputeTextBbox(canvas, textPtr);
}

/*
 *--------------------------------------------------------------
 *
 * TextDeleteChars --
 *
 *	Delete one or more characters from a text item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Characters between "first" and "last", inclusive, get
 *	deleted from itemPtr, and things like the selection
 *	position get updated.
 *
 *--------------------------------------------------------------
 */

static void
TextDeleteChars(canvas, itemPtr, first, last)
    Tk_Canvas canvas;		/* Canvas containing itemPtr. */
    Tk_Item *itemPtr;		/* Item in which to delete characters. */
    int first;			/* Index of first character to delete. */
    int last;			/* Index of last character to delete. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int count;
    char *new;
    Tk_CanvasTextInfo *textInfoPtr = textPtr->textInfoPtr;

    if (first < 0) {
	first = 0;
    }
    if (last >= textPtr->numChars) {
	last = textPtr->numChars-1;
    }
    if (first > last) {
	return;
    }
    count = last + 1 - first;

    new = (char *) ckalloc((unsigned) (textPtr->numChars + 1 - count));
    strncpy(new, textPtr->text, (size_t) first);
    strcpy(new+first, textPtr->text+last+1);
    ckfree(textPtr->text);
    textPtr->text = new;
    textPtr->numChars -= count;

    /*
     * Update indexes for the selection and cursor to reflect the
     * renumbering of the remaining characters.
     */

    if (textInfoPtr->selItemPtr == itemPtr) {
	if (textInfoPtr->selectFirst > first) {
	    textInfoPtr->selectFirst -= count;
	    if (textInfoPtr->selectFirst < first) {
		textInfoPtr->selectFirst = first;
	    }
	}
	if (textInfoPtr->selectLast >= first) {
	    textInfoPtr->selectLast -= count;
	    if (textInfoPtr->selectLast < (first-1)) {
		textInfoPtr->selectLast = (first-1);
	    }
	}
	if (textInfoPtr->selectFirst > textInfoPtr->selectLast) {
	    textInfoPtr->selItemPtr = NULL;
	}
	if ((textInfoPtr->anchorItemPtr == itemPtr)
		&& (textInfoPtr->selectAnchor > first)) {
	    textInfoPtr->selectAnchor -= count;
	    if (textInfoPtr->selectAnchor < first) {
		textInfoPtr->selectAnchor = first;
	    }
	}
    }
    if (textPtr->insertPos > first) {
	textPtr->insertPos -= count;
	if (textPtr->insertPos < first) {
	    textPtr->insertPos = first;
	}
    }
    ComputeTextBbox(canvas, textPtr);
    return;
}

/*
 *--------------------------------------------------------------
 *
 * TextToPoint --
 *
 *	Computes the distance from a given point to a given
 *	text item, in canvas units.
 *
 * Results:
 *	The return value is 0 if the point whose x and y coordinates
 *	are pointPtr[0] and pointPtr[1] is inside the text item.  If
 *	the point isn't inside the text item then the return value
 *	is the distance from the point to the text item.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static double
TextToPoint(canvas, itemPtr, pointPtr)
    Tk_Canvas canvas;		/* Canvas containing itemPtr. */
    Tk_Item *itemPtr;		/* Item to check against point. */
    double *pointPtr;		/* Pointer to x and y coordinates. */
{
    TextItem *textPtr;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);
    double value;

    textPtr = (TextItem *) itemPtr;
    value =  (double) Tk_DistanceToTextLayout(textPtr->textLayout,
	    (int) pointPtr[0] - textPtr->leftEdge,
	    (int) pointPtr[1] - textPtr->header.y1);

    if ((state == TK_STATE_HIDDEN) || (textPtr->color == NULL) ||
	    (textPtr->text == NULL) || (*textPtr->text == 0)) {
	value = 1.0e36;
    }
    return value;
}

/*
 *--------------------------------------------------------------
 *
 * TextToArea --
 *
 *	This procedure is called to determine whether an item
 *	lies entirely inside, entirely outside, or overlapping
 *	a given rectangle.
 *
 * Results:
 *	-1 is returned if the item is entirely outside the area
 *	given by rectPtr, 0 if it overlaps, and 1 if it is entirely
 *	inside the given area.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
TextToArea(canvas, itemPtr, rectPtr)
    Tk_Canvas canvas;		/* Canvas containing itemPtr. */
    Tk_Item *itemPtr;		/* Item to check against rectangle. */
    double *rectPtr;		/* Pointer to array of four coordinates
				 * (x1, y1, x2, y2) describing rectangular
				 * area.  */
{
    TextItem *textPtr;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);

    textPtr = (TextItem *) itemPtr;
    return Tk_IntersectTextLayout(textPtr->textLayout,
	    (int) (rectPtr[0] + 0.5) - textPtr->leftEdge,
	    (int) (rectPtr[1] + 0.5) - textPtr->header.y1,
	    (int) (rectPtr[2] - rectPtr[0] + 0.5),
	    (int) (rectPtr[3] - rectPtr[1] + 0.5));
}

/*
 *--------------------------------------------------------------
 *
 * ScaleText --
 *
 *	This procedure is invoked to rescale a text item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Scales the position of the text, but not the size
 *	of the font for the text.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static void
ScaleText(canvas, itemPtr, originX, originY, scaleX, scaleY)
    Tk_Canvas canvas;			/* Canvas containing rectangle. */
    Tk_Item *itemPtr;			/* Rectangle to be scaled. */
    double originX, originY;		/* Origin about which to scale rect. */
    double scaleX;			/* Amount to scale in X direction. */
    double scaleY;			/* Amount to scale in Y direction. */
{
    TextItem *textPtr = (TextItem *) itemPtr;

    textPtr->x = originX + scaleX*(textPtr->x - originX);
    textPtr->y = originY + scaleY*(textPtr->y - originY);
    ComputeTextBbox(canvas, textPtr);
    return;
}

/*
 *--------------------------------------------------------------
 *
 * TranslateText --
 *
 *	This procedure is called to move a text item by a
 *	given amount.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The position of the text item is offset by (xDelta, yDelta),
 *	and the bounding box is updated in the generic part of the
 *	item structure.
 *
 *--------------------------------------------------------------
 */

static void
TranslateText(canvas, itemPtr, deltaX, deltaY)
    Tk_Canvas canvas;			/* Canvas containing item. */
    Tk_Item *itemPtr;			/* Item that is being moved. */
    double deltaX, deltaY;		/* Amount by which item is to be
					 * moved. */
{
    TextItem *textPtr = (TextItem *) itemPtr;

    textPtr->x += deltaX;
    textPtr->y += deltaY;
    ComputeTextBbox(canvas, textPtr);
}

/*
 *--------------------------------------------------------------
 *
 * GetTextIndex --
 *
 *	Parse an index into a text item and return either its value
 *	or an error.
 *
 * Results:
 *	A standard Tcl result.  If all went well, then *indexPtr is
 *	filled in with the index (into itemPtr) corresponding to
 *	string.  Otherwise an error message is left in
 *	interp->result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
GetTextIndex(interp, canvas, itemPtr, obj, indexPtr)
    Tcl_Interp *interp;		/* Used for error reporting. */
    Tk_Canvas canvas;		/* Canvas containing item. */
    Tk_Item *itemPtr;		/* Item for which the index is being
				 * specified. */
    Tcl_Obj *obj;		/* Specification of a particular character
				 * in itemPtr's text. */
    int *indexPtr;		/* Where to store converted index. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int length;
    int c;
    TkCanvas *canvasPtr = (TkCanvas *) canvas;
    Tk_CanvasTextInfo *textInfoPtr = textPtr->textInfoPtr;
    char *string;
    int x, y;
    double dx,dy;
    char *end, *p;
    Tcl_Obj **objv;

    if (Tcl_ListObjGetElements(interp, obj, &c, &objv) == TCL_OK && c == 2
	&& Tcl_GetDoubleFromObj(interp, objv[0], &dx) == TCL_OK
	&& Tcl_GetDoubleFromObj(interp, objv[1], &dy) == TCL_OK) {
	goto doxy;
    }

    string = Tcl_GetStringFromObj(obj, &length);
    c = string[0];

    if ((c == 'e') && (strncmp(string, "end", length) == 0)) {
	*indexPtr = textPtr->numChars;
    } else if ((c == 'i') && (strncmp(string, "insert", length) == 0)) {
	*indexPtr = textPtr->insertPos;
    } else if ((c == 's') && (strncmp(string, "sel.first", length) == 0)
	    && (length >= 5)) {
	if (textInfoPtr->selItemPtr != itemPtr) {
	    Tcl_AppendResult(interp, "selection isn't in item", (char *) NULL);
	    return TCL_ERROR;
	}
	*indexPtr = textInfoPtr->selectFirst;
    } else if ((c == 's') && (strncmp(string, "sel.last", length) == 0)
	    && (length >= 5)) {
	if (textInfoPtr->selItemPtr != itemPtr) {
	    Tcl_AppendResult(interp, "selection isn't in item", (char *) NULL);
	    return TCL_ERROR;
	}
	*indexPtr = textInfoPtr->selectLast;
    } else if (c == '@') {
	p = string+1;
	dx = strtod(p, &end);
	if ((end == p) || (*end != ',')) {
	    goto badIndex;
	}
	p = end+1;
	dy = strtod(p, &end);
	if ((end == p) || (*end != 0)) {
	    goto badIndex;
	}
     doxy:
	x = (int) ((dx < 0) ? dx - 0.5 : dx + 0.5);
	y = (int) ((dy < 0) ? dy - 0.5 : dy + 0.5);
	*indexPtr = Tk_PointToChar(textPtr->textLayout,
		x + canvasPtr->scrollX1 - textPtr->leftEdge,
		y + canvasPtr->scrollY1 - textPtr->header.y1);
    } else if (Tcl_GetIntFromObj((Tcl_Interp *)NULL, obj, indexPtr) == TCL_OK) {
	if (*indexPtr < 0){
	    *indexPtr = 0;
	} else if (*indexPtr > textPtr->numChars) {
	    *indexPtr = textPtr->numChars;
	}
    } else {
	badIndex:
	Tcl_AppendResult(interp, "bad index \"", string, "\"",
		(char *) NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * SetTextCursor --
 *
 *	Set the position of the insertion cursor in this item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The cursor position will change.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static void
SetTextCursor(canvas, itemPtr, index)
    Tk_Canvas canvas;			/* Record describing canvas widget. */
    Tk_Item *itemPtr;			/* Text item in which cursor position
					 * is to be set. */
    int index;				/* Index of character just before which
					 * cursor is to be positioned. */
{
    TextItem *textPtr = (TextItem *) itemPtr;

    if (index < 0) {
	textPtr->insertPos = 0;
    } else  if (index > textPtr->numChars) {
	textPtr->insertPos = textPtr->numChars;
    } else {
	textPtr->insertPos = index;
    }
}

/*
 *--------------------------------------------------------------
 *
 * GetSelText --
 *
 *	This procedure is invoked to return the selected portion
 *	of a text item.  It is only called when this item has
 *	the selection.
 *
 * Results:
 *	The return value is the number of non-NULL bytes stored
 *	at buffer.  Buffer is filled (or partially filled) with a
 *	NULL-terminated string containing part or all of the selection,
 *	as given by offset and maxBytes.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
GetSelText(canvas, itemPtr, offset, buffer, maxBytes)
    Tk_Canvas canvas;			/* Canvas containing selection. */
    Tk_Item *itemPtr;			/* Text item containing selection. */
    int offset;				/* Offset within selection of first
					 * character to be returned. */
    char *buffer;			/* Location in which to place
					 * selection. */
    int maxBytes;			/* Maximum number of bytes to place
					 * at buffer, not including terminating
					 * NULL character. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int count;
    Tk_CanvasTextInfo *textInfoPtr = textPtr->textInfoPtr;

    count = textInfoPtr->selectLast + 1 - textInfoPtr->selectFirst - offset;
    if (textInfoPtr->selectLast == textPtr->numChars) {
	count -= 1;
    }
    if (count > maxBytes) {
	count = maxBytes;
    }
    if (count <= 0) {
	return 0;
    }
    strncpy(buffer, textPtr->text + textInfoPtr->selectFirst + offset,
	    (size_t) count);
    buffer[count] = '\0';
    return count;
}

/*
 *--------------------------------------------------------------
 *
 * TextToPostscript --
 *
 *	This procedure is called to generate Postscript for
 *	text items.
 *
 * Results:
 *	The return value is a standard Tcl result.  If an error
 *	occurs in generating Postscript then an error message is
 *	left in interp->result, replacing whatever used
 *	to be there.  If no error occurs, then Postscript for the
 *	item is appended to the result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
TextToPostscript(interp, canvas, itemPtr, prepass)
    Tcl_Interp *interp;			/* Leave Postscript or error message
					 * here. */
    Tk_Canvas canvas;			/* Information about overall canvas. */
    Tk_Item *itemPtr;			/* Item for which Postscript is
					 * wanted. */
    int prepass;			/* 1 means this is a prepass to
					 * collect font information;  0 means
					 * final Postscript is being created. */
{
    TextItem *textPtr = (TextItem *) itemPtr;
    int x, y;
    Tk_FontMetrics fm;
    char *justify;
    char buffer[500];
    XColor *color;
    Pixmap stipple;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);

    color = textPtr->color;
    stipple = textPtr->stipple;
    if (state == TK_STATE_HIDDEN || textPtr->color == NULL ||
	    textPtr->text == NULL || *textPtr->text == 0) {
	return TCL_OK;
    } else if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (textPtr->activeColor!=NULL) {
	    color = textPtr->activeColor;
	}
	if (textPtr->activeStipple!=None) {
	    stipple = textPtr->activeStipple;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (textPtr->disabledColor!=NULL) {
	    color = textPtr->disabledColor;
	}
	if (textPtr->disabledStipple!=None) {
	    stipple = textPtr->disabledStipple;
	}
    }

    if (Tk_CanvasPsFont(interp, canvas, textPtr->tkfont) != TCL_OK) {
	return TCL_ERROR;
    }
    if (prepass != 0) {
	return TCL_OK;
    }
    if (Tk_CanvasPsColor(interp, canvas, color) != TCL_OK) {
	return TCL_ERROR;
    }
    if (stipple != None) {
	Tcl_AppendResult(interp, "/StippleText {\n    ",
		(char *) NULL);
	Tk_CanvasPsStipple(interp, canvas, stipple);
	Tcl_AppendResult(interp, "} bind def\n", (char *) NULL);
    }

    sprintf(buffer, "%.15g %.15g [\n", textPtr->x,
	    Tk_CanvasPsY(canvas, textPtr->y));
    Tcl_AppendResult(interp, buffer, (char *) NULL);

    Tk_TextLayoutToPostscript(interp, textPtr->textLayout);

    x = 0;  y = 0;  justify = NULL;	/* lint. */
    switch (textPtr->anchor) {
	case TK_ANCHOR_NW:	x = 0; y = 0;	break;
	case TK_ANCHOR_N:	x = 1; y = 0;	break;
	case TK_ANCHOR_NE:	x = 2; y = 0;	break;
	case TK_ANCHOR_E:	x = 2; y = 1;	break;
	case TK_ANCHOR_SE:	x = 2; y = 2;	break;
	case TK_ANCHOR_S:	x = 1; y = 2;	break;
	case TK_ANCHOR_SW:	x = 0; y = 2;	break;
	case TK_ANCHOR_W:	x = 0; y = 1;	break;
	case TK_ANCHOR_CENTER:	x = 1; y = 1;	break;
    }
    switch (textPtr->justify) {
        case TK_JUSTIFY_LEFT:	justify = "0";	break;
	case TK_JUSTIFY_CENTER: justify = "0.5";break;
	case TK_JUSTIFY_RIGHT:  justify = "1";	break;
    }

    Tk_GetFontMetrics(textPtr->tkfont, &fm);
    sprintf(buffer, "] %d %g %g %s %s DrawText\n",
	    fm.linespace, x / -2.0, y / 2.0, justify,
	    ((stipple == None) ? "false" : "true"));
    Tcl_AppendResult(interp, buffer, (char *) NULL);

    return TCL_OK;
}
