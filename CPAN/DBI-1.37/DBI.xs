/* vim: ts=8:sw=4
 *
 * $Id: DBI.xs,v 1.1 2003/07/18 00:20:55 aa Exp $
 *
 * Copyright (c) 1994-2003  Tim Bunce  Ireland.
 *
 * See COPYRIGHT section in DBI.pm for usage and distribution rights.
 */

#define IN_DBI_XS 1	/* see DBIXS.h */

#include "DBIXS.h"	/* DBI public interface for DBD's written in C	*/

# if (defined(_WIN32) && (! defined(HAS_GETTIMEOFDAY)))
#include <sys/timeb.h>
# endif

#define MY_VERSION "DBI(" XS_VERSION ")"

#if (defined USE_THREADS || defined PERL_CAPI || defined PERL_OBJECT)
static int xsbypass = 0;	/* disable XSUB->XSUB shortcut		*/
#else
static int xsbypass = 1;	/* enable XSUB->XSUB shortcut		*/
#endif

#define DBI_MAGIC '~'

/* If the tests fail with errors about 'setlinebuf' then try	*/
/* deleting the lines in the block below except the setvbuf one	*/
#ifndef PerlIO_setlinebuf
#ifdef HAS_SETLINEBUF
#define PerlIO_setlinebuf(f)        setlinebuf(f)
#else
#ifndef USE_PERLIO
#define PerlIO_setlinebuf(f)        setvbuf(f, Nullch, _IOLBF, 0)
#endif
#endif
#endif

#ifndef CopFILEGV
#  define CopFILEGV(cop) cop->cop_filegv
#  define CopLINE(cop)   cop->cop_line
#  define CopSTASH(cop)           cop->cop_stash
#  define CopSTASHPV(cop)           (CopSTASH(cop) ? HvNAME(CopSTASH(cop)) : Nullch)
#endif
#ifndef PERL_GET_THX
#define PERL_GET_THX ((void*)0)
#endif
#ifndef PerlProc_getpid
#define PerlProc_getpid() getpid()
extern Pid_t getpid (void);
#endif
#ifndef aTHXo_
#define aTHXo_
#endif

#if (PERL_VERSION < 8) || ((PERL_VERSION == 8) && (PERL_SUBVERSION == 0))
#define DBI_save_hv_fetch_ent
#endif


static imp_xxh_t *dbih_getcom	   _((SV *h));
static imp_xxh_t *dbih_getcom2	   _((SV *h, MAGIC **mgp));
static void       dbih_clearcom	   _((imp_xxh_t *imp_xxh));
static int	  dbih_logmsg	   _((imp_xxh_t *imp_xxh, char *fmt, ...));
static SV	 *dbih_make_com	   _((SV *parent_h, imp_xxh_t *p_imp_xxh, char *imp_class, STRLEN imp_size, STRLEN extra, SV *template));
static SV	 *dbih_make_fdsv   _((SV *sth, char *imp_class, STRLEN imp_size, char *col_name));
static AV        *dbih_get_fbav	   _((imp_sth_t *imp_sth));
static SV	 *dbih_event	   _((SV *h, char *name, SV*, SV*));
static int        dbih_set_attr_k  _((SV *h, SV *keysv, int dbikey, SV *valuesv));
static SV        *dbih_get_attr_k  _((SV *h, SV *keysv, int dbikey));

static int	set_err _((SV *h, imp_xxh_t *imp_xxh, int errval, char *errstr, char *state));
static int	quote_type _((int sql_type, int p, int s, int *base_type, void *v));
static int	dbi_hash _((char *string, long i));
static void	dbih_dumphandle _((SV *h, char *msg, int level));
static void	dbih_dumpcom _((imp_xxh_t *imp_xxh, char *msg, int level));
char *neatsvpv _((SV *sv, STRLEN maxlen));

DBISTATE_DECLARE;

struct imp_drh_st { dbih_drc_t com; };
struct imp_dbh_st { dbih_dbc_t com; };
struct imp_sth_st { dbih_stc_t com; };
struct imp_fdh_st { dbih_fdc_t com; };


/* Internal Method Attributes (attached to dispatch methods when installed) */

typedef struct dbi_ima_st {
    short minargs;
    short maxargs;
    short hidearg;
    char *usage_msg;
    U16   flags;
    U16   trace_level;
} dbi_ima_t;

/* These values are embedded in the data passed to install_method	*/
#define IMA_HAS_USAGE		0x0001	/* check parameter usage	*/
#define IMA_FUNC_REDIRECT	0x0002	/* is $h->func(..., "method")	*/
#define IMA_KEEP_ERR		0x0004	/* don't reset err & errstr	*/
#define IMA_KEEP_ERR_SUB	0x0008	/*  '' if in a nested call	*/
#define IMA_NO_TAINT_IN   	0x0010	/* don't check for tainted args	*/
#define IMA_NO_TAINT_OUT   	0x0020	/* don't taint results		*/
#define IMA_COPY_STMT   	0x0040	/* copy sth Statement to dbh	*/
#define IMA_END_WORK	   	0x0080	/* set on commit & rollback	*/
#define IMA_STUB		0x0100	/* donothing eg $dbh->connected */
#define IMA_CLEAR_STMT   	0x0200	/* clear Statement before call	*/
#define IMA_PROF_EMPTY_STMT   	0x0400	/* profile as empty Statement	*/
#define IMA_NOT_FOUND_OKAY   	0x0800	/* no error if not found	*/

#define DBIc_STATE_adjust(imp_xxh, state)				 \
    (SvOK(state)	/* SQLSTATE is implemented by driver   */	 \
	? (strEQ(SvPV(state,lna),"00000") ? &sv_no : sv_mortalcopy(state))\
	: (SvTRUE(DBIc_ERR(imp_xxh))					 \
	    ? sv_2mortal(newSVpv("S1000",5)) /* General error	*/	 \
	    : &sv_no)			/* Success ("00000")	*/	 \
    )

#define DBI_LAST_HANDLE		g_dbi_last_h /* special fake inner handle */
#define DBI_IS_LAST_HANDLE(h)	((DBI_LAST_HANDLE) == SvRV(h))
#define DBI_SET_LAST_HANDLE(h)	((DBI_LAST_HANDLE) =  SvRV(h))
#define DBI_UNSET_LAST_HANDLE	((DBI_LAST_HANDLE) =  &sv_undef)
#define DBI_LAST_HANDLE_OK	((DBI_LAST_HANDLE) != &sv_undef )

#ifdef PERL_LONG_MAX
#define MAX_LongReadLen PERL_LONG_MAX
#else
#define MAX_LongReadLen 2147483647L
#endif

#ifdef DBI_USE_THREADS
static char *dbi_build_opt = "-ithread";
#else
static char *dbi_build_opt = "-nothread";
#endif

/* 32 bit magic FNV-0 and FNV-1 prime */
#define FNV_32_PRIME ((UV)0x01000193)

/* --- make DBI safe for multiple perl interpreters --- */
/*     Contributed by Murray Nesbitt of ActiveState     */
typedef struct {
    SV   *dbi_last_h;
    dbistate_t* dbi_state;
} PERINTERP_t;

#if defined(MULTIPLICITY) || defined(PERL_OBJECT) || defined(PERL_CAPI)

#   if (PATCHLEVEL == 4) && (SUBVERSION < 68)
#     define dPERINTERP_SV                                     \
        SV *perinterp_sv = get_sv(MY_VERSION, FALSE)
#   else
#     define dPERINTERP_SV                                     \
        SV *perinterp_sv = *hv_fetch(PL_modglobal, MY_VERSION, \
                                 sizeof(MY_VERSION)-1, TRUE)
#   endif

#   define dPERINTERP_PTR(T,name)                            \
	T name = (T)(perinterp_sv && SvIOK(perinterp_sv)     \
                 ? (T)SvIVX(perinterp_sv) : NULL)
#   define dPERINTERP                                        \
	dPERINTERP_SV; dPERINTERP_PTR(PERINTERP_t *, PERINTERP)
#   define INIT_PERINTERP \
	dPERINTERP;                                          \
	Newz(0,PERINTERP,1,PERINTERP_t);                     \
	sv_setiv(perinterp_sv, (IV)PERINTERP)

#   undef DBIS
#   define DBIS			(PERINTERP->dbi_state)

#else
    static PERINTERP_t Interp;
#   define dPERINTERP typedef int _interp_DBI_dummy
#   define PERINTERP (&Interp)
#   define INIT_PERINTERP 
#endif

#define g_dbi_last_h            (PERINTERP->dbi_last_h)

/* --- */

static void
check_version(char *name, int dbis_cv, int dbis_cs, int need_dbixs_cv, int drc_s, 
	int dbc_s, int stc_s, int fdc_s)
{
    dPERINTERP;
    char *msg = "you probably need to rebuild the DBD driver (or possibly the DBI)";
    if (dbis_cv != DBISTATE_VERSION || dbis_cs != sizeof(*DBIS))
	croak("DBI/DBD internal version mismatch (DBI is v%d/s%d, DBD %s expected v%d/s%d) %s.\n",
	    DBISTATE_VERSION, sizeof(*DBIS), name, dbis_cv, dbis_cs, msg);
    /* Catch structure size changes - We should probably force a recompile if the DBI	*/
    /* runtime version is different from the build time. That would be harsh but safe.	*/
    if (drc_s != sizeof(dbih_drc_t) || dbc_s != sizeof(dbih_dbc_t) ||
	stc_s != sizeof(dbih_stc_t) || fdc_s != sizeof(dbih_fdc_t) )
	    croak("%s (dr:%d/%d, db:%d/%d, st:%d/%d, fd:%d/%d), %s.\n",
		"DBI/DBD internal structure mismatch",
		drc_s, sizeof(dbih_drc_t), dbc_s, sizeof(dbih_dbc_t),
		stc_s, sizeof(dbih_stc_t), fdc_s, sizeof(dbih_fdc_t), msg);
}

static void
dbi_bootinit(dbistate_t * parent_dbis)
{
INIT_PERINTERP;

    Newz(dummy, DBIS, 1, dbistate_t);

    /* store version and size so we can spot DBI/DBD version mismatch	*/
    DBIS->check_version = check_version;
    DBIS->version = DBISTATE_VERSION;
    DBIS->size    = sizeof(*DBIS);
    DBIS->xs_version = DBIXS_VERSION;

    DBIS->logmsg      = dbih_logmsg;
    DBIS->logfp	      = PerlIO_stderr();
    DBIS->debug	      = (parent_dbis) ? parent_dbis->debug : 0;
    DBIS->neatsvpvlen = (parent_dbis) ? parent_dbis->neatsvpvlen
				      : perl_get_sv("DBI::neat_maxlen", GV_ADDMULTI);
#ifdef DBI_USE_THREADS
    DBIS->thr_owner   = PERL_GET_THX;
#endif

    /* publish address of dbistate so dynaloaded DBD's can find it	*/
    sv_setiv(perl_get_sv(DBISTATE_PERLNAME,1), (IV)DBIS);

    DBISTATE_INIT; /* check DBD code to set DBIS from DBISTATE_PERLNAME	*/

    /* store some function pointers so DBD's can call our functions	*/
    DBIS->getcom      = dbih_getcom;
    DBIS->clearcom    = dbih_clearcom;
    DBIS->event       = dbih_event;
    DBIS->set_attr_k  = dbih_set_attr_k;
    DBIS->get_attr_k  = dbih_get_attr_k;
    DBIS->get_fbav    = dbih_get_fbav;
    DBIS->make_fdsv   = dbih_make_fdsv;
    DBIS->neat_svpv   = neatsvpv;
    DBIS->bind_as_num = quote_type;
    DBIS->hash        = dbi_hash;

    /* Remember the last handle used. BEWARE! Sneaky stuff here!	*/
    /* We want a handle reference but we don't want to increment	*/
    /* the handle's reference count and we don't want perl to try	*/
    /* to destroy it during global destruction. Take care!		*/
    DBI_UNSET_LAST_HANDLE;	/* ensure setup the correct way		*/

    /* trick to avoid 'possible typo' warnings	*/
    gv_fetchpv("DBI::state",  GV_ADDMULTI, SVt_PV);
    gv_fetchpv("DBI::err",    GV_ADDMULTI, SVt_PV);
    gv_fetchpv("DBI::errstr", GV_ADDMULTI, SVt_PV);
    gv_fetchpv("DBI::lasth",  GV_ADDMULTI, SVt_PV);
    gv_fetchpv("DBI::rows",   GV_ADDMULTI, SVt_PV);
}


/* ----------------------------------------------------------------- */
/* Utility functions                                                 */


static char *
dbih_htype_name(int htype)
{
    switch(htype) {
    case DBIt_DR: return "dr";
    case DBIt_DB: return "db";
    case DBIt_ST: return "st";
    case DBIt_FD: return "fd";
    default:      return "??";
    }
}


char *
neatsvpv(SV *sv, STRLEN maxlen) /* return a tidy ascii value, for debugging only */
{
    dPERINTERP;
    STRLEN len;
    SV *nsv = Nullsv;
    SV *infosv = Nullsv;
    char *v;

    /* We take care not to alter the supplied sv in any way at all.	*/

    if (!sv)
	return "Null!";				/* should never happen	*/

    /* try to do the right thing with magical values			*/
    if (SvMAGICAL(sv)) {
	if (DBIS->debug >= 3) {	/* add magic details to help debugging	*/
	    MAGIC* mg;
	    infosv = sv_2mortal(newSVpv(" (magic-",0));
	    if (SvSMAGICAL(sv)) sv_catpvn(infosv,"s",1);
	    if (SvGMAGICAL(sv)) sv_catpvn(infosv,"g",1);
	    if (SvRMAGICAL(sv)) sv_catpvn(infosv,"r",1);
	    sv_catpvn(infosv,":",1);
	    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
		sv_catpvn(infosv, &mg->mg_type, 1);
	    sv_catpvn(infosv, ")", 1);
	}
	if (SvGMAGICAL(sv))
	    mg_get(sv);		/* trigger magic to FETCH the value	*/
    }

    if (!SvOK(sv)) {
	if (SvTYPE(sv) >= SVt_PVAV)
	    return sv_reftype(sv,0);	/* raw AV/HV etc, not via a ref	*/
	if (!infosv)
	    return "undef";
	sv_insert(infosv, 0,0, "undef",5);
	return SvPVX(infosv);
    }

    if (SvNIOK(sv)) {	  /* is a numeric value - so no surrounding quotes	*/
	char buf[48];
	if (SvPOK(sv)) {  /* already has string version of the value, so use it	*/
	    v = SvPV(sv,len);
	    if (len == 0) { v="''"; len=2; } /* catch &sv_no style special case	*/
	    if (!infosv)
		return v;
	    sv_insert(infosv, 0,0, v, len);
	    return SvPVX(infosv);
	}
	/* we don't use SvPV here since we don't want to alter sv in _any_ way	*/
	if (SvIOK(sv))
	     sprintf(buf, "%ld", (long)SvIVX(sv));
	else sprintf(buf, "%g",  (double)SvNVX(sv));
	nsv = sv_2mortal(newSVpv(buf, 0));
	if (infosv)
	    sv_catsv(nsv, infosv);
	return SvPVX(nsv);
    }

    nsv = sv_newmortal();
    sv_upgrade(nsv, SVt_PV);

    if (SvROK(sv)) {
	if (!SvAMAGIC(sv))	/* (un-amagic'd) refs get no special treatment	*/
	    v = SvPV(sv,len);
	else {
	    /* handle Overload magic refs */
	    SvAMAGIC_off(sv);	/* should really be done via local scoping */
	    v = SvPV(sv,len);	/* XXX how does this relate to SvGMAGIC?   */
	    SvAMAGIC_on(sv);
	}
	sv_setpvn(nsv, v, len);
	if (infosv)
	    sv_catsv(nsv, infosv);
	return SvPV(nsv, len);
    }

    if (SvPOK(sv))		/* usual simple string case		   */
	v = SvPV(sv,len);
    else			/* handles all else via sv_2pv()	   */
	v = SvPV(sv,len);	/* XXX how does this relate to SvGMAGIC?   */

    /* for strings we limit the length and translate codes	*/
    if (maxlen == 0)
	maxlen = SvIV(DBIS->neatsvpvlen);
    if (maxlen < 6)			/* handle daft values	*/
	maxlen = 6;
    maxlen -= 2;			/* account for quotes	*/
    if (len > maxlen) {
	SvGROW(nsv, (1+maxlen+4+1));
	sv_setpvn(nsv, "'", 1);
	sv_catpvn(nsv, v, maxlen-3);	/* account for three dots */
	sv_catpvn(nsv, "...'", 4);
    } else {
	SvGROW(nsv, (1+len+1+1));
	sv_setpvn(nsv, "'", 1);
	sv_catpvn(nsv, v, len);
	sv_catpvn(nsv, "'", 1);
    }
    if (infosv)
	sv_catsv(nsv, infosv);
    v = SvPV(nsv, len);
    while(len-- > 0) { /* cleanup string (map control chars to ascii etc) */
	char c = v[len] & 0x7F;	/* ignore top bit for multinational chars */
	if (!isPRINT(c) && !isSPACE(c))
	    v[len] = '.';
    }
    return v;
}


static int
set_err(SV *h, imp_xxh_t *imp_xxh, int errval, char *errstr, char *state)
{
    STRLEN lna;
    sv_setiv(DBIc_ERR(imp_xxh),    errval);
    if (!errstr || !*errstr)
	errstr = SvPV(DBIc_ERR(imp_xxh), lna);
    sv_setpv(DBIc_ERRSTR(imp_xxh), errstr);
    if (state && *state) {
	if (strlen(state) != 5)
	    croak("set_err: state must be 5 character string");
	sv_setpv(DBIc_STATE(imp_xxh), state);
    }
    else {
	(void)SvOK_off(DBIc_STATE(imp_xxh));
    }
    return 0;
}


static char *
mkvname( HV *stash, char *item, int uplevel)	/* construct a variable name	*/
{
    STRLEN lna;
    SV *sv = sv_newmortal();
    sv_setpv(sv, HvNAME(stash));
    if(uplevel) {
	while(SvCUR(sv) && *SvEND(sv)!=':')
	    --SvCUR(sv);
	if (SvCUR(sv))
	    --SvCUR(sv);
    }
    sv_catpv(sv, "::");
    sv_catpv(sv, item);
    return SvPV(sv, lna);
}


static int
dbi_hash(char *key, long type)
{
    if (type == 0) {
	STRLEN klen = strlen(key);
	U32 hash = 0;
	while (klen--)
	    hash = hash * 33 + *key++;
	hash &= 0x7FFFFFFF;	/* limit to 31 bits		*/
	hash |= 0x40000000;	/* set bit 31			*/
	return -(int)hash;	/* return negative int	*/
    }
    else if (type == 1) {	/* Fowler/Noll/Vo hash	*/
	/* see http://www.isthe.com/chongo/tech/comp/fnv/ */
	U32 hash = 0x811c9dc5;
	unsigned char *s = (unsigned char *)key;    /* unsigned string */
	while (*s) {
	    /* multiply by the 32 bit FNV magic prime mod 2^64 */
	    hash *= FNV_32_PRIME;
	    /* xor the bottom with the current octet */
	    hash ^= (U32)*s++;
	}
	return hash;
    }
    croak("DBI::hash(%d): invalid type", type);
    return 0; /* NOT REACHED */
}


static int
dbih_logmsg(imp_xxh_t *imp_xxh, char *fmt, ...)
{
    dPERINTERP;
    va_list args;
#ifdef I_STDARG
    va_start(args, fmt);
#else
    va_start(args);
#endif
    (void) PerlIO_vprintf(DBIS->logfp, fmt, args);
    va_end(args);
    return 1;
}


