# IRQ Steering Benchmark Analysis

## AMD Ryzen 9 9900X3D -- Cyberpunk 2077 Test Results

------------------------------------------------------------------------

## Test Objective

To determine whether GPU interrupts (MSI-X) should be handled on:

-   **V-Cache CCD (CCD1)** -- Same CCD as the game threads\
-   **Frequency CCD (CCD0)** -- Separate CCD from the game threads

The goal was to measure:

-   Average FPS
-   Frametime consistency
-   1% and 0.1% low FPS
-   Cache-to-cache latency (perf c2c)
-   Cross-CCD traffic

------------------------------------------------------------------------

## System Configuration

-   CPU: AMD Ryzen 9 9900X3D
-   GPU: Radeon RX 9070 XT
-   Game: Cyberpunk 2077 (Full Benchmark Run)
-   Game threads pinned to: **V-Cache CCD0 (CPUs 0-5, 12-17)**
-   IRQ mask used for CCD0: `0xfc0fc0` **(CPUs 6-11, 18-23)**

------------------------------------------------------------------------

## Benchmark Results

### IRQ on V-Cache CCD (Game + IRQ on same CCD)

-   Average FPS: **118.1**
-   Average Frametime: **8.5 ms**
-   1% Low: **41.45 FPS**
-   0.1% Low: **41.45 FPS**

------------------------------------------------------------------------

## IRQ on Frequency CCD (Game isolated on V-Cache CCD)

-   Average FPS: **121.5**
-   Average Frametime: **8.2 ms**
-   1% Low: **53.72 FPS**
-   0.1% Low: **53.72 FPS**

------------------------------------------------------------------------

## Performance Comparison

  Metric          V-Cache IRQ   Frequency IRQ   Improvement
  --------------- ------------- --------------- ---------------
  Average FPS     118.1         121.5           +2.9%
  Avg Frametime   8.5 ms        8.2 ms          -3.5% latency
  0.1% Low FPS    41.45         53.72           **+29.6%**

------------------------------------------------------------------------

## What This Means

1.  **Average FPS improved slightly** (+3 FPS).
2.  **Frametime latency decreased**, meaning frames were delivered
    faster on average.
3.  **Worst-case performance (0.1% lows) improved massively (\~30%)**.

The 0.1% low improvement is the most important metric. It represents the
worst frametime spikes during gameplay. A 30% improvement here means:

-   Fewer stutters
-   Smoother frame pacing
-   More consistent gameplay

------------------------------------------------------------------------

## Cache & Latency Findings (perf c2c)

The perf cache-to-cache analysis showed:

-   **Zero cross-CCD memory traffic**
-   No remote DRAM accesses
-   No Infinity Fabric penalties

This confirms:

IRQ steering successfully isolated CCD domains.

The improvement did NOT come from eliminating cross-CCD penalties (those
were already zero).

Instead, it came from:

-   Faster interrupt handling on the higher-clock Frequency CCD
-   Keeping the V-Cache CCD dedicated entirely to game execution
-   Reduced interrupt contention inside the V-Cache L3

------------------------------------------------------------------------

## Why Frequency CCD Wins

The Frequency CCD:

-   Has higher clock speeds
-   Handles interrupts faster
-   Processes GPU fences and scheduler wakeups more quickly

The V-Cache CCD:

-   Has larger L3 cache (96MB)
-   Is optimized for cache-heavy workloads like game threads

Separating responsibilities allows each CCD to specialize:

-   Game logic → V-Cache CCD
-   Interrupt handling → Frequency CCD

This produced measurable improvements in both average and worst-case
performance.

------------------------------------------------------------------------

## Conclusion

IRQ steering to the Frequency CCD on the Ryzen 9 9900X3D produced:

-   Higher average FPS
-   Lower average frametime
-   Dramatically better 0.1% lows
-   No cross-CCD latency penalties

This validates the effectiveness of CCD-aware interrupt steering on X3D
processors.
