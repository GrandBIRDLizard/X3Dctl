#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>
#include <sched.h>
#include <ctype.h>
#include <errno.h>

#define SYSFS_BASE "/sys/bus/platform/drivers/amd_x3d_vcache"
#define CPU_BASE "/sys/devices/system/cpu"

static cpu_set_t cache_mask;
static cpu_set_t freq_mask;
static int topology_initialized = 0;



// Find the amd_x3d_mode file dynamically
int find_x3d_path(char *out_path, size_t size) {
    DIR *dir = opendir(SYSFS_BASE);
    struct dirent *entry;
    if (!dir) return -1;

    while ((entry = readdir(dir)) != NULL) {
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
    if (topology_initialized)
        return;

    CPU_ZERO(&cache_mask);
    CPU_ZERO(&freq_mask);

    DIR *dir = opendir(CPU_BASE);
    if (!dir)
        return;

    struct dirent *entry;
    char path[PATH_MAX];

    while ((entry = readdir(dir)) != NULL) {
        int cpu_id;

        if (sscanf(entry->d_name, "cpu%d", &cpu_id) != 1)
            continue;

        snprintf(path, sizeof(path),
                 "%s/cpu%d/cache/index3/size",
                 CPU_BASE, cpu_id);

        FILE *f = fopen(path, "r");
        if (!f)
            continue;

        char buf[64];
        long size_kb = 0;

        if (fgets(buf, sizeof(buf), f))
            size_kb = strtol(buf, NULL, 10);

        fclose(f);

        /* Heuristic: V-Cache CCD > 50MB */
        if (size_kb > 50000)
            CPU_SET(cpu_id, &cache_mask);
        else if (size_kb > 0)
            CPU_SET(cpu_id, &freq_mask);
    }

    closedir(dir);
    topology_initialized = 1;
}


//   Affinity Control
int pin_pid(pid_t pid, const char *type) {
    init_topology();

    cpu_set_t *target = NULL;

    if (strcmp(type, "cache") == 0)
        target = &cache_mask;
    else if (strcmp(type, "frequency") == 0)
        target = &freq_mask;
    else
        return 1;

    if (CPU_COUNT_S(sizeof(cpu_set_t), target) == 0) {
        fprintf(stderr, "Topology detection failed: empty mask\n");
        return 1;
    }

    if (sched_setaffinity(pid, sizeof(cpu_set_t), target) != 0) {
        perror("sched_setaffinity");
        return 1;
    }

    return 0;
}


int main(int argc, char *argv[]) {

    if (argc < 2) {
        fprintf(stderr,
            "Usage:\n"
            "  x3dctl-helper cache\n"
            "  x3dctl-helper frequency\n"
            "  x3dctl-helper status\n"
            "  x3dctl-helper pin <pid> <cache|frequency>\n");
        return 1;
    }

    /* Pin command does not require driver */
    if (strcmp(argv[1], "pin") == 0) {
        if (argc != 4) {
            fprintf(stderr, "Usage: pin <pid> <cache|frequency>\n");
            return 1;
        }

        char *end;
        long pid_long = strtol(argv[2], &end, 10);

        if (*end != '\0' || pid_long <= 0) {
            fprintf(stderr, "Invalid PID\n");
            return 1;
        }

        return pin_pid((pid_t)pid_long, argv[3]);
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

