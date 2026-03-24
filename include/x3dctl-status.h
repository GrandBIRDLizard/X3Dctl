#ifndef X3DCTL_STATUS_H
#define X3DCTL_STATUS_H

#include "x3dctl-common.h"
#include "x3dctl-topology.h"

/*
 * Print the current x3dctl system status report.
 *
 * Current v1.3.0 output includes:
 *   - banner
 *   - CPU model
 *   - current X3D mode
 *   - irqbalance service state
 *   - GPU IRQ audit
 *   - IRQ steering summary
 *
 * sysfs_path should be the resolved AMD X3D mode path.
 *
 * Returns 0 on success.
 */
int status_print_report(const char *sysfs_path, struct x3d_topology *topo);

#endif /* X3DCTL_STATUS_H */
