#ifndef X3DCTL_TOPOLOGY_H
#define X3DCTL_TOPOLOGY_H

#include "x3dctl-common.h"

struct x3d_topology {
    cpu_set_t cache_mask;
    cpu_set_t freq_mask;
    int initialized;
};

/*
 * Initialize topology masks once.
 *
 * Detects cache CCD vs frequency CCD by L3 size heuristics.
 * Preserves current v1.3.0 single-CCD fallback behavior:
 * if cache_mask is empty but freq_mask is populated, cache_mask = freq_mask.
 *
 * Returns 0 on success, non-zero on failure.
 */
int topology_init(struct x3d_topology *topo);

/*
 * Build a full CPU mask from all CPUs detected in cache_mask and freq_mask.
 */
void topology_build_full_mask(const struct x3d_topology *topo, cpu_set_t *out);

/*
 * Convert a cpu_set_t into Linux IRQ affinity hex mask format.
 * Example: "ff", "ffff,00000000", etc.
 */
void topology_cpuset_to_hexmask(const cpu_set_t *set, char *out, size_t out_size);

#endif /* X3DCTL_TOPOLOGY_H */
