# Results


## Frametime and Framerate Analysis

Performance testing was conducted using Cyberpunk 2077 under controlled conditions with identical system configuration, workload, and CPU affinity for game threads. The only variable modified between test runs was the CPU affinity of GPU MSI-X interrupt handlers. In the baseline configuration, GPU interrupts were serviced on the V-Cache CCD alongside game execution threads. In the experimental configuration, GPU interrupts were instead serviced on the frequency-optimized CCD, while game threads remained affinitized to the V-Cache CCD.

Average framerate improved modestly from 118.1 FPS to 121.5 FPS (+2.9%) when interrupt handling was isolated to the frequency CCD. More significantly, worst-case frametime stability improved substantially. The 0.1% low framerate increased from 41.45 FPS to 53.72 FPS, representing an improvement of approximately 29.6%. This metric reflects worst-case frame delivery latency and is a primary indicator of perceptible stutter.

Frametime timeline visualization confirmed these results. When interrupts were handled on the V-Cache CCD, multiple severe frametime spikes were observed, with peak frametimes exceeding 24 ms. In contrast, when interrupts were isolated to the frequency CCD, the frequency and magnitude of such spikes were substantially reduced. The experimental configuration exhibited fewer high-latency outliers and improved overall frametime consistency.

These findings indicate that interrupt execution on the same CCD as latency-sensitive application threads introduces execution resource contention, resulting in delayed frame completion under certain conditions. Separating interrupt handling to a distinct CCD mitigates this contention and improves worst-case frame delivery latency.


-------------------------------------------------------------------------------------------------------------------------------------

## Cache and Memory Access Analysis

To investigate the underlying mechanism responsible for the observed performance differences, cache-to-cache analysis was performed using the Linux perf c2c subsystem. This analysis measured cache coherence traffic, memory locality, and remote memory accesses across CCD boundaries.

Both configurations demonstrated zero remote DRAM accesses and zero remote peer cache hits. This confirms that no cross-CCD memory locality penalties were introduced by isolating interrupts to a separate CCD. Cache coherence traffic remained local to each CCD domain, and no Infinity Fabric remote memory transfers were observed.

These results indicate that performance improvements were not attributable to reduced cache coherence overhead or improved memory locality. Instead, the improvements are attributable to reduced execution resource contention and improved interrupt servicing latency when interrupt handling was isolated to the higher-frequency CCD.


-------------------------------------------------------------------------------------------------------------------------------------

## Execution Resource Contention and Interrupt Latency

Modern X3D processors employ asymmetric CCD topology, where one CCD provides substantially larger L3 cache capacity while another CCD operates at higher clock frequencies. These architectural differences create specialization opportunities for workload placement.

Latency-sensitive application threads benefit from large L3 cache capacity due to reduced memory access latency and improved cache residency. Interrupt handlers, however, benefit more from higher clock frequency due to reduced interrupt service latency and faster kernel execution.

When interrupts were handled on the V-Cache CCD, interrupt handlers and application threads competed for shared execution resources, including execution units, scheduler priority, and cache access bandwidth. This competition resulted in intermittent delays in frame completion, manifesting as frametime spikes.

When interrupts were isolated to the frequency CCD, application threads were able to execute uninterrupted on the V-Cache CCD, while interrupt handlers executed independently on the higher-frequency CCD. This separation reduced execution contention and improved worst-case frametime stability.


-------------------------------------------------------------------------------------------------------------------------------------

## Conclusion

This study evaluated the performance impact of CCD-aware interrupt steering on an AMD Ryzen 9 9900X3D processor using a real-world gaming workload. By directing GPU interrupts to the frequency-optimized CCD while maintaining application execution on the V-Cache CCD, both average and worst-case performance metrics improved.

Average framerate increased modestly, while worst-case frametime stability improved substantially. Cache-to-cache analysis confirmed that these improvements were not attributable to changes in memory locality or cache coherence traffic, but rather to reduced execution resource contention and improved interrupt handling latency.

These findings demonstrate that interrupt placement is a critical factor in achieving optimal performance on asymmetric multi-CCD architectures. Isolating interrupt handling from latency-sensitive application workloads allows each CCD to operate within its architectural strengths, improving overall system performance and frametime stability.

This work provides empirical evidence supporting CCD-aware interrupt steering as an effective optimization strategy for heterogeneous cache architectures such as AMD X3D processors. Future work will extend this analysis to additional workloads, including compute, storage, and network-intensive scenarios, to further characterize the general applicability of these findings.

-------------------------------------------------------------------------------------------------------------------------------------

## Acknowledgements

Ken Thompson, Dennis Ritchie, and Brian W. Kernighan for being the key proponents of the [Unix philosophy][1] which favors composability as opposed to monolithic design.

Hans-Bernhard Broeker(broeker), Clark Gaylord(cgaylord), Lars Hecking(lhecking), and Ethan Merritt(sfeam) for their selfless contributions to the scientific and open-source community by providing documentation and instruction on [2D and 3D plotting][2], leading to the development of my script-driven plotting implementation.

All research and collection of data was preformed by [GrandBIRDLizard][3], and can be found and reproduced in the project's [repository][4].

-------------------------------------------------------------------------------------------------------------------------------------

## Footnotes

### Funding:
The author has not declared a specific grant for this research from any funding agency in the public, commercial, or not-for-profit sectors. If you would like to donate to the author directly helping fund current and future research you may do so [here][].

-------------------------------------------------------------------------------------------------------------------------------------

## References

[1] :https://harmful.cat-v.org/cat-v/unix_prog_design.pdf .

[2] :https://gnuplot.sourceforge.net/ .

[3] :https://github.com/GrandBIRDLizard .

[4] :https://github.com/GrandBIRDLizard/X3Dctl .  

[here]:https://buymeacoffee.com/grandbirdlizard 
