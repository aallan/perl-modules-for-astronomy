/* -*-C-*-
 * Server code for handling requests from clients and forwarding them
 * on to the GNU Emacs process.
 * 
 * This file is part of GNU Emacs.
 * 
 * Copying is permitted under those conditions described by the GNU
 * General Public License.
 * 
 * Copyright (C) 1989 Free Software Foundation, Inc.
 * 
 * Author: Andy Norman (ange@hplb.hpl.hp.com), based on 'etc/server.c'
 * from the 18.52 GNU Emacs distribution.
 * 
 * Please mail bugs and suggestions to the author at the above address.
 */

/* HISTORY 
 * 11-Nov-1990                bristor@simba   
 *    Added EOT stuff.
 */

/*
 * This file incorporates new features added by Bob Weiner <weiner@mot.com>,
 * Darrell Kindred <dkindred@cmu.edu> and Arup Mukherjee <arup@cmu.edu>.
 * Please see the note at the end of the README file for details.
 *
 * (If gnuserv came bundled with your emacs, the README file is probably
 * ../etc/gnuserv.README relative to the directory containing this file)
 */

/*
 * modified for GTop::Server by dougm:
 * - all config info moved to glibtop_server_config_t structure
 * - port/uid/gid config is now dynamic (rather than hardwire #defined)
 * - xauth is ignored
 * - access control is now dynamic and more flexable (see access.c)
 * - logging is plugin-able, syslog is the default
 * - added NO_FORK option 
 */

#include <sys/time.h>

#include <netinet/tcp.h>
#include <glibtop.h>
#include <glibtop/open.h>
#include <glibtop/close.h>
#include <glibtop/command.h>
#include <glibtop/xmalloc.h>

#include <glibtop/parameter.h>

#include <glibtop/gnuserv.h>

#include <errno.h>

#include "daemon.h"

#ifdef AIX
#include <sys/select.h>
#endif

static glibtop_server_config_t _glibtop_server_config;
glibtop_server_config_t *glibtop_server_config = &_glibtop_server_config;

#define GSC glibtop_server_config

#define GTOP_S_DO_FORK (!GTOP_S_NO_FORK)

#define DEFAULT_SERVER_PORT	42800
#define DEFAULT_SERVER_UID	65534
#define DEFAULT_SERVER_GID	65534

#define SERVER_PORT GSC->server_port
#define SERVER_UID  GSC->server_uid
#define SERVER_GID  GSC->server_gid

static glibtop_server_log_vtbl_t syslog_vtbl = {
    syslog_open, syslog_message, syslog_io_message,
};

void glibtop_server_config_init(int flags)
{
    if (!GTOP_S_INIT) {
	if (!GSC->server_port) {
	    GSC->server_port = DEFAULT_SERVER_PORT;
	}
	if (!GSC->server_uid) {
	    GSC->server_uid = DEFAULT_SERVER_UID;
	}
	if (!GSC->server_gid) {
	    GSC->server_uid = DEFAULT_SERVER_GID;
	}
	if (!GSC->log_vtbl.gts_log_open) {
	    GSC->log_vtbl = syslog_vtbl;
	}
    }
    if (flags) {
	GSC->flags = flags;
    }

    GTOP_S_INIT_on;
}

/*
 * permitted -- return whether a given host is allowed to connect to the server.
 */
static int skip_auth(int fd);

static int
permitted (u_long host_addr, int fd)
{
    (void)skip_auth(fd); /* not interested in Xauth */

    return glibtop_server_is_allowed(host_addr);
}

/*
 * internet_init -- initialize server, returning an internet socket that can
 * be listened on.
 */

static int
internet_init (void)
{
    int ls;			/* socket descriptor */
    struct sockaddr_in server;	/* for local socket address */

    /* clear out address structure */
    memset ((char *) &server, 0, sizeof (struct sockaddr_in));

    /* Set up address structure for the listen socket. */
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;

    /* We use a fixed port given in the config file. */
    server.sin_port = htons (SERVER_PORT);

    if (GTOP_S_VERBOSE)
	GTOP_S_LOG_MESSAGE (LOG_INFO, "Using port %u.", SERVER_PORT);

    /* Create the listen socket. */
    if ((ls = socket (AF_INET, SOCK_STREAM, 0)) == -1) {
	GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "unable to create socket");
	exit (1);
    }

    {
	int optval = 1;
	setsockopt(ls, SOL_SOCKET, SO_REUSEADDR,
		   (const char *)&optval, sizeof(optval));
	optval = 1;
	setsockopt(ls, IPPROTO_TCP, TCP_NODELAY, 
		   (const char *)&optval, sizeof(optval));
    }

    /* Bind the listen address to the socket. */
    if (bind (ls, (struct sockaddr *) &server,
	      sizeof (struct sockaddr_in)) == -1) {
	GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "bind");
	exit (1);
    }

    /* Initiate the listen on the socket so remote users * can connect.  */
    if (listen (ls, 20) == -1) {
	GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "listen");
	exit (1);
    }

    return (ls);
}				/* internet_init */

