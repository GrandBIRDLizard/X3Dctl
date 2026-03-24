#ifndef X3DCTL_IRQ_H
#define X3DCTL_IRQ_H

#include "x3dctl-common.h"

/*
 * Return non-zero if a /proc/interrupts line appears to belong to a GPU driver.
 * Current v1.3.0 logic matches:
 *   - amdgpu
 *   - nvidia
 *   - nouveau
 */
int irq_is_gpu_line(const char *line);

/*
 * Steer all detected GPU IRQs to the provided CPU mask.
 *
 * Best-effort behavior matches current v1.3.0:
 * if /proc/interrupts or a specific IRQ affinity file cannot be opened,
 * the function silently skips those cases.
 */
void irq_steer_gpu_irqs(const cpu_set_t *target_mask);

/*
 * Read the current smp_affinity mask for a specific IRQ into buf.
 * Newline is stripped if present.
 *
 * Returns 0 on success, non-zero on failure.
 */
int irq_read_mask(int irq, char *buf, size_t size);

#endif /* X3DCTL_IRQ_H */
