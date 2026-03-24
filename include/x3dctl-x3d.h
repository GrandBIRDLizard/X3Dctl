#ifndef X3DCTL_X3D_H
#define X3DCTL_X3D_H

#include "x3dctl-common.h"

/*
 * Locate the active AMD X3D mode sysfs control path.
 * Writes the full path to out_path on success.
 *
 * Returns 0 on success, non-zero on failure.
 */
int x3d_find_mode_path(char *out_path, size_t size);

/*
 * Write "cache" or "frequency" to the AMD X3D mode sysfs node.
 *
 * Returns 0 on success, non-zero on failure.
 */
int x3d_write_mode(const char *path, const char *mode);

/*
 * Read the current AMD X3D mode string into caller-provided buffer.
 * Newline is stripped if present.
 *
 * Returns 0 on success, non-zero on failure.
 */
int x3d_read_mode(const char *path, char *buf, size_t size);

#endif /* X3DCTL_X3D_H */
