/*
   $Id: dbdimp.h,v 1.1 2003/07/18 00:23:04 aa Exp $

   Copyright (c) 1997-2001  Michael Peppler

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

   Based on DBD::Oracle dbdimp.h, Copyright (c) 1994,1995 Tim Bunce

*/

typedef struct imp_fbh_st imp_fbh_t;

/*
** Maximum character buffer for displaying a column
*/
#define MAX_CHAR_BUF	1024


typedef struct _col_data
{
    CS_SMALLINT	indicator;
    CS_INT	type;
    CS_INT      realType;
    CS_INT      realLength;
    union {
	CS_CHAR	*c;
	CS_INT i;
	CS_FLOAT f;
/*	CS_DATETIME dt;
	CS_MONEY mn;
	CS_NUMERIC num; */
    } value;
    CS_INT	valuelen;
} ColData;


struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
};

#define MAX_SQL_SIZE 255

/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t com;		/* MUST be first element in structure	*/
    
    CS_CONNECTION *connection;
    CS_LOCALE     *locale;
    CS_IODESC      iodesc;
    char      tranName[32];
    int       inTransaction;
    int       doRealTran;
    int       chainedSupported;
    int       quotedIdentifier;
    int	      useBin0x;
    int       binaryImage;

    int lasterr;
    int lastsev;

    char      uid[32];
    char      pwd[32];

    char      server[64];
    char      charset[64];
    char      packetSize[64];
    char      language[64];
    char      ifile[255];
    char      loginTimeout[64];
    char      timeout[64];
    char      scriptName[255];
    char      hostname[255];
    char      database[36];
    char      tdsLevel[30];
    char      encryptPassword[10];

    int       isDead;

    SV	      *err_handler;

    SV        *row_cb;

    int       showEed;
    int       showSql;
    int       flushFinish;
    int       rowcount;
    int       doProcStatus;
    int       deadlockRetry;
    int       deadlockSleep;
    int       deadlockVerbose;

    int       noChildCon;	/* Don't create child connections for
				   simultaneous statement handles */
    int       failedDbUseFatal;
    int       bindEmptyStringNull;
    int       alwaysForceFailure; /* PR/471 */

    char      *sql;
};

typedef struct phs_st {
    int ftype;
    int sql_type;
    SV *sv;
    int sv_type;
    bool is_inout;
    IV maxlen;

    char *sv_buf;

    CS_DATAFMT datafmt;
    char varname[34];
    
    int alen_incnull;	/* 0 or 1 if alen should include null	*/
    char name[1];	/* struct is malloc'd bigger as needed	*/

} phs_t;


/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/

    CS_CONNECTION *connection;	/* set if this is a sub-connection */
    CS_COMMAND *cmd;
    ColData    *coldata;
    CS_DATAFMT *datafmt;

    int         numCols;
    CS_INT      lastResType;
    CS_INT      numRows;
    int         moreResults;

    int         doProcStatus;
    int         lastProcStatus;
    int         noBindBlob;

    int         retryCount;

    int         exec_done;

    /* Input Details	*/
    char      dyn_id[50];	/* The id for this ct_dynamic() call */
    int       dyn_execed;       /* true if ct_dynamic(CS_EXECUTE) has been called */
    int       type;		/* 0 = normal, 1 => rpc */
    char      proc[150];	/* used for rpc calls */
    char      *statement;	/* sql (see sth_scan)		*/
    HV        *all_params_hv;	/* all params, keyed by name	*/
    AV        *out_params_av;	/* quick access to inout params	*/
    int        syb_pad_empty;	/* convert ""->" " when binding	*/

    /* Select Column Output Details	*/
    int        done_desc;   /* have we described this sth yet ?	*/

    /* (In/)Out Parameter Details */
    int  has_inout_params;
};
#define IMP_STH_EXECUTING	0x0001

int syb_db_date_fmt _((SV *, imp_dbh_t *, char *));
