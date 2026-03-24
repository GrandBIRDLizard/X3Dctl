#include "x3dctl-common.h"
#include "x3dctl-x3d.h"

int x3d_find_mode_path(char *out_path, size_t size)
{
    if (!out_path || size == 0)
        return 1;

    DIR *dir = opendir(SYSFS_BASE);
    if (!dir)
        return 1;

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (entry->d_name[0] == '.')
            continue;

        if (strncmp(entry->d_name, "AMDI", 4) != 0)
            continue;

        snprintf(out_path, size, "%s/%s/amd_x3d_mode",
                 SYSFS_BASE, entry->d_name);

        if (access(out_path, F_OK) == 0) {
            closedir(dir);
            return 0;
        }
    }

    closedir(dir);
    return 1;
}

int x3d_write_mode(const char *path, const char *mode)
{
    if (!path || !mode)
        return 1;

    FILE *f = fopen(path, "w");
    if (!f)
        return 1;

    fprintf(f, "%s", mode);
    fclose(f);
    return 0;
}

int x3d_read_mode(const char *path, char *buf, size_t size)
{
    if (!path || !buf || size == 0)
        return 1;

    FILE *f = fopen(path, "r");
    if (!f)
        return 1;

    if (!fgets(buf, size, f)) {
        fclose(f);
        buf[0] = '\0';
        return 1;
    }

    fclose(f);

    buf[strcspn(buf, "\n")] = '\0';
    return 0;
}