/*
 * handle_internet_request -- accept a request from a client and send the
 * information to stdout (the gnu process).
 */

static void
handle_internet_request (int ls)
{
    int s;
    size_t addrlen = sizeof (struct sockaddr_in);
    struct sockaddr_in peer;	/* for peer socket address */
    pid_t pid;

    memset ((char *) &peer, 0, sizeof (struct sockaddr_in));

    if ((s = accept (ls, (struct sockaddr *) &peer, (void *) &addrlen)) == -1) {
	GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "accept");
	exit (1);
    }

    if (GTOP_S_VERBOSE)
	GTOP_S_LOG_MESSAGE (LOG_INFO, "Connection was made from %s port %u.",
			inet_ntoa (peer.sin_addr), ntohs (peer.sin_port));

    /* Check that access is allowed - if not return crud to the client */
    if (!permitted (peer.sin_addr.s_addr, s)) {
	close (s);
	GTOP_S_LOG_MESSAGE (LOG_CRIT, "Refused connection from %s.",
			inet_ntoa (peer.sin_addr));
	return;
    }			/* if */

    if (GTOP_S_VERBOSE)
	GTOP_S_LOG_MESSAGE (LOG_INFO, "Accepted connection from %s port %u.",
			inet_ntoa (peer.sin_addr), ntohs (peer.sin_port));

    if (GTOP_S_DO_FORK) {
	pid = fork ();

	if (pid == -1) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "fork failed");
	    exit (1);
	}

	if (pid) {
	    if (GTOP_S_VERBOSE)
		GTOP_S_LOG_MESSAGE (LOG_INFO, "Child pid is %d.", pid);
	    return;
	}
    }

    handle_parent_connection (s);

    close (s);

    if (GTOP_S_VERBOSE)	
	GTOP_S_LOG_MESSAGE (LOG_INFO, "Closed connection to %s port %u.",
			inet_ntoa (peer.sin_addr), ntohs (peer.sin_port));

    if (GTOP_S_DO_FORK) {
	_exit (0);
    }
}				/* handle_internet_request */

static void
handle_signal (int sig)
{
    if (sig == SIGCHLD)
	return;

    GTOP_S_LOG_MESSAGE (LOG_ERR, "Catched signal %d.\n", sig);
    exit (1);
}

int glibtop_server_start (void)
{
    const unsigned method = GLIBTOP_METHOD_PIPE;
    const unsigned long features = GLIBTOP_SYSDEPS_ALL;
    glibtop *server = glibtop_global_server;

    int ils = -1;		/* internet domain listen socket */

    glibtop_server_config_init(0); /* set defaults if not already done */

    if (GTOP_S_DEBUG) {
	GTOP_S_VERBOSE_on;
    }

    GTOP_S_LOG_OPEN();

    if (!GTOP_S_NO_DAEMON) {
	pid_t pid = fork ();

	if (pid == -1) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "fork failed");
	    exit (1);
	} else if (pid)
	    exit (0);

	close (0);

	setsid ();
    }

    glibtop_init_r (&glibtop_global_server, 0, GLIBTOP_INIT_NO_INIT);

    signal (SIGCHLD, handle_signal);

    /* If we are root, completely switch to SERVER_UID and
     * SERVER_GID. Otherwise we completely drop any priviledges.
     */

    if (GTOP_S_DEBUG)		
	GTOP_S_LOG_MESSAGE (LOG_DEBUG, "Parent ID: (%d, %d) - (%d, %d)",
			getuid (), geteuid (), getgid (), getegid ());

    if (geteuid () == 0) {
	GTOP_S_CHANGED_UID_on;
	if (setregid (SERVER_GID, SERVER_GID)) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "setregid (SERVER_GID)");
	    exit (1);
	}
	if (setreuid (SERVER_UID, SERVER_UID)) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "setreuid (SERVER_UID)");
	    exit (1);
	}
    } else {
	if (setreuid (geteuid (), geteuid ())) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "setreuid (euid)");
	    exit (1);
	}
    }

    if (GTOP_S_DEBUG)
	GTOP_S_LOG_MESSAGE (LOG_DEBUG, "Parent ID: (%d, %d) - (%d, %d)",
			getuid (), geteuid (), getgid (), getegid ());

    /* get a internet domain socket to listen on. */
    ils = internet_init ();

    if (ils <= 0) {
	GTOP_S_LOG_MESSAGE (LOG_ERR, "Unable to get internet domain socket.");
	exit (1);
    }

    glibtop_set_parameter_l (server, GLIBTOP_PARAM_METHOD,
			     &method, sizeof (method));

    server->features = features;

    glibtop_init_r (&server, 0, 0);

    while (1) {
	fd_set rmask;
	int status, ret;

	if (GTOP_S_DO_FORK) {
	    while ((ret = wait3 (&status, WNOHANG, NULL)) != 0) {
		if ((ret == -1) && (errno == ECHILD))
		    break;

		if ((ret == -1) && ((errno == EAGAIN)))
		    continue;
		if (ret == 0) {
		    GTOP_S_LOG_IO_MESSAGE (LOG_WARNING, "wait3");
		    continue;
		}

		if (GTOP_S_VERBOSE)
		    GTOP_S_LOG_MESSAGE (LOG_INFO, "Child %d exited.", ret);
	    }
	}

	FD_ZERO (&rmask);

	/* Only the child accepts connections from standard
	 * input made by its parent. */

	FD_SET (ils, &rmask);

	if (GTOP_S_DEBUG)
	    GTOP_S_LOG_MESSAGE (LOG_DEBUG,
			    "Server ready and waiting for connections.");

	if (select (ils+1, &rmask, (fd_set *) NULL, (fd_set *) NULL,
		    (struct timeval *) NULL) < 0) {
	    if (errno == EINTR)
		continue;
	    GTOP_S_LOG_IO_MESSAGE (LOG_ERR, "select");
	    exit (1);
	}

	if (FD_ISSET (ils, &rmask))
	    handle_internet_request (ils);
    }

    return 0;
}