static int
set_trace_file(SV *file)
{
    dPERINTERP;
    STRLEN lna;
    char *filename;
    PerlIO *fp;
    if (!file)		/* no arg == no change */
	return 0;
    /* XXX need to support file being a filehandle object */
    filename = (SvOK(file)) ? SvPV(file, lna) : Nullch;
    /* undef arg == reset back to stderr */
    if (!filename || strEQ(filename,"STDERR")) {
	if (DBILOGFP != PerlIO_stderr() && DBILOGFP != PerlIO_stdout())
	    PerlIO_close(DBILOGFP);
	DBILOGFP = PerlIO_stderr();
	return 1;
    }
    if (strEQ(filename,"STDOUT")) {
	if (DBILOGFP != PerlIO_stderr() && DBILOGFP != PerlIO_stdout())
	    PerlIO_close(DBILOGFP);
	DBILOGFP = PerlIO_stdout();
	return 1;
    }
    fp = PerlIO_open(filename, "a+");
    if (fp == Nullfp) {
	warn("Can't open trace file %s: %s", filename, Strerror(errno));
	return 0;
    }
    else {
	if (DBILOGFP != PerlIO_stderr())
	    PerlIO_close(DBILOGFP);
	DBILOGFP = fp;
	/* if this line causes your compiler or linker to choke	*/
	/* then just comment it out, it's not essential.	*/
	PerlIO_setlinebuf(fp);	/* force line buffered output */
	return 1;
    }
}


static int
set_trace(SV *h, int level, SV *file)
{
    dPERINTERP;
    D_imp_xxh(h);
    SV *dsv = DBIc_DEBUG(imp_xxh);
    /* Return trace level in effect now. No change if new value not given */
    int RETVAL = (DBIS->debug > SvIV(dsv)) ? DBIS->debug : SvIV(dsv);
    set_trace_file(file);
    if (level != RETVAL) {	 /* set value */
	if (level > 0) {
	    PerlIO_printf(DBILOGFP,"    %s trace level set to %d in DBI %s%s\n",
		neatsvpv(h,0), level, XS_VERSION, dbi_build_opt);
	    if (!dowarn && level>0)
		PerlIO_printf(DBILOGFP,"    Note: perl is running without the recommended perl -w option\n");
	    PerlIO_flush(DBILOGFP);
	}
	sv_setiv(dsv, level);
    }
    return RETVAL;
}


static SV *
dbih_inner(SV *orv, char *what)
{   /* convert outer to inner handle else croak(what) if what is not null */
    dPERINTERP;
    MAGIC *mg;
    SV *ohv;		/* outer HV after derefing the RV	*/
    SV *hrv;		/* dni inner handle RV-to-HV		*/

    /* enable a raw HV (not ref-to-HV) to be passed in, eg DBIc_MY_H */
    ohv = SvROK(orv) ? SvRV(orv) : orv;

    if (!ohv || SvTYPE(ohv) != SVt_PVHV) {
	if (!what)
	    return NULL;
	if (DBIS->debug)
	    sv_dump(orv);
	if (!SvOK(orv))
	    croak("%s given an undefined handle %s",
		what, "(perhaps returned from a previous call which failed)");
	croak("%s handle %s is not a DBI handle", what, neatsvpv(orv,0));
    }
    if (!SvMAGICAL(ohv)) {
	sv_dump(orv);
	croak("%s handle %s is not a DBI handle (has no magic)",
		what, neatsvpv(orv,0));
    }

    if ( (mg=mg_find(ohv,'P')) == NULL) {	/* hash tie magic	*/
	/* not tied, maybe it's already an inner handle... */
	if (mg_find(ohv, DBI_MAGIC) == NULL) {
	    if (!what)
		return NULL;
	    sv_dump(orv);
	    croak("%s handle %s is not a valid DBI handle",
		what, neatsvpv(orv,0));
	}
	hrv = orv; /* was already a DBI handle inner hash */
    }
    else {
	hrv = mg->mg_obj;  /* inner hash of tie */
    }

    /* extra checks if being paranoid */
    if (DBIS->debug && (!SvROK(hrv) || SvTYPE(SvRV(hrv)) != SVt_PVHV)) {
	if (!what)
	    return NULL;
	sv_dump(orv);
	croak("panic: %s inner handle %s is not a hash ref",
		what, neatsvpv(hrv,0));
    }
    return hrv;
}



/* --------------------------------------------------------------------	*/
/* Functions to manage a DBI handle (magic and attributes etc).     	*/

static imp_xxh_t *
dbih_getcom(SV *hrv) /* used by drivers via DBIS func ptr */
{
    imp_xxh_t *imp_xxh = dbih_getcom2(hrv, 0);
    if (!imp_xxh)	/* eg after take_imp_data */
	croak("Invalid DBI handle %s, has no dbi_imp_data", neatsvpv(hrv,0));
    return imp_xxh;
}

static imp_xxh_t *
dbih_getcom2(SV *hrv, MAGIC **mgp) /* Get com struct for handle. Must be fast.	*/
{
    dPERINTERP;
    imp_xxh_t *imp_xxh;
    MAGIC *mg;
    SV *sv;

    /* important and quick sanity check (esp non-'safe' Oraperl)	*/
    if (SvROK(hrv)) 			/* must at least be a ref */
	sv = SvRV(hrv);
    else if (hrv == DBI_LAST_HANDLE)	/* special for var::FETCH */
	sv = DBI_LAST_HANDLE;
    else {
	sv_dump(hrv);
	croak("Invalid DBI handle %s", neatsvpv(hrv,0));
    }

    /* Short cut for common case. We assume that a magic var always	*/
    /* has magic and that DBI_MAGIC, if present, will be the first.	*/
    if (SvRMAGICAL(sv) && (mg=SvMAGIC(sv))->mg_type == DBI_MAGIC) {
	/* nothing to do here */
    }
    else {
	/* Validate handle (convert outer to inner if required)	*/
	hrv = dbih_inner(hrv, "dbih_getcom");
	mg  = mg_find(SvRV(hrv), DBI_MAGIC);
    }
    if (mgp)	/* let caller pickup magic struct for this handle */
	*mgp = mg;

    if (!mg->mg_obj)	/* eg after take_imp_data */
	return 0;

    /* ignore 'cast increases required alignment' warning	*/
    /* not a problem since we created the pointers anyway.	*/
    imp_xxh = (imp_xxh_t*)(void*)SvPVX(mg->mg_obj);

    return imp_xxh;
}


static SV *
dbih_setup_attrib(SV *h, char *attrib, SV *parent, int read_only, int optional)
{
    dPERINTERP;
    STRLEN len = strlen(attrib);
    SV **asvp;

    asvp = hv_fetch((HV*)SvRV(h), attrib, len, !optional);
    /* we assume that we won't have any existing 'undef' attributes here */
    /* (or, alternately, we take undef to mean 'copy from parent')	 */
    if (!(asvp && SvOK(*asvp))) { /* attribute doesn't already exists (the common case) */
	SV **psvp;
	if ((!parent || !SvROK(parent)) && !optional) {
	    croak("dbih_setup_attrib(%s): %s not set and no parent supplied",
		    neatsvpv(h,0), attrib);
	}
	psvp = hv_fetch((HV*)SvRV(parent), attrib, len, 0);
	if (psvp) {
	    if (!asvp)
		asvp = hv_fetch((HV*)SvRV(h), attrib, len, 1);
	    sv_setsv(*asvp, *psvp); /* copy attribute from parent to handle */
	}
	else {
	    if (!optional)
		croak("dbih_setup_attrib(%s): %s not set and not in parent",
		    neatsvpv(h,0), attrib);
	}
    }
    if (DBIS->debug >= 5) {
	PerlIO_printf(DBILOGFP,"    dbih_setup_attrib(%s, %s, %s)",
	    neatsvpv(h,0), attrib, neatsvpv(parent,0));
	if (!asvp)
	     PerlIO_printf(DBILOGFP," undef (not defined)\n");
	else
	if (SvOK(*asvp))
	     PerlIO_printf(DBILOGFP," %s (already defined)\n", neatsvpv(*asvp,0));
	else PerlIO_printf(DBILOGFP," %s (copied from parent)\n", neatsvpv(*asvp,0));
    }
    if (read_only && asvp)
	SvREADONLY_on(*asvp);
    return asvp ? *asvp : &sv_undef;
}


static SV *
dbih_make_fdsv(SV *sth, char *imp_class, STRLEN imp_size, char *col_name)
{
    dPERINTERP;
    D_imp_sth(sth);
    STRLEN cn_len = strlen(col_name);
    imp_fdh_t *imp_fdh;
    SV *fdsv;
    if (imp_size < sizeof(imp_fdh_t) || cn_len<10 || strNE("::fd",&col_name[cn_len-4]))
	croak("panic: dbih_makefdsv %s '%s' imp_size %d invalid",
		imp_class, col_name, imp_size);
    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    dbih_make_fdsv(%s, %s, %ld, '%s')\n",
		neatsvpv(sth,0), imp_class, (long)imp_size, col_name);
    fdsv = dbih_make_com(sth, (imp_xxh_t*)imp_sth, imp_class, imp_size, cn_len+2, 0);
    imp_fdh = (imp_fdh_t*)(void*)SvPVX(fdsv);
    imp_fdh->com.col_name = ((char*)imp_fdh) + imp_size;
    strcpy(imp_fdh->com.col_name, col_name);
    return fdsv;
}


static SV *
dbih_make_com(SV *p_h, imp_xxh_t *p_imp_xxh, char *imp_class, STRLEN imp_size, STRLEN extra, SV* template)
{
    dPERINTERP;
    char *errmsg = "Can't make DBI com handle for %s: %s";
    HV *imp_stash;
    SV *dbih_imp_sv;
    imp_xxh_t *imp;
    STRLEN memzero_size;

    if ( (imp_stash = gv_stashpv(imp_class, FALSE)) == NULL)
        croak(errmsg, imp_class, "unknown package");

    if (imp_size == 0) {
	/* get size of structure to allocate for common and imp specific data   */
	char *imp_size_name = mkvname(imp_stash, "imp_data_size", 0);
	imp_size = SvIV(perl_get_sv(imp_size_name, 0x05));
	if (imp_size == 0) {
	    imp_size = sizeof(imp_sth_t);
	    if (sizeof(imp_dbh_t) > imp_size)
		imp_size = sizeof(imp_dbh_t);
	    if (sizeof(imp_drh_t) > imp_size)
		imp_size = sizeof(imp_drh_t);
	    imp_size += 4;
	}
    }

    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    dbih_make_com(%s, %p, %s, %ld, %p) thr#%p\n",
	    neatsvpv(p_h,0), p_imp_xxh, imp_class, (long)imp_size, template, PERL_GET_THX);

    if (template) {
	/* validate the supplied dbi_imp_data looks reasonable,	*/
	if (SvCUR(template) != imp_size)
	    croak("Can't use dbi_imp_data, wrong size (%d not %d)",
		SvCUR(template), imp_size);
	/* copy the whole template, then zero out our imp_xxh struct */
	dbih_imp_sv = newSVsv(template);
	switch ( (p_imp_xxh) ? DBIc_TYPE(p_imp_xxh)+1 : DBIt_DR ) {
	case DBIt_DR: memzero_size = sizeof(imp_drh_t); break;
	case DBIt_DB: memzero_size = sizeof(imp_dbh_t); break;
	case DBIt_ST: memzero_size = sizeof(imp_sth_t); break;
	default: croak("dbih_make_com dbi_imp_data bad h type");
	}
    }
    else {
	dbih_imp_sv = newSV(imp_size); /* is grown to imp_size+1 */
	memzero_size = imp_size;
    }
    imp = (imp_xxh_t*)(void*)SvPVX(dbih_imp_sv);
    memzero((char*)imp, memzero_size);

    DBIc_DBISTATE(imp)  = DBIS;
    DBIc_IMP_STASH(imp) = imp_stash;

    if (!p_h) {		/* only a driver (drh) has no parent	*/
	DBIc_PARENT_H(imp)    = &sv_undef;
	DBIc_PARENT_COM(imp)  = NULL;
	DBIc_TYPE(imp)	      = DBIt_DR;
	DBIc_on(imp,DBIcf_WARN		/* set only here, children inherit	*/
		   |DBIcf_ACTIVE	/* drivers are 'Active' by default	*/
		   |DBIcf_AutoCommit	/* advisory, driver must manage this	*/
	);
    } else {		
	DBIc_PARENT_H(imp)    = (SV*)SvREFCNT_inc(p_h); /* ensure it lives	*/
	DBIc_PARENT_COM(imp)  = p_imp_xxh;	 	/* shortcut for speed	*/
	DBIc_TYPE(imp)	      = DBIc_TYPE(p_imp_xxh) + 1;
	DBIc_FLAGS(imp)       = DBIc_FLAGS(p_imp_xxh) & ~DBIcf_INHERITMASK;
	++DBIc_KIDS(p_imp_xxh);
    }
#ifdef DBI_USE_THREADS
    DBIc_THR_USER(imp) = PERL_GET_THX ;
#endif

    if (DBIc_TYPE(imp) == DBIt_ST) {
	imp_sth_t *imp_sth = (imp_sth_t*)imp;
	DBIc_ROW_COUNT(imp_sth)  = -1;
    }

    DBIc_COMSET_on(imp);	/* common data now set up		*/

    /* The implementor should DBIc_IMPSET_on(imp) when setting up	*/
    /* any private data which will need clearing/freeing later.		*/

    return dbih_imp_sv;
}


static void
dbih_setup_handle(SV *orv, char *imp_class, SV *parent, SV *imp_datasv)
{
    dPERINTERP;
    SV *h;
    char *errmsg = "Can't setup DBI handle of %s to %s: %s";
    SV *dbih_imp_sv;
    SV *dbih_imp_rv;
    SV *dbi_imp_data = Nullsv;
    SV **svp;
    char imp_mem_name[300];
    HV  *imp_mem_stash;
    imp_xxh_t *imp;
    imp_xxh_t *parent_imp;

    h      = dbih_inner(orv, "dbih_setup_handle");
    parent = dbih_inner(parent, NULL);	/* check parent valid (& inner)	*/

    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    dbih_setup_handle(%s=>%s, %s, %lx, %s)\n",
	    neatsvpv(orv,0), neatsvpv(h,0), imp_class, (long)parent, neatsvpv(imp_datasv,0));

    if (mg_find(SvRV(h), DBI_MAGIC) != NULL)
	croak(errmsg, neatsvpv(orv,0), imp_class, "already a DBI (or ~magic) handle");

    strcpy(imp_mem_name, imp_class);
    strcat(imp_mem_name, "_mem");
    if ( (imp_mem_stash = gv_stashpv(imp_mem_name, FALSE)) == NULL) 
        croak(errmsg, neatsvpv(orv,0), imp_mem_name, "unknown _mem package");

    DBI_LOCK;

    if (parent) {
	parent_imp = DBIh_COM(parent);
	if (DBIc_TYPE(parent_imp) == DBIt_DR && (svp = hv_fetch((HV*)SvRV(h), "dbi_imp_data", 12, 0))) {
	    dbi_imp_data = *svp;
	}
    }
    else {
	parent_imp = NULL;
    }

    dbih_imp_sv = dbih_make_com(parent, parent_imp, imp_class, 0, 0, dbi_imp_data);
    imp = (imp_xxh_t*)(void*)SvPVX(dbih_imp_sv);

    dbih_imp_rv = newRV(dbih_imp_sv);	/* just needed for sv_bless */
    sv_bless(dbih_imp_rv, imp_mem_stash);
    sv_free(dbih_imp_rv);

    DBIc_MY_H(imp) = (HV*)SvRV(orv);	/* take _copy_ of pointer, not new ref	*/
    DBIc_IMP_DATA(imp) = (imp_datasv) ? newSVsv(imp_datasv) : &sv_undef;

    if (DBIc_TYPE(imp) <= DBIt_ST) {
	SV **tmp_svp;
	/* Copy some attributes from parent if not defined locally and	*/
	/* also take address of attributes for speed of direct access.	*/
	/* parent is null for drh, in which case h must hold the values	*/
#define COPY_PARENT(name,ro,opt) SvREFCNT_inc(dbih_setup_attrib(h,(name),parent,ro,opt))
#define DBIc_ATTR(imp, f) _imp2com(imp, attr.f)
	/* XXX we should validate that these are the right type (refs etc)	*/
	DBIc_ATTR(imp, Err)      = COPY_PARENT("Err",1,0);	/* scalar ref	*/
	DBIc_ATTR(imp, State)    = COPY_PARENT("State",1,0);	/* scalar ref	*/
	DBIc_ATTR(imp, Errstr)   = COPY_PARENT("Errstr",1,0);	/* scalar ref	*/
	DBIc_ATTR(imp, TraceLevel)=COPY_PARENT("TraceLevel",0,0);/* scalar (int)*/
	DBIc_ATTR(imp, FetchHashKeyName) = COPY_PARENT("FetchHashKeyName",0,0);	/* scalar ref */
	if (parent) {
	    dbih_setup_attrib(h,"HandleError",parent,0,1);
	    if (DBIc_has(parent_imp,DBIcf_Profile)) {
		dbih_setup_attrib(h,"Profile",parent,0,1);
	    }
	    DBIc_LongReadLen(imp) = DBIc_LongReadLen(parent_imp);
	}
	else {
	    DBIc_LongReadLen(imp) = DBIc_LongReadLen_init;
	}

	switch (DBIc_TYPE(imp)) {
	case DBIt_DB:
	    /* cache _inner_ handle, but also see quick_FETCH */
	    hv_store((HV*)SvRV(h), "Driver", 6, newRV(SvRV(parent)), 0);
	    hv_store((HV*)SvRV(h), "Statement", 9, &sv_undef, 0);
	    break;
	case DBIt_ST:
	    /* cache _inner_ handle, but also see quick_FETCH */
	    hv_store((HV*)SvRV(h), "Database", 8, newRV(SvRV(parent)), 0);
	    /* copy (alias) Statement from the sth up into the dbh	*/
	    tmp_svp = hv_fetch((HV*)SvRV(h), "Statement", 9, 1);
	    hv_store((HV*)SvRV(parent), "Statement", 9, SvREFCNT_inc(*tmp_svp), 0);
	    break;
	}
    }

    /* Use DBI magic on inner handle to carry handle attributes 	*/
    sv_magic(SvRV(h), dbih_imp_sv, DBI_MAGIC, Nullch, 0);
    SvREFCNT_dec(dbih_imp_sv);	/* since sv_magic() incremented it	*/
    SvRMAGICAL_on(SvRV(h));	/* so magic gets sv_clear'd ok		*/

    DBI_SET_LAST_HANDLE(h);

    DBI_UNLOCK;
}


static void
dbih_dumphandle(SV *h, char *msg, int level)
{
    D_imp_xxh(h);
    dbih_dumpcom(imp_xxh, msg, level);
}

