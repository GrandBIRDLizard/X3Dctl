#include "x3dctl-common.h"
#include "x3dctl-x3d.h"
#include "x3dctl-topology.h"
#include "x3dctl-irq.h"
#include "x3dctl-status.h"

static void print_cpu_model(void)
{
    FILE *f = fopen("/proc/cpuinfo", "r");
    if (!f)
        return;

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "model name", 10) == 0) {
            char *colon = strchr(line, ':');
            if (colon)
                printf("CPU: %s", colon + 2);
            break;
        }
    }

    fclose(f);
}

static int irqbalance_active(void)
{
    int ret = system("systemctl is-active --quiet irqbalance 2>/dev/null");
    return ret == 0;
}

int status_print_report(const char *sysfs_path, struct x3d_topology *topo)
{
    if (!sysfs_path || !topo)
        return 1;

    printf("o=========================================o\n");
    printf("          X3DCTL SYSTEM STATUS\n");
    printf("o=========================================o\n");

    print_cpu_model();

    char mode_buf[32] = {0};
    if (x3d_read_mode(sysfs_path, mode_buf, sizeof(mode_buf)) != 0)
        mode_buf[0] = '\0';

    printf("\nMode: %s\n", mode_buf[0] ? mode_buf : "Unknown");

    if (irqbalance_active())
        printf("irqbalance Service: ACTIVE (may override steering)\n");
    else
        printf("irqbalance Service: OFF\n");

    if (topology_init(topo) != 0) {
        printf("\nGPU IRQ Audit: unavailable\n");
        printf("o=========================================o\n");
        return 0;
    }

    char cache_hex[CPU_SETSIZE / 4 + 32];
    char freq_hex[CPU_SETSIZE / 4 + 32];
    char full_hex[CPU_SETSIZE / 4 + 32];

    topology_cpuset_to_hexmask(&topo->cache_mask, cache_hex, sizeof(cache_hex));
    topology_cpuset_to_hexmask(&topo->freq_mask, freq_hex, sizeof(freq_hex));

    cpu_set_t full_mask;
    topology_build_full_mask(topo, &full_mask);
    topology_cpuset_to_hexmask(&full_mask, full_hex, sizeof(full_hex));

    FILE *f = fopen("/proc/interrupts", "r");
    if (!f) {
        printf("\nGPU IRQ Audit: unavailable\n");
        printf("o=========================================o\n");
        return 0;
    }

    printf("\nGPU IRQ Audit:\n");

    char line[512];
    int all_full = 1;
    int all_freq = 1;
    int all_cache = 1;
    int irq_found = 0;

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

        char current_mask[256];
        if (irq_read_mask(irq, current_mask, sizeof(current_mask)) != 0)
            continue;

        irq_found = 1;

        printf("  IRQ %d → 0x%s\n", irq, current_mask);

        if (strcasecmp(current_mask, full_hex) != 0)
            all_full = 0;

        if (strcasecmp(current_mask, freq_hex) != 0)
            all_freq = 0;

        if (strcasecmp(current_mask, cache_hex) != 0)
            all_cache = 0;
    }

    fclose(f);

    printf("\nIRQ Steering: ");

    if (!irq_found) {
        printf("No GPU IRQs detected\n");
    } else if (all_full) {
        printf("DISABLED (Full Mask)\n");
    } else if (all_freq) {
        printf("Pinned to Frequency CCD\n");
    } else if (all_cache) {
        printf("Pinned to Cache CCD\n");
    } else {
        printf("Custom / Mixed\n");
    }

    printf("o=========================================o\n");
    return 0;
}
