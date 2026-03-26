#include "x3dctl-common.h"
#include "x3dctl-topology.h"
#include "x3dctl-irq.h"

int irq_is_gpu_line(const char *line)
{
    if (!line)
        return 0;

    return (
        strstr(line, "amdgpu") ||
        strstr(line, "nvidia") ||
        strstr(line, "nouveau")
    );
}

void irq_steer_gpu_irqs(const cpu_set_t *target_mask)
{
    if (!target_mask)
        return;

    FILE *f = fopen("/proc/interrupts", "r");
    if (!f)
        return;

    char line[512];
    char hexmask[CPU_SETSIZE / 4 + 32];

    topology_cpuset_to_hexmask(target_mask, hexmask, sizeof(hexmask));

    while (fgets(line, sizeof(line), f)) {
        if (!irq_is_gpu_line(line))
            continue;

        char *colon = strchr(line, ':');
        if (!colon)
            continue;

        *colon = '\0';

        int irq = atoi(line);
        if (irq <= 0)
            continue;

        char path[128];
        snprintf(path, sizeof(path),
                 "/proc/irq/%d/smp_affinity", irq);

        FILE *irqf = fopen(path, "w");
        if (!irqf)
            continue;

        fprintf(irqf, "%s", hexmask);
        fclose(irqf);
    }

    fclose(f);
}

int irq_read_mask(int irq, char *buf, size_t size)
{
    if (irq <= 0 || !buf || size == 0)
        return 1;

    char path[128];
    snprintf(path, sizeof(path),
             "/proc/irq/%d/smp_affinity", irq);

    FILE *f = fopen(path, "r");
    if (!f)
        return 1;

    if (!fgets(buf, size, f)) {
        fclose(f);
        return 1;
    }

    buf[strcspn(buf, "\n")] = '\0';
    fclose(f);
    return 0;
}
