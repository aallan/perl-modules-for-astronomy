#
# Makefile for the estar_io
#
#
# Requires that the GLOBUS_DEVELOPMENT_PATH variables is set. This 
# environment variable must point to the Globus development directory
# containing the flavor or libraries, etc. that you wish to use when
# building this example.  This environment variable should be set in
# the shell prior to envoking make.  The utility program
# $GLOBUS_PATH/globus-development-path can be used to assist you in
# determining the correct setting. 
#
# CSH:
#
# Non-threaded:
#
# setenv GLOBUS_DEVELOPMENT_PATH \
#	`$GLOBUS_PATH/globus-development-path -nothreads`
# 
# Threaded:
#
# setenv GLOBUS_DEVELOPMENT_PATH \
# 	`$GLOBUS_PATH/globus-development-path -threads`
#



#
# Read the makefile header containing build specific definitions
#

include $(GLOBUS_DEVELOPMENT_PATH)/etc/makefile_header

INCDIR		= $(IO_SRC_HOME)/include

IO_CFLAGS 	=-I$(includedir) $(CFLAGS) $(GLOBUS_COMMON_CFLAGS) -I$(INCDIR) -DESTAR_IO_DEBUG $(GLOBUS_IO_CFLAGS)
IO_LDFLAGS 	=-L$(libdir) $(LDFLAGS) $(GLOBUS_COMMON_LDFLAGS) $(GLOBUS_IO_LDFLAGS)
IO_LIBS  	= $(GLOBUS_IO_LIBS) 

SRCS		= estar_io.c
OBJS		= $(SRCS:%.c=%.o)
SHARED_LIBRARYS = $(ESTAR_LIB_HOME)/libestar_io.so

ESTAR_LIB_HOME = .

$(ESTAR_LIB_HOME)/libestar_io.so: $(OBJS)
	$(CC) -shared $(IO_CFLAGS) $(IO_LDFLAGS) -o $@ $(OBJS) $(IO_LIBS)

%.o: %.c
	$(CC) $(IO_CFLAGS) -c $< -o $@

docs: $(DOCS)

depend:
	makedepend -- $(IO_CFLAGS) -- $(SRCS)

clean:
	$(RM) -f $(SHARED_LIBRARYS) $(APPS) $(DOCS) *.so *.o 


estar_io.o: /usr/include/string.h /usr/include/features.h
estar_io.o: /usr/include/sys/cdefs.h /usr/include/gnu/stubs.h
estar_io.o: /usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h
estar_io.o: /usr/include/time.h /usr/include/bits/time.h
estar_io.o: /usr/include/bits/types.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_common.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_config.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_release.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_module.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_url.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_list.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_hashtable.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_fifo.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_cfifo.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_symboltable.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_object.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_object_hierarchy.h
estar_io.o: /usr/include/stdio.h
estar_io.o: /usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stdarg.h
estar_io.o: /usr/include/libio.h /usr/include/_G_config.h
estar_io.o: /usr/include/bits/stdio_lim.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_error.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_error_hierarchy.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_thread_pthreads.h
estar_io.o: /usr/include/pthread.h /usr/include/sched.h
estar_io.o: /usr/include/bits/sched.h /usr/include/signal.h
estar_io.o: /usr/include/bits/sigset.h /usr/include/bits/pthreadtypes.h
estar_io.o: /usr/include/bits/sigthread.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_time.h
estar_io.o: /usr/include/assert.h /usr/include/stdlib.h
estar_io.o: /usr/include/sys/types.h /usr/include/endian.h
estar_io.o: /usr/include/bits/endian.h /usr/include/sys/select.h
estar_io.o: /usr/include/bits/select.h /usr/include/sys/sysmacros.h
estar_io.o: /usr/include/alloca.h /usr/include/sys/time.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_thread_pool.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_handle_table.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_callback.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_timeq.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_memory.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_print.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_tilde_expand.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_libc.h
estar_io.o: /usr/include/sys/stat.h /usr/include/bits/stat.h
estar_io.o: /usr/include/sys/signal.h /usr/include/unistd.h
estar_io.o: /usr/include/bits/posix_opt.h /usr/include/bits/confname.h
estar_io.o: /usr/include/getopt.h /usr/include/errno.h
estar_io.o: /usr/include/bits/errno.h /usr/include/linux/errno.h
estar_io.o: /usr/include/asm/errno.h /usr/include/pwd.h /usr/include/netdb.h
estar_io.o: /usr/include/rpc/netdb.h /usr/include/sys/socket.h
estar_io.o: /usr/include/bits/socket.h /usr/include/limits.h
estar_io.o: /usr/include/bits/posix1_lim.h /usr/include/bits/local_lim.h
estar_io.o: /usr/include/linux/limits.h /usr/include/bits/posix2_lim.h
estar_io.o: /usr/include/bits/sockaddr.h /usr/include/asm/socket.h
estar_io.o: /usr/include/asm/sockios.h /usr/include/netinet/in.h
estar_io.o: /usr/include/stdint.h /usr/include/bits/wordsize.h
estar_io.o: /usr/include/bits/in.h /usr/include/bits/byteswap.h
estar_io.o: /usr/include/sys/param.h /usr/include/linux/param.h
estar_io.o: /usr/include/asm/param.h /usr/include/fcntl.h
estar_io.o: /usr/include/bits/fcntl.h /usr/include/dirent.h
estar_io.o: /usr/include/bits/dirent.h /usr/include/sys/uio.h
estar_io.o: /usr/include/bits/uio.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_debug.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_args.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_strptime.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_thread_common.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_io.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_gss_assist.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/gssapi.h
estar_io.o: /home/globus/bin/globus/development/i686-pc-linux-gnu_pthreads_standard_debug/include/globus_io_error_hierarchy.h
estar_io.o: ./estar_io.h
