# x3dctl Roadmap

This document outlines development direction and architectural goals for x3dctl.

x3dctl is currently in the 0.x series.  
Interfaces and behavior may evolve as the project matures.

---

# Current State (0.5.x)

As of v0.5.x, x3dctl provides:

## Implemented Capabilities

### Deterministic Mode Control
- Explicit cache (gaming) and frequency (performance) X3D mode switching
- Toggle support
- No background daemon or automation

### Topology-Aware CCD Detection
- Automatic detection of cache vs frequency CCD
- Dynamic CPU mask generation
- No hardcoded CPU numbering assumptions

### Process Policy Engine
- Per-process affinity control
- Scheduler class selection
- Nice level management
- I/O priority configuration
- Deterministic inheritance model for launched applications

### Mode-Bound GPU IRQ Steering
- Gaming mode steers GPU IRQs to frequency CCD
- Performance mode restores full CPU mask
- Optional `--no-irq` override
- No state drift between transitions

### Privilege Separation
- Restricted helper binary
- Sudo rule isolation
- Configuration ownership validation
- No realtime scheduling exposure

---

# Near-Term Goals (0.5.x Direction)

### Profile Refinement
- Cleaner internal profile model
- Optional user-defined profile expansion
- Maintain static validation and deterministic behavior

### Improved CLI Feedback
- Version reporting
- Extended validation messages
- Optional inspection tools (topology / IRQ state reporting)

### Steam / Launcher Integration Improvements
- Clean support for Steam launch options
- Improved wrapper clarity
- Better documentation for gaming workflows

---

# Mid-Term Goals

### Extended Hardware Awareness
- Improved handling for future multi-CCD designs
- Safer behavior on single-CCD systems
- Better detection heuristics where needed

### Advanced Profile Expansion
Allow users to define reusable workload profiles, such as:

- gaming
- streaming
- workstation
- content creation

Without introducing runtime automation.

### Packaging Support
- Distribution packages (AUR and others)
- Installation improvements
- Documentation polish

---

# Long-Term Exploration

These features are exploratory and may change based on user feedback.

### Optional Inspection Utilities
- IRQ mask display helpers
- CCD topology visualization
- Debug-focused system state reporting

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

While in the 0.x release series:

- CLI behavior may evolve
- Configuration formats may change
- Backwards compatibility is not guaranteed

Major behavior changes will always be documented in release notes.

---

# Community Feedback

Feedback is welcome through:

- GitHub Issues
- Feature discussions
- Pull requests

Measurement-driven feedback (performance impact, workload results) is especially valuable.
