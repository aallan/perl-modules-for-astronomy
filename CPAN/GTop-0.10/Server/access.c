#include "daemon.h"

static GList *ServerAllow = NULL;

/* this code borrowed from Apache mod_access.c 
 * Copyright (c) 1995-1999 The Apache Group.  All rights reserved.
 */

#ifndef INADDR_NONE
#define INADDR_NONE 0xffffffff
#endif

enum allowdeny_type {
    T_IP,
    T_HOST,
    T_FAIL
};

typedef struct {
    union {
	char *from;
	struct {
	    unsigned long net;
	    unsigned long mask;
	} ip;
    } x;
    enum allowdeny_type type;
} allowdeny;

static int is_ip(const char *host)
{
    while ((*host == '.') || isdigit(*host))
	host++;
    return (*host == '\0');
}

void glibtop_server_allow_clear(void)
{
    GList *list = ServerAllow;
    while (list) {
	if (list->data) {
	    free(list->data);
	}
	list = g_list_next(list);
    }
    g_list_free(list);
    ServerAllow = NULL;
}

char *glibtop_server_allow(char *where)
{
    allowdeny *a;
    char *s;

    a = (allowdeny *)malloc(sizeof(*a));
    ServerAllow = g_list_append(ServerAllow, a);

    a->x.from = where;

    if ((s = strchr(where, '/'))) {
	unsigned long mask;

	a->type = T_IP;
	/* trample on where, we won't be using it any more */
	*s++ = '\0';

	if (!is_ip(where)
	    || (a->x.ip.net = inet_addr(where)) == INADDR_NONE) {
	    a->type = T_FAIL;
	    return "syntax error in network portion of network/netmask";
	}

	/* is_ip just tests if it matches [\d.]+ */
	if (!is_ip(s)) {
	    a->type = T_FAIL;
	    return "syntax error in mask portion of network/netmask";
	}
	/* is it in /a.b.c.d form? */
	if (strchr(s, '.')) {
	    mask = inet_addr(s);
	    if (mask == INADDR_NONE) {
		a->type = T_FAIL;
		return "syntax error in mask portion of network/netmask";
	    }
	}
	else {
	    /* assume it's in /nnn form */
	    mask = atoi(s);
	    if (mask > 32 || mask <= 0) {
		a->type = T_FAIL;
		return "invalid mask in network/netmask";
	    }
	    mask = 0xFFFFFFFFUL << (32 - mask);
	    mask = htonl(mask);
	}
	a->x.ip.mask = mask;
        a->x.ip.net  = (a->x.ip.net & mask);   /* pjr - This fixes PR 4770 */
    }
    else if (isdigit(*where) && is_ip(where)) {
	/* legacy syntax for ip addrs: a.b.c. ==> a.b.c.0/24 for example */
	int shift;
	char *t;
	int octet;

	a->type = T_IP;
	/* parse components */
	s = where;
	a->x.ip.net = 0;
	a->x.ip.mask = 0;
	shift = 24;
	while (*s) {
	    t = s;
	    if (!isdigit(*t)) {
		a->type = T_FAIL;
		return "invalid ip address";
	    }
	    while (isdigit(*t)) {
		++t;
	    }
	    if (*t == '.') {
		*t++ = 0;
	    }
	    else if (*t) {
		a->type = T_FAIL;
		return "invalid ip address";
	    }
	    if (shift < 0) {
		return "invalid ip address, only 4 octets allowed";
	    }
	    octet = atoi(s);
	    if (octet < 0 || octet > 255) {
		a->type = T_FAIL;
		return "each octet must be between 0 and 255 inclusive";
	    }
	    a->x.ip.net |= octet << shift;
	    a->x.ip.mask |= 0xFFUL << shift;
	    s = t;
	    shift -= 8;
	}
	a->x.ip.net = ntohl(a->x.ip.net);
	a->x.ip.mask = ntohl(a->x.ip.mask);
    }
    else {
	a->type = T_HOST;
    }

    return NULL;
}

static int in_domain(const char *domain, const char *what)
{
    int dl = strlen(domain);
    int wl = strlen(what);

    if ((wl - dl) >= 0) {
	if (strcasecmp(domain, &what[wl - dl]) != 0)
	    return 0;

	/* Make sure we matched an *entire* subdomain --- if the user
	 * said 'allow from good.com', we don't want people from nogood.com
	 * to be able to get in.
	 */

	if (wl == dl)
	    return 1;		/* matched whole thing */
	else
	    return (domain[0] == '.' || what[wl - dl - 1] == '.');
    }
    else
	return 0;
}

int glibtop_server_is_allowed(u_long host_addr)
{
    int i;
    int gothost = 0;
    const char *remotehost = NULL;
    GList *list = ServerAllow;

    while (list) {
	allowdeny *a = (allowdeny *)list->data;
	switch (a->type) {
	case T_IP:
	    if (a->x.ip.net != INADDR_NONE
		&& (host_addr & a->x.ip.mask) == a->x.ip.net) {
		return 1;
	    }
	    break;

	case T_HOST:
	    if (!gothost) {
		/* remotehost = ... */

		if ((remotehost == NULL) || is_ip(remotehost))
		    gothost = 1;
		else
		    gothost = 2;
	    }

	    if ((gothost == 2) && in_domain(a->x.from, remotehost))
		return 1;
	    break;

	case T_FAIL:
	    /* do nothing? */
	    break;
	}
	list = g_list_next(list);
    }

    return 0;
}