static void
dbih_dumpcom(imp_xxh_t *imp_xxh, char *msg, int level)
{
    dPERINTERP;
    SV *flags = sv_2mortal(newSVpv("",0));
    STRLEN lna;
    char *pad = "      ";
    if (!msg)
	msg = "dbih_dumpcom";
    PerlIO_printf(DBILOGFP,"    %s (%sh 0x%lx 0x%lx, com 0x%lx, imp %s):\n",
	msg, dbih_htype_name(DBIc_TYPE(imp_xxh)),
	(long)DBIc_MY_H(imp_xxh), (long)SvRVx(DBIc_MY_H(imp_xxh)),
	(long)imp_xxh, HvNAME(DBIc_IMP_STASH(imp_xxh)));
    if (DBIc_COMSET(imp_xxh))			sv_catpv(flags,"COMSET ");
    if (DBIc_IMPSET(imp_xxh))			sv_catpv(flags,"IMPSET ");
    if (DBIc_ACTIVE(imp_xxh))			sv_catpv(flags,"Active ");
    if (DBIc_WARN(imp_xxh))			sv_catpv(flags,"Warn ");
    if (DBIc_COMPAT(imp_xxh))			sv_catpv(flags,"CompatMode ");
    if (DBIc_is(imp_xxh, DBIcf_ChopBlanks))	sv_catpv(flags,"ChopBlanks ");
    if (DBIc_is(imp_xxh, DBIcf_RaiseError))	sv_catpv(flags,"RaiseError ");
    if (DBIc_is(imp_xxh, DBIcf_PrintError))	sv_catpv(flags,"PrintError ");
    if (DBIc_is(imp_xxh, DBIcf_HandleError))	sv_catpv(flags,"HandleError ");
    if (DBIc_is(imp_xxh, DBIcf_ShowErrorStatement))	sv_catpv(flags,"ShowErrorStatement ");
    if (DBIc_is(imp_xxh, DBIcf_AutoCommit))	sv_catpv(flags,"AutoCommit ");
    if (DBIc_is(imp_xxh, DBIcf_BegunWork))	sv_catpv(flags,"BegunWork ");
    if (DBIc_is(imp_xxh, DBIcf_LongTruncOk))	sv_catpv(flags,"LongTruncOk ");
    if (DBIc_is(imp_xxh, DBIcf_MultiThread))	sv_catpv(flags,"MultiThread ");
    if (DBIc_is(imp_xxh, DBIcf_TaintIn))	sv_catpv(flags,"TaintIn ");
    if (DBIc_is(imp_xxh, DBIcf_TaintOut))	sv_catpv(flags,"TaintOut ");
    if (DBIc_is(imp_xxh, DBIcf_Profile))	sv_catpv(flags,"Profile ");
    PerlIO_printf(DBILOGFP,"%s FLAGS 0x%lx: %s\n", pad, (long)DBIc_FLAGS(imp_xxh), SvPV(flags,lna));
    PerlIO_printf(DBILOGFP,"%s PARENT %s\n",	pad, neatsvpv((SV*)DBIc_PARENT_H(imp_xxh),0));
    PerlIO_printf(DBILOGFP,"%s KIDS %ld (%ld Active)\n", pad,
		    (long)DBIc_KIDS(imp_xxh), (long)DBIc_ACTIVE_KIDS(imp_xxh));
    PerlIO_printf(DBILOGFP,"%s IMP_DATA %s\n", pad, neatsvpv(DBIc_IMP_DATA(imp_xxh),0));
    if (DBIc_LongReadLen(imp_xxh) != DBIc_LongReadLen_init)
	PerlIO_printf(DBILOGFP,"%s LongReadLen %ld\n", pad, (long)DBIc_LongReadLen(imp_xxh));

    if (DBIc_TYPE(imp_xxh) <= DBIt_DB) {
	imp_dbh_t *imp_dbh = (imp_dbh_t*)imp_xxh;
	if (DBIc_CACHED_KIDS(imp_dbh))
	    PerlIO_printf(DBILOGFP,"%s CachedKids %d\n", pad, (int)HvKEYS(DBIc_CACHED_KIDS(imp_dbh)));
    }
    if (DBIc_TYPE(imp_xxh) == DBIt_ST) {
	imp_sth_t *imp_sth = (imp_sth_t*)imp_xxh;
	PerlIO_printf(DBILOGFP,"%s NUM_OF_FIELDS %d\n", pad, DBIc_NUM_FIELDS(imp_sth));
	PerlIO_printf(DBILOGFP,"%s NUM_OF_PARAMS %d\n", pad, DBIc_NUM_PARAMS(imp_sth));
    }
    if (level > 0) {
        SV* value;
	char *key;
	I32   keylen;
	SV *inner;
	PerlIO_printf(DBILOGFP,"%s cached attributes:\n", pad);
	inner = dbih_inner((SV*)DBIc_MY_H(imp_xxh), msg);
	while ( (value = hv_iternextsv((HV*)SvRV(inner), &key, &keylen)) ) {
	    PerlIO_printf(DBILOGFP,"%s   '%s' => %s\n", pad, key, neatsvpv(value,0));
	}
    }
}


static void
dbih_clearcom(imp_xxh_t *imp_xxh)
{
    dPERINTERP;
    dTHR;
    dTHX;
    int dump = FALSE;
    int debug = DBIS->debug;
    int auto_dump = (debug >= 6);

    /* Note that we're very much on our own here. DBIc_MY_H(imp_xxh) almost	*/
    /* certainly points to memory which has been freed. Don't use it!		*/

    /* --- pre-clearing sanity checks --- */

#ifdef DBI_USE_THREADS
    if (DBIc_THR_USER(imp_xxh) != my_perl) { /* don't clear handle that belongs to another thread */
	if (debug >= 3) {
	    PerlIO_printf(DBILOGFP,"    skipped dbih_clearcom: DBI handle (type=%d, %s) is owned by thread %p not current thread %p\n", 
		  DBIc_TYPE(imp_xxh), HvNAME(DBIc_IMP_STASH(imp_xxh)), DBIc_THR_USER(imp_xxh), my_perl) ;
	    PerlIO_flush(DBILOGFP);
	}
	return;
    }
#endif

    if (!DBIc_COMSET(imp_xxh)) {	/* should never happen	*/
	dbih_dumpcom(imp_xxh, "dbih_clearcom: DBI handle already cleared", 0);
	return;
    }

    if (auto_dump)
	dbih_dumpcom(imp_xxh,"DESTROY (dbih_clearcom)", 0);

    if (!dirty) {
	if (DBIc_TYPE(imp_xxh) <= DBIt_DB) {
	    imp_dbh_t *imp_dbh = (imp_dbh_t*)imp_xxh; /* works for DRH also */
	    if (DBIc_CACHED_KIDS(imp_dbh)) {
		warn("DBI handle cleared whilst still holding %d cached kids",
			HvKEYS(DBIc_CACHED_KIDS(imp_dbh)) );
		SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh)); /* may recurse */
		DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
	    }
	}

	if (DBIc_ACTIVE(imp_xxh)) {	/* bad news		*/
	    warn("DBI handle cleared whilst still active");
	    dump = TRUE;
	}

	/* check that the implementor has done its own housekeeping	*/
	if (DBIc_IMPSET(imp_xxh)) {
	    warn("DBI handle has uncleared implementors data");
	    dump = TRUE;
	}

	if (DBIc_KIDS(imp_xxh)) {
	    warn("DBI handle has %d uncleared child handles",
		    (int)DBIc_KIDS(imp_xxh));
	    dump = TRUE;
	}
    }

    if (dump && !auto_dump) /* else was already dumped above */
	dbih_dumpcom(imp_xxh, "dbih_clearcom", 0);

    /* --- pre-clearing adjustments --- */

    if (DBIc_PARENT_COM(imp_xxh) && !dirty) {
	--DBIc_KIDS(DBIc_PARENT_COM(imp_xxh));
    }

    /* --- clear fields (may invoke object destructors) ---	*/

    if (DBIc_TYPE(imp_xxh) == DBIt_ST) {
	imp_sth_t *imp_sth = (imp_sth_t*)imp_xxh;
	if (DBIc_FIELDS_AV(imp_sth));
	    sv_free((SV*)DBIc_FIELDS_AV(imp_sth));
    }

    sv_free(DBIc_IMP_DATA(imp_xxh));	/* do this first	*/
    if (DBIc_TYPE(imp_xxh) <= DBIt_ST) {	/* DBIt_FD doesn't have attr */
	sv_free(_imp2com(imp_xxh, attr.TraceLevel));
	sv_free(_imp2com(imp_xxh, attr.State));
	sv_free(_imp2com(imp_xxh, attr.Err));
	sv_free(_imp2com(imp_xxh, attr.Errstr));
	sv_free(_imp2com(imp_xxh, attr.FetchHashKeyName));
    }


    sv_free((SV*)DBIc_PARENT_H(imp_xxh));	/* do this last		*/

    DBIc_COMSET_off(imp_xxh);

    if (debug >= 4)
	PerlIO_printf(DBILOGFP,"    dbih_clearcom 0x%lx (com 0x%lx, type %d) done.\n\n",
		(long)DBIc_MY_H(imp_xxh), (long)imp_xxh, DBIc_TYPE(imp_xxh));
}


/* --- Functions for handling field buffer arrays ---		*/

static AV *
dbih_setup_fbav(imp_sth_t *imp_sth)
{
    dPERINTERP;
    int i;
    AV *av;

   if (DBIc_FIELDS_AV(imp_sth))
	return DBIc_FIELDS_AV(imp_sth);

    i = DBIc_NUM_FIELDS(imp_sth);
    if (i <= 0 || i > 32000)	/* trap obvious mistakes */
	croak("dbih_setup_fbav: invalid number of fields: %d%s",
		i, ", NUM_OF_FIELDS attribute probably not set right");
    av = newAV();
    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    dbih_setup_fbav for %d fields => 0x%lx\n",
		    i, (long)av);
    /* load array with writeable SV's. Do this backwards so	*/
    /* the array only gets extended once.			*/
    while(i--)			/* field 1 stored at index 0	*/
	av_store(av, i, newSV(0));
    SvREADONLY_on(av);		/* protect against shift @$row etc */
    /* row_count will need to be manually reset by the driver if the	*/
    /* sth is re-executed (since this code won't get rerun)		*/
    DBIc_ROW_COUNT(imp_sth) = 0;
    DBIc_FIELDS_AV(imp_sth) = av;
    return av;
}


static AV *
dbih_get_fbav(imp_sth_t *imp_sth)
{
    AV *av;

    if ( (av = DBIc_FIELDS_AV(imp_sth)) == Nullav)
	av = dbih_setup_fbav(imp_sth);

    if (DBIc_is(imp_sth, DBIcf_TaintOut)) {
	dTHR;
	TAINT;	/* affects sv_setsv()'s called within same perl statement */
    }

    /* XXX fancy stuff to happen here later (re scrolling etc)	*/
    ++DBIc_ROW_COUNT(imp_sth);
    return av;
}


static int
dbih_sth_bind_col(SV *sth, SV *col, SV *ref, SV *attribs)
{
    dPERINTERP;
    D_imp_sth(sth);
    AV *av;
    int idx = SvIV(col);
    int fields = DBIc_NUM_FIELDS(imp_sth);

    if (fields <= 0) {
	attribs = attribs;	/* avoid 'unused variable' warning	*/
	croak("Statement has no result columns to bind%s",
	    DBIc_ACTIVE(imp_sth)
		? "" : " (perhaps you need to call execute first)");
    }

    if (!SvROK(ref) || SvTYPE(SvRV(ref)) >= SVt_PVBM)	/* XXX LV */
	croak("Can't %s->bind_col(%s, %s,...), need a reference to a scalar",
		neatsvpv(sth,0), neatsvpv(col,0), neatsvpv(ref,0));

    if ( (av = DBIc_FIELDS_AV(imp_sth)) == Nullav)
	av = dbih_setup_fbav(imp_sth);

    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    dbih_sth_bind_col %s => %s\n",
		neatsvpv(col,0), neatsvpv(ref,0));

    if (idx < 1 || idx > fields)
	croak("bind_col: column %d is not a valid column (1..%d)",
			idx, fields);

    /* use supplied scalar as storage for this column */
    SvREADONLY_off(av);
    av_store(av, idx-1, SvREFCNT_inc(SvRV(ref)) );
    SvREADONLY_on(av);
    return 1;
}


static int
quote_type(int sql_type, int p, int s, int *t, void *v)
{
    /* Returns true if type should be bound as a number else	*/
    /* false implying that binding as a string should be okay.	*/
    /* The true value is either SQL_INTEGER or SQL_DOUBLE which	*/
    /* can be used as a hint if desired.			*/
    switch(sql_type) {
    case SQL_INTEGER:
    case SQL_SMALLINT:
    case SQL_TINYINT:
    case SQL_BIGINT:
	return 0;
    case SQL_FLOAT:
    case SQL_REAL:
    case SQL_DOUBLE:
	return 0;
    case SQL_NUMERIC:
    case SQL_DECIMAL:
	return 0;	/* bind as string to attempt to retain precision */
    }
    return 1;
}


/* --- Generic Handle Attributes (for all handle types) ---	*/

static int
dbih_set_attr_k(SV *h, SV *keysv, int dbikey, SV *valuesv)
{
    dPERINTERP;
    dTHR;
    D_imp_xxh(h);
    STRLEN keylen;
    char  *key = SvPV(keysv, keylen);
    int    htype = DBIc_TYPE(imp_xxh);
    int    on = (SvTRUE(valuesv));
    int    internal = 1; /* DBIh_IN_PERL_DBD(imp_xxh); -- for DBD's in perl */
    int    cacheit = 0;

    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    STORE %s %s => %s\n",
		neatsvpv(h,0), neatsvpv(keysv,0), neatsvpv(valuesv,0));

    if (strEQ(key, "CompatMode")) {
	(on) ? DBIc_COMPAT_on(imp_xxh) : DBIc_COMPAT_off(imp_xxh);
    }
    else if (strEQ(key, "Warn")) {
	(on) ? DBIc_WARN_on(imp_xxh) : DBIc_WARN_off(imp_xxh);
    }
    else if (internal && strEQ(key, "Active")) {
	if (on) {
	    D_imp_sth(h);
	    DBIc_ACTIVE_on(imp_xxh);
	    /* for pure-perl drivers on second and subsequent	*/
	    /* execute()'s, else row count keeps rising.	*/
	    if (htype==DBIt_ST && DBIc_FIELDS_AV(imp_sth))
		DBIc_ROW_COUNT(imp_sth) = 0;
	}
	else {
	    DBIc_ACTIVE_off(imp_xxh);
	}
    }
    else if (strEQ(key, "InactiveDestroy")) {
	(on) ? DBIc_IADESTROY_on(imp_xxh) : DBIc_IADESTROY_off(imp_xxh);
    }
    else if (strEQ(key, "FetchHashKeyName")) {
	if (htype >= DBIt_ST)
	    croak("Can't set FetchHashKeyName for a statement handle, set in parent before prepare()");
	cacheit = 1;	/* just save it */
    }
    else if (strEQ(key, "RootClass")) {
	cacheit = 1;	/* just save it */
    }
    else if (strEQ(key, "RowCacheSize")) {
	cacheit = 0;	/* ignore it */
    }
    else if (strEQ(key, "ChopBlanks")) {
	DBIc_set(imp_xxh,DBIcf_ChopBlanks, on);
    }
    else if (strEQ(key, "LongReadLen")) {
	if (SvNV(valuesv) < 0 || SvNV(valuesv) > MAX_LongReadLen)
	    croak("Can't set LongReadLen < 0 or > %ld",MAX_LongReadLen);
	DBIc_LongReadLen(imp_xxh) = SvIV(valuesv);
	cacheit = 1;	/* save it for clone */
    }
    else if (strEQ(key, "LongTruncOk")) {
	DBIc_set(imp_xxh,DBIcf_LongTruncOk, on);
    }
    else if (strEQ(key, "RaiseError")) {
	DBIc_set(imp_xxh,DBIcf_RaiseError, on);
    }
    else if (strEQ(key, "PrintError")) {
	DBIc_set(imp_xxh,DBIcf_PrintError, on);
    }
    else if (strEQ(key, "HandleError")) {
	if ( on && (!SvROK(valuesv) || (SvTYPE(SvRV(valuesv)) != SVt_PVCV)) ) {
	    croak("Can't set HandleError to '%s'",neatsvpv(valuesv,0));
	}
	DBIc_set(imp_xxh,DBIcf_HandleError, on);
	cacheit = 1; /* child copy setup by dbih_setup_handle() */
    }
    else if (strEQ(key, "Profile")) {
	char *class = "DBI::Profile";
	if (on && (!SvROK(valuesv) || (SvTYPE(SvRV(valuesv)) != SVt_PVHV)) ) {
	    /* not a hash ref so use DBI::Profile to work out what to do */
	    dTHR;
	    dSP;
	    I32 returns;
	    TAINT_NOT; /* the require is presumed innocent till proven guilty */
	    perl_require_pv("DBI/Profile.pm");
	    if (SvTRUE(ERRSV)) {
		STRLEN lna;
		warn("Can't load %s: %s", class, SvPV(ERRSV,lna));
		valuesv = &sv_undef;
	    }
	    else {
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSVpv(class,0)));
		XPUSHs(valuesv);
		PUTBACK;
		returns = perl_call_method("_auto_new", G_SCALAR);
		if (returns != 1)
		    croak("_auto_new");
		SPAGAIN;
		valuesv = POPs;
		PUTBACK;
	    }
	    on = SvTRUE(valuesv); /* in case it returns undef */
	}
	if (on && !sv_isobject(valuesv)) {
	    /* not blessed already - so default to DBI::Profile */
	    HV *stash;
	    perl_require_pv(class);
	    stash = gv_stashpv(class, GV_ADDWARN);
	    sv_bless(valuesv, stash);
	}
	DBIc_set(imp_xxh,DBIcf_Profile, on);
	cacheit = 1; /* child copy setup by dbih_setup_handle() */
    }
    else if (strEQ(key, "ShowErrorStatement")) {
	DBIc_set(imp_xxh,DBIcf_ShowErrorStatement, on);
    }
    else if (strEQ(key, "MultiThread") && internal) {
	/* here to allow pure-perl drivers to set MultiThread */
	DBIc_set(imp_xxh,DBIcf_MultiThread, on);
	if (on && DBIc_WARN(imp_xxh)) {
	    warn("MultiThread support not yet implemented in DBI");
	}
    }
    else if (strEQ(key, "Taint")) {
	/* 'Taint' is a shortcut for both in and out mode */
	DBIc_set(imp_xxh,DBIcf_TaintIn|DBIcf_TaintOut, on);
    }
    else if (strEQ(key, "TaintIn")) {
	DBIc_set(imp_xxh,DBIcf_TaintIn, on);
    }
    else if (strEQ(key, "TaintOut")) {
	DBIc_set(imp_xxh,DBIcf_TaintOut, on);
    }
    else if (htype<=DBIt_DB && keylen==10 && strEQ(key, "CachedKids")) {
	D_imp_dbh(h);	/* XXX also for drh */
	if (DBIc_CACHED_KIDS(imp_dbh)) {
	    SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh));
	    DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
	}
	if (SvROK(valuesv)) {
	    DBIc_CACHED_KIDS(imp_dbh) = (HV*)SvREFCNT_inc(SvRV(valuesv));
	}
    }
    else if (htype<=DBIt_DB && keylen==10 && strEQ(key, "AutoCommit")) {
	/* driver should have intercepted this and either handled it	*/
	/* or set valuesv to either the 'magic' on or off value.	*/
	if (SvIV(valuesv) != -900 && SvIV(valuesv) != -901)
	    croak("DBD driver has not implemented the AutoCommit attribute");
	DBIc_set(imp_xxh,DBIcf_AutoCommit, (SvIV(valuesv)==-901));
    }
    else if (htype==DBIt_DB && keylen==9 && strEQ(key, "BegunWork")) {
	DBIc_set(imp_xxh,DBIcf_BegunWork, on);
    }
    else if (keylen==10  && strEQ(key, "TraceLevel")) {
	set_trace(h, (int)SvIV(valuesv), Nullsv);
    }
    else if (keylen==9  && strEQ(key, "TraceFile")) { /* XXX undocumented and readonly */
	set_trace_file(valuesv);
    }
    else if (htype==DBIt_ST && strEQ(key, "NUM_OF_FIELDS")) {
	D_imp_sth(h);
	if (DBIc_NUM_FIELDS(imp_sth) > 0)	/* don't change NUM_FIELDS! */
	    croak("NUM_OF_FIELDS already set to %d", DBIc_NUM_FIELDS(imp_sth));
	DBIc_NUM_FIELDS(imp_sth) = SvIV(valuesv);
	cacheit = 1;
    }
    else if (htype==DBIt_ST && strEQ(key, "NUM_OF_PARAMS")) {
	D_imp_sth(h);
	DBIc_NUM_PARAMS(imp_sth) = SvIV(valuesv);
	cacheit = 1;
    }
    /* these are here due to clone() needing to set attribs through a public api */
    else if (htype<=DBIt_DB && (strEQ(key, "Name")
			    || strEQ(key,"ImplementorClass")
			    || strEQ(key,"Statement")
			    || strEQ(key,"Username")
    ) ) {
	cacheit = 1;
    }
    else {	/* XXX should really be an event ? */
	if (isUPPER(*key)) {
	    char *hint = "";
	    if (strEQ(key, "NUM_FIELDS"))
		hint = " (perhaps you meant NUM_OF_FIELDS)";
	    croak("Can't set %s->{%s}: unrecognised attribute or invalid value%s",
		    neatsvpv(h,0), key, hint);
	}
	/* Allow private_* attributes to be stored in the cache.	*/
	/* This is designed to make life easier for people subclassing	*/
	/* the DBI classes and may be of use to simple perl DBD's.	*/
	if (strnNE(key,"private_",8) && strnNE(key,"dbd_",4) && strnNE(key,"dbi_",4)) {
	    if (DBIS->debug) { /* change to DBIc_WARN(imp_xxh) once we can validate prefix against registry */
		PerlIO_printf(DBILOGFP,"$h->{%s}=%s ignored for invalid driver-specific attribute\n",
			neatsvpv(keysv,0), neatsvpv(valuesv,0));
	    }
	    return FALSE;
	}
	cacheit = 1;
    }
    if (cacheit) {
	hv_store((HV*)SvRV(h), key, keylen, newSVsv(valuesv), 0);
    }
    return TRUE;
}


