/*
 * tkEntry.c --
 *
 *	This module implements entry widgets for the Tk
 *	toolkit.  An entry displays a string and allows
 *	the string to be edited.
 *
 * Copyright (c) 1990-1994 The Regents of the University of California.
 * Copyright (c) 1994-1996 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkEntry.c,v 1.1 2003/09/28 14:54:57 aa Exp $
 */

#include "tkInt.h"
#include "tkVMacro.h"
#include "default.h"

#define ENTRY_VALIDATE

/*
 * A data structure of the following type is kept for each entry
 * widget managed by this file:
 */

typedef struct {
    Tk_Window tkwin;		/* Window that embodies the entry. NULL
				 * means that the window has been destroyed
				 * but the data structures haven't yet been
				 * cleaned up.*/
    Display *display;		/* Display containing widget.  Used, among
				 * other things, so that resources can be
				 * freed even after tkwin has gone away. */
    Tcl_Interp *interp;		/* Interpreter associated with entry. */
    Tcl_Command widgetCmd;	/* Token for entry's widget command. */

    /*
     * Fields that are set by widget commands other than "configure".
     */

    char *string;		/* Pointer to storage for string;
				 * NULL-terminated;  malloc-ed. */
    int insertPos;		/* Index of character before which next
				 * typed character will be inserted. */

    /*
     * Information about what's selected, if any.
     */

    int selectFirst;		/* Index of first selected character (-1 means
				 * nothing selected. */
    int selectLast;		/* Index of last selected character (-1 means
				 * nothing selected. */
    int selectAnchor;		/* Fixed end of selection (i.e. "select to"
				 * operation will use this as one end of the
				 * selection). */

    /*
     * Information for scanning:
     */

    int scanMarkX;		/* X-position at which scan started (e.g.
				 * button was pressed here). */
    int scanMarkIndex;		/* Index of character that was at left of
				 * window when scan started. */

    /*
     * Configuration settings that are updated by Tk_ConfigureWidget.
     */

    Tk_3DBorder normalBorder;	/* Used for drawing border around whole
				 * window, plus used for background. */
    int borderWidth;		/* Width of 3-D border around window. */
    Tk_Cursor cursor;		/* Current cursor for window, or None. */
    int exportSelection;	/* Non-zero means tie internal entry selection
				 * to X selection. */
    Tk_Font tkfont;		/* Information about text font, or NULL. */
    XColor *fgColorPtr;		/* Text color in normal mode. */
    XColor *highlightBgColorPtr;/* Color for drawing traversal highlight
				 * area when highlight is off. */
    XColor *highlightColorPtr;	/* Color for drawing traversal highlight. */
    int highlightWidth;		/* Width in pixels of highlight to draw
				 * around widget when it has the focus.
				 * <= 0 means don't draw a highlight. */
    Tk_3DBorder insertBorder;	/* Used to draw vertical bar for insertion
				 * cursor. */
    int insertBorderWidth;	/* Width of 3-D border around insert cursor. */
    int insertOffTime;		/* Number of milliseconds cursor should spend
				 * in "off" state for each blink. */
    int insertOnTime;		/* Number of milliseconds cursor should spend
				 * in "on" state for each blink. */
    int insertWidth;		/* Total width of insert cursor. */
    Tk_Justify justify;		/* Justification to use for text within
				 * window. */
    int relief;			/* 3-D effect: TK_RELIEF_RAISED, etc. */
    Tk_3DBorder selBorder;	/* Border and background for selected
				 * characters. */
    int selBorderWidth;		/* Width of border around selection. */
    XColor *selFgColorPtr;	/* Foreground color for selected text. */
    char *showChar;		/* Value of -show option.  If non-NULL, first
				 * character is used for displaying all
				 * characters in entry.  Malloc'ed. */
    Tk_State state;		/* Normal or disabled.  Entry is read-only
				 * when disabled. */
    Var textVarName;		/* Name of variable (malloc'ed) or NULL.
				 * If non-NULL, entry's string tracks the
				 * contents of this variable and vice versa. */
    char *takeFocus;		/* Value of -takefocus option;  not used in
				 * the C code, but used by keyboard traversal
				 * scripts.  Malloc'ed, but may be NULL. */
    int prefWidth;		/* Desired width of window, measured in
				 * average characters. */
    LangCallback *scrollCmd;	/* Command prefix for communicating with
				 * scrollbar(s).  Malloc'ed.  NULL means
				 * no command to issue. */

    /*
     * Fields whose values are derived from the current values of the
     * configuration settings above.
     */

    int numChars;		/* Number of non-NULL characters in
				 * string (may be 0). */
    char *displayString;	/* If non-NULL, points to string with same
				 * length as string but whose characters
				 * are all equal to showChar.  Malloc'ed. */
    int inset;			/* Number of pixels on the left and right
				 * sides that are taken up by XPAD, borderWidth
				 * (if any), and highlightWidth (if any). */
    Tk_TextLayout textLayout;	/* Cached text layout information. */
    int layoutX, layoutY;	/* Origin for layout. */
    int leftIndex;		/* Index of left-most character visible in
				 * window. */
    int leftX;			/* X position at which character at leftIndex
				 * is drawn (varies depending on justify). */
    Tcl_TimerToken insertBlinkHandler;
				/* Timer handler used to blink cursor on and
				 * off. */
    GC textGC;			/* For drawing normal text. */
    GC selTextGC;		/* For drawing selected text. */
    GC highlightGC;		/* For drawing traversal highlight. */
    int avgWidth;		/* Width of average character. */
    int flags;			/* Miscellaneous flags;  see below for
				 * definitions. */
    Tk_Tile tile, disabledTile, fgTile;
    GC tileGC;
    Tk_TSOffset tsoffset;
#ifdef ENTRY_VALIDATE
    LangCallback *validateCmd;  /* Command prefix to use when invoking
				 * validate command.  NULL means don't
				 * invoke commands.  Malloc'ed. */
    int validate;               /* Non-zero means try to validate */
    LangCallback *invalidCmd;	/* Command called when a validation returns 0
				 * (successfully fails), defaults to {}. */
#endif /* ENTRY_VALIDATE */
} Entry;

/*
 * Assigned bits of "flags" fields of Entry structures, and what those
 * bits mean:
 *
 * REDRAW_PENDING:		Non-zero means a DoWhenIdle handler has
 *				already been queued to redisplay the entry.
 * BORDER_NEEDED:		Non-zero means 3-D border must be redrawn
 *				around window during redisplay.  Normally
 *				only text portion needs to be redrawn.
 * CURSOR_ON:			Non-zero means insert cursor is displayed at
 *				present.  0 means it isn't displayed.
 * GOT_FOCUS:			Non-zero means this window has the input
 *				focus.
 * UPDATE_SCROLLBAR:		Non-zero means scrollbar should be updated
 *				during next redisplay operation.
 * GOT_SELECTION:		Non-zero means we've claimed the selection.
 * VALIDATING:                  Non-zero means we are in a validateCmd
 * VALIDATE_VAR:                Non-zero means we are attempting to validate
 *                              the entry's textvariable with validateCmd
 * VALIDATE_ABORT:              Non-zero if validatecommand signals an abort
 *                              for current procedure and make no changes */

#define REDRAW_PENDING		1
#define BORDER_NEEDED		2
#define CURSOR_ON		4
#define GOT_FOCUS		8
#define UPDATE_SCROLLBAR	0x10
#define GOT_SELECTION		0x20
#ifdef ENTRY_VALIDATE
#define VALIDATING              0x40
#define VALIDATE_VAR            0x80
#define VALIDATE_ABORT          0x100
#endif /* ENTRY_VALIDATE */

/*
 * The following macro defines how many extra pixels to leave on each
 * side of the text in the entry.
 */

#define XPAD 1
#define YPAD 1

#ifdef ENTRY_VALIDATE
/*
 * Definitions for validate values:
 */

#define VALIDATE_NONE		0
#define VALIDATE_ALL		1
#define VALIDATE_KEY		2
#define VALIDATE_FOCUS		3
#define VALIDATE_FOCUSIN	4
#define VALIDATE_FOCUSOUT	5

#define DEF_ENTRY_VALIDATE	VALIDATE_NONE

static int	ValidateParseProc _ANSI_ARGS_((ClientData clientData,
		    Tcl_Interp *interp, Tk_Window tkwin,
		    Arg value, char *entry, int offset));
static Arg	ValidatePrintProc _ANSI_ARGS_((ClientData clientData,
		    Tk_Window tkwin, char *entry, int offset,
		    Tcl_FreeProc **freeProcPtr));

static Tk_CustomOption validateOption = {
	ValidateParseProc,
	ValidatePrintProc,
	(ClientData) NULL};
#endif /* ENTRY_VALIDATE */

/*
 * Custom options for handling "-state" , "-tile" and "-offset"
 */

static Tk_CustomOption stateOption = {
    Tk_StateParseProc,
    Tk_StatePrintProc,
    (ClientData) NULL	/* only "normal" and "disabled" */
};

static Tk_CustomOption tileOption = {
    Tk_TileParseProc,
    Tk_TilePrintProc,
    (ClientData) NULL
};

static Tk_CustomOption offsetOption = {
    Tk_OffsetParseProc,
    Tk_OffsetPrintProc,
    (ClientData) NULL
};

/*
 * Information used for argv parsing.
 */

