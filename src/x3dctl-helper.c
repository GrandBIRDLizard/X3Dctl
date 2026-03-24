#include "x3dctl-common.h"
#include "x3dctl-x3d.h"
#include "x3dctl-topology.h"
#include "x3dctl-irq.h"
#include "x3dctl-config.h"
#include "x3dctl-policy.h"
#include "x3dctl-status.h"

static int helper_has_cap(cap_value_t cap)
{
    cap_t caps = cap_get_proc();
    if (!caps)
        return 0;

    cap_flag_value_t value = CAP_CLEAR;

    if (cap_get_flag(caps, cap, CAP_EFFECTIVE, &value) != 0) {
        cap_free(caps);
        return 0;
    }

    cap_free(caps);
    return value == CAP_SET;
}

/*static int helper_has_control_privilege(void)
{
    if (geteuid() == 0)
        return 1;

    if (!helper_has_cap(CAP_SYS_NICE))
        return 0;

    if (!helper_has_cap(CAP_SYS_ADMIN))
        return 0;

    return 1;
}*/

static int helper_has_control_privilege(void)
{
    if (geteuid() == 0)
        return 1;

    if (helper_has_cap(CAP_SYS_NICE))
        return 1;

    return 0;
}



static int helper_require_control_privilege(const char *argv0)
{
    if (helper_has_control_privilege())
        return 0;

    fprintf(stderr,
        "x3dctl-helper lacks required privilege.\n"
        "Either run via sudo (with the x3dctl sudoers rule), or apply capabilities:\n"
        "  sudo setcap 'cap_sys_nice,cap_sys_admin=ep' %s\n",
        argv0 ? argv0 : "x3dctl-helper");

    return 1;
}

int main(int argc, char *argv[])
{
    struct x3d_topology topo = {0};

    if (argc < 2) {
        fprintf(stderr, "No command specified\n");
        return 1;
    }

    if (strcmp(argv[1], "can-control") == 0) {
        return helper_has_control_privilege() ? 0 : 1;
    }

    if (strcmp(argv[1], "query") == 0) {
        if (argc != 3)
            return 1;

        char *profile = config_query_profile_for_app(argv[2]);
        if (!profile)
            return 1;

        printf("%s\n", profile);
        free(profile);
        return 0;
    }

    if (strcmp(argv[1], "apply") == 0) {
        if (helper_require_control_privilege(argv[0]) != 0)
            return 1;

        if (argc != 4) {
            fprintf(stderr, "Usage: x3dctl-helper apply <pid> <profile>\n");
            return 1;
        }

        pid_t pid = (pid_t)atoi(argv[2]);
        if (pid <= 0) {
            fprintf(stderr, "Invalid PID\n");
            return 1;
        }

        struct profile p;
        if (policy_load_profile(argv[3], &p) != 0) {
            fprintf(stderr, "Unknown profile\n");
            return 1;
        }

        return policy_apply(pid, &p, &topo);
    }

    char sysfs_path[PATH_MAX];
    if (x3d_find_mode_path(sysfs_path, sizeof(sysfs_path)) != 0) {
        fprintf(stderr, "X3D driver not found.\n");
        return 1;
    }

    if (strcmp(argv[1], "cache") == 0) {
        if (helper_require_control_privilege(argv[0]) != 0)
            return 1;

        int disable_irq = 0;

        if (argc == 3 && strcmp(argv[2], "--no-irq") == 0)
            disable_irq = 1;
        else if (argc > 2)
            return 1;

        if (x3d_write_mode(sysfs_path, "cache") != 0)
            return 1;

        if (topology_init(&topo) != 0)
            return 1;

        cpu_set_t full_mask;
        topology_build_full_mask(&topo, &full_mask);

        if (disable_irq)
            irq_steer_gpu_irqs(&full_mask);
        else
            irq_steer_gpu_irqs(&topo.freq_mask);

        return 0;
    }

    if (strcmp(argv[1], "frequency") == 0) {
        if (helper_require_control_privilege(argv[0]) != 0)
            return 1;

        int disable_irq = 0;

        if (argc == 3 && strcmp(argv[2], "--no-irq") == 0)
            disable_irq = 1;
        else if (argc > 2)
            return 1;

        if (x3d_write_mode(sysfs_path, "frequency") != 0)
            return 1;

        if (topology_init(&topo) != 0)
            return 1;

        cpu_set_t full_mask;
        topology_build_full_mask(&topo, &full_mask);

        (void)disable_irq;
        irq_steer_gpu_irqs(&full_mask);

        return 0;
    }

    if (strcmp(argv[1], "status") == 0) {
        return status_print_report(sysfs_path, &topo);
    }

    fprintf(stderr, "Unknown command\n");
    return 1;
}
