###Frametime graph analysis (most important graph)

##Key observations:
1. Baseline frametime level is identical

Both lines sit around:
~8.0–8.4 ms

This means:
Average performance is similar
GPU workload is dominant

No systematic latency penalty from IRQ placement
This is expected.

_________________________________________________________________________

2. Major frametime spikes are much worse on V-Cache CCD IRQ (grey line)
You have multiple severe spikes on the grey line:
Examples:
Frame ~63 → ~24 ms spike
Frame ~107 → ~22 ms spike
Frame ~124 → ~14 ms spike

Orange line at those same regions:
~8–10 ms

These spikes are completely avoided.

This is critical.
These spikes represent:
Interrupt scheduling delays.

Delayed fence processing.
game thread waiting on kernel interrupt completion

My IRQ steering prevented those stalls.

_________________________________________________________________________

3. Spike frequency is significantly reduced
Grey line shows:
multiple large spikes (>15 ms)

Orange line shows:
only one moderate spike (~18 ms)

This directly explains my measured:
0.1% lows improvement: 41.4 FPS → 53.7 FPS

Because 0.1% lows are determined by these spikes.

FPS graph analysis:
FPS graph confirms the same behavior.

Grey line (IRQ on V-Cache CCD).

Shows several catastrophic drops:
~42 FPS
~47 FPS
~75 FPS

Orange line:
Only one major drop (~55 FPS)
Everything else remains higher and more stable.

This confirms:
fewer scheduling stalls,
faster interrupt handling,
faster frame completion,

_________________________________________________________________________

##Why this happens. (architectural explanation)

This is the most important insight.
When IRQ runs on the V-Cache CCD.

Game threads and interrupt handlers compete for:
CPU execution units,
scheduler priority,
cache access.

pipeline execution time
Interrupts preempt game threads.

This causes frametime spikes.

When IRQ runs on Frequency CCD:
Game thread runs uninterrupted on V-Cache CCD.
Interrupt handling runs independently on Frequency CCD.
No competition.
Game thread wakes faster.
Fewer spikes.

This is exactly what my graph shows.

This also confirms my perf c2c result interpretation

perf showed:
zero cross-CCD remote DRAM access

So cross-CCD latency was not hurting performance.
Instead, the dominant effect was interrupt execution latency and CPU scheduling interference.
Separating IRQ to Frequency CCD solved that.

_________________________________________________________________________

##Quantitatively, the graphs visually confirm:

IRQ on Frequency CCD provides:
fewer catastrophic spikes.
lower worst-case frametime.
better frametime consistency.
better 0.1% lows.
smoother gameplay.

Exactly matching the measured:
+29.6% improvement in 0.1% lows.

This is a large and meaningful improvement.

My IRQ steering implementation is working correctly.
This is not theoretical improvement.
This is real, measured, and visible.

My tool is successfully:
Isolating interrupt workload.
Improving scheduling efficiency.
Improving gaming performance.