static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_BORDER, "-background", "background", "Background",
	DEF_ENTRY_BG_COLOR, Tk_Offset(Entry, normalBorder),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_BORDER, "-background", "background", "Background",
	DEF_ENTRY_BG_MONO, Tk_Offset(Entry, normalBorder),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_SYNONYM, "-bd", "borderWidth", (char *) NULL,
	(char *) NULL, 0, 0},
    {TK_CONFIG_SYNONYM, "-bg", "background", (char *) NULL,
	(char *) NULL, 0, 0},
    {TK_CONFIG_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
	DEF_ENTRY_BORDER_WIDTH, Tk_Offset(Entry, borderWidth), 0},
    {TK_CONFIG_ACTIVE_CURSOR, "-cursor", "cursor", "Cursor",
	DEF_ENTRY_CURSOR, Tk_Offset(Entry, cursor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-disabledtile", "disabledTile", "Tile", (char *) NULL,
	Tk_Offset(Entry, disabledTile),TK_CONFIG_DONT_SET_DEFAULT, &tileOption},
    {TK_CONFIG_BOOLEAN, "-exportselection", "exportSelection",
	"ExportSelection", DEF_ENTRY_EXPORT_SELECTION,
	Tk_Offset(Entry, exportSelection), 0},
    {TK_CONFIG_SYNONYM, "-fg", "foreground", (char *) NULL,
	(char *) NULL, 0, 0},
    {TK_CONFIG_FONT, "-font", "font", "Font",
	DEF_ENTRY_FONT, Tk_Offset(Entry, tkfont), 0},
    {TK_CONFIG_COLOR, "-foreground", "foreground", "Foreground",
	DEF_ENTRY_FG, Tk_Offset(Entry, fgColorPtr), 0},
    {TK_CONFIG_SYNONYM, "-fgtile", "foregroundTile", (char *) NULL,
	(char *) NULL, 0, 0},
    {TK_CONFIG_CUSTOM, "-foregroundtile", "foregroundTile", "Tile", (char *) NULL,
	Tk_Offset(Entry, fgTile),TK_CONFIG_DONT_SET_DEFAULT, &tileOption},
    {TK_CONFIG_COLOR, "-highlightbackground", "highlightBackground",
	"HighlightBackground", DEF_ENTRY_HIGHLIGHT_BG,
	Tk_Offset(Entry, highlightBgColorPtr), 0},
    {TK_CONFIG_COLOR, "-highlightcolor", "highlightColor", "HighlightColor",
	DEF_ENTRY_HIGHLIGHT, Tk_Offset(Entry, highlightColorPtr), 0},
    {TK_CONFIG_PIXELS, "-highlightthickness", "highlightThickness",
	"HighlightThickness",
	DEF_ENTRY_HIGHLIGHT_WIDTH, Tk_Offset(Entry, highlightWidth), 0},
    {TK_CONFIG_BORDER, "-insertbackground", "insertBackground", "Foreground",
	DEF_ENTRY_INSERT_BG, Tk_Offset(Entry, insertBorder), 0},
    {TK_CONFIG_PIXELS, "-insertborderwidth", "insertBorderWidth", "BorderWidth",
	DEF_ENTRY_INSERT_BD_COLOR, Tk_Offset(Entry, insertBorderWidth),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_PIXELS, "-insertborderwidth", "insertBorderWidth", "BorderWidth",
	DEF_ENTRY_INSERT_BD_MONO, Tk_Offset(Entry, insertBorderWidth),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_INT, "-insertofftime", "insertOffTime", "OffTime",
	DEF_ENTRY_INSERT_OFF_TIME, Tk_Offset(Entry, insertOffTime), 0},
    {TK_CONFIG_INT, "-insertontime", "insertOnTime", "OnTime",
	DEF_ENTRY_INSERT_ON_TIME, Tk_Offset(Entry, insertOnTime), 0},
    {TK_CONFIG_PIXELS, "-insertwidth", "insertWidth", "InsertWidth",
	DEF_ENTRY_INSERT_WIDTH, Tk_Offset(Entry, insertWidth), 0},
#ifdef ENTRY_VALIDATE
    {TK_CONFIG_CALLBACK, "-invalidcommand", "invalidCommand", "InvalidCommand",
	(char *) NULL, Tk_Offset(Entry, invalidCmd), TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_SYNONYM, "-invcmd", "invalidCommand", (char *) NULL,
	(char *) NULL, 0, 0},
#endif /* ENTRY_VALIDATE */
    {TK_CONFIG_JUSTIFY, "-justify", "justify", "Justify",
	DEF_ENTRY_JUSTIFY, Tk_Offset(Entry, justify), 0},
    {TK_CONFIG_CUSTOM, "-offset", "offset", "Offset", "0 0",
	Tk_Offset(Entry, tsoffset),TK_CONFIG_DONT_SET_DEFAULT, &offsetOption},
    {TK_CONFIG_RELIEF, "-relief", "relief", "Relief",
	DEF_ENTRY_RELIEF, Tk_Offset(Entry, relief), 0},
    {TK_CONFIG_BORDER, "-selectbackground", "selectBackground", "Foreground",
	DEF_ENTRY_SELECT_COLOR, Tk_Offset(Entry, selBorder),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_BORDER, "-selectbackground", "selectBackground", "Foreground",
	DEF_ENTRY_SELECT_MONO, Tk_Offset(Entry, selBorder),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_PIXELS, "-selectborderwidth", "selectBorderWidth", "BorderWidth",
	DEF_ENTRY_SELECT_BD_COLOR, Tk_Offset(Entry, selBorderWidth),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_PIXELS, "-selectborderwidth", "selectBorderWidth", "BorderWidth",
	DEF_ENTRY_SELECT_BD_MONO, Tk_Offset(Entry, selBorderWidth),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_COLOR, "-selectforeground", "selectForeground", "Background",
	DEF_ENTRY_SELECT_FG_COLOR, Tk_Offset(Entry, selFgColorPtr),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_COLOR, "-selectforeground", "selectForeground", "Background",
	DEF_ENTRY_SELECT_FG_MONO, Tk_Offset(Entry, selFgColorPtr),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_STRING, "-show", "show", "Show",
	DEF_ENTRY_SHOW, Tk_Offset(Entry, showChar), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-state", "state", "State",
	DEF_ENTRY_STATE, Tk_Offset(Entry, state), 0, &stateOption},
    {TK_CONFIG_STRING, "-takefocus", "takeFocus", "TakeFocus",
	DEF_ENTRY_TAKE_FOCUS, Tk_Offset(Entry, takeFocus), TK_CONFIG_NULL_OK},
    {TK_CONFIG_SCALARVAR, "-textvariable", "textVariable", "Variable",
	DEF_ENTRY_TEXT_VARIABLE, Tk_Offset(Entry, textVarName),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-tile", "tile", "Tile", (char *) NULL,
	Tk_Offset(Entry, tile),TK_CONFIG_DONT_SET_DEFAULT, &tileOption},
#ifdef ENTRY_VALIDATE
    {TK_CONFIG_CUSTOM, "-validate", "validate", "Validate",
       DEF_ENTRY_VALIDATE, Tk_Offset(Entry, validate),
       TK_CONFIG_DONT_SET_DEFAULT, &validateOption},
    {TK_CONFIG_CALLBACK, "-validatecommand", "validateCommand", "ValidateCommand",
       (char *) NULL, Tk_Offset(Entry, validateCmd),
       TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_SYNONYM, "-vcmd", "validateCommand", (char *) NULL,
	(char *) NULL, 0, 0},
#endif /* ENTRY_VALIDATE */
    {TK_CONFIG_INT, "-width", "width", "Width",
	DEF_ENTRY_WIDTH, Tk_Offset(Entry, prefWidth), 0},
    {TK_CONFIG_CALLBACK, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
	DEF_ENTRY_SCROLL_COMMAND, Tk_Offset(Entry, scrollCmd),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_END, (char *) NULL, (char *) NULL, (char *) NULL,
	(char *) NULL, 0, 0}
};

/*
 * Flags for GetEntryIndex procedure:
 */

#define ZERO_OK			1
#define LAST_PLUS_ONE_OK	2

/*
 * Forward declarations for procedures defined later in this file:
 */

static int		ConfigureEntry _ANSI_ARGS_((Tcl_Interp *interp,
			    Entry *entryPtr, int argc, char **argv,
			    int flags));
static void		DeleteChars _ANSI_ARGS_((Entry *entryPtr, int index,
			    int count));
static void		DestroyEntry _ANSI_ARGS_((char *memPtr));
static void		DisplayEntry _ANSI_ARGS_((ClientData clientData));
static void		EntryBlinkProc _ANSI_ARGS_((ClientData clientData));
static void		EntryCmdDeletedProc _ANSI_ARGS_((
			    ClientData clientData));
static void		EntryComputeGeometry _ANSI_ARGS_((Entry *entryPtr));
static void		EntryEventProc _ANSI_ARGS_((ClientData clientData,
			    XEvent *eventPtr));
static void		EntryFocusProc _ANSI_ARGS_ ((Entry *entryPtr,
			    int gotFocus));
static int		EntryFetchSelection _ANSI_ARGS_((ClientData clientData,
			    int offset, char *buffer, int maxBytes));
static void		EntryLostSelection _ANSI_ARGS_((
			    ClientData clientData));
static void		EventuallyRedraw _ANSI_ARGS_((Entry *entryPtr));
static void		EntryScanTo _ANSI_ARGS_((Entry *entryPtr, int y));
static void		EntrySetValue _ANSI_ARGS_((Entry *entryPtr,
			    char *value));
static void		EntrySelectTo _ANSI_ARGS_((
			    Entry *entryPtr, int index));
static char *		EntryTextVarProc _ANSI_ARGS_((ClientData clientData,
			    Tcl_Interp *interp, Var name1, char *name2,
			    int flags));
static void		EntryUpdateScrollbar _ANSI_ARGS_((Entry *entryPtr));
#ifdef ENTRY_VALIDATE
static int		EntryValidate _ANSI_ARGS_((Entry *entryPtr,
			    LangCallback *cmd,char *string));
static int		EntryValidateChange _ANSI_ARGS_((Entry *entryPtr,
			    char *string, char *new, int index, int type));
static void		ExpandPercents _ANSI_ARGS_((Entry *entryPtr,
			    char *before, char *add, char *new, int index,
			    int type, Tcl_DString *dsPtr));
#endif /* ENTRY_VALIDATE */
static void		EntryValueChanged _ANSI_ARGS_((Entry *entryPtr));
static void		EntryVisibleRange _ANSI_ARGS_((Entry *entryPtr,
			    double *firstPtr, double *lastPtr));
static int		EntryWidgetCmd _ANSI_ARGS_((ClientData clientData,
			    Tcl_Interp *interp, int argc, char **argv));
static void		EntryWorldChanged _ANSI_ARGS_((
			    ClientData instanceData));
static int		GetEntryIndex _ANSI_ARGS_((Tcl_Interp *interp,
			    Entry *entryPtr, Arg arg, int *indexPtr));
static void		InsertChars _ANSI_ARGS_((Entry *entryPtr, int index,
			    char *string));
static void		TileChangedProc _ANSI_ARGS_((ClientData clientData,
			    Tk_Tile tile, Tk_Item *itemPtr));

/*
 * The structure below defines entry class behavior by means of procedures
 * that can be invoked from generic window code.
 */

static TkClassProcs entryClass = {
    NULL,			/* createProc. */
    EntryWorldChanged,		/* geometryProc. */
    NULL			/* modalProc. */
};


/*
 *--------------------------------------------------------------
 *
 * Tk_EntryCmd --
 *
 *	This procedure is invoked to process the "entry" Tcl
 *	command.  See the user documentation for details on what
 *	it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *--------------------------------------------------------------
 */

int
Tk_EntryCmd(clientData, interp, argc, argv)
    ClientData clientData;	/* Main window associated with
				 * interpreter. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    char **argv;		/* Argument strings. */
{
    Tk_Window tkwin = (Tk_Window) clientData;
    register Entry *entryPtr;
    Tk_Window new;

    if (argc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " pathName ?options?\"", (char *) NULL);
	return TCL_ERROR;
    }

    new = Tk_CreateWindowFromPath(interp, tkwin, argv[1], (char *) NULL);
    if (new == NULL) {
	return TCL_ERROR;
    }

    /*
     * Initialize the fields of the structure that won't be initialized
     * by ConfigureEntry, or that ConfigureEntry requires to be
     * initialized already (e.g. resource pointers).
     */

    entryPtr = (Entry *) ckalloc(sizeof(Entry));
    entryPtr->tkwin = new;
    entryPtr->display = Tk_Display(new);
    entryPtr->interp = interp;
    entryPtr->widgetCmd = Tcl_CreateCommand(interp,
	    Tk_PathName(entryPtr->tkwin), EntryWidgetCmd,
	    (ClientData) entryPtr, EntryCmdDeletedProc);
    entryPtr->string = (char *) ckalloc(1);
    entryPtr->string[0] = '\0';
    entryPtr->insertPos = 0;
    entryPtr->selectFirst = -1;
    entryPtr->selectLast = -1;
    entryPtr->selectAnchor = 0;
    entryPtr->scanMarkX = 0;
    entryPtr->scanMarkIndex = 0;

    entryPtr->normalBorder = NULL;
    entryPtr->borderWidth = 0;
    entryPtr->cursor = None;
    entryPtr->exportSelection = 1;
    entryPtr->tkfont = NULL;
    entryPtr->fgColorPtr = NULL;
    entryPtr->highlightBgColorPtr = NULL;
    entryPtr->highlightColorPtr = NULL;
    entryPtr->highlightWidth = 0;
    entryPtr->insertBorder = NULL;
    entryPtr->insertBorderWidth = 0;
    entryPtr->insertOffTime = 0;
    entryPtr->insertOnTime = 0;
    entryPtr->insertWidth = 0;
    entryPtr->justify = TK_JUSTIFY_LEFT;
    entryPtr->relief = TK_RELIEF_FLAT;
    entryPtr->selBorder = NULL;
    entryPtr->selBorderWidth = 0;
    entryPtr->selFgColorPtr = NULL;
    entryPtr->showChar = NULL;
    entryPtr->state = TK_STATE_NORMAL;
    entryPtr->textVarName = NULL;
    entryPtr->takeFocus = NULL;
    entryPtr->prefWidth = 0;
    entryPtr->scrollCmd = NULL;

    entryPtr->numChars = 0;
    entryPtr->displayString = NULL;
    entryPtr->inset = XPAD;
    entryPtr->textLayout = NULL;
    entryPtr->layoutX = 0;
    entryPtr->layoutY = 0;
    entryPtr->leftIndex = 0;
    entryPtr->leftX = 0;
    entryPtr->insertBlinkHandler = (Tcl_TimerToken) NULL;
    entryPtr->textGC = None;
    entryPtr->selTextGC = None;
    entryPtr->highlightGC = None;
    entryPtr->avgWidth = 1;
    entryPtr->flags = 0;
    entryPtr->tile = NULL;
    entryPtr->disabledTile = NULL;
    entryPtr->fgTile = NULL;
    entryPtr->tileGC = NULL;
    entryPtr->tsoffset.flags = 0;
    entryPtr->tsoffset.xoffset = 0;
    entryPtr->tsoffset.yoffset = 0;
#ifdef ENTRY_VALIDATE
    entryPtr->validateCmd = NULL;
    entryPtr->validate = VALIDATE_NONE;
    entryPtr->invalidCmd = NULL;
#endif /* ENTRY_VALIDATE */

    TkClassOption(entryPtr->tkwin, "Entry",&argc,&argv);
    TkSetClassProcs(entryPtr->tkwin, &entryClass, (ClientData) entryPtr);
    Tk_CreateEventHandler(entryPtr->tkwin,
	    ExposureMask|StructureNotifyMask|FocusChangeMask,
	    EntryEventProc, (ClientData) entryPtr);
    Tk_CreateSelHandler(entryPtr->tkwin, XA_PRIMARY, XA_STRING,
	    EntryFetchSelection, (ClientData) entryPtr, XA_STRING);
    if (ConfigureEntry(interp, entryPtr, argc-2, argv+2, 0) != TCL_OK) {
	goto error;
    }

    interp->result = Tk_PathName(entryPtr->tkwin);
    return TCL_OK;

    error:
    Tk_DestroyWindow(entryPtr->tkwin);
    return TCL_ERROR;
}

