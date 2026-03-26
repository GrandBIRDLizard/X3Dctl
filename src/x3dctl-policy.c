#include "x3dctl-common.h"
#include "x3dctl-topology.h"
#include "x3dctl-policy.h"

static int apply_scheduler(pid_t pid, const char *policy_str)
{
    int policy;

    if (strcmp(policy_str, "other") == 0)
        policy = SCHED_OTHER;
    else if (strcmp(policy_str, "batch") == 0)
        policy = SCHED_BATCH;
    else if (strcmp(policy_str, "idle") == 0)
        policy = SCHED_IDLE;
    else {
        fprintf(stderr, "Invalid scheduler\n");
        return 1;
    }

    struct sched_param sp = {0};

    if (sched_setscheduler(pid, policy, &sp) != 0) {
        perror("sched_setscheduler");
        return 1;
    }

    return 0;
}

static int apply_ioprio(pid_t pid, int io_class, int io_level)
{
    if (io_class != IOPRIO_CLASS_BE &&
        io_class != IOPRIO_CLASS_IDLE) {
        fprintf(stderr, "Invalid IO class\n");
        return 1;
    }

    if (io_class == IOPRIO_CLASS_BE) {
        if (io_level < 0 || io_level > 7) {
            fprintf(stderr, "Invalid IO level\n");
            return 1;
        }
    }

    int prio = IOPRIO_PRIO_VALUE(io_class, io_level);

    if (syscall(SYS_ioprio_set, IOPRIO_WHO_PROCESS, pid, prio) != 0) {
        perror("ioprio_set");
        return 1;
    }

    return 0;
}

int policy_load_profile(const char *name, struct profile *p)
{
    if (!name || !p)
        return 1;

    if (strcmp(name, "gaming") == 0) {
        p->core_type = "cache";
        p->nice = -5;
        p->scheduler = "other";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 0;
        return 0;
    }

    if (strcmp(name, "workstation") == 0) {
        p->core_type = "frequency";
        p->nice = 5;
        p->scheduler = "batch";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 4;
        return 0;
    }

    if (strcmp(name, "frequency") == 0) {
        p->core_type = "frequency";
        p->nice = 0;
        p->scheduler = "other";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 0;
        return 0;
    }

    if (strcmp(name, "unrestricted") == 0) {
        p->core_type = "none";
        p->nice = -1;
        p->scheduler = "other";
        p->io_class = IOPRIO_CLASS_BE;
        p->io_level = 0;
        return 0;
    }

    return 1;
}

int policy_apply(pid_t pid, const struct profile *p, struct x3d_topology *topo)
{
    if (pid <= 0 || !p || !topo)
        return 1;

    if (topology_init(topo) != 0) {
        fprintf(stderr, "Topology detection failed\n");
        return 1;
    }

    cpu_set_t *mask = NULL;

    if (strcmp(p->core_type, "cache") == 0)
        mask = &topo->cache_mask;
    else if (strcmp(p->core_type, "frequency") == 0)
        mask = &topo->freq_mask;
    else if (strcmp(p->core_type, "none") == 0)
        mask = NULL;
    else {
        fprintf(stderr, "Invalid core type\n");
        return 1;
    }

    if (mask != NULL) {
        if (CPU_COUNT_S(sizeof(cpu_set_t), mask) == 0) {
            fprintf(stderr, "Topology detection failed\n");
            return 1;
        }

        if (sched_setaffinity(pid, sizeof(cpu_set_t), mask) != 0) {
            perror("sched_setaffinity");
            return 1;
        }
    }

    if (apply_scheduler(pid, p->scheduler) != 0)
        return 1;

    if (setpriority(PRIO_PROCESS, pid, p->nice) != 0) {
        perror("setpriority");
        return 1;
    }

    if (apply_ioprio(pid, p->io_class, p->io_level) != 0)
        return 1;

    return 0;
}
