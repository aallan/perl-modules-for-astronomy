#include "server_config_flags.h"

typedef struct {
    void (*gts_log_open)(void);
    void (*gts_log_message)(int priority, char *format, ...);
    void (*gts_log_io_message)(int priority, char *format, ...);
} glibtop_server_log_vtbl_t;

typedef struct {
    int flags;
    int server_port;
    uid_t server_uid;
    gid_t server_gid;
    glibtop_server_log_vtbl_t log_vtbl;
} glibtop_server_config_t;

glibtop_server_config_t *glibtop_server_config;

void glibtop_server_config_init(int flags);

#define GTOP_S_LOG_OPEN() \
 (*glibtop_server_config->log_vtbl.gts_log_open)()

#define GTOP_S_LOG_MESSAGE \
 (*glibtop_server_config->log_vtbl.gts_log_message)

#define GTOP_S_LOG_IO_MESSAGE \
 (*glibtop_server_config->log_vtbl.gts_log_io_message)
