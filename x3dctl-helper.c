#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>
#include <sched.h>
#include <errno.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <linux/ioprio.h>
#include <sys/syscall.h>

#define SYSFS_BASE "/sys/bus/platform/drivers/amd_x3d_vcache"
#define CPU_BASE   "/sys/devices/system/cpu"
#define CONFIG_PATH "/etc/x3dctl.conf"


static cpu_set_t cache_mask;
static cpu_set_t freq_mask;
static int topology_initialized = 0;

int find_x3d_path(char *out_path, size_t size) {
    DIR *dir = opendir(SYSFS_BASE);
    if (!dir) return -1;

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (entry->d_name[0] == '.') continue;
        if (strncmp(entry->d_name, "AMDI", 4) != 0) continue;

        snprintf(out_path, size, "%s/%s/amd_x3d_mode",
                 SYSFS_BASE, entry->d_name);

        if (access(out_path, F_OK) == 0) {
            closedir(dir);
            return 0;
        }
    }

    closedir(dir);
    return -1;
}

int write_mode(const char *path, const char *mode) {
    FILE *f = fopen(path, "w");
    if (!f) return 1;
    fprintf(f, "%s", mode);
    fclose(f);
    return 0;
}

int read_mode(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return 1;
    char buf[32];
    if (fgets(buf, sizeof(buf), f))
        printf("%s", buf);
    fclose(f);
    return 0;
}

static void init_topology(void) {
    if (topology_initialized) return;

    CPU_ZERO(&cache_mask);
    CPU_ZERO(&freq_mask);

    DIR *dir = opendir(CPU_BASE);
    if (!dir) return;

    struct dirent *entry;
    char path[PATH_MAX];

    while ((entry = readdir(dir))) {
        int cpu_id;
        if (sscanf(entry->d_name, "cpu%d", &cpu_id) != 1)
            continue;

        snprintf(path, sizeof(path),
                 "%s/cpu%d/cache/index3/size",
                 CPU_BASE, cpu_id);

        FILE *f = fopen(path, "r");
        if (!f) continue;

        char buf[64];
        long size_kb = 0;

        if (fgets(buf, sizeof(buf), f))
            size_kb = strtol(buf, NULL, 10);

        fclose(f);

        if (size_kb > 50000)
            CPU_SET(cpu_id, &cache_mask);
        else if (size_kb > 0)
            CPU_SET(cpu_id, &freq_mask);
    }

    closedir(dir);
    topology_initialized = 1;
}



static int verify_config_security(void) {
    struct stat st;
    if (stat(CONFIG_PATH, &st) != 0) return 1;

    if (st.st_uid != 0) {
        fprintf(stderr, "Config must be owned by root\n");
        return 1;
    }

    if (st.st_mode & (S_IWGRP | S_IWOTH)) {
        fprintf(stderr, "Config must not be writable by group/others\n");
        return 1;
    }

    return 0;
}

static void trim(char *s) {
    s[strcspn(s, "\r\n")] = 0;
}

static char *query_profile(const char *app) {
    if (verify_config_security() != 0)
        return NULL;

    FILE *f = fopen(CONFIG_PATH, "r");
    if (!f) return NULL;

    static char line[256];

    while (fgets(line, sizeof(line), f)) {
        trim(line);

        if (line[0] == '#' || line[0] == '\0')
            continue;

        char key[128], val[128];
        if (sscanf(line, "%127[^=]=%127s", key, val) == 2) {
            if (strcmp(key, app) == 0) {
                fclose(f);
                return strdup(val);
            }
        }
    }

    fclose(f);
    return NULL;
}



struct profile {
    const char *core_type;
    int nice;
    const char *scheduler;
    int io_class;
    int io_level;
};

static int load_profile(const char *name, struct profile *p) {

    if (strcmp(name, "gaming") == 0) {
        p->core_type = "cache";
        p->nice = -5;
        p->scheduler = "other";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 0;
        return 0;
    }

    if (strcmp(name, "workstation") == 0) {
        p->core_type = "frequency";
        p->nice = 5;
        p->scheduler = "batch";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 4;
        return 0;
    }

    if (strcmp(name, "frequency") == 0) {
        p->core_type = "frequency";
        p->nice = 0;
        p->scheduler = "other";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 0;
        return 0;
    }

    return 1;
}