/*
 *--------------------------------------------------------------
 *
 * EntryWidgetCmd --
 *
 *	This procedure is invoked to process the Tcl command
 *	that corresponds to a widget managed by this module.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *--------------------------------------------------------------
 */

static int
EntryWidgetCmd(clientData, interp, argc, argv)
    ClientData clientData;		/* Information about entry widget. */
    Tcl_Interp *interp;			/* Current interpreter. */
    int argc;				/* Number of arguments. */
    char **argv;			/* Argument strings. */
{
    register Entry *entryPtr = (Entry *) clientData;
    int result = TCL_OK;
    size_t length;
    int c;

    if (argc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " option ?arg arg ...?\"", (char *) NULL);
	return TCL_ERROR;
    }
    Tcl_Preserve((ClientData) entryPtr);
    c = argv[1][0];
    length = strlen(argv[1]);
    if ((c == 'b') && (strncmp(argv[1], "bbox", length) == 0)) {
	int index;
	int x, y, width, height;

	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " bbox index\"",
		    (char *) NULL);
	    goto error;
	}
	if (GetEntryIndex(interp, entryPtr, objv[2], &index) != TCL_OK) {
	    goto error;
	}
	if ((index == entryPtr->numChars) && (index > 0)) {
	    index--;
	}
	Tk_CharBbox(entryPtr->textLayout, index, &x, &y, &width, &height);
	sprintf(interp->result, "%d %d %d %d",
		x + entryPtr->layoutX, y + entryPtr->layoutY, width, height);
    } else if ((c == 'c') && (strncmp(argv[1], "cget", length) == 0)
	    && (length >= 2)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " cget option\"",
		    (char *) NULL);
	    goto error;
	}
	result = Tk_ConfigureValue(interp, entryPtr->tkwin, configSpecs,
		(char *) entryPtr, argv[2], 0);
    } else if ((c == 'c') && (strncmp(argv[1], "configure", length) == 0)
	    && (length >= 2)) {
	if (argc == 2) {
	    result = Tk_ConfigureInfo(interp, entryPtr->tkwin, configSpecs,
		    (char *) entryPtr, (char *) NULL, 0);
	} else if (argc == 3) {
	    result = Tk_ConfigureInfo(interp, entryPtr->tkwin, configSpecs,
		    (char *) entryPtr, argv[2], 0);
	} else {
	    result = ConfigureEntry(interp, entryPtr, argc-2, argv+2,
		    TK_CONFIG_ARGV_ONLY);
	}
    } else if ((c == 'd') && (strncmp(argv[1], "delete", length) == 0)) {
	int first, last;

	if ((argc < 3) || (argc > 4)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " delete firstIndex ?lastIndex?\"",
		    (char *) NULL);
	    goto error;
	}
	if (GetEntryIndex(interp, entryPtr, objv[2], &first) != TCL_OK) {
	    goto error;
	}
	if (argc == 3) {
	    last = first+1;
	} else {
	    if (GetEntryIndex(interp, entryPtr, objv[3], &last) != TCL_OK) {
		goto error;
	    }
	}
	if ((last >= first) && (entryPtr->state == TK_STATE_NORMAL)) {
	    DeleteChars(entryPtr, first, last-first);
	}
    } else if ((c == 'g') && (strncmp(argv[1], "get", length) == 0)) {
	if (argc != 2) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " get\"", (char *) NULL);
	    goto error;
	}
	interp->result = entryPtr->string;
    } else if ((c == 'i') && (strncmp(argv[1], "icursor", length) == 0)
	    && (length >= 2)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " icursor pos\"",
		    (char *) NULL);
	    goto error;
	}
	if (GetEntryIndex(interp, entryPtr, objv[2], &entryPtr->insertPos)
		!= TCL_OK) {
	    goto error;
	}
	EventuallyRedraw(entryPtr);
    } else if ((c == 'i') && (strncmp(argv[1], "index", length) == 0)
	    && (length >= 3)) {
	int index;

	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " index string\"", (char *) NULL);
	    goto error;
	}
	if (GetEntryIndex(interp, entryPtr, objv[2], &index) != TCL_OK) {
	    goto error;
	}
	sprintf(interp->result, "%d", index);
    } else if ((c == 'i') && (strncmp(argv[1], "insert", length) == 0)
	    && (length >= 3)) {
	int index;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " insert index text\"",
		    (char *) NULL);
	    goto error;
	}
	if (GetEntryIndex(interp, entryPtr, objv[2], &index) != TCL_OK) {
	    goto error;
	}
	if (entryPtr->state == TK_STATE_NORMAL) {
	    InsertChars(entryPtr, index, argv[3]);
	}
    } else if ((c == 's') && (length >= 2)
	    && (strncmp(argv[1], "scan", length) == 0)) {
	int x;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " scan mark|dragto x\"", (char *) NULL);
	    goto error;
	}
	if (Tcl_GetInt(interp, argv[3], &x) != TCL_OK) {
	    goto error;
	}
	if ((argv[2][0] == 'm')
		&& (strncmp(argv[2], "mark", strlen(argv[2])) == 0)) {
	    entryPtr->scanMarkX = x;
	    entryPtr->scanMarkIndex = entryPtr->leftIndex;
	} else if ((argv[2][0] == 'd')
		&& (strncmp(argv[2], "dragto", strlen(argv[2])) == 0)) {
	    EntryScanTo(entryPtr, x);
	} else {
	    Tcl_AppendResult(interp, "bad scan option \"", argv[2],
		    "\": must be mark or dragto", (char *) NULL);
	    goto error;
	}
    } else if ((c == 's') && (length >= 2)
	    && (strncmp(argv[1], "selection", length) == 0)) {
	int index, index2;

	if (argc < 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " select option ?index?\"", (char *) NULL);
	    goto error;
	}
	length = strlen(argv[2]);
	c = argv[2][0];
	if ((c == 'c') && (strncmp(argv[2], "clear", length) == 0)) {
	    if (argc != 3) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection clear\"", (char *) NULL);
		goto error;
	    }
	    if (entryPtr->selectFirst != -1) {
		entryPtr->selectFirst = entryPtr->selectLast = -1;
		EventuallyRedraw(entryPtr);
	    }
	    goto done;
	} else if ((c == 'p') && (strncmp(argv[2], "present", length) == 0)) {
	    if (argc != 3) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection present\"", (char *) NULL);
		goto error;
	    }
	    if (entryPtr->selectFirst == -1) {
		interp->result = "0";
	    } else {
		interp->result = "1";
	    }
	    goto done;
	}
	if (argc >= 4) {
	    if (GetEntryIndex(interp, entryPtr, objv[3], &index) != TCL_OK) {
		goto error;
	    }
	}
	if ((c == 'a') && (strncmp(argv[2], "adjust", length) == 0)) {
	    if (argc != 4) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection adjust index\"",
			(char *) NULL);
		goto error;
	    }
	    if (entryPtr->selectFirst >= 0) {
		int half1, half2;

		half1 = (entryPtr->selectFirst + entryPtr->selectLast)/2;
		half2 = (entryPtr->selectFirst + entryPtr->selectLast + 1)/2;
		if (index < half1) {
		    entryPtr->selectAnchor = entryPtr->selectLast;
		} else if (index > half2) {
		    entryPtr->selectAnchor = entryPtr->selectFirst;
		} else {
		    /*
		     * We're at about the halfway point in the selection;
		     * just keep the existing anchor.
		     */
		}
	    }
	    EntrySelectTo(entryPtr, index);
	} else if ((c == 'f') && (strncmp(argv[2], "from", length) == 0)) {
	    if (argc != 4) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection from index\"",
			(char *) NULL);
		goto error;
	    }
	    entryPtr->selectAnchor = index;
	} else if ((c == 'r') && (strncmp(argv[2], "range", length) == 0)) {
	    if (argc != 5) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection range start end\"",
			(char *) NULL);
		goto error;
	    }
	    if (GetEntryIndex(interp, entryPtr, objv[4], &index2) != TCL_OK) {
		goto error;
	    }
	    if (index >= index2) {
		entryPtr->selectFirst = entryPtr->selectLast = -1;
	    } else {
		entryPtr->selectFirst = index;
		entryPtr->selectLast = index2;
	    }
	    if (!(entryPtr->flags & GOT_SELECTION)
		    && (entryPtr->exportSelection)) {
		Tk_OwnSelection(entryPtr->tkwin, XA_PRIMARY,
			EntryLostSelection, (ClientData) entryPtr);
		entryPtr->flags |= GOT_SELECTION;
	    }
	    EventuallyRedraw(entryPtr);
	} else if ((c == 't') && (strncmp(argv[2], "to", length) == 0)) {
	    if (argc != 4) {
		Tcl_AppendResult(interp, "wrong # args: should be \"",
			argv[0], " selection to index\"",
			(char *) NULL);
		goto error;
	    }
	    EntrySelectTo(entryPtr, index);
	} else {
	    Tcl_AppendResult(interp, "bad selection option \"", argv[2],
		    "\": must be adjust, clear, from, present, range, or to",
		    (char *) NULL);
	    goto error;
	}
#ifdef ENTRY_VALIDATE
    } else if ((c == 'v') && (strncmp(argv[1], "validate", length) == 0)) {
	int code, x;
	if (argc != 2) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    argv[0], " validate\"", (char *) NULL);
	    goto error;
	}
	x = entryPtr->validate;
	entryPtr->validate = VALIDATE_ALL;
	code = EntryValidateChange(entryPtr, (char *) NULL,
				   entryPtr->string, -1, -1);
	if (entryPtr->validate) {
	    entryPtr->validate = x;
	}
	sprintf(interp->result, "%d", (code == TCL_OK) ? 1 : 0);
#endif /* ENTRY_VALIDATE */
    } else if ((c == 'x') && (strncmp(argv[1], "xview", length) == 0)) {
	int index, type, count, charsPerPage;
	double fraction, first, last;

	if (argc == 2) {
	    EntryVisibleRange(entryPtr, &first, &last);
	    sprintf(interp->result, "%g %g", first, last);
	    goto done;
	} else if (argc == 3) {
	    if (GetEntryIndex(interp, entryPtr, objv[2], &index) != TCL_OK) {
		goto error;
	    }
	} else {
	    type = Tk_GetScrollInfo(interp, argc, argv, &fraction, &count);
	    index = entryPtr->leftIndex;
	    switch (type) {
		case TK_SCROLL_ERROR:
		    goto error;
		case TK_SCROLL_MOVETO:
		    index = (int) ((fraction * entryPtr->numChars) + 0.5);
		    break;
		case TK_SCROLL_PAGES:
		    charsPerPage = ((Tk_Width(entryPtr->tkwin)
			    - 2*entryPtr->inset) / entryPtr->avgWidth) - 2;
		    if (charsPerPage < 1) {
			charsPerPage = 1;
		    }
		    index += charsPerPage*count;
		    break;
		case TK_SCROLL_UNITS:
		    index += count;
		    break;
	    }
	}
	if (index >= entryPtr->numChars) {
	    index = entryPtr->numChars-1;
	}
	if (index < 0) {
	    index = 0;
	}
	entryPtr->leftIndex = index;
	entryPtr->flags |= UPDATE_SCROLLBAR;
	EntryComputeGeometry(entryPtr);
	EventuallyRedraw(entryPtr);
    } else {
	Tcl_AppendResult(interp, "bad option \"", argv[1],
		"\": must be bbox, cget, configure, delete, get, ",
#ifdef ENTRY_VALIDATE
		"icursor, index, insert, scan, selection, validate, or xview",
#else
		"icursor, index, insert, scan, selection, or xview",
#endif /* ENTRY_VALIDATE */
		(char *) NULL);
	goto error;
    }
    done:
    Tcl_Release((ClientData) entryPtr);
    return result;

    error:
    Tcl_Release((ClientData) entryPtr);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * DestroyEntry --
 *
 *	This procedure is invoked by Tcl_EventuallyFree or Tcl_Release
 *	to clean up the internal structure of an entry at a safe time
 *	(when no-one is using it anymore).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Everything associated with the entry is freed up.
 *
 *----------------------------------------------------------------------
 */

