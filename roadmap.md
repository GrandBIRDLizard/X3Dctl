# x3dctl Roadmap:

This document outlines development direction and architectural goals for x3dctl.

x3dctl is currently in the 1.x release series.  
Core CLI behavior is expected to remain stable.

---

# Current Capabilities (1.x.x)

### Deterministic Mode Control:
- Explicit cache, (`gaming`) and frequency, (`performance`) switching.
- Toggle support.
- No background daemon.

### Topology-Aware CCD Detection:
- Dynamic cache vs frequency CCD detection.
- No hardcoded CPU numbering.
- Simple single-CCD fallback behavior.

### Process Policy Engine
- Affinity control (`gaming`, `frequency`, `workstation`, `unrestricted`).
- Scheduler class selection.
- Nice management.
- I/O priority management.
- Exec-based policy application for launched processes.

### Mode-Bound GPU IRQ Steering:
- `gaming` posture steers GPU IRQs away from the cache CCD.
- `performance` posture restores deterministic full CPU mask routing.
- `--no-irq` override restores deterministic full-mask baseline.
- No state drift between mode changes.

### Status Inspection:
- Mode reporting.
- GPU IRQ mask audit.
- irqbalance service detection.
- CPU model reporting.

### Packaging Support:
- DESTDIR-aware Makefile.
- AUR-compatible packaging layout.
- Static sudoers policy install.
- Local install and packaged install path support.

---

# Near-Term Focus

### Stability and Validation:
- Continue real-world validation on dual-CCD X3D systems
- Refine status output and mismatch reporting where useful
- Improve edge-case handling for unusual launch wrappers

### Documentation Polish:
- Keep README focused on usage and design
- Keep detailed parsing behavior in `man x3dctl` and `/etc/x3dctl.conf`
- Expand examples for Steam, launchers, and `unrestricted`

### Packaging Maintenance:
- Keep AUR package aligned with tagged releases.
- Maintain clean install/uninstall behavior.
- Keep local install and packaged install behavior consistent.

---

# Mid-Long-Term Goals

### Extended Hardware Awareness:
- Safer behavior on single-CCD systems.
- Better topology heuristics where needed.
- More defensive handling for unusual CPU layouts.

## Built-In Profile Expansion:
Expand the built-in profile model without introducing arbitrary runtime scheduling rules.

Possible future additions may include:
- streaming.
- content creation.
- background encode / render.
- mixed-load desktop presets.

## Kernel Scheduler Awareness:
- Detect active Linux scheduler at runtime.
- Adjust profile defaults depending on scheduler type.
- Preserve deterministic behavior across scheduler implementations.

---

## Planned Scheduler Support:
- CFS (default)
- BMQ(BMQ research has shown most promising specifically with Zen Kernel via SCHED_ALT custom patch).
- BMQ will lead the rounds of tests pressing forward.
I may kill a few birds with one stone and bench them with Cachy kernel as I bielieve they have patches for most of these scheduler types as well as (BORE/CacULE) built in. and will provide a large blanket of info for those curious enough to be on Cachy 

### Scheduler coices:
I assume you are already familiar with how the Completely Fair Scheduler(CFS and its modern EEVDF replacement) operates.
The difference between BMQ, BORE, and CacULE fundamentally comes down to how much "thinking" the kernel does to calculat.
fairness, and how that interacts with modern hardware.

### Here is a breakdown of how BORE and CacULE operate. 
- why BMQ often delivers tighter performance and lower latency. 

- Both BORE/CacULE attempt to fix the responsiveness issues of standard CFS/EEVDF, but they do so by adding more logic, 
not less.

### BORE(Burst-Oriented Response Enhancer): 
- BORE is built directly on top of EEVDF. 
- It introduces a dynamic "burstiness" score. 
- If a task yields the CPU frequently (like a game waiting on GPU sync), BORE lowers its burst score, 
- granting it a longer timeslice and aggressive wakeup preemption. However, underneath this scoring system, 
- it is still EEVDF; it still maintains a Red-Black tree and calculates virtual deadlines to maintain overarching system fairness.

### CacULE:
- This scheduler was inspired by FreeBSD’s ULE scheduler. 
- It replaces the CFS RB-Tree with a linked list and relies heavily on calculating an "interactivity score." 
- If a task’s interactivity score is high enough, it forcefully preempts the running task.


### Why BMQ Outperforms Them for Low Latency:
- BMQ abandons the concept of mathematical fairness entirely. 
- It does not calculate burstiness, virtual deadlines, or interactivity scores. 
- It just checks a bitmap and runs the highest-priority queue.

### This absolute simplicity provides massive advantages in highly tuned environments:

1. No Heuristic Guessing Games
BORE and CacULE rely on heuristics—they observe how a task behaves and "guess" if it is an interactive game thread or a background compiling job. Heuristics are inherently reactive; they take a few CPU cycles to adapt to sudden changes in load. BMQ doesn't guess. It relies on strict, predefined priority rules. When a heavy engine thread wakes up, BMQ immediately snaps it to the CPU without spending cycles recalculating its burst score.

2. Zero Friction with Manual CPU Topology Management
This is perhaps the most significant advantage on modern asymmetric processors, particularly those featuring dual CCDs where one handles dense 3D V-Cache and the other handles higher clock frequencies.
Complex schedulers like EEVDF and BORE inherently want to load-balance. 
They frequently attempt to migrate tasks across the entire CPU topology to prevent one core from doing all the work. 
If you are already running custom scripts or C-based daemons to read CPU topology, audit system states, and aggressively pin specific game threads directly to the cache-heavy CCD, an overactive scheduler will actively fight you. It will attempt to pull threads off the pinned cores in the name of "fairness."

BMQ is a much "dumber" and therefore more obedient scheduler. It respects strict CPU affinity much better because it lacks the aggressive, overarching load-balancing logic of EEVDF. It leaves your carefully pinned threads exactly where you put them.

3. Frametime Consistency Under Saturation
When running demanding, geometrically complex titles that saturate the CPU with heavy NPC logic and asset streaming, frametime variance (1% and 0.1% lows) is often caused by micro-stutters when the scheduler briefly interrupts the game to serve a background daemon. BORE will try to give that background task a tiny slice of time to be fair. BMQ will happily let the background task starve until the game thread actually goes to sleep, resulting in a significantly flatter frametime graph.

---

# Long-Term Exploration

These features are exploratory and may change based on user feedback.

### Limited Automation (Carefully Scoped)
- Optional dynamic switching experiments
- Only if deterministic guarantees can be preserved

Automation will not be added at the expense of predictability.

---

# Design Principles

x3dctl development follows these core goals:

- Keep the tool lightweight and script-friendly.
- Maintain strict privilege separation.
- Prefer deterministic behavior over automation.
- Avoid background daemons.
- Avoid PID chasing or polling.
- Maintain predictable and transparent configuration.
- Minimize runtime dependencies.

---

# Stability Expectations

While in the 1.x release series:

- Core CLI behavior should remain stable.
- Configuration formats may evolve carefully.
- Behavioral changes and bug fixes will be documented in release notes.

---

# Community Feedback

Feedback is welcome through:

- GitHub Issues
- Feature discussions
- Pull requests

Measurement-driven feedback (performance impact, workload results) is especially valuable.