static SV *
dbih_get_attr_k(SV *h, SV *keysv, int dbikey)
{
    dPERINTERP;
    dTHR;
    D_imp_xxh(h);
    STRLEN lna;
    STRLEN keylen;
    char  *key = SvPV(keysv, keylen);
    int    htype = DBIc_TYPE(imp_xxh);
    SV	*valuesv = Nullsv;
    int    cacheit = FALSE;
    char *p;
    int i;
    SV	*sv;
    SV	**svp;

    /* DBI quick_FETCH will service some requests (e.g., cached values)	*/

    if (htype == DBIt_ST) {
        switch (*key) {

          case 'D':
            if (keylen==8 && strEQ(key, "Database")) {
                /* this is here but is, sadly, not called because
                 * not-preloading them into the handle attrib cache caused
                 * wierdness in t/proxy.t that I never got to the bottom
                 * of. One day maybe.  */
                D_imp_from_child(imp_dbh, imp_dbh_t, imp_xxh);
                valuesv = newRV((SV*)DBIc_MY_H(imp_dbh));
                cacheit = FALSE;  /* else creates ref loop */
            }
            break;

          case 'N':
            if ((keylen==7 || keylen==9 || keylen==12)
                && strnEQ(key, "NAME_", 5)
                && (	(keylen==9 && strEQ(key, "NAME_hash"))
                      ||	((key[5]=='u' || key[5]=='l') && key[6] == 'c'
                               && (!key[7] || strnEQ(&key[7], "_hash", 5)))
                    )
                ) {
                D_imp_sth(h);
                AV *name_av = NULL;
                valuesv = &sv_undef;

                /* fetch from tied outer handle to trigger FETCH magic */
                svp = hv_fetch((HV*)DBIc_MY_H(imp_sth), "NAME",4, FALSE);
                sv = (svp) ? *svp : &sv_undef;
                if (SvGMAGICAL(sv))	/* resolve the magic		*/
                    mg_get(sv);       /* can core dump in 5.004   */
                name_av = (AV*)SvRV(sv);

                if (sv && name_av) {
                    char *name;
                    int upcase = (key[5] == 'u');
                    AV *av = Nullav;
                    HV *hv = Nullhv;
                    if (strEQ(&key[strlen(key)-5], "_hash"))
                        hv = newHV();
                    else av = newAV();
                    i = DBIc_NUM_FIELDS(imp_sth);
                    assert(i == AvFILL(name_av)+1);
                    while (--i >= 0) {
                        sv = newSVsv(AvARRAY(name_av)[i]);
                        name = SvPV(sv,lna);
                        if (key[5] != 'h') {	/* "NAME_hash" */
                            for (p = name; p && *p; ++p) {
#ifdef toUPPER_LC
                                *p = (upcase) ? toUPPER_LC(*p) : toLOWER_LC(*p);
#else
                                *p = (upcase) ? toUPPER(*p) : toLOWER(*p);
#endif
                            }
                        }
                        if (av)
                            av_store(av, i, sv);
                        else
                            hv_store(hv, name, SvCUR(sv), newSViv(i), 0);
                    }
                    valuesv = newRV(sv_2mortal( (av ? (SV*)av : (SV*)hv) ));
                    cacheit = TRUE;	/* can't change */
                }
            }
            else if (keylen==13 && strEQ(key, "NUM_OF_FIELDS")) {
                D_imp_sth(h);
                valuesv = newSViv(DBIc_NUM_FIELDS(imp_sth));
                if (DBIc_NUM_FIELDS(imp_sth) > 0)
                    cacheit = TRUE;	/* can't change once set */
            }
            else if (keylen==13 && strEQ(key, "NUM_OF_PARAMS")) {
                D_imp_sth(h);
                valuesv = newSViv(DBIc_NUM_PARAMS(imp_sth));
                cacheit = TRUE;	/* can't change */
            }
            break;

          case 'R':
            if (keylen==11 && strEQ(key, "RowsInCache")) {
                valuesv = &sv_undef;
            }
            break;
        }
        
    }
    else
    if (htype == DBIt_DB) {
        /* this is here but is, sadly, not called because
         * not-preloading them into the handle attrib cache caused
         * wierdness in t/proxy.t that I never got to the bottom
         * of. One day maybe.  */
        if (keylen==6 && strEQ(key, "Driver")) {
            D_imp_from_child(imp_dbh, imp_dbh_t, imp_xxh);
            valuesv = newRV((SV*)DBIc_MY_H(imp_dbh));
            cacheit = FALSE;  /* else creates ref loop */
        }
    }

    if (valuesv == Nullsv && htype <= DBIt_DB) {
        if (keylen==10  && strEQ(key, "CachedKids")) {
	    D_imp_dbh(h);
	    HV *hv = DBIc_CACHED_KIDS(imp_dbh);
	    valuesv = (hv) ? newRV((SV*)hv) : &sv_undef;
	}
        else if (keylen==10 && strEQ(key, "AutoCommit")) {
            valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_AutoCommit));
        }
    }

    if (valuesv == Nullsv) {
        switch (*key) {
          case 'A':
            if (keylen==6 && strEQ(key, "Active")) {
                valuesv = boolSV(DBIc_ACTIVE(imp_xxh));
            }
            else if (keylen==10 && strEQ(key, "ActiveKids")) {
                valuesv = newSViv(DBIc_ACTIVE_KIDS(imp_xxh));
            }
            break;
            
          case 'B':
            if (keylen==9 && strEQ(key, "BegunWork")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_BegunWork));
            }
            break;

          case 'C':
            if (strEQ(key, "ChopBlanks")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_ChopBlanks));
            }
            else if (strEQ(key, "CachedKids")) {
                valuesv = &sv_undef;
            }
            else if (strEQ(key, "CompatMode")) {
                valuesv = boolSV(DBIc_COMPAT(imp_xxh));
            }
            break;

          case 'I':
            if (strEQ(key, "InactiveDestroy")) {
                valuesv = boolSV(DBIc_IADESTROY(imp_xxh));
            }
            break;

          case 'K':
            if (keylen==4 && strEQ(key, "Kids")) {
                valuesv = newSViv(DBIc_KIDS(imp_xxh));
            }
            break;

          case 'L':
            if (keylen==11 && strEQ(key, "LongReadLen")) {
                valuesv = newSVnv((double)DBIc_LongReadLen(imp_xxh));
            }
            else if (keylen==11 && strEQ(key, "LongTruncOk")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_LongTruncOk));
            }
            break;

          case 'M':
            if (keylen==10 && strEQ(key, "MultiThread")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_MultiThread));
            }
            break;

          case 'P':
            if (keylen==10 && strEQ(key, "PrintError")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_PrintError));
            }
            break;

          case 'R':
            if (keylen==10 && strEQ(key, "RaiseError")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_RaiseError));
            }
            else if (keylen==12 && strEQ(key, "RowCacheSize")) {
                valuesv = &sv_undef;
            }
            break;

          case 'S':
            if (keylen==18 && strEQ(key, "ShowErrorStatement")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_ShowErrorStatement));
            }
            break;

          case 'T':
            if (keylen==4 && strEQ(key, "Type")) {
                char *type = dbih_htype_name(htype);
                valuesv = newSVpv(type,0);
                cacheit = TRUE;	/* can't change */
            }
            else if (keylen==10  && strEQ(key, "TraceLevel")) {
		/*
		IV d_debug = DBIS->debug;
		IV h_debug = DBIc_DEBUGIV(imp_xxh);
                valuesv = newSViv( (d_debug>h_debug) ? d_debug : h_debug );
		*/
                valuesv = newSViv( DBIc_DEBUGIV(imp_xxh) );
            }
            else if (keylen==5  && strEQ(key, "Taint")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_TaintIn) &&
                                 DBIc_has(imp_xxh,DBIcf_TaintOut));
            }
            else if (keylen==7  && strEQ(key, "TaintIn")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_TaintIn));
            }
            else if (keylen==8  && strEQ(key, "TaintOut")) {
                valuesv = boolSV(DBIc_has(imp_xxh,DBIcf_TaintOut));
            }
            break;

          case 'W':
            if (keylen==4 && strEQ(key, "Warn")) {
                valuesv = boolSV(DBIc_WARN(imp_xxh));
            }
            break;
        }
    }

    /* finally check the actual hash just in case	*/
    if (valuesv == Nullsv) {
	svp = hv_fetch((HV*)SvRV(h), key, keylen, FALSE);
	if (svp)
	    valuesv = newSVsv(*svp);	/* take copy to mortalize */
	else if (!isUPPER(*key))	/* dbd_*, private_* etc */
	    valuesv = &sv_undef;
	else if (	(*key=='H' && strEQ(key, "HandleError"))
		||	(*key=='S' && strEQ(key, "Statement"))
		||	(*key=='P' && strEQ(key, "ParamValues"))
		||	(*key=='P' && strEQ(key, "Profile"))
		||	(*key=='C' && strEQ(key, "CursorName"))
	)
	    valuesv = &sv_undef;
	else
	    croak("Can't get %s->{%s}: unrecognised attribute",neatsvpv(h,0),key);
    }
    
    if (cacheit) {
	svp = hv_fetch((HV*)SvRV(h), key, keylen, TRUE);
	sv = *svp;
	*svp = SvREFCNT_inc(valuesv);
	sv_free(sv);
    }
    if (DBIS->debug >= 3)
	PerlIO_printf(DBILOGFP,"    .. FETCH %s %s = %s%s\n", neatsvpv(h,0),
	    neatsvpv(keysv,0), neatsvpv(valuesv,0), cacheit?" (cached)":"");
    if (valuesv == &sv_yes || valuesv == &sv_no || valuesv == &sv_undef)
	return valuesv;	/* no need to mortalize yes or no */
    return sv_2mortal(valuesv);
}


static SV *			/* find attrib in handle or its parents	*/
dbih_find_attr(SV *h, SV *keysv, int copydown, int spare)
{
    D_imp_xxh(h);
    SV *ph;
    STRLEN keylen;
    char  *key = SvPV(keysv, keylen);
    SV *valuesv;
    SV **svp = hv_fetch((HV*)SvRV(h), key, keylen, FALSE);
    if (svp)
	valuesv = *svp;
    else
    if (!SvOK(ph=(SV*)DBIc_PARENT_H(imp_xxh)))
	valuesv = Nullsv;
    else /* recurse up */
	valuesv = dbih_find_attr(ph, keysv, copydown, spare);
    if (valuesv && copydown)
	hv_store((HV*)SvRV(h), key, keylen, newSVsv(valuesv), 0);
    return valuesv;	/* return actual sv, not a mortalised copy	*/
}


/* --------------------------------------------------------------------	*/
/* Functions implementing Error and Event Handling.                   	*/


static SV *
dbih_event(SV *hrv, char *evtype, SV *a1, SV *a2)
{
    /* We arrive here via DBIh_EVENT* macros (see DBIXS.h) called from	*/
    /* DBD driver C code OR $h->event() method (in DBD::_::common)	*/
    /* XXX VERY OLD INTERFACE/CONCEPT MAY GO SOON */
    /* OR MAY EVOLVE INTO A WAY TO HANDLE 'SUCCESS_WITH_INFO'/'WARNINGS' from db */
    return &sv_undef;
}


/* ----------------------------------------------------------------- */


STATIC I32
dbi_dopoptosub_at(PERL_CONTEXT *cxstk, I32 startingblock)
{
    I32 i;
    register PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
	cx = &cxstk[i];
	switch (CxTYPE(cx)) {
	default:
	    continue;
	case CXt_EVAL:
	case CXt_SUB:
#ifdef CXt_FORMAT
	case CXt_FORMAT:
#endif
	    DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
	    return i;
	}
    }
    return i;
}


static char *
dbi_caller(long *line)
{
    register I32 cxix;
    register PERL_CONTEXT *cx;
    register PERL_CONTEXT *ccstack = cxstack;
    PERL_SI *top_si = PL_curstackinfo;
    char *stashname;

    *line = -1;
    for ( cxix = dbi_dopoptosub_at(ccstack, cxstack_ix) ;; cxix = dbi_dopoptosub_at(ccstack, cxix - 1)) {
	/* we may be in a higher stacklevel, so dig down deeper */
	while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
	    top_si = top_si->si_prev;
	    ccstack = top_si->si_cxstack;
	    cxix = dbi_dopoptosub_at(ccstack, top_si->si_cxix);
	}
	if (cxix < 0) {
	    break;
	}
	if (PL_DBsub && cxix >= 0 && ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
	    continue;
	cx = &ccstack[cxix];
	stashname = CopSTASHPV(cx->blk_oldcop);
	if (!stashname)
	    continue;
	if (!(stashname[0] == 'D'
	    && stashname[1] == 'B'
	    && strchr("DI", stashname[2])
	    && (!stashname[3] || (stashname[3] == ':' && stashname[4] == ':')))) 
	{
	    STRLEN len;
	    *line = (I32)CopLINE(cx->blk_oldcop);
	    return SvPV(GvSV(CopFILEGV(cx->blk_oldcop)), len);
	}
	cxix = dbi_dopoptosub_at(ccstack, cxix - 1);
    }
    return NULL;
}

static char *
log_where(int trace_level, SV *buf, int append, char *suffix)
{
    dTHR;
    if (!buf) {
	buf = sv_2mortal(newSV(80));
	sv_setpv(buf,"");
    }
    else
    if (!append)
	sv_setpv(buf,"");
    if (CopLINE(curcop)) {
	STRLEN len;
	long  near_line = CopLINE(curcop);
	char *near_file = SvPV(GvSV(CopFILEGV(curcop)), len);
	char *file = near_file;
	if (trace_level <= 4) {
	    char *sep;
	    if ( (sep=strrchr(file,'/')) || (sep=strrchr(file,'\\')))
		file = sep+1;
	}
	sv_catpvf(buf, " at %s line %ld", file, near_line);

	if (trace_level >= 3) {
	    long far_line;
	    char *far_file = dbi_caller(&far_line);
	    if (far_file && !(far_line==near_line && strEQ(far_file,near_file)) )
		sv_catpvf(buf, " via %s line %ld", far_file, far_line);
	}
    }
    if (dirty)
	sv_catpvf(buf, " during global destruction");
    if (suffix)
	sv_catpv(buf, suffix);
    return SvPVX(buf);
}


static void
clear_cached_kids(SV *h, imp_xxh_t *imp_xxh, char *meth_name, int trace_level)
{
    dPERINTERP;
    if (DBIc_TYPE(imp_xxh) <= DBIt_DB && DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh)) {
	if (trace_level >= 2) {
	    PerlIO_printf(DBILOGFP,"    >> %s %s clearing %d CachedKids\n",
		meth_name, neatsvpv(h,0), (int)HvKEYS(DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh)));
	    PerlIO_flush(DBILOGFP);
	}
	/* This will probably recurse through dispatch to DESTROY the kids */
	/* For drh we should probably explicitly do dbh disconnects */
	SvREFCNT_dec(DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh));
	DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh) = Nullhv;
    }
}

static double
dbi_time() {
# ifdef HAS_GETTIMEOFDAY
    struct timeval when;
    gettimeofday(&when, (struct timezone *) 0);
    return when.tv_sec + (when.tv_usec / 1000000.0);
# else	/* per-second is almost useless */
# ifdef _WIN32 /* use _ftime() on Win32 (MS Visual C++ 6.0) */
#  if defined(__BORLANDC__)
#   define _timeb timeb
#   define _ftime ftime
#  endif
    struct _timeb when;
    _ftime( &when );
    return when.time + (when.millitm / 1000.0);
# else
    return time(NULL);
# endif
# endif
}

static void
dbi_profile(SV *h, imp_xxh_t *imp_xxh, char *statement, SV *method, double t1, double t2)
{
#define DBIprof_MAX_PATH_ELEM	9	/* STATEMENT->$Statement->$method */
#define DBIprof_COUNT		0
#define DBIprof_TOTAL_TIME	1
#define DBIprof_FIRST_TIME	2
#define DBIprof_MIN_TIME	3
#define DBIprof_MAX_TIME	4
#define DBIprof_FIRST_CALLED	5
#define DBIprof_LAST_CALLED	6
#define DBIprof_max_index	6
    double ti = t2 - t1;
    char *path[DBIprof_MAX_PATH_ELEM+1];
    int idx = -1;
    STRLEN lna;
    SV *profile;
    SV *tmp;
    AV *av;
    HV *h_hv;

    int call_depth = DBIc_CALL_DEPTH(imp_xxh);
    int parent_call_depth = DBIc_PARENT_COM(imp_xxh) ? DBIc_CALL_DEPTH(DBIc_PARENT_COM(imp_xxh)) : 0;
    /* Only count calls originating from the application code	*/
    /* *MAY* be made configurable later				*/
    /* XXX BEWARE that if nested call profile data is merged	*/
    /* with the non-nested data then we'll get invalid results	*/
    if (call_depth > 1 || parent_call_depth > 0)
	return;

    if (!DBIc_has(imp_xxh, DBIcf_Profile))
	return;

    /* XXX need to switch to inner handle */
    h_hv = (SvROK(h)) ? (HV*)SvRV(h) : (HV*)h;

    profile = *hv_fetch(h_hv, "Profile", 7, 1);
    if (profile && SvMAGICAL(profile))
	mg_get(profile); /* FETCH */
    if (!profile || !SvROK(profile)) {
	DBIc_set(imp_xxh, DBIcf_Profile, 0); /* disable */
	if (!dirty)
	    warn("Profile attribute isn't a hash ref (%s,%d)", neatsvpv(profile,0), SvTYPE(profile));
	return;
    }

    if (!statement) {
	SV **psv = hv_fetch(h_hv, "Statement", 9, 0);
	statement = (psv && SvOK(*psv)) ? SvPV(*psv, lna) : "";
    }
    if (DBIc_DBISTATE(imp_xxh)->debug >= 4)
	PerlIO_printf(DBIc_LOGPIO(imp_xxh), "dbi_profile %s %f %d %d q{%s}\n",
		neatsvpv((SvTYPE(method)==SVt_PVCV) ? (SV*)CvGV(method) : method, 0),
		ti, call_depth, parent_call_depth, statement);

    idx = 0;
    path[idx++] = "Data";
    tmp = *hv_fetch((HV*)SvRV(profile), "Path", 4, 1);
    if (SvROK(tmp) && SvTYPE(SvRV(tmp))==SVt_PVCV) {
	/* call sub, use returned list of values as path */
	/* if no values returned then don't save data	*/
	path[idx++] = Nullch;
    }
    else if (SvROK(tmp) && SvTYPE(SvRV(tmp))==SVt_PVAV) {
	int len;
	av = (AV*)SvRV(tmp);
	len = av_len(av); /* -1=empty, 0=one element */
	for ( ;(idx-1) <= len && idx < DBIprof_MAX_PATH_ELEM; ++idx) {
	    SV *pathsv = AvARRAY(av)[idx-1];
	    char *p;
	    switch(SvIOK(pathsv) ? SvIV(pathsv) : 0) {
	    case -2100000001:
		p = statement;
		break;
	    case -2100000002:
		p = (SvTYPE(method)==SVt_PVCV)
			? GvNAME(CvGV(method))
			: (isGV(method) ? GvNAME(method) : SvPV(method,lna));
		break;
	    case -2100000003:
		if (SvTYPE(method) == SVt_PVCV) {
		    p = SvPV((SV*)CvGV(method), lna);
		}
		else if (isGV(method)) {
		    /* just using SvPV(method,lna) sometimes causes an error:	*/
		    /* "Can't coerce GLOB to string" so we use gv_efullname()	*/
		    SV *tmpsv = sv_2mortal(newSVpv("",0));
		    gv_efullname(tmpsv, (GV*)method);
		    p = SvPV(tmpsv,lna);
		}
		else {
		    p = SvPV(method,lna);
		}
		break;
	    default:
		p = SvPV(pathsv,lna);
		break;
	    }
	    path[idx] = p;
	}
    }
    else if (SvOK(tmp)) {
	DBIc_set(imp_xxh, DBIcf_Profile, 0); /* disable */
	warn("Profile Path attribute isn't valid (%s)", neatsvpv(tmp,0));
	return;
    }
    else {
	path[idx++] = statement;
    }
    path[idx++] = Nullch;

    tmp = profile;
    for (idx=0; path[idx]; ++idx) {
	if (SvROK(tmp))
	    tmp = SvRV(tmp);
	else if (SvTYPE(tmp) != SVt_PVHV) {
	    HV *hv = newHV();
	    if (SvOK(tmp))
		warn("Profile data element %s replaced with new hash ref", neatsvpv(tmp,0));
	    sv_setsv(tmp, newRV_noinc((SV*)hv));
	    tmp = (SV*)hv;
	}
	if (SvTYPE(tmp) != SVt_PVHV)
	    break;
	tmp = *hv_fetch((HV*)tmp, path[idx], strlen(path[idx]), 1);
	/* warn("%d hv_fetch %s = %s", idx, path[idx], neatsvpv(tmp,0)); */
    }
    if (!SvOK(tmp)) {
	av = newAV();
	sv_setsv(tmp, newRV_noinc((SV*)av));
	av_store(av, DBIprof_COUNT,		newSViv(1));
	av_store(av, DBIprof_TOTAL_TIME,	newSVnv(ti));
	av_store(av, DBIprof_FIRST_TIME,	newSVnv(ti));
	av_store(av, DBIprof_MIN_TIME,		newSVnv(ti));
	av_store(av, DBIprof_MAX_TIME,		newSVnv(ti));
	av_store(av, DBIprof_FIRST_CALLED,	newSVnv(t1));
	av_store(av, DBIprof_LAST_CALLED,	newSVnv(t1));
        return;
    }
    if (SvROK(tmp))
	tmp = SvRV(tmp);
    if (SvTYPE(tmp) != SVt_PVAV)
	croak("Invalid Profile data leaf element at depth %d: %s (type %d)",
		idx, neatsvpv(tmp,0), SvTYPE(tmp));
    av = (AV*)tmp;
    sv_inc( *av_fetch(av, DBIprof_COUNT, 1));
    tmp = *av_fetch(av, DBIprof_TOTAL_TIME, 1);
    sv_setnv(tmp, SvNV(tmp) + ti);
    tmp = *av_fetch(av, DBIprof_MIN_TIME, 1);
    if (ti < SvNV(tmp)) sv_setnv(tmp, ti);
    tmp = *av_fetch(av, DBIprof_MAX_TIME, 1);
    if (ti > SvNV(tmp)) sv_setnv(tmp, ti);
    sv_setnv( *av_fetch(av, DBIprof_LAST_CALLED, 1), t1);
    return;
}

