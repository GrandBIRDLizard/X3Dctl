# x3dctl Roadmap

This document outlines development direction and architectural goals for x3dctl.

x3dctl is currently in the 1.x series.
Core CLI semantics are stable.

---

# Current Capabilities (1.0.x)
### Deterministic Mode Control
- Explicit cache (gaming) and frequency (performance) switching
- Toggle support
- No background daemon

### Topology-Aware CCD Detection
- Dynamic cache vs frequency CCD detection
- No hardcoded CPU numbering

### Process Policy Engine
- Affinity control (cache, frequency, unrestricted)
- Scheduler class selection
- Nice management
- I/O priority management
- Deterministic inheritance model

### Mode-Bound GPU IRQ Steering
- Gaming posture steers GPU IRQs
- Performance posture restores full CPU mask
- <--no-irq> override
- No state drift

### Status Inspection
- Mode reporting
- IRQ mask audit
- irqbalance detection

### Packaging Support
- Makefile with DESTDIR
- AUR-ready build system
- Static sudoers model

---

# Mid-Long-Term Goals

### Extended Hardware Awareness
- Safer behavior on single-CCD systems
- Better detection heuristics where needed

### Advanced Profile Expansion
Allow users to define reusable workload profiles, such as:

- gaming
- streaming
- workstation
- content creation

Without introducing runtime automation.

### Kernel Scheduler Awareness
- Detect active Linux scheduler at runtime.
- Adjust profile defaults depending on scheduler type.

### Support for:
- CFS (default)
- BMQ
- BORE
- Cachy scheduler variants

Preserve deterministic behavior across scheduler implementations.

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

- Keep the tool lightweight and script-friendly
- Maintain strict privilege separation
- Prefer deterministic behavior over automation magic
- Avoid background daemons
- Avoid PID chasing or polling
- Maintain predictable and transparent configuration
- Minimize runtime dependencies

---

# Stability Expectations

While in the 1.x release series:

- CLI behavior will remain stable 
- Configuration formats may change
- Backwards compatibility is guaranteed

Major behavior changes or bug fixes will always be documented in release notes.

---

# Community Feedback

Feedback is welcome through:

- GitHub Issues
- Feature discussions
- Pull requests

Measurement-driven feedback (performance impact, workload results) is especially valuable.