static void
DestroyEntry(memPtr)
    char *memPtr;		/* Info about entry widget. */
{
    register Entry *entryPtr = (Entry *) memPtr;

    /*
     * Free up all the stuff that requires special handling, then
     * let Tk_FreeOptions handle all the standard option-related
     * stuff.
     */

    ckfree(entryPtr->string);
    if (entryPtr->textVarName != NULL) {
	Tcl_UntraceVar(entryPtr->interp, entryPtr->textVarName,
		TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		EntryTextVarProc, (ClientData) entryPtr);
    }
    if (entryPtr->textGC != None) {
	Tk_FreeGC(entryPtr->display, entryPtr->textGC);
    }
    if (entryPtr->selTextGC != None) {
	Tk_FreeGC(entryPtr->display, entryPtr->selTextGC);
    }
    if (entryPtr->tile != NULL) {
	Tk_FreeTile(entryPtr->tile);
    }
    if (entryPtr->disabledTile != NULL) {
	Tk_FreeTile(entryPtr->disabledTile);
    }
    if (entryPtr->fgTile != NULL) {
	Tk_FreeTile(entryPtr->fgTile);
    }
    if (entryPtr->tileGC != NULL) {
	Tk_FreeGC(entryPtr->display, entryPtr->tileGC);
    }
    Tcl_DeleteTimerHandler(entryPtr->insertBlinkHandler);
    if (entryPtr->displayString != NULL) {
	ckfree(entryPtr->displayString);
    }
    Tk_FreeTextLayout(entryPtr->textLayout);
    Tk_FreeOptions(configSpecs, (char *) entryPtr, entryPtr->display, 0);
    ckfree((char *) entryPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TileChangedProc
 *
 * Results:
 *	None.
 *
 *----------------------------------------------------------------------
 */
/* ARGSUSED */
static void
TileChangedProc(clientData, tile, itemPtr)
    ClientData clientData;
    Tk_Tile tile;
    Tk_Item *itemPtr;			/* Not used */
{
    register Entry *entryPtr = (Entry *) clientData;

    ConfigureEntry(entryPtr->interp, entryPtr, 0, NULL, 0);
}

/*
 *----------------------------------------------------------------------
 *
 * ConfigureEntry --
 *
 *	This procedure is called to process an argv/argc list, plus
 *	the Tk option database, in order to configure (or reconfigure)
 *	an entry widget.
 *
 * Results:
 *	The return value is a standard Tcl result.  If TCL_ERROR is
 *	returned, then interp->result contains an error message.
 *
 * Side effects:
 *	Configuration information, such as colors, border width,
 *	etc. get set for entryPtr;  old resources get freed,
 *	if there were any.
 *
 *----------------------------------------------------------------------
 */

static int
ConfigureEntry(interp, entryPtr, argc, argv, flags)
    Tcl_Interp *interp;		/* Used for error reporting. */
    register Entry *entryPtr;	/* Information about widget;  may or may
				 * not already have values for some fields. */
    int argc;			/* Number of valid entries in argv. */
    char **argv;		/* Arguments. */
    int flags;			/* Flags to pass to Tk_ConfigureWidget. */
{
    int oldExport;

    /*
     * Eliminate any existing trace on a variable monitored by the entry.
     */

    if (entryPtr->textVarName != NULL) {
	Tcl_UntraceVar(interp, entryPtr->textVarName,
		TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		EntryTextVarProc, (ClientData) entryPtr);
    }

    oldExport = entryPtr->exportSelection;
    if (Tk_ConfigureWidget(interp, entryPtr->tkwin, configSpecs,
	    argc, argv, (char *) entryPtr, flags) != TCL_OK) {
	return TCL_ERROR;
    }

    /*
     * If the entry is tied to the value of a variable, then set up
     * a trace on the variable's value, create the variable if it doesn't
     * exist, and set the entry's value from the variable's value.
     */

    if (entryPtr->textVarName != NULL) {
	Arg value;

	value = Tcl_GetVar(interp, entryPtr->textVarName, TCL_GLOBAL_ONLY);
	if (value == NULL) {
	    EntryValueChanged(entryPtr);
	} else {
	    EntrySetValue(entryPtr, LangString(value));
	}
	Tcl_TraceVar(interp, entryPtr->textVarName,
		TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		EntryTextVarProc, (ClientData) entryPtr);
    }

    /*
     * A few other options also need special processing, such as parsing
     * the geometry and setting the background from a 3-D border.
     */

    if (entryPtr->insertWidth <= 0) {
	entryPtr->insertWidth = 2;
    }
    if (entryPtr->insertBorderWidth > entryPtr->insertWidth/2) {
	entryPtr->insertBorderWidth = entryPtr->insertWidth/2;
    }

    /*
     * Restart the cursor timing sequence in case the on-time or off-time
     * just changed.
     */

    if (entryPtr->flags & GOT_FOCUS) {
	EntryFocusProc(entryPtr, 1);
    }

    /*
     * Claim the selection if we've suddenly started exporting it.
     */

    if (entryPtr->exportSelection && (!oldExport)
	    && (entryPtr->selectFirst != -1)
	    && !(entryPtr->flags & GOT_SELECTION)) {
	Tk_OwnSelection(entryPtr->tkwin, XA_PRIMARY, EntryLostSelection,
		(ClientData) entryPtr);
	entryPtr->flags |= GOT_SELECTION;
    }

    /*
     * Recompute the window's geometry and arrange for it to be
     * redisplayed.
     */

    Tk_SetInternalBorder(entryPtr->tkwin,
	    entryPtr->borderWidth + entryPtr->highlightWidth);
    if (entryPtr->highlightWidth <= 0) {
	entryPtr->highlightWidth = 0;
    }
    entryPtr->inset = entryPtr->highlightWidth + entryPtr->borderWidth + XPAD;

    EntryWorldChanged((ClientData) entryPtr);
    return TCL_OK;
}

/*
 *---------------------------------------------------------------------------
 *
 * EntryWorldChanged --
 *
 *      This procedure is called when the world has changed in some
 *      way and the widget needs to recompute all its graphics contexts
 *	and determine its new geometry.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Entry will be relayed out and redisplayed.
 *
 *---------------------------------------------------------------------------
 */

static void
EntryWorldChanged(instanceData)
    ClientData instanceData;	/* Information about widget. */
{
    XGCValues gcValues;
    GC gc = None;
    unsigned long mask;
    Entry *entryPtr;
    Pixmap pixmap;

    entryPtr = (Entry *) instanceData;

    entryPtr->avgWidth = Tk_TextWidth(entryPtr->tkfont, "0", 1);
    if (entryPtr->avgWidth == 0) {
	entryPtr->avgWidth = 1;
    }

    Tk_SetTileChangedProc(entryPtr->tile, TileChangedProc,
	    (ClientData)entryPtr, (Tk_Item *) NULL);
    Tk_SetTileChangedProc(entryPtr->disabledTile, TileChangedProc,
	    (ClientData)entryPtr, (Tk_Item *) NULL);
    Tk_SetTileChangedProc(entryPtr->fgTile, TileChangedProc,
	    (ClientData)entryPtr, (Tk_Item *) NULL);

    if ((pixmap = Tk_PixmapOfTile(entryPtr->tile)) != None) {
	gcValues.fill_style = FillTiled;
	gcValues.tile = pixmap;
	gc = Tk_GetGC(entryPtr->tkwin, GCTile|GCFillStyle, &gcValues);
    } else if (entryPtr->normalBorder != NULL) {
	Tk_SetBackgroundFromBorder(entryPtr->tkwin, entryPtr->normalBorder);
    }
    if (entryPtr->tileGC != None) {
	Tk_FreeGC(entryPtr->display, entryPtr->tileGC);
    }
    entryPtr->tileGC = gc;

    gcValues.foreground = entryPtr->fgColorPtr->pixel;
    gcValues.font = Tk_FontId(entryPtr->tkfont);
    gcValues.graphics_exposures = False;
    mask = GCForeground | GCFont | GCGraphicsExposures;
    gc = Tk_GetGC(entryPtr->tkwin, mask, &gcValues);
    if (entryPtr->textGC != None) {
	Tk_FreeGC(entryPtr->display, entryPtr->textGC);
    }
    entryPtr->textGC = gc;

    gcValues.foreground = entryPtr->selFgColorPtr->pixel;
    gcValues.font = Tk_FontId(entryPtr->tkfont);
    mask = GCForeground | GCFont;
    gc = Tk_GetGC(entryPtr->tkwin, mask, &gcValues);
    if (entryPtr->selTextGC != None) {
	Tk_FreeGC(entryPtr->display, entryPtr->selTextGC);
    }
    entryPtr->selTextGC = gc;

    /*
     * Recompute the window's geometry and arrange for it to be
     * redisplayed.
     */

    EntryComputeGeometry(entryPtr);
    entryPtr->flags |= UPDATE_SCROLLBAR;
    EventuallyRedraw(entryPtr);
}

/*
 *--------------------------------------------------------------
 *
 * DisplayEntry --
 *
 *	This procedure redraws the contents of an entry window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Information appears on the screen.
 *
 *--------------------------------------------------------------
 */

static void
DisplayEntry(clientData)
    ClientData clientData;	/* Information about window. */
{
    register Entry *entryPtr = (Entry *) clientData;
    register Tk_Window tkwin = entryPtr->tkwin;
    int baseY, selStartX, selEndX, cursorX, x, w;
    int xBound;
    Tk_FontMetrics fm;
    Pixmap pixmap;
    int showSelection;
    Pixmap tilepixmap;
    Tk_Tile tile;

    entryPtr->flags &= ~REDRAW_PENDING;
    if ((entryPtr->tkwin == NULL) || !Tk_IsMapped(tkwin)) {
	return;
    }

    Tk_GetFontMetrics(entryPtr->tkfont, &fm);

    /*
     * Update the scrollbar if that's needed.
     */

    if (entryPtr->flags & UPDATE_SCROLLBAR) {
	entryPtr->flags &= ~UPDATE_SCROLLBAR;
	EntryUpdateScrollbar(entryPtr);
    }

    /*
     * In order to avoid screen flashes, this procedure redraws the
     * textual area of the entry into off-screen memory, then copies
     * it back on-screen in a single operation.  This means there's
     * no point in time where the on-screen image has been cleared.
     */

    pixmap = Tk_GetPixmap(entryPtr->display, Tk_WindowId(tkwin),
	    Tk_Width(tkwin), Tk_Height(tkwin), Tk_Depth(tkwin));

    /*
     * Compute x-coordinate of the pixel just after last visible
     * one, plus vertical position of baseline of text.
     */

    xBound = Tk_Width(tkwin) - entryPtr->inset;
    baseY = (Tk_Height(tkwin) + fm.ascent - fm.descent) / 2;

    /*
     * On Windows and Mac, we need to hide the selection whenever we
     * don't have the focus.
     */

#ifdef ALWAYS_SHOW_SELECTION
    showSelection = 1;
#else
    showSelection = (entryPtr->flags & GOT_FOCUS);
#endif

    /*
     * Draw the background in three layers.  From bottom to top the
     * layers are:  normal background, selection background, and
     * insertion cursor background.
     */

    if ((entryPtr->state == TK_STATE_DISABLED) &&
	    (entryPtr->disabledTile != NULL)) {
	tile = entryPtr->disabledTile;
    } else {
	tile = entryPtr->tile;
    }
    if ((tilepixmap = Tk_PixmapOfTile(tile)) != None) {
	Tk_SetTileOrigin(tkwin, entryPtr->tileGC, 0, 0);
	XFillRectangle(entryPtr->display, pixmap, entryPtr->tileGC, 0, 0,
		Tk_Width(tkwin), Tk_Height(tkwin));
	XSetTSOrigin(entryPtr->display, entryPtr->tileGC, 0, 0);
    } else {
	Tk_Fill3DRectangle(tkwin, pixmap, entryPtr->normalBorder,
		0, 0, Tk_Width(tkwin), Tk_Height(tkwin), 0, TK_RELIEF_FLAT);
    }
    if (showSelection && (entryPtr->selectLast > entryPtr->leftIndex)) {
	if (entryPtr->selectFirst <= entryPtr->leftIndex) {
	    selStartX = entryPtr->leftX;
	} else {
	    Tk_CharBbox(entryPtr->textLayout, entryPtr->selectFirst,
		    &x, NULL, NULL, NULL);
	    selStartX = x + entryPtr->layoutX;
	}
	if ((selStartX - entryPtr->selBorderWidth) < xBound) {
	    Tk_CharBbox(entryPtr->textLayout, entryPtr->selectLast - 1,
		    &x, NULL, &w, NULL);
	    selEndX = x + w + entryPtr->layoutX;
	    Tk_Fill3DRectangle(tkwin, pixmap, entryPtr->selBorder,
		    selStartX - entryPtr->selBorderWidth,
		    baseY - fm.ascent - entryPtr->selBorderWidth,
		    (selEndX - selStartX) + 2*entryPtr->selBorderWidth,
		    (fm.ascent + fm.descent) + 2*entryPtr->selBorderWidth,
		    entryPtr->selBorderWidth, TK_RELIEF_RAISED);
	}
    }

    /*
     * Draw a special background for the insertion cursor, overriding
     * even the selection background.  As a special hack to keep the
     * cursor visible when the insertion cursor color is the same as
     * the color for selected text (e.g., on mono displays), write
     * background in the cursor area (instead of nothing) when the
     * cursor isn't on.  Otherwise the selection would hide the cursor.
     */

    if ((entryPtr->insertPos >= entryPtr->leftIndex)
	    && (entryPtr->state == TK_STATE_NORMAL)
	    && (entryPtr->flags & GOT_FOCUS)) {
	if (entryPtr->insertPos == 0) {
	    cursorX = 0;
	} else if (entryPtr->insertPos >= entryPtr->numChars) {
	    Tk_CharBbox(entryPtr->textLayout, entryPtr->numChars - 1,
		    &x, NULL, &w, NULL);
	    cursorX = x + w;
	} else {
	    Tk_CharBbox(entryPtr->textLayout, entryPtr->insertPos,
		    &x, NULL, NULL, NULL);
	    cursorX = x;
	}
	cursorX += entryPtr->layoutX;
	cursorX -= (entryPtr->insertWidth)/2;
	if (cursorX < xBound) {
	    if (entryPtr->flags & CURSOR_ON) {
		Tk_Fill3DRectangle(tkwin, pixmap, entryPtr->insertBorder,
			cursorX, baseY - fm.ascent,
			entryPtr->insertWidth, fm.ascent + fm.descent,
			entryPtr->insertBorderWidth, TK_RELIEF_RAISED);
	    } else if (entryPtr->insertBorder == entryPtr->selBorder) {
		Tk_Fill3DRectangle(tkwin, pixmap, entryPtr->normalBorder,
			cursorX, baseY - fm.ascent,
			entryPtr->insertWidth, fm.ascent + fm.descent,
			0, TK_RELIEF_FLAT);
	    }
	}
    }

    /*
     * Draw the text in two pieces:  first the unselected portion, then the
     * selected portion on top of it.
     */

    Tk_DrawTextLayout(entryPtr->display, pixmap, entryPtr->textGC,
	    entryPtr->textLayout, entryPtr->layoutX, entryPtr->layoutY,
	    entryPtr->leftIndex, entryPtr->numChars);

    if (showSelection && (entryPtr->selTextGC != entryPtr->textGC) &&
	    (entryPtr->selectFirst < entryPtr->selectLast)) {
	int first;

	if (entryPtr->selectFirst - entryPtr->leftIndex < 0) {
	    first = entryPtr->leftIndex;
	} else {
	    first = entryPtr->selectFirst;
	}
	Tk_DrawTextLayout(entryPtr->display, pixmap, entryPtr->selTextGC,
		entryPtr->textLayout, entryPtr->layoutX, entryPtr->layoutY,
		first, entryPtr->selectLast);
    }

    /*
     * Draw the border and focus highlight last, so they will overwrite
     * any text that extends past the viewable part of the window.
     */

    if (entryPtr->relief != TK_RELIEF_FLAT) {
	Tk_Draw3DRectangle(tkwin, pixmap, entryPtr->normalBorder,
		entryPtr->highlightWidth, entryPtr->highlightWidth,
		Tk_Width(tkwin) - 2*entryPtr->highlightWidth,
		Tk_Height(tkwin) - 2*entryPtr->highlightWidth,
		entryPtr->borderWidth, entryPtr->relief);
    }
    if (entryPtr->highlightWidth != 0) {
	GC gc;

	if (entryPtr->flags & GOT_FOCUS) {
	    gc = Tk_GCForColor(entryPtr->highlightColorPtr, pixmap);
	} else {
	    gc = Tk_GCForColor(entryPtr->highlightBgColorPtr, pixmap);
	}
	Tk_DrawFocusHighlight(tkwin, gc, entryPtr->highlightWidth, pixmap);
    }

    /*
     * Everything's been redisplayed;  now copy the pixmap onto the screen
     * and free up the pixmap.
     */

    XCopyArea(entryPtr->display, pixmap, Tk_WindowId(tkwin), entryPtr->textGC,
	    0, 0, (unsigned) Tk_Width(tkwin), (unsigned) Tk_Height(tkwin),
	    0, 0);
    Tk_FreePixmap(entryPtr->display, pixmap);
    entryPtr->flags &= ~BORDER_NEEDED;
}

/*
 *----------------------------------------------------------------------
 *
 * EntryComputeGeometry --
 *
 *	This procedure is invoked to recompute information about where
 *	in its window an entry's string will be displayed.  It also
 *	computes the requested size for the window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The leftX and tabOrigin fields are recomputed for entryPtr,
 *	and leftIndex may be adjusted.  Tk_GeometryRequest is called
 *	to register the desired dimensions for the window.
 *
 *----------------------------------------------------------------------
 */

static void
EntryComputeGeometry(entryPtr)
    Entry *entryPtr;			/* Widget record for entry. */
{
    int totalLength, overflow, maxOffScreen, rightX;
    int height, width, i;
    Tk_FontMetrics fm;
    char *p, *displayString;

    /*
     * If we're displaying a special character instead of the value of
     * the entry, recompute the displayString.
     */

    if (entryPtr->displayString != NULL) {
	ckfree(entryPtr->displayString);
	entryPtr->displayString = NULL;
    }
    if (entryPtr->showChar != NULL) {
	entryPtr->displayString = (char *) ckalloc((unsigned)
		(entryPtr->numChars + 1));
	for (p = entryPtr->displayString, i = entryPtr->numChars; i > 0;
		i--, p++) {
	    *p = entryPtr->showChar[0];
	}
	*p = 0;
	displayString = entryPtr->displayString;
    } else {
	displayString = entryPtr->string;
    }
    Tk_FreeTextLayout(entryPtr->textLayout);
    entryPtr->textLayout = Tk_ComputeTextLayout(entryPtr->tkfont,
	    displayString, entryPtr->numChars, 0, entryPtr->justify,
	    TK_IGNORE_NEWLINES, &totalLength, &height);

    entryPtr->layoutY = (Tk_Height(entryPtr->tkwin) - height) / 2;

    /*
     * Recompute where the leftmost character on the display will
     * be drawn (entryPtr->leftX) and adjust leftIndex if necessary
     * so that we don't let characters hang off the edge of the
     * window unless the entire window is full.
     */

    overflow = totalLength - (Tk_Width(entryPtr->tkwin) - 2*entryPtr->inset);
    if (overflow <= 0) {
	entryPtr->leftIndex = 0;
	if (entryPtr->justify == TK_JUSTIFY_LEFT) {
	    entryPtr->leftX = entryPtr->inset;
	} else if (entryPtr->justify == TK_JUSTIFY_RIGHT) {
	    entryPtr->leftX = Tk_Width(entryPtr->tkwin) - entryPtr->inset
		    - totalLength;
	} else {
	    entryPtr->leftX = (Tk_Width(entryPtr->tkwin) - totalLength)/2;
	}
	entryPtr->layoutX = entryPtr->leftX;
    } else {
	/*
	 * The whole string can't fit in the window.  Compute the
	 * maximum number of characters that may be off-screen to
	 * the left without leaving empty space on the right of the
	 * window, then don't let leftIndex be any greater than that.
	 */

	maxOffScreen = Tk_PointToChar(entryPtr->textLayout, overflow, 0);
	Tk_CharBbox(entryPtr->textLayout, maxOffScreen,
		&rightX, NULL, NULL, NULL);
	if (rightX < overflow) {
	    maxOffScreen += 1;
	}
	if (entryPtr->leftIndex > maxOffScreen) {
	    entryPtr->leftIndex = maxOffScreen;
	}
	Tk_CharBbox(entryPtr->textLayout, entryPtr->leftIndex,
		&rightX, NULL, NULL, NULL);
	entryPtr->leftX = entryPtr->inset;
	entryPtr->layoutX = entryPtr->leftX - rightX;
    }

    Tk_GetFontMetrics(entryPtr->tkfont, &fm);
    height = fm.linespace + 2*entryPtr->inset + 2*(YPAD-XPAD);
    if (entryPtr->prefWidth > 0) {
	width = entryPtr->prefWidth*entryPtr->avgWidth + 2*entryPtr->inset;
    } else {
	if (totalLength == 0) {
	    width = entryPtr->avgWidth + 2*entryPtr->inset;
	} else {
	    width = totalLength + 2*entryPtr->inset;
	}
    }
    Tk_GeometryRequest(entryPtr->tkwin, width, height);
}

/*
 *----------------------------------------------------------------------
 *
 * InsertChars --
 *
 *	Add new characters to an entry widget.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	New information gets added to entryPtr;  it will be redisplayed
 *	soon, but not necessarily immediately.
 *
 *----------------------------------------------------------------------
 */

static void
InsertChars(entryPtr, index, string)
    register Entry *entryPtr;	/* Entry that is to get the new
				 * elements. */
    int index;			/* Add the new elements before this
				 * element. */
    char *string;		/* New characters to add (NULL-terminated
				 * string). */
{
    int length;
    char *new;

    length = strlen(string);
    if (length == 0) {
	return;
    }
    new = (char *) ckalloc((unsigned) (entryPtr->numChars + length + 1));
    strncpy(new, entryPtr->string, (size_t) index);
    strcpy(new+index, string);
    strcpy(new+index+length, entryPtr->string+index);
#ifdef ENTRY_VALIDATE
    if ((entryPtr->validate == VALIDATE_KEY ||
	 entryPtr->validate == VALIDATE_ALL) &&
	EntryValidateChange(entryPtr, string, new, index, 1) != TCL_OK) {
	ckfree(new);
	return;
    }
#endif /* ENTRY_VALIDATE */
    ckfree(entryPtr->string);
    entryPtr->string = new;
    entryPtr->numChars += length;

    /*
     * Inserting characters invalidates all indexes into the string.
     * Touch up the indexes so that they still refer to the same
     * characters (at new positions).  When updating the selection
     * end-points, don't include the new text in the selection unless
     * it was completely surrounded by the selection.
     */

    if (entryPtr->selectFirst >= index) {
	entryPtr->selectFirst += length;
    }
    if (entryPtr->selectLast > index) {
	entryPtr->selectLast += length;
    }
    if ((entryPtr->selectAnchor > index) || (entryPtr->selectFirst >= index)) {
	entryPtr->selectAnchor += length;
    }
    if (entryPtr->leftIndex > index) {
	entryPtr->leftIndex += length;
    }
    if (entryPtr->insertPos >= index) {
	entryPtr->insertPos += length;
    }
    EntryValueChanged(entryPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * DeleteChars --
 *
 *	Remove one or more characters from an entry widget.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Memory gets freed, the entry gets modified and (eventually)
 *	redisplayed.
 *
 *----------------------------------------------------------------------
 */

static void
DeleteChars(entryPtr, index, count)
    register Entry *entryPtr;	/* Entry widget to modify. */
    int index;			/* Index of first character to delete. */
    int count;			/* How many characters to delete. */
{
    char *new;
#ifdef ENTRY_VALIDATE
    char *string;
#endif /* ENTRY_VALIDATE */

    if ((index + count) > entryPtr->numChars) {
	count = entryPtr->numChars - index;
    }
    if (count <= 0) {
	return;
    }

    new = (char *) ckalloc((unsigned) (entryPtr->numChars + 1 - count));
    strncpy(new, entryPtr->string, (size_t) index);
    strcpy(new+index, entryPtr->string+index+count);
#ifdef ENTRY_VALIDATE
    string = (char *) ckalloc((unsigned) (1 + count));
    strncpy(string, entryPtr->string+index, (size_t) count);
    string[count] = '\0';

    if ((entryPtr->validate == VALIDATE_KEY ||
	 entryPtr->validate == VALIDATE_ALL) &&
	EntryValidateChange(entryPtr, string, new, index, 0) != TCL_OK) {
	ckfree(new);
	ckfree(string);
	return;
    }

    ckfree(string);
#endif /* ENTRY_VALIDATE */
    ckfree(entryPtr->string);
    entryPtr->string = new;
    entryPtr->numChars -= count;

    /*
     * Deleting characters results in the remaining characters being
     * renumbered.  Update the various indexes into the string to reflect
     * this change.
     */

    if (entryPtr->selectFirst >= index) {
	if (entryPtr->selectFirst >= (index+count)) {
	    entryPtr->selectFirst -= count;
	} else {
	    entryPtr->selectFirst = index;
	}
    }
    if (entryPtr->selectLast >= index) {
	if (entryPtr->selectLast >= (index+count)) {
	    entryPtr->selectLast -= count;
	} else {
	    entryPtr->selectLast = index;
	}
    }
    if (entryPtr->selectLast <= entryPtr->selectFirst) {
	entryPtr->selectFirst = entryPtr->selectLast = -1;
    }
    if (entryPtr->selectAnchor >= index) {
	if (entryPtr->selectAnchor >= (index+count)) {
	    entryPtr->selectAnchor -= count;
	} else {
	    entryPtr->selectAnchor = index;
	}
    }
    if (entryPtr->leftIndex > index) {
	if (entryPtr->leftIndex >= (index+count)) {
	    entryPtr->leftIndex -= count;
	} else {
	    entryPtr->leftIndex = index;
	}
    }
    if (entryPtr->insertPos >= index) {
	if (entryPtr->insertPos >= (index+count)) {
	    entryPtr->insertPos -= count;
	} else {
	    entryPtr->insertPos = index;
	}
    }
    EntryValueChanged(entryPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * EntryValueChanged --
 *
 *	This procedure is invoked when characters are inserted into
 *	an entry or deleted from it.  It updates the entry's associated
 *	variable, if there is one, and does other bookkeeping such
 *	as arranging for redisplay.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
EntryValueChanged(entryPtr)
    Entry *entryPtr;		/* Entry whose value just changed. */
{
    char *newValue;

    if (entryPtr->textVarName == NULL) {
	newValue = NULL;
    } else {
	newValue = Tcl_SetVar(entryPtr->interp, entryPtr->textVarName,
		entryPtr->string, TCL_GLOBAL_ONLY);
    }

    if ((newValue != NULL) && (strcmp(newValue, entryPtr->string) != 0)) {
	/*
	 * The value of the variable is different than what we asked for.
	 * This means that a trace on the variable modified it.  In this
	 * case our trace procedure wasn't invoked since the modification
	 * came while a trace was already active on the variable.  So,
	 * update our value to reflect the variable's latest value.
	 */

	EntrySetValue(entryPtr, newValue);
    } else {
	/*
	 * Arrange for redisplay.
	 */

	entryPtr->flags |= UPDATE_SCROLLBAR;
	EntryComputeGeometry(entryPtr);
	EventuallyRedraw(entryPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EntrySetValue --
 *
 *	Replace the contents of a text entry with a given value.  This
 *	procedure is invoked when updating the entry from the entry's
 *	associated variable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The string displayed in the entry will change.  The selection,
 *	insertion point, and view may have to be adjusted to keep them
 *	within the bounds of the new string.  Note: this procedure does
 *	*not* update the entry's associated variable, since that could
 *	result in an infinite loop.
 *
 *----------------------------------------------------------------------
 */

static void
EntrySetValue(entryPtr, value)
    register Entry *entryPtr;		/* Entry whose value is to be
					 * changed. */
    char *value;			/* New text to display in entry. */
{
#ifdef ENTRY_VALIDATE
    int code;

    if (strcmp(value, entryPtr->string) == 0) {
	return;
    }

    if (entryPtr->flags & VALIDATE_VAR) {
	/* Recursing : assume we are in fixup code and it knows
	   what it is doing
	*/
    } else {
	entryPtr->flags |= VALIDATE_VAR;
	code = EntryValidateChange(entryPtr, (char *) NULL, value, -1, -1);
	if (code != TCL_OK || (entryPtr->flags & VALIDATE_ABORT)) {
	    /*
	     * If VALIDATE_ABORT has been set, then this operation should be
	     * aborted because the validatecommand did something else instead
	     * Set variable to what that 'something' was.
	     */
	    EntryValueChanged(entryPtr);
	    entryPtr->flags &= ~VALIDATE_ABORT;
	    entryPtr->flags &= ~VALIDATE_VAR;
	    return;
	}
	entryPtr->flags &= ~VALIDATE_VAR;
    }
#endif /* ENTRY_VALIDATE */

    ckfree(entryPtr->string);
    entryPtr->numChars = strlen(value);
    entryPtr->string = (char *) ckalloc((unsigned) (entryPtr->numChars + 1));
    strcpy(entryPtr->string, value);
    if (entryPtr->selectFirst != -1) {
	if (entryPtr->selectFirst >= entryPtr->numChars) {
	    entryPtr->selectFirst = entryPtr->selectLast = -1;
	} else if (entryPtr->selectLast > entryPtr->numChars) {
	    entryPtr->selectLast = entryPtr->numChars;
	}
    }
    if (entryPtr->leftIndex >= entryPtr->numChars) {
	entryPtr->leftIndex = entryPtr->numChars-1;
	if (entryPtr->leftIndex < 0) {
	    entryPtr->leftIndex = 0;
	}
    }
    if (entryPtr->insertPos > entryPtr->numChars) {
	entryPtr->insertPos = entryPtr->numChars;
    }

    entryPtr->flags |= UPDATE_SCROLLBAR;
    EntryComputeGeometry(entryPtr);
    EventuallyRedraw(entryPtr);
}

/*
 *--------------------------------------------------------------
 *
 * EntryEventProc --
 *
 *	This procedure is invoked by the Tk dispatcher for various
 *	events on entryes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	When the window gets deleted, internal structures get
 *	cleaned up.  When it gets exposed, it is redisplayed.
 *
 *--------------------------------------------------------------
 */

static void
EntryEventProc(clientData, eventPtr)
    ClientData clientData;	/* Information about window. */
    XEvent *eventPtr;		/* Information about event. */
{
    Entry *entryPtr = (Entry *) clientData;
    if (eventPtr->type == Expose) {
	EventuallyRedraw(entryPtr);
	entryPtr->flags |= BORDER_NEEDED;
    } else if (eventPtr->type == DestroyNotify) {
	if (entryPtr->tkwin != NULL) {
	    entryPtr->tkwin = NULL;
            Tcl_DeleteCommandFromToken(entryPtr->interp, entryPtr->widgetCmd);
	}
	if (entryPtr->flags & REDRAW_PENDING) {
	    Tcl_CancelIdleCall(DisplayEntry, (ClientData) entryPtr);
	}
	Tcl_EventuallyFree((ClientData) entryPtr, DestroyEntry);
    } else if (eventPtr->type == ConfigureNotify) {
	Tcl_Preserve((ClientData) entryPtr);
	entryPtr->flags |= UPDATE_SCROLLBAR;
	EntryComputeGeometry(entryPtr);
	EventuallyRedraw(entryPtr);
	Tcl_Release((ClientData) entryPtr);
    } else if (eventPtr->type == FocusIn) {
	if (eventPtr->xfocus.detail != NotifyInferior) {
	    EntryFocusProc(entryPtr, 1);
	}
    } else if (eventPtr->type == FocusOut) {
	if (eventPtr->xfocus.detail != NotifyInferior) {
	    EntryFocusProc(entryPtr, 0);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EntryCmdDeletedProc --
 *
 *	This procedure is invoked when a widget command is deleted.  If
 *	the widget isn't already in the process of being destroyed,
 *	this command destroys it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The widget is destroyed.
 *
 *----------------------------------------------------------------------
 */

static void
EntryCmdDeletedProc(clientData)
    ClientData clientData;	/* Pointer to widget record for widget. */
{
    Entry *entryPtr = (Entry *) clientData;
    Tk_Window tkwin = entryPtr->tkwin;

    /*
     * This procedure could be invoked either because the window was
     * destroyed and the command was then deleted (in which case tkwin
     * is NULL) or because the command was deleted, and then this procedure
     * destroys the widget.
     */

    if (tkwin != NULL) {
	entryPtr->tkwin = NULL;
	Tk_DestroyWindow(tkwin);
    }
}

/*
 *--------------------------------------------------------------
 *
 * GetEntryIndex --
 *
 *	Parse an index into an entry and return either its value
 *	or an error.
 *
 * Results:
 *	A standard Tcl result.  If all went well, then *indexPtr is
 *	filled in with the index (into entryPtr) corresponding to
 *	string.  The index value is guaranteed to lie between 0 and
 *	the number of characters in the string, inclusive.  If an
 *	error occurs then an error message is left in interp->result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
GetEntryIndex(interp, entryPtr, arg, indexPtr)
    Tcl_Interp *interp;		/* For error messages. */
    Entry *entryPtr;		/* Entry for which the index is being
				 * specified. */
    Arg  arg;			/* Specifies character in entryPtr. */
    int *indexPtr;		/* Where to store converted index. */
{
    size_t length;
    char *string = LangString(arg);

    length = strlen(string);

    if (string[0] == 'a') {
	if (strncmp(string, "anchor", length) == 0) {
	    *indexPtr = entryPtr->selectAnchor;
	} else {
	    badIndex:

	    /*
	     * Some of the paths here leave messages in interp->result,
	     * so we have to clear it out before storing our own message.
	     */

	    Tcl_SetResult(interp, (char *) NULL, TCL_STATIC);
	    Tcl_AppendResult(interp, "bad entry index \"", string,
		    "\"", (char *) NULL);
	    return TCL_ERROR;
	}
    } else if (string[0] == 'e') {
	if (strncmp(string, "end", length) == 0) {
	    *indexPtr = entryPtr->numChars;
	} else {
	    goto badIndex;
	}
    } else if (string[0] == 'i') {
	if (strncmp(string, "insert", length) == 0) {
	    *indexPtr = entryPtr->insertPos;
	} else {
	    goto badIndex;
	}
    } else if (string[0] == 's') {
	if (entryPtr->selectFirst == -1) {
	    interp->result = "selection isn't in entry";
	    return TCL_ERROR;
	}
	if (length < 5) {
	    goto badIndex;
	}
	if (strncmp(string, "sel.first", length) == 0) {
	    *indexPtr = entryPtr->selectFirst;
	} else if (strncmp(string, "sel.last", length) == 0) {
	    *indexPtr = entryPtr->selectLast;
	} else {
	    goto badIndex;
	}
    } else if (string[0] == '@') {
	int x, roundUp;

        Arg tmp = LangStringArg(string+1);

	if (Tcl_GetInt(interp, tmp, &x) != TCL_OK) {
            LangFreeArg(tmp,TCL_DYNAMIC);
	    goto badIndex;
	}
        LangFreeArg(tmp,TCL_DYNAMIC);
	if (x < entryPtr->inset) {
	    x = entryPtr->inset;
	}
	roundUp = 0;
	if (x >= (Tk_Width(entryPtr->tkwin) - entryPtr->inset)) {
	    x = Tk_Width(entryPtr->tkwin) - entryPtr->inset - 1;
	    roundUp = 1;
	}
	*indexPtr = Tk_PointToChar(entryPtr->textLayout,
		x - entryPtr->layoutX, 0);

	/*
	 * Special trick:  if the x-position was off-screen to the right,
	 * round the index up to refer to the character just after the
	 * last visible one on the screen.  This is needed to enable the
	 * last character to be selected, for example.
	 */

	if (roundUp && (*indexPtr < entryPtr->numChars)) {
	    *indexPtr += 1;
	}
    } else {

	if (Tcl_GetInt(interp, arg, indexPtr) != TCL_OK) {
	    goto badIndex;
	}
	if (*indexPtr < 0){
	    *indexPtr = 0;
	} else if (*indexPtr > entryPtr->numChars) {
	    *indexPtr = entryPtr->numChars;
	}
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * EntryScanTo --
 *
 *	Given a y-coordinate (presumably of the curent mouse location)
 *	drag the view in the window to implement the scan operation.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The view in the window may change.
 *
 *----------------------------------------------------------------------
 */

static void
EntryScanTo(entryPtr, x)
    register Entry *entryPtr;		/* Information about widget. */
    int x;				/* X-coordinate to use for scan
					 * operation. */
{
    int newLeftIndex;

    /*
     * Compute new leftIndex for entry by amplifying the difference
     * between the current position and the place where the scan
     * started (the "mark" position).  If we run off the left or right
     * side of the entry, then reset the mark point so that the current
     * position continues to correspond to the edge of the window.
     * This means that the picture will start dragging as soon as the
     * mouse reverses direction (without this reset, might have to slide
     * mouse a long ways back before the picture starts moving again).
     */

    newLeftIndex = entryPtr->scanMarkIndex
	    - (10*(x - entryPtr->scanMarkX))/entryPtr->avgWidth;
    if (newLeftIndex >= entryPtr->numChars) {
	newLeftIndex = entryPtr->scanMarkIndex = entryPtr->numChars-1;
	entryPtr->scanMarkX = x;
    }
    if (newLeftIndex < 0) {
	newLeftIndex = entryPtr->scanMarkIndex = 0;
	entryPtr->scanMarkX = x;
    }
    if (newLeftIndex != entryPtr->leftIndex) {
	entryPtr->leftIndex = newLeftIndex;
	entryPtr->flags |= UPDATE_SCROLLBAR;
	EntryComputeGeometry(entryPtr);
	EventuallyRedraw(entryPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EntrySelectTo --
 *
 *	Modify the selection by moving its un-anchored end.  This could
 *	make the selection either larger or smaller.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection changes.
 *
 *----------------------------------------------------------------------
 */

static void
EntrySelectTo(entryPtr, index)
    register Entry *entryPtr;		/* Information about widget. */
    int index;				/* Index of element that is to
					 * become the "other" end of the
					 * selection. */
{
    int newFirst, newLast;

    /*
     * Grab the selection if we don't own it already.
     */

    if (!(entryPtr->flags & GOT_SELECTION) && (entryPtr->exportSelection)) {
	Tk_OwnSelection(entryPtr->tkwin, XA_PRIMARY, EntryLostSelection,
		(ClientData) entryPtr);
	entryPtr->flags |= GOT_SELECTION;
    }

    /*
     * Pick new starting and ending points for the selection.
     */

    if (entryPtr->selectAnchor > entryPtr->numChars) {
	entryPtr->selectAnchor = entryPtr->numChars;
    }
    if (entryPtr->selectAnchor <= index) {
	newFirst = entryPtr->selectAnchor;
	newLast = index;
    } else {
	newFirst = index;
	newLast = entryPtr->selectAnchor;
	if (newLast < 0) {
	    newFirst = newLast = -1;
	}
    }
    if ((entryPtr->selectFirst == newFirst)
	    && (entryPtr->selectLast == newLast)) {
	return;
    }
    entryPtr->selectFirst = newFirst;
    entryPtr->selectLast = newLast;
    EventuallyRedraw(entryPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * EntryFetchSelection --
 *
 *	This procedure is called back by Tk when the selection is
 *	requested by someone.  It returns part or all of the selection
 *	in a buffer provided by the caller.
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
 *----------------------------------------------------------------------
 */

static int
EntryFetchSelection(clientData, offset, buffer, maxBytes)
    ClientData clientData;		/* Information about entry widget. */
    int offset;				/* Offset within selection of first
					 * character to be returned. */
    char *buffer;			/* Location in which to place
					 * selection. */
    int maxBytes;			/* Maximum number of bytes to place
					 * at buffer, not including terminating
					 * NULL character. */
{
    Entry *entryPtr = (Entry *) clientData;
    int count;
    char *displayString;

    if ((entryPtr->selectFirst < 0) || !(entryPtr->exportSelection)) {
	return -1;
    }
    count = entryPtr->selectLast - entryPtr->selectFirst - offset;
    if (count > maxBytes) {
	count = maxBytes;
    }
    if (count <= 0) {
	return 0;
    }
    if (entryPtr->displayString == NULL) {
	displayString = entryPtr->string;
    } else {
	displayString = entryPtr->displayString;
    }
    strncpy(buffer, displayString + entryPtr->selectFirst + offset,
	    (size_t) count);
    buffer[count] = '\0';
    return count;
}

/*
 *----------------------------------------------------------------------
 *
 * EntryLostSelection --
 *
 *	This procedure is called back by Tk when the selection is
 *	grabbed away from an entry widget.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The existing selection is unhighlighted, and the window is
 *	marked as not containing a selection.
 *
 *----------------------------------------------------------------------
 */

static void
EntryLostSelection(clientData)
    ClientData clientData;		/* Information about entry widget. */
{
    Entry *entryPtr = (Entry *) clientData;

    entryPtr->flags &= ~GOT_SELECTION;

    /*
     * On Windows and Mac systems, we want to remember the selection
     * for the next time the focus enters the window.  On Unix, we need
     * to clear the selection since it is always visible.
     */

#ifdef ALWAYS_SHOW_SELECTION
    if ((entryPtr->selectFirst != -1) && entryPtr->exportSelection) {
	entryPtr->selectFirst = -1;
	entryPtr->selectLast = -1;
	EventuallyRedraw(entryPtr);
    }
#endif
}

/*
 *----------------------------------------------------------------------
 *
 * EventuallyRedraw --
 *
 *	Ensure that an entry is eventually redrawn on the display.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Information gets redisplayed.  Right now we don't do selective
 *	redisplays:  the whole window will be redrawn.  This doesn't
 *	seem to hurt performance noticeably, but if it does then this
 *	could be changed.
 *
 *----------------------------------------------------------------------
 */

static void
EventuallyRedraw(entryPtr)
    register Entry *entryPtr;		/* Information about widget. */
{
    if ((entryPtr->tkwin == NULL) || !Tk_IsMapped(entryPtr->tkwin)) {
	return;
    }

    /*
     * Right now we don't do selective redisplays:  the whole window
     * will be redrawn.  This doesn't seem to hurt performance noticeably,
     * but if it does then this could be changed.
     */

    if (!(entryPtr->flags & REDRAW_PENDING)) {
	entryPtr->flags |= REDRAW_PENDING;
	Tcl_DoWhenIdle(DisplayEntry, (ClientData) entryPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EntryVisibleRange --
 *
 *	Return information about the range of the entry that is
 *	currently visible.
 *
 * Results:
 *	*firstPtr and *lastPtr are modified to hold fractions between
 *	0 and 1 identifying the range of characters visible in the
 *	entry.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
EntryVisibleRange(entryPtr, firstPtr, lastPtr)
    Entry *entryPtr;			/* Information about widget. */
    double *firstPtr;			/* Return position of first visible
					 * character in widget. */
    double *lastPtr;			/* Return position of char just after
					 * last visible one. */
{
    int charsInWindow;

    if (entryPtr->numChars == 0) {
	*firstPtr = 0.0;
	*lastPtr = 1.0;
    } else {
	charsInWindow = Tk_PointToChar(entryPtr->textLayout,
		Tk_Width(entryPtr->tkwin) - entryPtr->inset
			- entryPtr->layoutX - 1, 0) + 1;
	if (charsInWindow > entryPtr->numChars) {
	    /*
	     * If all chars were visible, then charsInWindow will be
	     * the index just after the last char that was visible.
	     */
	
	    charsInWindow = entryPtr->numChars;
	}
	charsInWindow -= entryPtr->leftIndex;
	if (charsInWindow == 0) {
	    charsInWindow = 1;
	}
	*firstPtr = ((double) entryPtr->leftIndex)/entryPtr->numChars;
	*lastPtr = ((double) (entryPtr->leftIndex + charsInWindow))
		/entryPtr->numChars;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EntryUpdateScrollbar --
 *
 *	This procedure is invoked whenever information has changed in
 *	an entry in a way that would invalidate a scrollbar display.
 *	If there is an associated scrollbar, then this procedure updates
 *	it by invoking a Tcl command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A Tcl command is invoked, and an additional command may be
 *	invoked to process errors in the command.
 *
 *----------------------------------------------------------------------
 */

static void
EntryUpdateScrollbar(entryPtr)
    Entry *entryPtr;			/* Information about widget. */
{
    char args[100];
    int code;
    double first, last;
    Tcl_Interp *interp;

    if (entryPtr->scrollCmd == NULL) {
	return;
    }

    interp = entryPtr->interp;
    Tcl_Preserve((ClientData) interp);
    EntryVisibleRange(entryPtr, &first, &last);
    code = LangDoCallback(entryPtr->interp, entryPtr->scrollCmd, 0, 2, " %g %g", first, last);
    if (code != TCL_OK) {
	Tcl_AddErrorInfo(interp,
		"\n    (horizontal scrolling command executed by entry)");
	Tcl_BackgroundError(interp);
    }
    Tcl_SetResult(interp, (char *) NULL, TCL_STATIC);
    Tcl_Release((ClientData) interp);
}

/*
 *----------------------------------------------------------------------
 *
 * EntryBlinkProc --
 *
 *	This procedure is called as a timer handler to blink the
 *	insertion cursor off and on.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The cursor gets turned on or off, redisplay gets invoked,
 *	and this procedure reschedules itself.
 *
 *----------------------------------------------------------------------
 */

static void
EntryBlinkProc(clientData)
    ClientData clientData;	/* Pointer to record describing entry. */
{
    register Entry *entryPtr = (Entry *) clientData;

    if (!(entryPtr->flags & GOT_FOCUS) || (entryPtr->insertOffTime == 0)) {
	return;
    }
    if (entryPtr->flags & CURSOR_ON) {
	entryPtr->flags &= ~CURSOR_ON;
	entryPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
		entryPtr->insertOffTime, EntryBlinkProc, (ClientData) entryPtr);
    } else {
	entryPtr->flags |= CURSOR_ON;
	entryPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
		entryPtr->insertOnTime, EntryBlinkProc, (ClientData) entryPtr);
    }
    EventuallyRedraw(entryPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * EntryFocusProc --
 *
 *	This procedure is called whenever the entry gets or loses the
 *	input focus.  It's also called whenever the window is reconfigured
 *	while it has the focus.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The cursor gets turned on or off.
 *
 *----------------------------------------------------------------------
 */

static void
EntryFocusProc(entryPtr, gotFocus)
    register Entry *entryPtr;	/* Entry that got or lost focus. */
    int gotFocus;		/* 1 means window is getting focus, 0 means
				 * it's losing it. */
{
    Tcl_DeleteTimerHandler(entryPtr->insertBlinkHandler);
    if (gotFocus) {
	entryPtr->flags |= GOT_FOCUS | CURSOR_ON;
	if (entryPtr->insertOffTime != 0) {
	    entryPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
		    entryPtr->insertOnTime, EntryBlinkProc,
		    (ClientData) entryPtr);
	}
#ifdef ENTRY_VALIDATE
	if (entryPtr->validate == VALIDATE_ALL ||
	    entryPtr->validate == VALIDATE_FOCUS ||
	    entryPtr->validate == VALIDATE_FOCUSIN) {
	    EntryValidateChange(entryPtr, (char *) NULL,
				entryPtr->string, -1, -2);
	}
#endif /* ENTRY_VALIDATE */
    } else {
	entryPtr->flags &= ~(GOT_FOCUS | CURSOR_ON);
	entryPtr->insertBlinkHandler = (Tcl_TimerToken) NULL;
#ifdef ENTRY_VALIDATE
	if (entryPtr->validate == VALIDATE_ALL ||
	    entryPtr->validate == VALIDATE_FOCUS ||
	    entryPtr->validate == VALIDATE_FOCUSOUT) {
	    EntryValidateChange(entryPtr, (char *) NULL,
				entryPtr->string, -1, -3);
	}
#endif /* ENTRY_VALIDATE */
    }
    EventuallyRedraw(entryPtr);
}

/*
 *--------------------------------------------------------------
 *
 * EntryTextVarProc --
 *
 *	This procedure is invoked when someone changes the variable
 *	whose contents are to be displayed in an entry.
 *
 * Results:
 *	NULL is always returned.
 *
 * Side effects:
 *	The text displayed in the entry will change to match the
 *	variable.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static char *
EntryTextVarProc(clientData, interp, name1, name2, flags)
    ClientData clientData;	/* Information about button. */
    Tcl_Interp *interp;		/* Interpreter containing variable. */
    Var name1;			/* Not used. */
    char *name2;		/* Not used. */
    int flags;			/* Information about what happened. */
{
    register Entry *entryPtr = (Entry *) clientData;
    char *value;

    /*
     * If the variable is unset, then immediately recreate it unless
     * the whole interpreter is going away.
     */

    if (flags & TCL_TRACE_UNSETS) {
	if ((flags & TCL_TRACE_DESTROYED) && !(flags & TCL_INTERP_DESTROYED)) {
	    Tcl_SetVar(interp, entryPtr->textVarName, entryPtr->string,
		    TCL_GLOBAL_ONLY);
	    Tcl_TraceVar(interp, entryPtr->textVarName,
		    TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		    EntryTextVarProc, clientData);
	}
	return (char *) NULL;
    }

    /*
     * Update the entry's text with the value of the variable, unless
     * the entry already has that value (this happens when the variable
     * changes value because we changed it because someone typed in
     * the entry).
     */

    value = LangString(Tcl_GetVar(interp, entryPtr->textVarName, TCL_GLOBAL_ONLY));
    if (value == NULL) {
	value = "";
    }
#ifdef ENTRY_VALIDATE
    EntrySetValue(entryPtr, value);
#else
    if (strcmp(value, entryPtr->string) != 0) {
	EntrySetValue(entryPtr, value);
    }
#endif /* ENTRY_VALIDATE */
    return (char *) NULL;
}
#ifdef ENTRY_VALIDATE

/*
 *--------------------------------------------------------------
 *
 * EntryValidate --
 *
 *	This procedure is invoked when any character is added or
 *	removed from the entry widget, or a focus has trigerred validation.
 *
 * Results:
 *	TCL_OK if the validatecommand passes the new string.
 *      TCL_BREAK if the vcmd executed OK, but rejects the string.
 *      TCL_ERROR if an error occurred while executing the vcmd
 *      or a valid Tcl_Bool is not returned.
 *
 * Side effects:
 *      An error condition may arise
 *
 *--------------------------------------------------------------
 */

static int
EntryValidate(entryPtr, cmd, string)
     register Entry *entryPtr;	/* Entry that needs validation. */
     register LangCallback *cmd;	/* Validation command (NULL-terminated
				 * string). */
     char *string;
{
    int code;
    Arg result;

    code = LangDoCallback(entryPtr->interp, cmd, 1, 1, "%s", string);

    if (code != TCL_OK && code != TCL_RETURN) {
	Tcl_AddErrorInfo(entryPtr->interp,
		 "\n\t(in validation command executed by entry)");
	Tcl_BackgroundError(entryPtr->interp);
	return TCL_ERROR;
    }

    result = Tcl_ResultArg(entryPtr->interp);

    if (Tcl_GetBoolean(entryPtr->interp,  result, &code) != TCL_OK) {
	Tcl_AddErrorInfo(entryPtr->interp,
		 "\nValid Tcl Boolean not returned by validation command");
	Tcl_BackgroundError(entryPtr->interp);
	Tcl_SetResult(entryPtr->interp, (char *) NULL, TCL_STATIC);
	return TCL_ERROR;
    }

    Tcl_SetResult(entryPtr->interp, (char *) NULL, TCL_STATIC);
    return code ? TCL_OK : TCL_BREAK;
}

/*
 *--------------------------------------------------------------
 *
 * EntryValidateChange --
 *
 *	This procedure is invoked when any character is added or
 *	removed from the entry widget, or a focus has trigerred validation.
 *
 * Results:
 *	TCL_OK if the validatecommand accepts the new string,
 *      TCL_ERROR if any problems occured with validatecommand.
 *
 * Side effects:
 *      The insertion/deletion may be aborted, and the
 *      validatecommand might turn itself off (if an error
 *      or loop condition arises).
 *
 *--------------------------------------------------------------
 */

static int
EntryValidateChange(entryPtr, string, new, index, type)
     register Entry *entryPtr;	/* Entry that needs validation. */
     char *string;		/* New characters to add (NULL-terminated
				 * string). */
     char *new;                 /* Potential new value of entry string */
     int index;                 /* index of insert/delete, -1 otherwise */
     int type;                  /* -1 == forced, 0 == delete, 1 == insert
				 * -2 == focusin, -3 == focusout */
{
    int code;
    char *p;
    Arg result;
    Tcl_DString script;

    if (entryPtr->validateCmd == NULL ||
	entryPtr->validate == VALIDATE_NONE) {
	return TCL_OK;
    }

    /*
     * If we're already validating, then we're hitting a loop condition
     * Return and set validate to 0 to disallow further validations
     * and prevent current validation from finishing
     */
    if (entryPtr->flags & VALIDATING) {
	if (entryPtr->flags & VALIDATE_VAR) {
	    return TCL_OK;
	}
	else {
	    Tcl_SetResult(entryPtr->interp,"Validate recursed",TCL_STATIC);
	    return TCL_ERROR;
	}
    }

    entryPtr->flags |= VALIDATING;

    /*
     * Now form command string and run through the -validatecommand
     */

#ifndef _LANG
    Tcl_DStringInit(&script);
    ExpandPercents(entryPtr, entryPtr->validateCmd,
		   string, new, index, type, &script);
    Tcl_DStringAppend(&script, "", 1);

    p = Tcl_DStringValue(&script);
    code = EntryValidate(entryPtr, p);
    Tcl_DStringFree(&script);
#else

    code = LangDoCallback(entryPtr->interp, entryPtr->validateCmd, 1, 5, "%s %s %s %d %d",
                          new, string,  entryPtr->string, index, type);
    if (code != TCL_OK && code != TCL_RETURN) {
	Tcl_AddErrorInfo(entryPtr->interp,
		 "\n\t(in validation command executed by entry)");
	Tcl_BackgroundError(entryPtr->interp);
	goto done;
    }

    result = Tcl_ResultArg(entryPtr->interp);

    if (Tcl_GetBoolean(entryPtr->interp,  result, &code) != TCL_OK) {
	Tcl_AddErrorInfo(entryPtr->interp,
		 "\nValid Tcl Boolean not returned by validation command");
	Tcl_BackgroundError(entryPtr->interp);
	Tcl_SetResult(entryPtr->interp, (char *) NULL, TCL_STATIC);
        code = TCL_ERROR;
	goto done;
    }

    Tcl_ResetResult(entryPtr->interp);
    code = (code) ? TCL_OK : TCL_BREAK;

#endif

    /*
     * If e->validate has become VALIDATE_NONE during the validation,
     * it means that a loop condition almost occured.  Do not allow
     * this validation result to finish.
     */
    if (entryPtr->validate == VALIDATE_NONE ) {
	code = TCL_ERROR;
    }
    /*
     * If validate will return ERROR, then disallow further validations
     * Otherwise, if it didn't accept the new string (returned TCL_BREAK)
     * then eval the invalidCmd (if it's set)
     */
    if (code == TCL_ERROR) {
	entryPtr->validate = VALIDATE_NONE;
    } else if (code == TCL_BREAK) {
	if (entryPtr->invalidCmd != NULL) {
#ifndef _LANG
	    Tcl_DStringInit(&script);
	    ExpandPercents(entryPtr, entryPtr->invalidCmd,
			   string, new, index, type, &script);
	    Tcl_DStringAppend(&script, "", 1);
	    p = Tcl_DStringValue(&script);
	    if (Tcl_Eval(entryPtr->interp, p) != TCL_OK) {
		Tcl_AddErrorInfo(entryPtr->interp,
				 "\n\t(in invalidcommand executed by entry)");
		Tcl_BackgroundError(entryPtr->interp);
		code = TCL_ERROR;
		entryPtr->validate = VALIDATE_NONE;
	    }
	    Tcl_DStringFree(&script);
#else
	    if (LangDoCallback(entryPtr->interp, entryPtr->invalidCmd, 1, 5, "%s %s %s %d %d",
			       new, string, entryPtr->string, index, type) != TCL_OK) {
		Tcl_AddErrorInfo(entryPtr->interp,
				 "\n\t(in invalidcommand executed by entry)");
		Tcl_BackgroundError(entryPtr->interp);
		code = TCL_ERROR;
		entryPtr->validate = VALIDATE_NONE;
	    }
#endif
	}
    }

done:
    entryPtr->flags &= ~VALIDATING;
    return code;
}

/*
 *--------------------------------------------------------------
 *
 * ExpandPercents --
 *
 *	Given a command and an event, produce a new command
 *	by replacing % constructs in the original command
 *	with information from the X event.
 *
 * Results:
 *	The new expanded command is appended to the dynamic string
 *	given by dsPtr.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

#ifndef _LANG
static void
ExpandPercents(entryPtr, before, add, new, index, type, dsPtr)
     register Entry *entryPtr;	/* Entry that needs validation. */
     register char *before;	/* Command containing percent
				 * expressions to be replaced. */
     char *add; 		/* New characters to add (NULL-terminated
				 * string). */
     char *new;                 /* Potential new value of entry string */
     int index;                 /* index of insert/delete */
     int type;                  /* INSERT or DELETE */
     Tcl_DString *dsPtr;        /* Dynamic string in which to append
				 * new command. */
{
    int spaceNeeded, cvtFlags;	/* Used to substitute string as proper Tcl
				 * list element. */
    int number, length;
#define NUM_SIZE 40
    register char *string;
    char numStorage[NUM_SIZE+1];

    while (1) {
	/*
	 * Find everything up to the next % character and append it
	 * to the result string.
	 */

	for (string = before; (*string != 0) && (*string != '%'); string++) {
	    /* Empty loop body. */
	}
	if (string != before) {
	    Tcl_DStringAppend(dsPtr, before, string-before);
	    before = string;
	}
	if (*before == 0) {
	    break;
	}

	/*
	 * There's a percent sequence here.  Process it.
	 */

	number = 0;
	string = "??";
	switch (before[1]) {
	  case 'd': /* Type of call that caused validation */
	    number = type;
	    goto doNumber;
	  case 'i': /* index of insert/delete */
	    number = index;
	    goto doNumber;
	  case 'P': /* 'Peeked' new value of the string */
	    string = new;
	    goto doString;
	  case 's': /* Current string value of entry */
	    string = entryPtr->string;
	    goto doString;
	  case 'S': /* string to be inserted/delete, if any */
	    string = add;
	    goto doString;
	  case 'v': /* type of validation */
	    string = ValidatePrintProc((ClientData) NULL, entryPtr->tkwin,
				       (char *) entryPtr, 0, 0);
	    goto doString;
	  case 'W': /* widget name */
	    string = Tk_PathName(entryPtr->tkwin);
	    goto doString;
	  default:
	    numStorage[0] = before[1];
	    numStorage[1] = '\0';
	    string = numStorage;
	    goto doString;
	}

	doNumber:
	sprintf(numStorage, "%d", number);
	string = numStorage;

	doString:
	spaceNeeded = Tcl_ScanElement(string, &cvtFlags);
	length = Tcl_DStringLength(dsPtr);
	Tcl_DStringSetLength(dsPtr, length + spaceNeeded);
	spaceNeeded = Tcl_ConvertElement(string,
		Tcl_DStringValue(dsPtr) + length,
		cvtFlags | TCL_DONT_USE_BRACES);
	Tcl_DStringSetLength(dsPtr, length + spaceNeeded);
	before += 2;
    }
}
#endif /* _LANG */

/*
 *--------------------------------------------------------------
 *
 * ValidateParseProc --
 *
 *	This procedure is invoked by Tk_ConfigureWidget during
 *	option processing to handle "-validate" options for entry
 *	widgets.
 *
 * Results:
 *	A standard Tcl return value.
 *
 * Side effects:
 *	The validation style for the entry widget may change.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static int
ValidateParseProc(clientData, interp, tkwin, ovalue, widgRec, offset)
    ClientData clientData;		/* Not used.*/
    Tcl_Interp *interp;			/* Used for reporting errors. */
    Tk_Window tkwin;			/* Window for text widget. */
    Arg ovalue;			/* Value of option. */
    char *widgRec;			/* Pointer to widgRec structure. */
    int offset;				/* Offset into item (ignored). */
{
    int c;
    size_t length;
    char *value = LangString(ovalue);

    register int *validatePtr = (int *) (widgRec + offset);

    if(value == NULL || *value == 0) {
	*validatePtr = VALIDATE_NONE;
	return TCL_OK;
    }

    c = value[0];
    length = strlen(value);
    if ((c == 'n') && (strncmp(value, "none", length) == 0)) {
	*validatePtr = VALIDATE_NONE;
    } else if ((c == 'a') && (strncmp(value, "all", length) == 0)) {
	*validatePtr = VALIDATE_ALL;
    } else if ((c == 'k') && (strncmp(value, "key", length) == 0)) {
	*validatePtr = VALIDATE_KEY;
    } else if (strcmp(value, "focus") == 0) {
	*validatePtr = VALIDATE_FOCUS;
    } else if (strcmp(value, "focusin") == 0) {
	*validatePtr = VALIDATE_FOCUSIN;
    } else if (strcmp(value, "focusout") == 0) {
	*validatePtr = VALIDATE_FOCUSOUT;
    } else {
	Tcl_AppendResult(interp, "bad validation type \"", value,
		"\": must be none, all, key, focus, focusin, or focusout",
		(char *) NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ValidatePrintProc --
 *
 *	This procedure is invoked by the Tk configuration code
 *	to produce a printable string for the "-validate" configuration
 *	option for entry widgets.
 *
 * Results:
 *	The return value is a string describing the entry
 *	widget's current validation style.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static Arg
ValidatePrintProc(clientData, tkwin, widgRec, offset, freeProcPtr)
    ClientData clientData;		/* Ignored. */
    Tk_Window tkwin;			/* Window for text widget. */
    char *widgRec;			/* Pointer to widgRec structure. */
    int offset;				/* Ignored. */
    Tcl_FreeProc **freeProcPtr;		/* Pointer to variable to fill in with
					 * information about how to reclaim
					 * storage for return string. */
{
    register int *validatePtr = (int *) (widgRec + offset);
    Arg result = NULL;

    switch (*validatePtr) {
	case VALIDATE_NONE:
	    return LangStringArg("none");
	case VALIDATE_ALL:
	    return LangStringArg("all");
	case VALIDATE_KEY:
	    return LangStringArg("key");
	case VALIDATE_FOCUS:
	    return LangStringArg("focus");
	case VALIDATE_FOCUSIN:
	    return LangStringArg("focusin");
	    break;
	case VALIDATE_FOCUSOUT:
	    return LangStringArg("focusout");
	    break;
	default:
	    return NULL;
    }
}
#endif /* ENTRY_VALIDATE */