static void
dbi_profile_merge(SV *dest, SV *increment)
{
    AV *d_av, *i_av;
    SV *tmp;
    double i_nv;
    if (!SvROK(dest)      || SvTYPE(SvRV(dest))      != SVt_PVAV
    ||  !SvROK(increment) || SvTYPE(SvRV(increment)) != SVt_PVAV)
	croak("dbi_profile_merge(%s, %s) requires array refs",
		neatsvpv(dest,0), neatsvpv(dest,0));
    i_av = (AV*)SvRV(increment);
    d_av = (AV*)SvRV(dest);

    if (av_len(d_av) < DBIprof_max_index) {
	int idx;
	av_extend(d_av, DBIprof_max_index);
	for(idx=0; idx<=DBIprof_max_index; ++idx) {
	    tmp = *av_fetch(d_av, idx, 1);
	    if (!SvOK(tmp))
		sv_setiv(tmp, 0);
	}
    }

    tmp = *av_fetch(d_av, DBIprof_COUNT, 1);
    sv_setiv( tmp, SvIV(tmp) + SvIV( *av_fetch(i_av, DBIprof_COUNT, 1)) );

    tmp = *av_fetch(d_av, DBIprof_TOTAL_TIME, 1);
    sv_setnv( tmp, SvNV(tmp) + SvNV( *av_fetch(i_av, DBIprof_TOTAL_TIME, 1)) );

    i_nv = SvNV(*av_fetch(i_av, DBIprof_MIN_TIME, 1));
    tmp  =      *av_fetch(d_av, DBIprof_MIN_TIME, 1);
    if (i_nv < SvNV(tmp)) sv_setnv(tmp, i_nv);

    i_nv = SvNV(*av_fetch(i_av, DBIprof_MAX_TIME, 1));
    tmp  =      *av_fetch(d_av, DBIprof_MAX_TIME, 1);
    if (i_nv > SvNV(tmp)) sv_setnv(tmp, i_nv);

    i_nv = SvNV(*av_fetch(i_av, DBIprof_FIRST_CALLED, 1));
    tmp  =      *av_fetch(d_av, DBIprof_FIRST_CALLED, 1);
    if (i_nv < SvNV(tmp)) {
	sv_setnv(tmp, i_nv);
	/* If the increment has an earlier DBIprof_FIRST_CALLED
	then we use the DBIprof_FIRST_TIME from the increment */
	sv_setnv( tmp, SvNV( *av_fetch(i_av, DBIprof_FIRST_TIME, 1)) );
    }

    i_nv = SvNV(*av_fetch(i_av, DBIprof_LAST_CALLED, 1));
    tmp  =      *av_fetch(d_av, DBIprof_LAST_CALLED, 1);
    if (i_nv > SvNV(tmp)) sv_setnv(tmp, i_nv);
}


/* ----------------------------------------------------------------- */
/* ---   The DBI dispatcher. The heart of the perl DBI.          --- */

XS(XS_DBI_dispatch)         /* prototype must match XS produced code */
{
    dXSARGS;
    dPERINTERP;

    SV *h   = ST(0);		/* the DBI handle we are working with	*/
    SV *st1 = ST(1);		/* used in debugging */
    SV *st2 = ST(2);		/* used in debugging */
    SV *orig_h = h;
    MAGIC *mg;
    STRLEN lna;
    int gimme = GIMME;
    int debug = DBIS->debug;	/* local, may change during dispatch	*/
    int is_DESTROY;
    int is_FETCH;
    int keep_error = FALSE;
    int i, outitems;
    int call_depth;
    double profile_t1 = 0.0;

    char	*meth_name = GvNAME(CvGV(cv));
    dbi_ima_t	*ima       = (dbi_ima_t*)CvXSUBANY(cv).any_ptr;
    imp_xxh_t	*imp_xxh   = NULL;
    SV		*imp_msv   = Nullsv;
    SV		*qsv       = Nullsv; /* quick result from a shortcut method   */


    if (debug >= 9) {
	PerlIO *logfp = DBILOGFP;
        PerlIO_printf(logfp,"%c   >> %-11s DISPATCH (%s rc%ld/%ld @%ld g%x ima%lx pid#%ld)",
	    (dirty?'!':' '), meth_name, neatsvpv(h,0),
	    (long)SvREFCNT(h), (SvROK(h) ? (long)SvREFCNT(SvRV(h)) : (long)-1),
	    (long)items, (int)gimme, (long)(ima?ima->flags:0), (long)PerlProc_getpid());
	PerlIO_puts(logfp, log_where(debug, 0, 0, "\n"));
	PerlIO_flush(logfp);
    }

    if (!SvROK(h) || SvTYPE(SvRV(h)) != SVt_PVHV) {
        croak("%s: handle %s is not a hash reference",meth_name,neatsvpv(h,0));
    }

    if ( ( (is_DESTROY=(*meth_name=='D' && strEQ(meth_name,"DESTROY")))) ) {
	/* note that croak()'s won't propagate, only append to $@ */
	keep_error = TRUE;
    }

    /* If h is a tied hash ref, switch to the inner ref 'behind' the tie.
       This means *all* DBI methods work with the inner (non-tied) ref.
       This makes it much easier for methods to access the real hash
       data (without having to go through FETCH and STORE methods) and
       for tie and non-tie methods to call each other.
    */
    if (SvRMAGICAL(SvRV(h)) && (mg=mg_find(SvRV(h),'P'))!=NULL) {

        if (SvPVX(mg->mg_obj)==NULL) {  /* maybe global destruction */
            if (debug >= 3)
                PerlIO_printf(DBILOGFP,
		    "%c   <> %s for %s ignored (inner handle gone)\n",
		    (dirty?'!':' '), meth_name, neatsvpv(h,0));
	    XSRETURN(0);
        }
	/* Distinguish DESTROY of tie (outer) from DESTROY of inner ref	*/
	/* This may one day be used to manually destroy extra internal	*/
	/* refs if the application ceases to use the handle.		*/
	if (is_DESTROY) {
	    imp_xxh = DBIh_COM(mg->mg_obj);
	    if (imp_xxh && DBIc_TYPE(imp_xxh) <= DBIt_DB && DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh))
		clear_cached_kids(mg->mg_obj, imp_xxh, meth_name, debug);
	    if (debug >= 3)
                PerlIO_printf(DBILOGFP,"%c   <> DESTROY ignored for outer handle %s (inner %s)\n",
		    (dirty?'!':' '), neatsvpv(h,0), neatsvpv(mg->mg_obj,0));
	    /* for now we ignore it since it'll be followed soon by	*/
	    /* a destroy of the inner hash and that'll do the real work	*/
	    XSRETURN(0);
	}
        h = mg->mg_obj; /* switch h to inner ref			*/
        ST(0) = h;      /* switch handle on stack to inner ref		*/
    }

    imp_xxh = dbih_getcom2(h, 0); /* get common Internal Handle Attributes	*/
    if (!imp_xxh) {
	/* XXX perhaps warn() for anything other than DESTROY? */
	if (debug)
	    PerlIO_printf(DBILOGFP, "%c   <> %s for %s ignored (dbi_imp_data gone)\n",
		(dirty?'!':' '), meth_name, neatsvpv(h,0));
	if (!is_DESTROY)
	    warn("Can't call %s method on handle %s after take_imp_data()", meth_name, neatsvpv(h,0));
	XSRETURN(0);
    }

    if (DBIc_has(imp_xxh,DBIcf_Profile)) {
	profile_t1 = dbi_time(); /* just get start time here */
    }

