// x3dctl-helper.c
// Minimal privileged helper for AMD X3D mode switching
// Only supports: cache, frequency, status
// No shell execution, no dynamic commands

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>

#define SYSFS_BASE "/sys/bus/platform/drivers/amd_x3d_vcache"


// Find the amd_x3d_mode file dynamically
int find_x3d_path(char *out_path, size_t size) {
    DIR *dir;
    struct dirent *entry;

    dir = opendir(SYSFS_BASE);
    if (!dir) {
        perror("opendir");
        return -1;
    }

    while ((entry = readdir(dir)) != NULL) {
        // Skip "." and ".."
        if (entry->d_name[0] == '.')
            continue;

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
    if (!f) {
        perror("fopen");
        return -1;
    }

    fprintf(f, "%s", mode);
    fclose(f);
    return 0;
}

int read_mode(const char *path) {
    char buffer[64];
    FILE *f = fopen(path, "r");
    if (!f) {
        perror("fopen");
        return -1;
    }

    if (fgets(buffer, sizeof(buffer), f) != NULL) {
        printf("%s", buffer);
    }

    fclose(f);
    return 0;
}


int main(int argc, char *argv[]) {
    char sysfs_path[PATH_MAX];

    if (find_x3d_path(sysfs_path, sizeof(sysfs_path)) != 0) {
        fprintf(stderr, "Could not locate amd_x3d_mode\n");
        return 1;
    }

    if (argc != 2) {
        fprintf(stderr, "Usage: x3dctl-helper [cache|frequency|status]\n");
        return 1;
    }

    if (strcmp(argv[1], "cache") == 0) {
        return write_mode(sysfs_path, "cache");
    }
    else if (strcmp(argv[1], "frequency") == 0) {
        return write_mode(sysfs_path, "frequency");
    }
    else if (strcmp(argv[1], "status") == 0) {
        return read_mode(sysfs_path);
    }
    else {
        fprintf(stderr, "Invalid argument\n");
        return 1;
    }
}

