#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "daemon.h"

typedef glibtop_server_config_t * GTop__Server;

#define server_start(s)       glibtop_server_start()
#define server_allow(s, addr) glibtop_server_allow(addr)

static void boot_GTop_Server_constants(void)
{
    HV *stash = gv_stashpv("GTop::Server", TRUE);
#include "constants.c"
}

MODULE = GTop::Server   PACKAGE = GTop::Server  PREFIX = server_

BOOT:
    boot_GTop_Server_constants();

GTop::Server
new(CLASS)
    SV *CLASS

    CODE:
    RETVAL = glibtop_server_config;

    OUTPUT:
    RETVAL

int
flags(server, val=-1)
    GTop::Server server
    int val

    CODE:
    RETVAL = server->flags;
    if (val > 0) {
	server->flags = val;
    }

    OUTPUT:
    RETVAL

int
port(server, val=-1)
    GTop::Server server
    int val

    CODE:
    RETVAL = server->server_port;
    if (val > 0) {
	server->server_port = val;
    }

    OUTPUT:
    RETVAL


void
server_start(server)
    GTop::Server server

char *
server_allow(server, addr)
    GTop::Server server
    char *addr

void
END()

   CODE:
   glibtop_server_allow_clear();