static int apply_scheduler(pid_t pid, const char *policy_str) {

    int policy;

    if (strcmp(policy_str, "other") == 0)
        policy = SCHED_OTHER;
    else if (strcmp(policy_str, "batch") == 0)
        policy = SCHED_BATCH;
    else if (strcmp(policy_str, "idle") == 0)
        policy = SCHED_IDLE;
    else {
        fprintf(stderr, "Invalid scheduler\n");
        return 1;
    }

    struct sched_param sp = {0};

    if (sched_setscheduler(pid, policy, &sp) != 0) {
        perror("sched_setscheduler");
        return 1;
    }

    return 0;
}

static int apply_ioprio(pid_t pid, int io_class, int io_level) {

    if (io_class != IOPRIO_CLASS_BE &&
        io_class != IOPRIO_CLASS_IDLE) {
        fprintf(stderr, "Invalid IO class\n");
        return 1;
    }

    if (io_class == IOPRIO_CLASS_BE) {
        if (io_level < 0 || io_level > 7) {
            fprintf(stderr, "Invalid IO level\n");
            return 1;
        }
    }

    int prio = IOPRIO_PRIO_VALUE(io_class, io_level);

    if (syscall(SYS_ioprio_set, IOPRIO_WHO_PROCESS, pid, prio) != 0) {
        perror("ioprio_set");
        return 1;
    }

    return 0;
}



static int apply_policy(pid_t pid, const struct profile *p) {

    init_topology();

    cpu_set_t *mask = NULL;

    if (strcmp(p->core_type, "cache") == 0)
        mask = &cache_mask;
    else if (strcmp(p->core_type, "frequency") == 0)
        mask = &freq_mask;
    else {
        fprintf(stderr, "Invalid core type\n");
        return 1;
    }

    if (CPU_COUNT_S(sizeof(cpu_set_t), mask) == 0) {
        fprintf(stderr, "Topology detection failed\n");
        return 1;
    }

    if (sched_setaffinity(pid, sizeof(cpu_set_t), mask) != 0) {
        perror("sched_setaffinity");
        return 1;
    }

    if (apply_scheduler(pid, p->scheduler) != 0)
        return 1;

    if (setpriority(PRIO_PROCESS, pid, p->nice) != 0) {
        perror("setpriority");
        return 1;
    }

    if (apply_ioprio(pid, p->io_class, p->io_level) != 0)
        return 1;

    return 0;
}



int main(int argc, char *argv[]) {

    if (argc < 2) {
        fprintf(stderr,
            "Usage:\n"
            "  x3dctl-helper cache\n"
            "  x3dctl-helper frequency\n"
            "  x3dctl-helper status\n"
            "  x3dctl-helper query <app>\n"
            "  x3dctl-helper apply <pid> <profile>\n");
        return 1;
    }

    if (strcmp(argv[1], "query") == 0) {
        if (argc != 3) return 1;
        char *profile = query_profile(argv[2]);
        if (!profile) return 1;
        printf("%s\n", profile);
        free(profile);
        return 0;
    }

    if (strcmp(argv[1], "apply") == 0) {
        if (argc != 4) return 1;

        pid_t pid = (pid_t)atoi(argv[2]);

        struct profile p;
        if (load_profile(argv[3], &p) != 0) {
            fprintf(stderr, "Unknown profile\n");
            return 1;
        }

        return apply_policy(pid, &p);
    }

    char sysfs_path[PATH_MAX];
    if (find_x3d_path(sysfs_path, sizeof(sysfs_path)) != 0) {
        fprintf(stderr, "X3D driver not found.\n");
        return 1;
    }

    if (strcmp(argv[1], "cache") == 0)
        return write_mode(sysfs_path, "cache");

    if (strcmp(argv[1], "frequency") == 0)
        return write_mode(sysfs_path, "frequency");

    if (strcmp(argv[1], "status") == 0)
        return read_mode(sysfs_path);

    return 1;
}

