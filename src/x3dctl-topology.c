#include "x3dctl-common.h"
#include "x3dctl-topology.h"

int topology_init(struct x3d_topology *topo)
{
    if (!topo)
        return 1;

    if (topo->initialized)
        return 0;

    CPU_ZERO(&topo->cache_mask);
    CPU_ZERO(&topo->freq_mask);

    DIR *dir = opendir(CPU_BASE);
    if (!dir)
        return 1;

    struct dirent *entry;
    char path[PATH_MAX];

    while ((entry = readdir(dir))) {
        int cpu_id;

        if (sscanf(entry->d_name, "cpu%d", &cpu_id) != 1)
            continue;

        if (cpu_id >= CPU_SETSIZE)
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

        if (size_kb > 50000)
            CPU_SET(cpu_id, &topo->cache_mask);
        else if (size_kb > 0)
            CPU_SET(cpu_id, &topo->freq_mask);
    }

    closedir(dir);

    /* Preserve v1.3.0 single-CCD fallback behavior */
    if (CPU_COUNT(&topo->cache_mask) == 0 && CPU_COUNT(&topo->freq_mask) > 0) {
        topo->cache_mask = topo->freq_mask;
    }

    topo->initialized = 1;
    return 0;
}

void topology_build_full_mask(const struct x3d_topology *topo, cpu_set_t *out)
{
    if (!topo || !out)
        return;

    CPU_ZERO(out);

    for (int i = 0; i < CPU_SETSIZE; i++) {
        if (CPU_ISSET(i, &topo->cache_mask) ||
            CPU_ISSET(i, &topo->freq_mask)) {
            CPU_SET(i, out);
        }
    }
}

void topology_cpuset_to_hexmask(const cpu_set_t *set, char *out, size_t out_size)
{
    if (!set || !out || out_size == 0)
        return;

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

    *ptr = '\0';
}
