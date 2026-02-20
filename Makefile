#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <stdint.h>
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

//   Global CPU masks

static cpu_set_t cache_mask;
static cpu_set_t freq_mask;
static int topology_initialized = 0;

//   X3D sysfs logic

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

//   Topology detection

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


//   IRQ Steering

static void cpuset_to_hexmask(const cpu_set_t *set, char *out, size_t out_size)
{
    const int bits_per_chunk = 32;
    const int total_bits = CPU_SETSIZE;
    const int chunks = (total_bits + bits_per_chunk - 1) / bits_per_chunk;

    uint32_t words[chunks];
    memset(words, 0, sizeof(words));

    for (int cpu = 0; cpu < total_bits; cpu++) {
        if (CPU_ISSET(cpu, set)) {
            int word = cpu / bits_per_chunk;
            int bit  = cpu % bits_per_chunk;
            words[word] |= (1U << bit);
        }
    }

    int highest = chunks - 1;
    while (highest > 0 && words[highest] == 0)
        highest--;

    char *ptr = out;
    size_t remaining = out_size;

    for (int i = highest; i >= 0; i--) {

        int written = snprintf(ptr, remaining,
                               (i == highest) ? "%x" : ",%08x",
                               words[i]);

        if (written < 0 || (size_t)written >= remaining) {
            if (remaining > 0)
                out[out_size - 1] = '\0';
            return;
        }

        ptr += written;
        remaining -= written;
    }
}

static int is_gpu_irq_line(const char *line)
{
    return (
        strstr(line, "amdgpu") ||
        strstr(line, "nvidia") ||
        strstr(line, "nouveau")
    );
}

static void build_full_mask(cpu_set_t *out)
{
    CPU_ZERO(out);

    for (int i = 0; i < CPU_SETSIZE; i++) {
        if (CPU_ISSET(i, &cache_mask) ||
            CPU_ISSET(i, &freq_mask)) {
            CPU_SET(i, out);
        }
    }
}


static void steer_gpu_irqs(const cpu_set_t *target_mask)
{
    FILE *f = fopen("/proc/interrupts", "r");
    if (!f)
        return;

    char line[512];

    /* Large enough for CPU_SETSIZE bits */
    char hexmask[CPU_SETSIZE / 4 + 32];
    cpuset_to_hexmask(target_mask, hexmask, sizeof(hexmask));

    while (fgets(line, sizeof(line), f)) {

        if (!is_gpu_irq_line(line))
            continue;

        char *colon = strchr(line, ':');
        if (!colon)
            continue;

        *colon = '\0';

        int irq = atoi(line);
        if (irq <= 0)
            continue;

        char path[128];
        snprintf(path, sizeof(path),
                 "/proc/irq/%d/smp_affinity", irq);

        FILE *irqf = fopen(path, "w");
        if (!irqf)
            continue;

        fprintf(irqf, "%s", hexmask);
        fclose(irqf);
    }

    fclose(f);
}


//   Config security check

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
    char *start = s;
    char *end;

    // Skip leading whitespace
    while (*start && isspace((unsigned char)*start))
        start++;

    if (start != s)
        memmove(s, start, strlen(start) + 1);

    // Trim trailing whitespace
    end = s + strlen(s) - 1;
    while (end >= s && isspace((unsigned char)*end))
        *end-- = '\0';
}


static char *query_profile(const char *app) {

    if (verify_config_security() != 0)
        return NULL;

    FILE *f = fopen(CONFIG_PATH, "r");
    if (!f)
        return NULL;

    static char line[512];

    while (fgets(line, sizeof(line), f)) {

        // Remove newline
        line[strcspn(line, "\r\n")] = 0;

        // Skip comments or empty lines
        if (line[0] == '#' || line[0] == '\0')
            continue;

        // Find first '='
        char *eq = strchr(line, '=');
        if (!eq)
            continue;

        *eq = '\0';
        char *key = line;
        char *val = eq + 1;

        trim(key);
        trim(val);

        // Ignore inline comments in value
        char *comment = strchr(val, '#');
        if (comment) {
            *comment = '\0';
            trim(val);
        }

        if (strcmp(key, app) == 0) {
            fclose(f);
            return strdup(val);
        }
    }

    fclose(f);
    return NULL;
}


//   Profile definitions

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

//   Scheduler & IO

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

//   Apply policy

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

//   MAIN

int main(int argc, char *argv[]) {

    if (argc < 2) {
        fprintf(stderr,
            "Usage:\n"
            "  x3dctl-helper cache [--no-irq]\n"
            "  x3dctl-helper frequency [--no-irq]\n"
            "  x3dctl-helper status\n"
            "  x3dctl-helper query <app>\n"
            "  x3dctl-helper apply <pid> <profile>\n");
        return 1;
    }


//       Query config

    if (strcmp(argv[1], "query") == 0) {
        if (argc != 3)
            return 1;

        char *profile = query_profile(argv[2]);
        if (!profile)
            return 1;

        printf("%s\n", profile);
        free(profile);
        return 0;
    }

//       Apply profile (PROCESS ONLY)

    if (strcmp(argv[1], "apply") == 0) {

        if (argc != 4) {
            fprintf(stderr,
                "Usage: x3dctl-helper apply <pid> <profile>\n");
            return 1;
        }

        pid_t pid = (pid_t)atoi(argv[2]);
        if (pid <= 0) {
            fprintf(stderr, "Invalid PID\n");
            return 1;
        }

        struct profile p;
        if (load_profile(argv[3], &p) != 0) {
            fprintf(stderr, "Unknown profile\n");
            return 1;
        }

        return apply_policy(pid, &p);
    }


//       Sysfs Mode Commands (MODE-BOUND IRQ)


    char sysfs_path[PATH_MAX];
    if (find_x3d_path(sysfs_path, sizeof(sysfs_path)) != 0) {
        fprintf(stderr, "X3D driver not found.\n");
        return 1;
    }

    if (strcmp(argv[1], "cache") == 0) {

        int disable_irq = 0;
        if (argc == 3 && strcmp(argv[2], "--no-irq") == 0)
            disable_irq = 1;
        else if (argc > 2)
            return 1;

        if (write_mode(sysfs_path, "cache") != 0)
            return 1;

        if (!disable_irq) {
            init_topology();
            steer_gpu_irqs(&freq_mask);
        }

        return 0;
    }

    if (strcmp(argv[1], "frequency") == 0) {

        int disable_irq = 0;
        if (argc == 3 && strcmp(argv[2], "--no-irq") == 0)
            disable_irq = 1;
        else if (argc > 2)
            return 1;

        if (write_mode(sysfs_path, "frequency") != 0)
            return 1;

        if (!disable_irq) {
            init_topology();
            cpu_set_t full_mask;
            build_full_mask(&full_mask);
            steer_gpu_irqs(&full_mask);
        }

        return 0;
    }

    if (strcmp(argv[1], "status") == 0)
        return read_mode(sysfs_path);

    fprintf(stderr, "Unknown command\n");
    return 1;
}