#ifdef DBI_USE_THREADS
{
    PerlInterpreter * h_perl = DBIc_THR_USER(imp_xxh) ;
    if (h_perl != my_perl) {
	/* XXX could call a 'handle clone' method here, for dbh's at least */
	if (is_DESTROY) {
	    if (debug >= 2) {
		PerlIO_printf(DBILOGFP,"    DESTROY ignored because DBI %sh handle (%s) is owned by thread %p not current thread %p\n",
		      dbih_htype_name(DBIc_TYPE(imp_xxh)), HvNAME(DBIc_IMP_STASH(imp_xxh)), h_perl, my_perl) ;
		PerlIO_flush(DBILOGFP);
	    }
	    XSRETURN(0); /* don't DESTROY handle, if it is not our's !*/
	}
	croak("%s %s failed: handle %d is owned by thread %x not current thread %x (%s)",
	    HvNAME(DBIc_IMP_STASH(imp_xxh)), meth_name, DBIc_TYPE(imp_xxh), h_perl, my_perl,
	    "handles can't be shared between threads and your driver may need a CLONE method added");
    }
}
#endif

    /* Check method call against Internal Method Attributes */
    if (ima) {

	if (ima->flags & (IMA_STUB|IMA_FUNC_REDIRECT|IMA_KEEP_ERR|IMA_KEEP_ERR_SUB|IMA_CLEAR_STMT)) {

	    if (ima->flags & IMA_STUB) {
		if (*meth_name == 'c' && strEQ(meth_name,"can")) {
		    char *can_meth = SvPV(st1,lna);
		    SV *dbi_msv = Nullsv;
		    SV	*imp_msv; /* handle implementors method (GV or CV) */
		    if ( (imp_msv = (SV*)gv_fetchmethod(DBIc_IMP_STASH(imp_xxh), can_meth)) ) {
			/* return DBI's CV, not the implementors CV (else we'd bypass dispatch) */
			/* and anyway, we may have hit a private method not part of the DBI	*/
			GV *gv = gv_fetchmethod_autoload(SvSTASH(SvRV(orig_h)), can_meth, FALSE);
			if (gv && isGV(gv))
			    dbi_msv = (SV*)GvCV(gv);
		    }
		    if (debug >= 3) {
			PerlIO *logfp = DBILOGFP;
			PerlIO_printf(logfp,"    <- %s(%s) = %p (%s %p)\n", meth_name, can_meth, dbi_msv,
				(imp_msv && isGV(imp_msv)) ? HvNAME(GvSTASH(imp_msv)) : "?", imp_msv);
		    }
		    if (dbi_msv) {
			ST(0) = sv_2mortal(newRV(dbi_msv));
			XSRETURN(1);
		    }
		}
		XSRETURN(0);
	    }
	    if (ima->flags & IMA_FUNC_REDIRECT) {
		SV *meth_name_sv = POPs;
		PUTBACK;
		--items;
		if (!SvPOK(meth_name_sv) || SvNIOK(meth_name_sv))
		    croak("%s->%s() invalid redirect method name %s",
			    neatsvpv(h,0), meth_name, neatsvpv(meth_name_sv,0));
		meth_name = SvPV(meth_name_sv, lna);
	    }
	    if (ima->flags & IMA_KEEP_ERR)
		keep_error = TRUE;
	    if (ima->flags & IMA_KEEP_ERR_SUB
		&& DBIc_PARENT_COM(imp_xxh) && DBIc_CALL_DEPTH(DBIc_PARENT_COM(imp_xxh)) > 0)
		keep_error = TRUE;
	    if (ima->flags & IMA_CLEAR_STMT)
		hv_store((HV*)SvRV(h), "Statement", 9, &sv_undef, 0);
	}

	if (ima->flags & IMA_HAS_USAGE) {
	    char *err = NULL;
	    char msg[200];

	    if (ima->minargs && (items < ima->minargs
				|| (ima->maxargs>0 && items > ima->maxargs))) {
		/* the error reporting is a little tacky here */
		sprintf(msg,
		    "DBI %s: invalid number of parameters: handle + %ld\n",
		    meth_name, (long)items-1);
		err = msg;
	    }
	    /* arg type checking could be added here later */
	    if (err) {
		croak("%sUsage: %s->%s(%s)", err, "$h", meth_name,
		    (ima->usage_msg) ? ima->usage_msg : "...?");
	    }
	}
    }

    if (tainting && items > 1		      /* method call has args	*/
	&& DBIc_is(imp_xxh, DBIcf_TaintIn)    /* taint checks requested	*/
	&& !(ima && ima->flags & IMA_NO_TAINT_IN)
    ) {
	for(i=1; i < items; ++i) {
	    if (SvTAINTED(ST(i))) {
		char buf[100];
		sprintf(buf,"parameter %d of %s->%s method call",
			i, SvPV(h,lna), meth_name);
		tainted = 1;	/* needed for TAINT_PROPER to work	*/
		TAINT_PROPER(buf);	/* die's */
	    }
	}
    }

    if ( (i = DBIc_DEBUGIV(imp_xxh)) > debug) {
	/* bump up debugging if handle wants it	*/
	debug = i;
    }

    /* record this inner handle for use by DBI::var::FETCH	*/
    if (is_DESTROY) {
	SV *lhp = DBIc_PARENT_H(imp_xxh);

	if (DBIc_TYPE(imp_xxh) <= DBIt_DB ) {	/* is dbh or drh */
	    imp_xxh_t *parent_imp;

	    if (SvTRUE(DBIc_ERR(imp_xxh)) && (parent_imp = DBIc_PARENT_COM(imp_xxh)) ) {
		/* copy err/errstr/state values to $DBI::err etc still work */
		sv_setsv(DBIc_ERR(parent_imp),    DBIc_ERR(imp_xxh));
		sv_setsv(DBIc_ERRSTR(parent_imp), DBIc_ERRSTR(imp_xxh));
		sv_setsv(DBIc_STATE(parent_imp),  DBIc_STATE(imp_xxh));
	    }

	    if (DBIc_CACHED_KIDS((imp_drh_t*)imp_xxh))
		clear_cached_kids(h, imp_xxh, meth_name, debug);
	}

	if (DBI_IS_LAST_HANDLE(h)) {	/* if destroying _this_ handle */
	    if (lhp && SvROK(lhp)) {
		DBI_SET_LAST_HANDLE(lhp);
	    }
	    else {
		DBI_UNSET_LAST_HANDLE;
	    }
	
	} /* otherwise don't alter last handle */

	if (DBIc_IADESTROY(imp_xxh)) { /* want's ineffective destroy	*/
	    DBIc_ACTIVE_off(imp_xxh);
	}
	call_depth = 0;
    }
    else {
	DBI_SET_LAST_HANDLE(h);
	SAVEINT(DBIc_CALL_DEPTH(imp_xxh));
	call_depth = ++DBIc_CALL_DEPTH(imp_xxh);

	if (ima) {
	    if (ima->flags & IMA_COPY_STMT) { /* execute() */
		SV *parent = DBIc_PARENT_H(imp_xxh);
		SV **tmp_svp = hv_fetch((HV*)SvRV(h), "Statement", 9, 1);
		/* XXX sv_copy() if Profiling? */
		hv_store((HV*)SvRV(parent), "Statement", 9, SvREFCNT_inc(*tmp_svp), 0);
	    }
	}
    }

    /* --- dispatch --- */

    if (!keep_error)
	DBIh_CLEAR_ERROR(imp_xxh);

    /* The "quick_FETCH" logic...					*/
    /* Shortcut for fetching attributes to bypass method call overheads */
    if ( (is_FETCH = (*meth_name=='F' && strEQ(meth_name,"FETCH"))) && !DBIc_COMPAT(imp_xxh)) {
	STRLEN kl;
	char *key = SvPV(st1, kl);
	SV **attr_svp;
	if (*key != '_' && (attr_svp=hv_fetch((HV*)SvRV(h), key, kl, 0))) {
	    qsv = *attr_svp;
	    /* disable FETCH from cache for special attributes */
	    if (SvROK(qsv) && SvTYPE(SvRV(qsv))==SVt_PVHV && *key=='D' &&
		(  (kl==6 && DBIc_TYPE(imp_xxh)==DBIt_DB && strEQ(key,"Driver"))
		|| (kl==8 && DBIc_TYPE(imp_xxh)==DBIt_ST && strEQ(key,"Database")) )
	    ) {
		qsv = Nullsv;
	    }
	}
    }

    if (qsv) { /* skip real method call if we already have a 'quick' value */

	ST(0) = sv_mortalcopy(qsv);
	outitems = 1;

    }
    else {
#ifdef DBI_save_hv_fetch_ent
	HE save_mh;
	if (is_FETCH)
	    save_mh = PL_hv_fetch_ent_mh; /* XXX nested tied FETCH bug17575 workaround */
#endif

	if (debug) {
	    SAVEI32(DBIS->debug);	/* fall back to orig value later */
	    if (ima && debug < ima->trace_level) {
		debug = 0;		/* silence dispatch log for this method	*/
	    }
	    DBIS->debug = debug;	/* make value global (for now)	 */
	}

	imp_msv = (SV*)gv_fetchmethod(DBIc_IMP_STASH(imp_xxh), meth_name);

	if (debug >= 2) {
	    PerlIO *logfp = DBILOGFP;
	    /* Full pkg method name (or just meth_name for ANON CODE)	*/
	    char *imp_meth_name = (imp_msv && isGV(imp_msv)) ? GvNAME(imp_msv) : meth_name;
	    HV *imp_stash = DBIc_IMP_STASH(imp_xxh);
	    PerlIO_printf(logfp, "%c   -> %s ",
		    call_depth>1 ? '0'+call_depth-1 : (dirty?'!':' '), imp_meth_name);
	    if (imp_meth_name[0] == 'A' && strEQ(imp_meth_name,"AUTOLOAD"))
		    PerlIO_printf(logfp, "\"%s\" ", meth_name);
	    if (imp_msv && isGV(imp_msv) && GvSTASH(imp_msv) != imp_stash)
		PerlIO_printf(logfp, "in %s ", HvNAME(GvSTASH(imp_msv)));
	    PerlIO_printf(logfp, "for %s (%s", HvNAME(imp_stash),
			SvPV(orig_h,lna));
	    if (h != orig_h)	/* show inner handle to aid tracing */
		 PerlIO_printf(logfp, "~0x%lx", (long)SvRV(h));
	    else PerlIO_printf(logfp, "~INNER");
	    for(i=1; i<items; ++i) {
		PerlIO_printf(logfp," %s",
		    (ima && i==ima->hidearg) ? "****" : neatsvpv(ST(i),0));
	    }
#ifdef DBI_USE_THREADS
	    PerlIO_printf(logfp, ") thr#%p\n", DBIc_THR_USER(imp_xxh));
#else
	    PerlIO_printf(logfp, ")\n");
#endif
	    PerlIO_flush(logfp);
	}

	if (!imp_msv) {
	    if (dirty || is_DESTROY) {
		outitems = 0;
		goto post_dispatch;
	    }
	    if (ima && ima->flags & IMA_NOT_FOUND_OKAY) {
		outitems = 0;
		goto post_dispatch;
	    }
	    croak("Can't locate DBI object method \"%s\" via package \"%s\"",
		meth_name, HvNAME(DBIc_IMP_STASH(imp_xxh)));
	}

	PUSHMARK(mark);  /* mark arguments again so we can pass them on	*/

	/* Note: the handle on the stack is still an object blessed into a
	 * DBI::* class and *not* the DBD::*::* class whose method is being
	 * invoked. This *is* correct and should be largely transparent.
	 */

	/* SHORT-CUT ALERT! */
	if (xsbypass && isGV(imp_msv) && CvXSUB(GvCV(imp_msv))) {

	    /* If we are calling an XSUB we jump directly to its C code and
	     * bypass perl_call_sv(), pp_entersub() etc. This is fast.
	     * This code is copied from a small section of pp_entersub().
	     */
	    I32 markix = TOPMARK;
	    CV *xscv   = GvCV(imp_msv);
	    (void)(*CvXSUB(xscv))(aTHXo_ xscv);	/* Call the C code directly */

	    if (gimme == G_SCALAR) {    /* Enforce sanity in scalar context */
		if (++markix != stack_sp - stack_base ) {
		    if (markix > stack_sp - stack_base)
			 *(stack_base + markix) = &sv_undef;
		    else *(stack_base + markix) = *stack_sp;
		    stack_sp = stack_base + markix;
		}
		outitems = 1;
	    }
	    else {
		outitems = stack_sp - (stack_base + markix);
	    }

	}
	else {
	    outitems = perl_call_sv(isGV(imp_msv) ? (SV*)GvCV(imp_msv) : imp_msv,
		(is_DESTROY ? gimme | G_EVAL | G_KEEPERR : gimme) );
	}
	SPAGAIN;

	if (debug) { /* XXX restore local vars so ST(n) works below	*/
	    sp -= outitems; ax = (sp - stack_base) + 1; 
	}

#ifdef DBI_save_hv_fetch_ent
	if (is_FETCH)
	    PL_hv_fetch_ent_mh = save_mh;	/* see start of block */
#endif
    }

    post_dispatch:

    if (debug >= 1) {
	PerlIO *logfp = DBILOGFP;
	int is_fetch  = (*meth_name=='f' && DBIc_TYPE(imp_xxh)==DBIt_ST && strnEQ(meth_name,"fetch",5));
	int row_count = (is_fetch) ? DBIc_ROW_COUNT((imp_sth_t*)imp_xxh) : 0;
	if (is_fetch && row_count>=2 && debug<=1 && SvOK(ST(0))) {
	    /* skip the 'middle' rows to reduce output */
	    goto skip_meth_return_trace;
	}
	if (SvTRUE(DBIc_ERR(imp_xxh))) {
	    PerlIO_printf(logfp,
		(keep_error) ? "       error: %s %s\n"
			     : "    !! ERROR: %s %s\n",
		neatsvpv(DBIc_ERR(imp_xxh),0), neatsvpv(DBIc_ERRSTR(imp_xxh),0));
	}
	PerlIO_printf(logfp,"%c%c  <- %s",
		    (call_depth > 1)  ? '0'+call_depth-1 : (dirty?'!':' '),
		    (DBIc_is(imp_xxh, DBIcf_TaintIn|DBIcf_TaintOut)) ? 'T' : ' ',
		    meth_name);
	if (debug==1 && items>=2) { /* make level 1 more useful */
	    /* we only have the first two parameters available here */
	    PerlIO_printf(logfp,"(%s", neatsvpv(st1,0));
	    if (items >= 3)
		PerlIO_printf(logfp," %s", neatsvpv(st2,0));
	    PerlIO_printf(logfp,"%s)", (items > 3) ? " ..." : "");
	}

	if (gimme & G_ARRAY)
	     PerlIO_printf(logfp,"= (");
	else PerlIO_printf(logfp,"=");
	for(i=0; i < outitems; ++i) {
	    SV *s = ST(i);
	    if ( SvROK(s) && SvTYPE(SvRV(s))==SVt_PVAV) {
		AV *av = (AV*)SvRV(s);
		int avi;
		PerlIO_printf(logfp, " [");
		for(avi=0; avi <= AvFILL(av); ++avi)
		    PerlIO_printf(logfp, " %s",  neatsvpv(AvARRAY(av)[avi],0));
		PerlIO_printf(logfp, " ]");
	    }
	    else {
		PerlIO_printf(logfp, " %s",  neatsvpv(s,0));
		if ( SvROK(s) && SvTYPE(SvRV(s))==SVt_PVHV && !SvOBJECT(SvRV(s)) )
		    PerlIO_printf(logfp, "%ldkeys", (long)HvKEYS(SvRV(s)));
	    }
	}
	if (gimme & G_ARRAY) {
	    PerlIO_printf(logfp," ) [%d items]", outitems);
	}
	if (is_fetch && row_count) {
	    PerlIO_printf(logfp," row%d", row_count);
	}
	if (qsv) /* flag as quick and peek at the first arg (still on the stack) */
	    PerlIO_printf(logfp," (%s from cache)", neatsvpv(st1,0));
	else if (!imp_msv)
	    PerlIO_printf(logfp," (not implemented)");
	/* XXX add flag to show pid here? */
	PerlIO_puts(logfp, log_where(debug, 0, 0, "\n")); /* add file and line number information */
    skip_meth_return_trace:
	PerlIO_flush(logfp);
    }

    if (ima && ima->flags & IMA_END_WORK) { /* commit() or rollback() */
	if (DBIc_has(imp_xxh, DBIcf_BegunWork)) {
	    DBIc_off(imp_xxh, DBIcf_BegunWork);
	    if (!DBIc_has(imp_xxh, DBIcf_AutoCommit)) {
		/* We only get here if the driver hasn't implemented their own code	*/
		/* for begin_work, or has but hasn't correctly turned AutoCommit	*/
		/* back on in their commit or rollback code. So we have to do it.	*/
		/* This is bad because it'll probably trigger a spurious commit()	*/
		/* and may mess up the error handling below for the commit/rollback	*/
		PUSHMARK(SP);
		XPUSHs(h);
		XPUSHs(sv_2mortal(newSVpv("AutoCommit",0)));
		XPUSHs(&sv_yes);
		PUTBACK;
		perl_call_method("STORE", G_DISCARD);
		SPAGAIN;
	    }
	}
    }

    if (tainting
	&& DBIc_is(imp_xxh, DBIcf_TaintOut)   /* taint checks requested	*/
	/* XXX this would taint *everything* being returned from *any*	*/
	/* method that doesn't have IMA_NO_TAINT_OUT set.		*/
	/* DISABLED: just tainting fetched data in get_fbav seems ok	*/
	&& 0/* XXX disabled*/ /* !(ima && ima->flags & IMA_NO_TAINT_OUT) */
    ) {
	dTHR;
	TAINT; /* affects sv_setsv()'s within same perl statement */
	for(i=0; i < outitems; ++i) {
	    I32 avi;
	    char *p;
	    SV *s;
	    SV *agg = ST(i);
	    if ( !SvROK(agg) )
		continue;
	    agg = SvRV(agg);
#define DBI_OUT_TAINTABLE(s) (!SvREADONLY(s) && !SvTAINTED(s))
	    switch (SvTYPE(agg)) {
	    case SVt_PVAV:
		for(avi=0; avi <= AvFILL((AV*)agg); ++avi) {
		    s = AvARRAY((AV*)agg)[avi];
		    if (DBI_OUT_TAINTABLE(s))
			SvTAINTED_on(s);
		}
		break;
	    case SVt_PVHV:
		hv_iterinit((HV*)agg);
		while( (s = hv_iternextsv((HV*)agg, &p, &avi)) ) {
		    if (DBI_OUT_TAINTABLE(s))
			SvTAINTED_on(s);
		}
		break;
	    default:
		if (DBIc_WARN(imp_xxh)) {
		    PerlIO_printf(DBILOGFP,"Don't know how to taint contents of returned %s (type %ld)",
			neatsvpv(agg,0), SvTYPE(agg));
		}
	    }
	}
    }

    if (   !keep_error				/* so would be a new error	*/
	&& SvTRUE(DBIc_ERR(imp_xxh))		/* and an error exists		*/
	&& call_depth <= 1			/* skip nested (internal) calls	*/
	&& DBIc_has(imp_xxh, DBIcf_RaiseError|DBIcf_PrintError|DBIcf_HandleError)
	/* check that we're not nested inside a call to our parent */
	&& (!DBIc_PARENT_COM(imp_xxh) || DBIc_CALL_DEPTH(DBIc_PARENT_COM(imp_xxh)) < 1)
    ) {
	SV *msg;
	SV **hook_svp = 0;
	SV **statement_svp = NULL;
	char *err_meth_name = meth_name;
	char intro[200];

	if (*meth_name=='s' && strEQ(meth_name,"set_err")) {
	    SV **sem_svp = hv_fetch((HV*)SvRV(h), "dbi_set_err_method", 18, GV_ADDWARN);
	    if (SvOK(*sem_svp))
		err_meth_name = SvPV(*sem_svp,lna);
	}

	sprintf(intro,"%s %s failed: ", HvNAME(DBIc_IMP_STASH(imp_xxh)), err_meth_name);
	msg = sv_2mortal(newSVpv(intro,0));
	sv_catsv(msg, DBIc_ERRSTR(imp_xxh));

	if (    DBIc_has(imp_xxh, DBIcf_ShowErrorStatement)
	    && (DBIc_TYPE(imp_xxh) == DBIt_ST
		|| strEQ(err_meth_name,"prepare")	/* XXX use IMA flag for this */
		|| strEQ(err_meth_name,"do")
		|| strnEQ(err_meth_name,"select",6)
		)
	    && (statement_svp = hv_fetch((HV*)SvRV(h), "Statement", 9, 0))
	    &&  statement_svp && SvOK(*statement_svp)
	) {
	    SV **svp;
	    sv_catpv(msg, " [for statement ``");
	    sv_catsv(msg, *statement_svp);

	    /* fetch from tied outer handle to trigger FETCH magic  */
	    /* could add DBIcf_ShowErrorParams (default to on?)		*/
	    svp = hv_fetch((HV*)DBIc_MY_H(imp_xxh),"ParamValues",11,FALSE);
	    if (svp && SvMAGICAL(*svp))
		mg_get(*svp);
	    if (svp && SvRV(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV ) {
		HV *bvhv = (HV*)SvRV(*svp);
		SV *sv;
		char *key;
		I32 keylen;
		I32 param_idx = 0;
		hv_iterinit(bvhv);
		sv_catpv(msg, "'' with params: ");
		while ( (sv = hv_iternextsv(bvhv, &key, &keylen)) ) {
		    sv_catpvf(msg, "%s%s=%s",
			(param_idx++==0 ? "" : ", "),
			key, neatsvpv(sv,0));
		}
		sv_catpv(msg, "])");
	    }
	    else {
		sv_catpv(msg, "''])");
	    }
	}

	if (DBIc_has(imp_xxh, DBIcf_HandleError)
		&& (hook_svp=hv_fetch((HV*)SvRV(h),"HandleError",11,0))
		&&  hook_svp && SvOK(*hook_svp)
	) {
	    dSP;
	    SV *result = *(sp-outitems+1);
	    PerlIO *logfp = DBILOGFP;
	    IV items;
	    SV *status;
	    if (debug)
		PerlIO_printf(logfp,"    -> HandleError on %s via %s%s%s%s\n",
		    neatsvpv(h,0), neatsvpv(*hook_svp,0),
		    (result ? " (" : ""),
		    (result ? neatsvpv(result,0) : ""),
		    (result ? ")" : "")
		);
	    PUSHMARK(SP);
	    XPUSHs(msg);
	    XPUSHs(sv_2mortal(newRV((SV*)DBIc_MY_H(imp_xxh))));
	    XPUSHs( result ? result : sv_newmortal() );
	    PUTBACK;
	    items = perl_call_sv(*hook_svp, G_SCALAR);
	    SPAGAIN;
	    status = POPs;
	    PUTBACK;
	    if (!SvTRUE(status)) /* handler says it didn't handle it, so... */
		hook_svp = 0;  /* pretend we didn't have a handler...     */
	    if (debug)
		PerlIO_printf(logfp,"    <- HandleError= %s%s%s%s\n",
		    neatsvpv(status,0),
		    (result ? " (" : ""),
		    (result ? neatsvpv(result,0) : ""),
		    (result ? ")" : "")
		);
	}

	if (profile_t1) { /* see also dbi_profile() call a few lines below */
	    char *Statement = (ima && ima->flags & IMA_PROF_EMPTY_STMT) ? "" : Nullch;
	    dbi_profile(h, imp_xxh, Statement, imp_msv ? imp_msv : (SV*)cv,
		profile_t1, dbi_time());
	}
	if (!hook_svp) {
	    if (DBIc_has(imp_xxh, DBIcf_PrintError))
		warn("%s", SvPV(msg,lna));
	    if (DBIc_has(imp_xxh, DBIcf_RaiseError))
		croak("%s", SvPV(msg,lna));
	}
    }
    else if (profile_t1) { /* see also dbi_profile() call a few lines above */
	char *Statement = (ima && ima->flags & IMA_PROF_EMPTY_STMT) ? "" : Nullch;
	dbi_profile(h, imp_xxh, Statement, imp_msv ? imp_msv : (SV*)cv,
		profile_t1, dbi_time());
    }

    XSRETURN(outitems);
}



/* --------------------------------------------------------------------	*/

/* comment and placeholder styles to accept and return */

#define DBIpp_cm_cs 0x000001   /* C style */
#define DBIpp_cm_hs 0x000002   /* #       */
#define DBIpp_cm_dd 0x000004   /* --      */
#define DBIpp_cm_br 0x000008   /* {}      */
#define DBIpp_cm_dw 0x000010   /* '-- ' dash dash whitespace */
#define DBIpp_cm_XX 0x00001F   /* any of the above */
     
#define DBIpp_ph_qm 0x000100   /* ?       */
#define DBIpp_ph_cn 0x000200   /* :1      */
#define DBIpp_ph_cs 0x000400   /* :name   */
#define DBIpp_ph_sp 0x000800   /* %s (as return only, not accept)    */
#define DBIpp_ph_XX 0x000F00   /* any of the above */

#define DBIpp_st_qq 0x010000   /* '' char escape */
#define DBIpp_st_bs 0x020000   /* \  char escape */
#define DBIpp_st_XX 0x030000   /* any of the above */

#define DBIpp_L_BRACE '{'
#define DBIpp_R_BRACE '}'
#define PS_accept(flag)  DBIbf_has(ps_accept,(flag))
#define PS_return(flag)  DBIbf_has(ps_return,(flag))

