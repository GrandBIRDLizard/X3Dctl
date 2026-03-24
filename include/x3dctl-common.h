#ifndef X3DCTL_COMMON_H
#define X3DCTL_COMMON_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <stdint.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <linux/ioprio.h>
#include <sys/syscall.h>
#include <sys/capability.h>

#define SYSFS_BASE   "/sys/bus/platform/drivers/amd_x3d_vcache"
#define CPU_BASE     "/sys/devices/system/cpu"
#define CONFIG_PATH  "/etc/x3dctl.conf"

#endif /* X3DCTL_COMMON_H */
