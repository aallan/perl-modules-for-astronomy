/* -*-C-*- */

/* $Id: Sybase.xs,v 1.1 2003/07/18 00:23:04 aa Exp $
   Copyright (c) 1997-2003 Michael Peppler

   Uses from Driver.xst
   Copyright (c) 1994,1995,1996,1997  Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include "Sybase.h"

DBISTATE_DECLARE;

MODULE = DBD::Sybase    PACKAGE = DBD::Sybase

I32
constant()
    PROTOTYPE:
    ALIAS:
    CS_ROW_RESULT           = 4040
    CS_CURSOR_RESULT        = 4041
    CS_PARAM_RESULT         = 4042
    CS_STATUS_RESULT        = 4043
    CS_MSG_RESULT           = 4044
    CS_COMPUTE_RESULT       = 4045
    CODE:
    if (!ix) {
	char *what = GvNAME(CvGV(cv));
	croak("Unknown DBD::Sybase constant '%s'", what);
    }
    else RETVAL = ix;
    OUTPUT:
    RETVAL


void
timeout(value)
    int		value
    CODE:
    ST(0) = sv_2mortal(newSViv(syb_set_timeout(value)));


MODULE = DBD::Sybase    PACKAGE = DBD::Sybase::db

void
_isdead(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    ST(0) = sv_2mortal(newSViv(imp_dbh->isDead));

void
_date_fmt(dbh, fmt)
    SV *	dbh
    char *	fmt
    CODE:
    D_imp_dbh(dbh);
    ST(0) = syb_db_date_fmt(dbh, imp_dbh, fmt) ? &sv_yes : &sv_no;

MODULE = DBD::Sybase    PACKAGE = DBD::Sybase::st

void
cancel(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_st_cancel(sth, imp_sth) ? &sv_yes : &sv_no;

void
ct_get_data(sth, column, bufrv, buflen=0)
    SV *	sth
    int		column
    SV *	bufrv
    int		buflen
    CODE:
    {
    D_imp_sth(sth);
    int len = syb_ct_get_data(sth, imp_sth, column, bufrv, buflen);
    ST(0) = sv_2mortal(newSViv(len));
    }

void
ct_data_info(sth, action, column, attr=&PL_sv_undef)
    SV *	sth
    char *	action
    int		column
    SV *	attr
    CODE:
    {
    D_imp_sth(sth);
    int sybaction;
    if(strEQ(action, "CS_SET")) {
	sybaction = CS_SET;
    } else if (strEQ(action, "CS_GET")) {
	sybaction = CS_GET;
    }
    ST(0) = syb_ct_data_info(sth, imp_sth, sybaction, column, attr) ? &sv_yes : &sv_no;
    }

void
ct_send_data(sth, buffer, size)
    SV *	sth
    char *	buffer
    int		size
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_send_data(sth, imp_sth, buffer, size) ? &sv_yes : &sv_no;

void
ct_prepare_send(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_prepare_send(sth, imp_sth) ? &sv_yes : &sv_no;

void
ct_finish_send(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_finish_send(sth, imp_sth) ? &sv_yes : &sv_no;



MODULE = DBD::Sybase	PACKAGE = DBD::Sybase

INCLUDE: Sybase.xsi