SV *
preparse(SV *dbh, char *statement, IV ps_return, IV ps_accept, void *foo)
{
	D_imp_xxh(dbh);
/*
	The idea here is that ps_accept defines which constructs to
	recognize (accept) as valid in the source string (other
	constructs are ignored), and ps_return defines which
	constructs are valid to return in the result string.

	If a construct that is valid in the input is also valid in the
	output then it's simply copied. If it's not valid in the output
	then it's editied into one of the valid forms (ideally the most
	'standard' and/or information preserving one).

	For example, if ps_accept includes '--' style comments but
	ps_return doesn't, but ps_return does include '#' style
	comments then any '--' style comments would be rewritten as '#'
	style comments.

	Similarly for placeholders. DBD::Oracle, for example, would say
	'?', ':1' and ':name' are all acceptable input, but only
	':name' should be returned.

	(There's a tricky issue with the '--' comment style because it can
	clash with valid syntax, i.e., "... set foo=foo--1 ..." so it
	would be *bad* to misinterpret that as the start of a comment.
	Perhaps we need a DBIpp_cm_dw (for dash-dash-whitespace) style
	to allow for that.)

	Also, we'll only support DBIpp_cm_br as an input style. And
	even then, only with reluctance. We may (need to) drop it when
	we add support for odbc escape sequences.
*/

    int idx = 1;

    char in_quote = '\0';
    char in_comment = '\0';
    char rt_comment = '\0';
    char *src, *start, *dest;
    char *style = "", *laststyle = '\0';
    SV *new_stmt_sv;

    if (!(ps_return | DBIpp_ph_XX)) { /* no return ph type specified */
	ps_return |= ps_accept | DBIpp_ph_XX;	/* so copy from ps_accept */
    }

    /* XXX this allocation strategy won't work when we get to more advanced stuff */
    new_stmt_sv = newSV(strlen(statement) * 3);
    sv_setpv(new_stmt_sv,"");
    src  = statement;
    dest = SvPVX(new_stmt_sv);

    while( *src ) 
    {
	if (*src == '%' && PS_return(DBIpp_ph_sp))
	    *dest++ = '%';

	if (in_comment)
	{
	     if (	(in_comment == '-' && (*src == '\n' || *(src+1) == '\0')) 
		||	(in_comment == '#' && (*src == '\n' || *(src+1) == '\0'))
		||	(in_comment == DBIpp_L_BRACE && *src == DBIpp_R_BRACE) /* XXX nesting? */
		||	(in_comment == '/' && *src == '*' && *(src+1) == '/')
	     ) {
		switch (rt_comment) {
		case '/':	*dest++ = '*'; *dest++ = '/';	break;
		case '-':	*dest++ = '\n';			break;
		case '#':	*dest++ = '\n';			break;
		case DBIpp_L_BRACE: *dest++ = DBIpp_R_BRACE;	break;
		case '\0':	/* ensure deleting a comment doesn't join two tokens */
			if (in_comment=='/' || in_comment==DBIpp_L_BRACE)
			    *dest++ = ' '; /* ('-' and '#' styles use the newline) */
			break;
		}
		if (in_comment == '/')
		    src++;
		src += (*src != '\n' || *(dest-1)=='\n') ? 1 : 0;
		in_comment = '\0';
		rt_comment = '\0';
	     }
             else 
	     if (rt_comment)
                *dest++ = *src++;
	     else
		src++;	/* delete (don't copy) the comment */
	     continue;
	}

	if (in_quote)
	{
	    if (*src == in_quote) {
		in_quote = 0;
	    }
	    *dest++ = *src++;
	    continue;
	}

	/* Look for comments */
        if (*src == '-' && *(src+1) == '-' &&
		(PS_accept(DBIpp_cm_dd) || (*(src+2) == ' ' && PS_accept(DBIpp_cm_dw)))
	)
        {
	    in_comment = *src;
	    src += 2;	/* skip past 2nd char of double char delimiters */
	    if (PS_return(DBIpp_cm_dd) || PS_return(DBIpp_cm_dw)) {
                *dest++ = rt_comment = '-';
                *dest++ = '-';
                if (PS_return(DBIpp_cm_dw) && *src!=' ')
		    *dest++ = ' '; /* insert needed white space */
            }
	    else if (PS_return(DBIpp_cm_cs)) {
                *dest++ = rt_comment = '/';
                *dest++ = '*';
            }
	    else if (PS_return(DBIpp_cm_hs)) {
                *dest++ = rt_comment = '#';
            }
	    else if (PS_return(DBIpp_cm_br)) {
                *dest++ = rt_comment = DBIpp_L_BRACE;
            }
	    continue;
        }
        else if (*src == '/' && *(src+1) == '*' && PS_accept(DBIpp_cm_cs))
        {
	    in_comment = *src;
	    src += 2;	/* skip past 2nd char of double char delimiters */
	    if (PS_return(DBIpp_cm_cs)) {
                *dest++ = rt_comment = '/';
                *dest++ = '*';
            }
	    else if (PS_return(DBIpp_cm_dd) || PS_return(DBIpp_cm_dw)) {
                *dest++ = rt_comment = '-';
                *dest++ = '-';
                if (PS_return(DBIpp_cm_dw)) *dest++ = ' '; 
            }
	    else if (PS_return(DBIpp_cm_hs)) {
                *dest++ = rt_comment = '#';
            }
	    else if (PS_return(DBIpp_cm_br)) {
                *dest++ = rt_comment = DBIpp_L_BRACE;
            }
	    continue;
        }
        else if (*src == '#' && PS_accept(DBIpp_cm_hs))
        {
	    in_comment = *src;
	    src++;
	    if (PS_return(DBIpp_cm_hs)) {
                *dest++ = rt_comment = '#';
            }
	    else if (PS_return(DBIpp_cm_dd) || PS_return(DBIpp_cm_dw)) {
                *dest++ = rt_comment = '-';
                *dest++ = '-';
                if (PS_return(DBIpp_cm_dw)) *dest++ = ' '; 
            }
	    else if (PS_return(DBIpp_cm_cs)) {
                *dest++ = rt_comment = '/';
                *dest++ = '*';
            }
	    else if (PS_return(DBIpp_cm_br)) {
                *dest++ = rt_comment = DBIpp_L_BRACE;
            }
	    continue;
        }
        else if (*src == DBIpp_L_BRACE && PS_accept(DBIpp_cm_br))
        {
	    in_comment = *src;
	    src++;
	    if (PS_return(DBIpp_cm_br)) {
                *dest++ = rt_comment = DBIpp_L_BRACE;
            }
	    else if (PS_return(DBIpp_cm_dd) || PS_return(DBIpp_cm_dw)) {
                *dest++ = rt_comment = '-';
                *dest++ = '-';
                if (PS_return(DBIpp_cm_dw)) *dest++ = ' '; 
            }
	    else if (PS_return(DBIpp_cm_cs)) {
                *dest++ = rt_comment = '/';
                *dest++ = '*';
            }
	    else if (PS_return(DBIpp_cm_hs)) {
                *dest++ = rt_comment = '#';
            }
	    continue;
        }

       if (    !(*src==':' && (PS_accept(DBIpp_ph_cn) || PS_accept(DBIpp_ph_cs)))
           &&  !(*src=='?' &&  PS_accept(DBIpp_ph_qm))
       ){
	    if (*src == '\'' || *src == '"')
		in_quote = *src;
	    *dest++ = *src++;
	    continue;
	}

	/* only here for : or ? outside of a comment or literal	*/

	start = dest;			/* save name inc colon	*/ 
	*dest++ = *src++;		/* copy and move past first char */

	if (*start == '?')		/* X/Open Standard */
        {
	    style = "?";

            if (PS_return(DBIpp_ph_qm))
		;
            else if (PS_return(DBIpp_ph_cn)) { /* '?' -> ':p1' (etc) */
                sprintf(start,":p%d", idx++);
                dest = start+strlen(start);
            }
            else if (PS_return(DBIpp_ph_sp)) { /* '?' -> '%s' */
		   *start  = '%';
		   *dest++ = 's';
            }
	} 
        else if (isDIGIT(*src)) {   /* :1 */ 
	    int pln = atoi(src);
	    style = ":1";

	    if (PS_return(DBIpp_ph_cn)) { /* ':1'->':p1'  */
		   idx = pln;
		   *dest++ = 'p';
		   while(isDIGIT(*src))
		       *dest++ = *src++;
            }
	    else if (PS_return(DBIpp_ph_qm) /* ':1' -> '?'  */
	    	 ||  PS_return(DBIpp_ph_sp) /* ':1' -> '%s' */
	    ) {
		   PS_return(DBIpp_ph_qm) ? sprintf(start,"?") : sprintf(start,"%%s");
		   dest = start + strlen(start);
                   if (pln != idx) {
			char buf[99];
			sprintf(buf, "preparse found placeholder :%d out of sequence, expected :%d", pln, idx);
			set_err(dbh, imp_xxh, 1, buf, 0);
			return &sv_undef;
                   }
		   while(isDIGIT(*src)) src++;
                   idx++;
            }
	} 
        else if (isALNUM(*src))         /* :name */ 
        {
	    style = ":name";

	    if (PS_return(DBIpp_ph_cs)) {
		;
            }
	    else if (PS_return(DBIpp_ph_qm) /* ':name' -> '?'  */
	    	 ||  PS_return(DBIpp_ph_sp) /* ':name' -> '%s' */
	    ) {
		PS_return(DBIpp_ph_qm) ? sprintf(start,"?") : sprintf(start,"%%s");
		dest = start + strlen(start);
		while (isALNUM(*src))	/* consume name, includes '_'	*/
		    src++;
	    }
	}
        /* perhaps ':=' PL/SQL construct */
	else { continue; }

	*dest = '\0';			/* handy for debugging	*/

	if (laststyle && style != laststyle) {
	    char buf[99];
	    sprintf(buf, "preparse found mixed placeholder styles (%s / %s)", style, laststyle);
	    set_err(dbh, imp_xxh, 1, buf, 0);
            return &sv_undef;
        }
	laststyle = style;
    }
    *dest = '\0';

    /* warn about probable parsing errors, but continue anyway (returning processed string) */
    switch (in_quote)
    {
    case '\'':
	    set_err(dbh, imp_xxh, 1, "preparse found unterminated single-quoted string", 0);
	    break;
    case '\"':
	    set_err(dbh, imp_xxh, 1, "preparse found unterminated double-quoted string", 0);
	    break;
    }
    switch (in_comment)
    {
    case DBIpp_L_BRACE:
	    set_err(dbh, imp_xxh, 1, "preparse found unterminated bracketed {...} comment", 0);
	    break;
    case '/':
	    set_err(dbh, imp_xxh, 1, "preparse found unterminated bracketed C-style comment", 0);
	    break;
    }

    SvCUR_set(new_stmt_sv, strlen(SvPVX(new_stmt_sv)));
    *SvEND(new_stmt_sv) = '\0';
    return new_stmt_sv;
}


/* --------------------------------------------------------------------	*/
/* The DBI Perl interface (via XS) starts here. Currently these are 	*/
/* all internal support functions. Note install_method and see DBI.pm	*/

MODULE = DBI   PACKAGE = DBI

REQUIRE:    1.929
PROTOTYPES: DISABLE


BOOT:
    items = items;		/* avoid 'unused variable' warning	*/
    dbi_bootinit(NULL);


I32
constant()
	PROTOTYPE:
    ALIAS:
	SQL_ALL_TYPES                    = SQL_ALL_TYPES
	SQL_ARRAY                        = SQL_ARRAY
	SQL_ARRAY_LOCATOR                = SQL_ARRAY_LOCATOR
	SQL_BINARY                       = SQL_BINARY
	SQL_BIT                          = SQL_BIT
	SQL_BLOB                         = SQL_BLOB
	SQL_BLOB_LOCATOR                 = SQL_BLOB_LOCATOR
	SQL_BOOLEAN                      = SQL_BOOLEAN
	SQL_CHAR                         = SQL_CHAR
	SQL_CLOB                         = SQL_CLOB
	SQL_CLOB_LOCATOR                 = SQL_CLOB_LOCATOR
	SQL_DATE                         = SQL_DATE
	SQL_DATETIME                     = SQL_DATETIME
	SQL_DECIMAL                      = SQL_DECIMAL
	SQL_DOUBLE                       = SQL_DOUBLE
	SQL_FLOAT                        = SQL_FLOAT
	SQL_GUID                         = SQL_GUID
	SQL_INTEGER                      = SQL_INTEGER
	SQL_INTERVAL                     = SQL_INTERVAL
	SQL_INTERVAL_DAY                 = SQL_INTERVAL_DAY
	SQL_INTERVAL_DAY_TO_HOUR         = SQL_INTERVAL_DAY_TO_HOUR
	SQL_INTERVAL_DAY_TO_MINUTE       = SQL_INTERVAL_DAY_TO_MINUTE
	SQL_INTERVAL_DAY_TO_SECOND       = SQL_INTERVAL_DAY_TO_SECOND
	SQL_INTERVAL_HOUR                = SQL_INTERVAL_HOUR
	SQL_INTERVAL_HOUR_TO_MINUTE      = SQL_INTERVAL_HOUR_TO_MINUTE
	SQL_INTERVAL_HOUR_TO_SECOND      = SQL_INTERVAL_HOUR_TO_SECOND
	SQL_INTERVAL_MINUTE              = SQL_INTERVAL_MINUTE
	SQL_INTERVAL_MINUTE_TO_SECOND    = SQL_INTERVAL_MINUTE_TO_SECOND
	SQL_INTERVAL_MONTH               = SQL_INTERVAL_MONTH
	SQL_INTERVAL_SECOND              = SQL_INTERVAL_SECOND
	SQL_INTERVAL_YEAR                = SQL_INTERVAL_YEAR
	SQL_INTERVAL_YEAR_TO_MONTH       = SQL_INTERVAL_YEAR_TO_MONTH
	SQL_LONGVARBINARY                = SQL_LONGVARBINARY
	SQL_LONGVARCHAR                  = SQL_LONGVARCHAR
	SQL_MULTISET                     = SQL_MULTISET
	SQL_MULTISET_LOCATOR             = SQL_MULTISET_LOCATOR
	SQL_NUMERIC                      = SQL_NUMERIC
	SQL_REAL                         = SQL_REAL
	SQL_REF                          = SQL_REF
	SQL_ROW                          = SQL_ROW
	SQL_SMALLINT                     = SQL_SMALLINT
	SQL_TIME                         = SQL_TIME
	SQL_TIMESTAMP                    = SQL_TIMESTAMP
	SQL_TINYINT                      = SQL_TINYINT
	SQL_TYPE_DATE                    = SQL_TYPE_DATE
	SQL_TYPE_TIME                    = SQL_TYPE_TIME
	SQL_TYPE_TIMESTAMP               = SQL_TYPE_TIMESTAMP
	SQL_TYPE_TIMESTAMP_WITH_TIMEZONE = SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
	SQL_TYPE_TIME_WITH_TIMEZONE      = SQL_TYPE_TIME_WITH_TIMEZONE
	SQL_UDT                          = SQL_UDT
	SQL_UDT_LOCATOR                  = SQL_UDT_LOCATOR
	SQL_UNKNOWN_TYPE                 = SQL_UNKNOWN_TYPE
	SQL_VARBINARY                    = SQL_VARBINARY
	SQL_VARCHAR                      = SQL_VARCHAR
	SQL_WCHAR                        = SQL_WCHAR
	SQL_WLONGVARCHAR                 = SQL_WLONGVARCHAR
	SQL_WVARCHAR                     = SQL_WVARCHAR
	DBIpp_cm_cs	= DBIpp_cm_cs
	DBIpp_cm_hs	= DBIpp_cm_hs
	DBIpp_cm_dd	= DBIpp_cm_dd
	DBIpp_cm_dw	= DBIpp_cm_dw
	DBIpp_cm_br	= DBIpp_cm_br
	DBIpp_cm_XX	= DBIpp_cm_XX
	DBIpp_ph_qm	= DBIpp_ph_qm
	DBIpp_ph_cn	= DBIpp_ph_cn
	DBIpp_ph_cs	= DBIpp_ph_cs
	DBIpp_ph_sp	= DBIpp_ph_sp
	DBIpp_ph_XX	= DBIpp_ph_XX
	DBIpp_st_qq	= DBIpp_st_qq
	DBIpp_st_bs	= DBIpp_st_bs
	DBIpp_st_XX	= DBIpp_st_XX
    CODE:
    RETVAL = ix;
    OUTPUT:
    RETVAL


void
_clone_dbis()
    CODE:
    dPERINTERP;
    dbi_bootinit(DBIS);


void
_setup_handle(sv, imp_class, parent, imp_datasv)
    SV *	sv
    char *	imp_class
    SV *	parent
    SV *	imp_datasv
    CODE:
    dbih_setup_handle(sv, imp_class, parent, SvOK(imp_datasv) ? imp_datasv : Nullsv);
    ST(0) = &sv_undef;


void
_get_imp_data(sv)
    SV *	sv
    CODE:
    D_imp_xxh(sv);
    ST(0) = sv_mortalcopy(DBIc_IMP_DATA(imp_xxh)); /* okay if NULL	*/


void
_handles(sv)
    SV *	sv
    PPCODE:
    /* return the outer and inner handle for any given handle */
    D_imp_xxh(sv);
    SV *ih = sv_mortalcopy( dbih_inner(sv, "_handles") );
    SV *oh = sv_2mortal(newRV((SV*)DBIc_MY_H(imp_xxh))); /* XXX dangerous */
    EXTEND(SP, 2);
    PUSHs(oh);	/* returns outer handle then inner */
    PUSHs(ih);


void
neat(sv, maxlen=0)
    SV *	sv
    U32	maxlen
    CODE:
    ST(0) = sv_2mortal(newSVpv(neatsvpv(sv, maxlen), 0));


int
hash(key, type=0)
    char *key
    long type
    CODE:
    RETVAL = dbi_hash(key, type);
    OUTPUT:
    RETVAL

void
looks_like_number(...)
    PPCODE:
    int i;
    EXTEND(SP, items);
    for(i=0; i < items ; ++i) {
	SV *sv = ST(i);
	if (!SvOK(sv) || (SvPOK(sv) && SvCUR(sv)==0))
	    PUSHs(&sv_undef);
	else if ( looks_like_number(sv) )
	    PUSHs(&sv_yes);
	else
	    PUSHs(&sv_no);
    }
	

void
_install_method(class, meth_name, file, attribs=Nullsv)
    char *	class
    char *	meth_name
    char *	file
    SV *	attribs
    CODE:
    {
    dPERINTERP;
    /* install another method name/interface for the DBI dispatcher	*/
    int debug = (DBIS->debug >= 10);
    CV *cv;
    SV **svp;
    dbi_ima_t *ima = NULL;
    class = class;		/* avoid 'unused variable' warning	*/

    if (debug)
	PerlIO_printf(DBILOGFP,"install_method %s\t", meth_name);

    if (strnNE(meth_name, "DBI::", 5))	/* XXX m/^DBI::\w+::\w+$/	*/
	croak("install_method: invalid name '%s'", meth_name);

    if (attribs && SvROK(attribs)) {
	SV *sv;
	/* convert and store method attributes in a fast access form	*/
	if (SvTYPE(SvRV(attribs)) != SVt_PVHV)
	    croak("install_method %s: bad attribs", meth_name);

	sv = newSV(sizeof(*ima));
	ima = (dbi_ima_t*)(void*)SvPVX(sv);
	memzero((char*)ima, sizeof(*ima));
	DBD_ATTRIB_GET_IV(attribs, "O",1, svp, ima->flags);
	DBD_ATTRIB_GET_IV(attribs, "T",1, svp, ima->trace_level);
	DBD_ATTRIB_GET_IV(attribs, "H",1, svp, ima->hidearg);

	if ( (svp=DBD_ATTRIB_GET_SVP(attribs, "U",1)) != NULL) {
	    STRLEN lna;
	    AV *av = (AV*)SvRV(*svp);
	    ima->minargs    = SvIV(*av_fetch(av, 0, 1));
	    ima->maxargs    = SvIV(*av_fetch(av, 1, 1));
			      svp = av_fetch(av, 2, 0);
	    ima->usage_msg  = savepv( (svp) ? SvPV(*svp,lna) : "");
	    ima->flags |= IMA_HAS_USAGE;
	    if (debug)
		PerlIO_printf(DBILOGFP,"    usage: min %d, max %d, '%s', tl %d\n",
			ima->minargs, ima->maxargs, ima->usage_msg, ima->trace_level);
	}
	if (debug)
	    PerlIO_printf(DBILOGFP,", flags 0x%x", ima->flags);

    } else if (attribs && SvOK(attribs)) {
	croak("install_method %s: attributes not a ref", meth_name);
    }
    cv = newXS(meth_name, XS_DBI_dispatch, file);
    CvXSUBANY(cv).any_ptr = ima;
    if (debug)
	PerlIO_printf(DBILOGFP,"\n");
    ST(0) = &sv_yes;
    }


int
trace(sv, level=-1, file=Nullsv)
    SV *	sv
    int	level
    SV *	file
    ALIAS:
    _debug_dispatch = 1
    CODE:
    {
    dPERINTERP;
    if (!DBIS) {
	sv=sv; ix=ix;		/* avoid 'unused variable' warnings	*/
	croak("DBI not initialised");
    }
    if (level == -1) level = DBIS->debug;
    /* Return old/current value. No change if new value not given.	*/
    RETVAL = DBIS->debug;
    set_trace_file(file);	/* always call this regardless of level */
    if (level != DBIS->debug) {
	if (level > 0) {
	    PerlIO_printf(DBILOGFP,"    DBI %s%s dispatch trace level set to %d\n",
		XS_VERSION, dbi_build_opt, level);
	    if (!dowarn)
		PerlIO_printf(DBILOGFP,"    Note: perl is running without the recommended perl -w option\n");
	    PerlIO_flush(DBILOGFP);
	}
	DBIS->debug = level;
	sv_setiv(perl_get_sv("DBI::dbi_debug",0x5), level);
    }
    }
    OUTPUT:
    RETVAL



void
dump_handle(sv, msg="DBI::dump_handle", level=0)
    SV *	sv
    char *	msg
    int 	level
    CODE:
    dbih_dumphandle(sv, msg, level);



void
_svdump(sv)
    SV *	sv
    CODE:
    {
    dPERINTERP;
    PerlIO_printf(DBILOGFP, "DBI::_svdump(%s)", neatsvpv(sv,0));
#ifdef DEBUGGING
    sv_dump(sv);
#endif
    }


double
dbi_time()


SV *
dbi_profile(h, statement, method, t1, t2)
    SV *h
    SV *statement
    SV *method
    double t1
    double t2
    CODE:
    D_imp_xxh(h);
    STRLEN lna = 0;
    dbi_profile(h, imp_xxh,
	SvOK(statement) ? SvPV(statement,lna) : Nullch,
	SvROK(method)   ? SvRV(method)        : method,
	t1, t2
    );
    RETVAL = &sv_undef;
    OUTPUT:
    RETVAL


SV *
dbi_profile_merge(dest, ...)
    SV * dest
    CODE:
    {
	if (!SvROK(dest) || SvTYPE(SvRV(dest)) != SVt_PVAV)
	    croak("dbi_profile_merge(%s,...) not an array reference", neatsvpv(dest,0));
	/* items==2 for dest + 1 arg, ST(0) is dest, ST(1) is first arg */
	while (--items >= 1) {
	    SV *thingy = ST(items); /* currently has to be an array ref */
	    dbi_profile_merge(dest, thingy);
	}
	RETVAL = newSVsv(*av_fetch((AV*)SvRV(dest), DBIprof_TOTAL_TIME, 1));
    }
    OUTPUT:
    RETVAL


