#include "DBIXS.h"
#include "dbd_xsh.h"

struct imp_drh_st {
    dbih_drc_t com;     /* MUST be first element in structure   */
};
struct imp_dbh_st {
    dbih_dbc_t com;     /* MUST be first element in structure   */
};
struct imp_sth_st {
    dbih_stc_t com;     /* MUST be first element in structure   */
};


DBISTATE_DECLARE;

MODULE = DBD::Perl    PACKAGE = DBD::Perl

INCLUDE: Perl.xsi

