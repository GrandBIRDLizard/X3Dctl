#ifndef X3DCTL_CONFIG_H
#define X3DCTL_CONFIG_H

#include "x3dctl-common.h"

/*
 * Validate /etc/x3dctl.conf ownership and permissions.
 *
 *   - must be owned by root
 *   - must not be writable by group or others
 *
 * Returns 0 if valid, non-zero otherwise.
 */
int config_verify_security(void);

/*
 * Query a profile name for the provided application string.
 *
 *   - matches by basename only
 *   - ignores blank lines and comments
 *   - trims whitespace around key/value
 *   - supports inline comments in values
 *   - returns strdup()'d profile string on match
 *   - returns NULL on no match or validation/read failure
 *
 * Caller must free() the returned string.
 */
char *config_query_profile_for_app(const char *app);

#endif 
