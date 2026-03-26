#ifndef X3DCTL_POLICY_H
#define X3DCTL_POLICY_H

#include "x3dctl-common.h"
#include "x3dctl-topology.h"

struct profile {
    const char *core_type;  
    int nice;
    const char *scheduler;   /* "other", "batch", or "idle" until new schedulers accepted */
    int io_class;
    int io_level;
};

/*
 * Load one of the built-in profile definitions into *p.
 *
 *   - gaming
 *   - workstation
 *   - frequency
 *   - unrestricted
 *
 * Returns 0 on success, non-zero on unknown profile.
 */
int policy_load_profile(const char *name, struct profile *p);

/*
 * Apply a built-in profile to the target PID.
 *
 *   - initializes topology if needed
 *   - applies affinity unless core_type == "none"
 *   - applies scheduler class
 *   - applies nice value
 *   - applies I/O priority
 *
 * Returns 0 on success, non-zero on failure.
 */
int policy_apply(pid_t pid, const struct profile *p, struct x3d_topology *topo);

#endif 