/* syslog stuff */

void syslog_open(void)
{
    if (GTOP_S_NO_DAEMON) {
	openlog ("libgtop-daemon", LOG_PERROR | LOG_PID, LOG_LOCAL0);
    } else {
	openlog ("libgtop-daemon", LOG_PID, LOG_LOCAL0);
    }
}

void
syslog_message (int priority, char *format, ...)
{
    va_list ap;
    char buffer [BUFSIZ];

    va_start (ap, format);
    vsnprintf (buffer, BUFSIZ-1, format, ap);
    va_end (ap);

    syslog (priority, buffer);
}

void
syslog_io_message (int priority, char *format, ...)
{
    va_list ap;
    char buffer [BUFSIZ];
    char buffer2 [BUFSIZ];

    va_start (ap, format);
    vsnprintf (buffer, BUFSIZ-1, format, ap);
    va_end (ap);

    snprintf (buffer2, BUFSIZ-1, "%s: %s", buffer, strerror (errno));
    syslog (priority, buffer2);
}

/*
 * --------------------------------------------------------------------
 * XXX: would like todo without xauth all together
 * --------------------------------------------------------------------
 */

/*
 * timed_read - Read with timeout.
 */

static int
timed_read (int fd, char *buf, int max, int timeout, int one_line)
{
    fd_set rmask;
    struct timeval tv;	/* = {timeout, 0}; */
    char c = 0;
    int nbytes = 0;
    int r;

    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    FD_ZERO (&rmask);
    FD_SET (fd, &rmask);

    do {
	r = select (fd + 1, &rmask, NULL, NULL, &tv);

	if (r > 0) {
	    if (read (fd, &c, 1) == 1) {
		*buf++ = c;
		++nbytes;
	    } else {
		GTOP_S_LOG_IO_MESSAGE (LOG_WARNING, "read error on socket");
		return -1;
	    }
	} else if (r == 0) {
	    GTOP_S_LOG_IO_MESSAGE (LOG_WARNING, "read timed out");
	    return -1;
	} else {
	    GTOP_S_LOG_IO_MESSAGE (LOG_WARNING, "error in select");
	    return -1;
	}
    } while ((nbytes < max) && !(one_line && (c == '\n')));

    --buf;
    if (one_line && *buf == '\n') {
	*buf = 0;
    }
    return nbytes;
}

static int skip_auth(int fd)
{

    char auth_protocol[128];

#ifndef AUTH_MAGIC_COOKIE

    /* skip auth protocol for now */
    /* 
     * original server called timed_read which called 
     * read(..., 1) * strlen(DEFAUTH_NAME)+1 - ouch!
     */

    do_read(fd, auth_protocol, strlen(DEFAUTH_NAME)+1);

#else

    int auth_data_len;

    if (timed_read (fd, auth_protocol, AUTH_NAMESZ, AUTH_TIMEOUT, 1) <= 0)
	return FALSE;

    if (GTOP_S_DEBUG)
	GTOP_S_LOG_MESSAGE (LOG_DEBUG,
			"Client sent authenticatin protocol '%s'.",
			auth_protocol);

    if (strcmp (auth_protocol, DEFAUTH_NAME) &&
	strcmp (auth_protocol, MCOOKIE_NAME)) {
	GTOP_S_LOG_MESSAGE (LOG_WARNING,
			"Invalid authentication protocol "
			"'%s' from client",
			auth_protocol);
	return FALSE;
    }
	
    if (!strcmp (auth_protocol, MCOOKIE_NAME)) {
	/* 
	 * doing magic cookie auth
	 */
			
	if (timed_read (fd, buf, 10, AUTH_TIMEOUT, 1) <= 0)
	    return FALSE;

	auth_data_len = atoi (buf);

	if (timed_read (fd, buf, auth_data_len, AUTH_TIMEOUT, 0) != auth_data_len)
	    return FALSE;
    }

#endif
    return TRUE;
}