MODULE = DBI   PACKAGE = DBI::var

void
FETCH(sv)
    SV *	sv
    CODE:
    dPERINTERP;
    /* Note that we do not come through the dispatcher to get here.	*/
    STRLEN lna;
    char *meth = SvPV(SvRV(sv),lna);	/* what should this tie do ?	*/
    char type = *meth++;		/* is this a $ or & style	*/
    imp_xxh_t *imp_xxh = (DBI_LAST_HANDLE_OK) ? DBIh_COM(DBI_LAST_HANDLE) : NULL;
    int trace = 0;
    double profile_t1 = 0.0;

    if (imp_xxh && DBIc_has(imp_xxh,DBIcf_Profile))
	profile_t1 = dbi_time();

    if (DBIS->debug >= 2 || (imp_xxh && DBIc_DEBUGIV(imp_xxh) >= 2)) {
	trace = 2;
	PerlIO_printf(DBILOGFP,"    -> $DBI::%s (%c) FETCH from lasth=%s\n", meth, type,
		(imp_xxh) ? neatsvpv(DBI_LAST_HANDLE,0): "none");
    }

    if (type == '!') {	/* special case for $DBI::lasth */
	/* Currently we can only return the INNER handle.	*/
	/* This handle should only be used for true/false tests	*/
	ST(0) = (imp_xxh) ? sv_2mortal(newRV(DBI_LAST_HANDLE)) : &sv_undef;
    }
    else if ( !imp_xxh ) {
	if (trace)
	    warn("Can't read $DBI::%s, last handle unknown or destroyed", meth);
	ST(0) = &sv_undef;
    }
    else if (type == '*') {	/* special case for $DBI::err, see also err method	*/
	SV *errsv = DBIc_ERR(imp_xxh);
	ST(0) = sv_mortalcopy(errsv);
    }
    else if (type == '"') {	/* special case for $DBI::state	*/
	SV *state = DBIc_STATE(imp_xxh);
	ST(0) = DBIc_STATE_adjust(imp_xxh, state);
    }
    else if (type == '$') { /* lookup scalar variable in implementors stash */
	char *vname = mkvname(DBIc_IMP_STASH(imp_xxh), meth, 0);
	SV *vsv = perl_get_sv(vname, 1);
	ST(0) = sv_mortalcopy(vsv);
    }
    else {
	/* default to method call via stash of implementor of DBI_LAST_HANDLE */
	GV *imp_gv;
	HV *imp_stash = DBIc_IMP_STASH(imp_xxh);
#ifdef DBI_save_hv_fetch_ent
	HE save_mh = PL_hv_fetch_ent_mh; /* XXX nested tied FETCH bug17575 workaround */
#endif
	profile_t1 = 0.0; /* profile this via dispatch only (else we'll double count) */
	if (DBIS->debug >= 2)
	    PerlIO_printf(DBILOGFP,"    >> %s::%s\n", HvNAME(imp_stash), meth);
	ST(0) = sv_2mortal(newRV(DBI_LAST_HANDLE));
	if ((imp_gv = gv_fetchmethod(imp_stash,meth)) == NULL) {
	    croak("Can't locate $DBI::%s object method \"%s\" via package \"%s\"",
		meth, meth, HvNAME(imp_stash));
	}
	PUSHMARK(mark);  /* reset mark (implies one arg as we were called with one arg?) */
	perl_call_sv((SV*)GvCV(imp_gv), GIMME);
#ifdef DBI_save_hv_fetch_ent
	PL_hv_fetch_ent_mh = save_mh;
#endif
    }
    if (trace)
	PerlIO_printf(DBILOGFP,"    <- $DBI::%s= %s\n", meth, neatsvpv(ST(0),0));
    if (profile_t1)
	dbi_profile(DBI_LAST_HANDLE, imp_xxh, Nullch, (SV*)cv, profile_t1, dbi_time());


MODULE = DBI   PACKAGE = DBD::_::db

SV *
preparse(dbh, statement, ps_accept, ps_return, foo=Nullch)
    SV *	dbh
    char *	statement
    IV		ps_accept
    IV		ps_return
    void	*foo


void
take_imp_data(h)
    SV *	h
    PREINIT:
    /* take_imp_data currently in DBD::_::db not DBD::_::common, so for dbh's only */
    D_imp_xxh(h);
    MAGIC *mg;
    SV *imp_xxh_sv;
    CODE:
    /*
    If the drivers imp data contains SV*'s, or other interpreter
    specific items, they should be freed by the drivers own take_imp_data
    method before it calls SUPER::take_imp_data to finalize the removal.
    The driver needs to view the take_imp_data method as being
    nearly the same as disconnect+DESTROY only not actually calling
    the database API to disconnect.
    All that needs to remain is the underlying database API connection data.
    Everything else should in a 'clean' state such that if the drivers
    own DESTROY method instead of take_imp_data, it would be able to
    properly handle the contents of the structure. This is important in case
    a new handle created using this imp_data, possibly in a new thread, might
    end up being DESTROY's before the driver has had a chance to 're-setup'
    the data. See dbih_setup_handle()
    */
    if (DBIc_TYPE(imp_xxh) <= DBIt_DB && DBIc_CACHED_KIDS((imp_dbh_t*)imp_xxh))
	clear_cached_kids(h, imp_xxh, "take_imp_data", DBIc_DEBUGIV(imp_xxh));
    if (DBIc_KIDS(imp_xxh)) {	/* safety check, may be relaxed later to DBIc_ACTIVE_KIDS */
	set_err(h, imp_xxh, 1, "Can't take_imp_data from handle while it still has kids", 0);
	XSRETURN(0);
    }
    dbih_getcom2(h, &mg);	/* get the MAGIC so we can change it	*/
    imp_xxh_sv = mg->mg_obj;	/* take local copy of the imp_data pointer */
    mg->mg_obj = Nullsv;	/* sever the link from handle to imp_xxh */
    if (DBIc_DEBUGIV(imp_xxh))
	sv_dump(imp_xxh_sv);
    /* --- housekeeping */
    DBIc_ACTIVE_off(imp_xxh);	/* silence warning from dbih_clearcom */
    DBIc_IMPSET_off(imp_xxh);	/* silence warning from dbih_clearcom */
    dbih_clearcom(imp_xxh);	/* free SVs like DBD::_mem::common::DESTROY */
    SvOBJECT_off(imp_xxh_sv);	/* no longer needs DESTROY via dbih_clearcom */
    DBIc_IMPSET_on(imp_xxh);	/* to mark fact imp data still present */
    /* --- tidy up the raw PV for life as a more normal string */
    SvPOK_on(imp_xxh_sv);
    SvCUR_set(imp_xxh_sv, SvLEN(imp_xxh_sv)-1); /* SvLEN(imp_xxh_sv)-1 == imp_size */
    *SvEND(imp_xxh_sv) = '\0';
    /* --- return the actual imp_xxh_sv on the stack */
    ST(0) = imp_xxh_sv;



MODULE = DBI   PACKAGE = DBD::_::st

void
_get_fbav(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    AV *av = dbih_get_fbav(imp_sth);
    ST(0) = sv_2mortal(newRV((SV*)av));

void
_set_fbav(sth, src_rv)
    SV *	sth
    SV *	src_rv
    CODE:
    D_imp_sth(sth);
    int i;
    AV *src_av;
    AV *dst_av = dbih_get_fbav(imp_sth);
    int num_fields = AvFILL(dst_av)+1;
    if (!SvROK(src_rv) || SvTYPE(SvRV(src_rv)) != SVt_PVAV)
	croak("_set_fbav(%s): not an array ref", neatsvpv(src_rv,0));
    src_av = (AV*)SvRV(src_rv);
    if (AvFILL(src_av)+1 != num_fields)
	croak("_set_fbav(%s): array has %d fields, should have %d",
		neatsvpv(src_rv,0), AvFILL(src_av)+1, num_fields);
    for(i=0; i < num_fields; ++i) {	/* copy over the row	*/
        /* If we're given the values, then taint them if required */
        if (DBIc_is(imp_sth, DBIcf_TaintOut))
            SvTAINT(AvARRAY(src_av)[i]);
	sv_setsv(AvARRAY(dst_av)[i], AvARRAY(src_av)[i]);
    }
    ST(0) = sv_2mortal(newRV((SV*)dst_av));


void
bind_col(sth, col, ref, attribs=Nullsv)
    SV *	sth
    SV *	col
    SV *	ref
    SV *	attribs
    CODE:
    DBD_ATTRIBS_CHECK("bind_col", sth, attribs);
    ST(0) = boolSV(dbih_sth_bind_col(sth, col, ref, attribs));

void
bind_columns(sth, ...)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    SV *colsv;
    SV *attribs = &sv_undef;
    int fields = DBIc_NUM_FIELDS(imp_sth);
    int skip = 0;
    int i;
    if (fields <= 0 && !DBIc_ACTIVE(imp_sth))
	croak("Statement has no result columns to bind %s",
		"(perhaps you need to successfully call execute first)");
    ST(0) = &sv_yes;
    /* Backwards compatibility for old-style call with attribute hash	*/
    /* ref as first arg. Skip arg if undef or a hash ref.		*/
    if (!SvOK(ST(1)) || (SvROK(ST(1)) && SvTYPE(SvRV(ST(1)))==SVt_PVHV)) {
	attribs = ST(1);
	DBD_ATTRIBS_CHECK("bind_columns", sth, attribs);
	skip = 1;
    }
    if (items-(1+skip) != fields)
	croak("bind_columns called with %ld refs when %d needed.", items-(1+skip), fields);
    colsv = sv_2mortal(newSViv(0));
    for(i=1; i < items-skip; ++i) {
	sv_setiv(colsv, i);
	if (!dbih_sth_bind_col(sth, colsv, ST(skip+i), attribs)) {
	    ST(0) = &sv_no;
	    break;
	}
    }


void
fetchrow_array(sth)
    SV *	sth
    ALIAS:
    fetchrow = 1
    PPCODE:
    dPERINTERP;
    SV *retsv;
    if (CvDEPTH(cv) == 99) {
	ix = ix;	/* avoid 'unused variable' warning'		*/
        croak("Deep recursion, probably fetchrow-fetch-fetchrow loop");
    }
    PUSHMARK(sp);
    XPUSHs(sth);
    PUTBACK;
    if (perl_call_method("fetch", G_SCALAR) != 1)
	croak("panic: DBI fetch");	/* should never happen */
    SPAGAIN;
    retsv = POPs;
    PUTBACK;
    if (SvROK(retsv) && SvTYPE(SvRV(retsv)) == SVt_PVAV) {
	D_imp_sth(sth);
	int num_fields, i;
	AV *bound_av;
	AV *av = (AV*)SvRV(retsv);
	num_fields = AvFILL(av)+1;
	EXTEND(sp, num_fields+1);

	/* We now check for bind_col() having been called but fetch	*/
	/* not returning the fields_svav array. Probably because the	*/
	/* driver is implemented in perl. XXX This logic may change later.	*/
	bound_av = DBIc_FIELDS_AV(imp_sth); /* bind_col() called ?	*/
	if (bound_av && av != bound_av) {
	    /* let dbih_get_fbav know what's going on	*/
	    bound_av = dbih_get_fbav(imp_sth);
	    if (DBIc_DEBUGIV(imp_sth) >= 3) {
		PerlIO_printf(DBILOGFP,
		    "fetchrow: updating fbav 0x%lx from 0x%lx\n",
		    (long)bound_av, (long)av);
	    }
	    for(i=0; i < num_fields; ++i) {	/* copy over the row	*/
		sv_setsv(AvARRAY(bound_av)[i], AvARRAY(av)[i]);
	    }
	}
	for(i=0; i < num_fields; ++i) {
	    PUSHs(AvARRAY(av)[i]);
	}
    }


SV *
fetchrow_hashref(sth, keyattrib=Nullch)
    SV *	sth
    char *	keyattrib
    PREINIT:
    SV *rowavr;
    SV *ka_rv;
    D_imp_sth(sth);
    CODE:
    PUSHMARK(sp);
    XPUSHs(sth);
    PUTBACK;
    if (!keyattrib || !*keyattrib) {
	SV *kn = DBIc_FetchHashKeyName(imp_sth);
	if (kn && SvOK(kn))
	    keyattrib = SvPVX(kn);
	else
	    keyattrib = "NAME";
    }
    ka_rv = *hv_fetch((HV*)DBIc_MY_H(imp_sth), keyattrib,strlen(keyattrib), TRUE);
    /* we copy to invoke FETCH magic, and we do that before fetch() so if tainting */
    /* then the taint triggered by the fetch won't then apply to the fetched name */
    ka_rv = newSVsv(ka_rv);
    if (perl_call_method("fetch", G_SCALAR) != 1)
	croak("panic: DBI fetch");	/* should never happen */
    SPAGAIN;
    rowavr = POPs;
    PUTBACK;
    /* have we got an array ref in rowavr */
    if (SvROK(rowavr) && SvTYPE(SvRV(rowavr)) == SVt_PVAV) {
	int i;
	AV *rowav = (AV*)SvRV(rowavr);
	int num_fields = AvFILL(rowav)+1;
	HV *hv;
	AV *ka_av;
	if (!(SvROK(ka_rv) && SvTYPE(SvRV(ka_rv))==SVt_PVAV)) {
	    sv_setiv(DBIc_ERR(imp_sth), 1);
	    sv_setpvf(DBIc_ERRSTR(imp_sth),
		"Can't use attribute '%s' because it doesn't contain a reference to an array (%s)",
		keyattrib, neatsvpv(ka_rv,0));
	    XSRETURN_UNDEF;
	}
	ka_av = (AV*)SvRV(ka_rv);
	hv    = newHV();
	for (i=0; i < num_fields; ++i) {	/* honor the original order as sent by the database */
	    STRLEN len;
	    SV  **field_name_svp = av_fetch(ka_av, i, 1);
	    char *field_name     = SvPV(*field_name_svp, len);
	    hv_store(hv, field_name, len, newSVsv((SV*)(AvARRAY(rowav)[i])), 0);
	}
	RETVAL = newRV((SV*)hv);
	SvREFCNT_dec(hv);  	/* since newRV incremented it	*/
    }
    else {
	RETVAL = &sv_undef;
#if (PERL_VERSION < 4) || ((PERL_VERSION == 4) && (PERL_SUBVERSION <= 4))
	RETVAL = newSV(0); /* mutable undef for 5.004_04 */
#endif
    }
    SvREFCNT_dec(ka_rv);	/* since we created it		*/
    OUTPUT:
    RETVAL


void
fetch(sth)
    SV *	sth
    ALIAS:
    fetchrow_arrayref = 1
    CODE:
    int num_fields;
    if (CvDEPTH(cv) == 99) {
	ix = ix;	/* avoid 'unused variable' warning'		*/
        croak("Deep recursion. Probably fetch-fetchrow-fetch loop.");
    }
    PUSHMARK(sp);
    XPUSHs(sth);
    PUTBACK;
    num_fields = perl_call_method("fetchrow", G_ARRAY);	/* XXX change the name later */
    if (num_fields == 0) {
	ST(0) = &sv_undef;
    } else {
	D_imp_sth(sth);
	AV *av = dbih_get_fbav(imp_sth);
	if (num_fields != AvFILL(av)+1)
	    croak("fetchrow returned %d fields, expected %d",
		    num_fields, AvFILL(av)+1);
	SPAGAIN;
	while(--num_fields >= 0)
	    sv_setsv(AvARRAY(av)[num_fields], POPs);
	PUTBACK;
	ST(0) = sv_2mortal(newRV((SV*)av));
    }


void
rows(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    IV rows = DBIc_ROW_COUNT(imp_sth);
    ST(0) = sv_2mortal(newSViv(rows));


void
finish(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    DBIc_ACTIVE_off(imp_sth);
    ST(0) = &sv_yes;


MODULE = DBI   PACKAGE = DBD::_::common


void
STORE(h, keysv, valuesv)
    SV *	h
    SV *	keysv
    SV *	valuesv
    CODE:
    ST(0) = &sv_yes;
    if (!dbih_set_attr_k(h, keysv, 0, valuesv))
	    ST(0) = &sv_no;
 

void
FETCH(h, keysv)
    SV *	h
    SV *	keysv
    CODE:
    ST(0) = dbih_get_attr_k(h, keysv, 0);


void
private_data(h)
    SV *	h
    CODE:
    D_imp_xxh(h);
    ST(0) = sv_mortalcopy(DBIc_IMP_DATA(imp_xxh));


void
err(h)
    SV * h
    CODE:
    D_imp_xxh(h);
    SV *errsv = DBIc_ERR(imp_xxh);
    ST(0) = sv_mortalcopy(errsv);

void
state(h)
    SV * h
    CODE:
    D_imp_xxh(h);
    STRLEN lna;
    SV *state = DBIc_STATE(imp_xxh);
    ST(0) = DBIc_STATE_adjust(imp_xxh, state);

void
errstr(h)
    SV *    h
    CODE:
    D_imp_xxh(h);
    SV *errstr = DBIc_ERRSTR(imp_xxh);
    SV *err;
    /* If there's no errstr but there is an err then use err */
    if (!SvTRUE(errstr) && (err=DBIc_ERR(imp_xxh)) && SvTRUE(err))
	    errstr = err;
    ST(0) = sv_mortalcopy(errstr);


void
set_err(h, errval, errstr=&sv_no, state=&sv_undef, method=&sv_undef, result=Nullsv)
    SV *	h
    SV *	errval
    SV *	errstr
    SV *	state
    SV *	method
    SV *	result
    CODE:
    {
    D_imp_xxh(h);
    STRLEN lna;
    SV **sem_svp;
    sv_setsv(DBIc_ERR(imp_xxh),    errval);
    if (errstr==&sv_no || !SvOK(errstr))
	errstr = errval;
    sv_setsv(DBIc_ERRSTR(imp_xxh), errstr);
    if (SvTRUE(state)) {
	STRLEN len;
	if (SvPV(state, len) && len != 5)
	    croak("set_err: state must be 5 character string");
	sv_setsv(DBIc_STATE(imp_xxh), state);
    }
    else {
	(void)SvOK_off(DBIc_STATE(imp_xxh));
    }
    /* store provided method name so handler code can find it */
    sem_svp = hv_fetch((HV*)SvRV(h), "dbi_set_err_method", 18, 1);
    if (SvOK(method))
	sv_setpv(*sem_svp, SvPV(method,lna));
    else
	(void)SvOK_off(*sem_svp);

    /* We don't check RaiseError and call die here because that must be	*/
    /* done by returning theough dispatch and letting the DBI handle it	*/
    ST(0) = (result ? result : &sv_undef);
    }


int
trace(h, level=0, file=Nullsv)
    SV *h
    int	level
    SV *file
    ALIAS:
    debug = 1
    CODE:
    ix = ix;	/* avoid 'unused variable' warning	*/
    RETVAL = set_trace(h, level, file);
    OUTPUT:
    RETVAL


void
trace_msg(sv, msg, min_level=1)
    SV *sv
    char *msg
    int min_level
    PREINIT:
    int debug = 0;
    CODE:
    {
    dPERINTERP;
    if (SvROK(sv)) {
	D_imp_xxh(sv);
	debug = DBIc_DEBUGIV(imp_xxh);
    }
    if (DBIS->debug >= min_level || debug >= min_level) {
	PerlIO_puts(DBILOGFP, msg);
        ST(0) = &sv_yes;
    }
    else {
        ST(0) = &sv_no;
    }
    }


void
rows(h)
    SV *        h
    CODE:
    /* fallback esp for $DBI::rows after $drh was last used */
	if (0) h = h;	/* avoid unused variable warning */
    ST(0) = sv_2mortal(newSViv(-1));


MODULE = DBI   PACKAGE = DBD::_mem::common

void
DESTROY(imp_xxh_rv)
    SV *	imp_xxh_rv
    CODE:
    dPERINTERP;
    /* ignore 'cast increases required alignment' warning	*/
    imp_xxh_t *imp_xxh = (imp_xxh_t*)SvPVX(SvRV(imp_xxh_rv));
    DBIS->clearcom(imp_xxh);

# end
