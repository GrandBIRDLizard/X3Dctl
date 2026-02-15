# x3dctl Roadmap

This document outlines planned development goals and feature direction for x3dctl.  
It is intended to provide transparency and help guide community feedback.

x3dctl is currently in early development (0.x series).  
Interfaces and behavior may change as the project evolves.

---

## Near-Term Goals

### Simple Configuration System
Introduce a lightweight configuration file supporting:

- Default profile selection
- Optional per-application profile mapping
- Minimal validation and safe fallback behavior

Design goals:

- Keep configuration human-readable
- Avoid complex dependency or parsing overhead
- Maintain predictable CLI behavior

---

### CCD Pinning / Process Affinity Support
Provide optional helpers for directing workloads to specific CCDs.

Planned capabilities:

- Manual process pinning helpers
- Application launch pinning support
- Safe CPU topology detection
- Clear separation from automatic scheduling behavior

---

### Improved Process Detection
Enhance application passthrough behavior with:

- More reliable process identification
- Better command parsing
- Safer handling of launch wrappers

---

## Mid-Term Goals

### Profile Expansion
Allow users to define reusable workload profiles.

Potential examples:

- gaming
- streaming
- workstation
- content creation

---

### CLI Quality Improvements

- Extended validation
- Improved error reporting
- Debugging and status inspection tools
- Version reporting

---

### Packaging Support

- Distribution package support (AUR and others)
- Installation and dependency improvements
- Documentation polish

---

## Long-Term Exploration

These features are under consideration and may change based on user feedback.

### Automation / Policy Engine
Allow dynamic profile switching based on workload characteristics.

### Extended Hardware Awareness
Improve topology awareness for future multi-CCD and heterogeneous designs.

### Monitoring Integration
Optional runtime inspection and local telemetry support.

---

## Design Principles

x3dctl development follows several core goals:

- Keep the tool lightweight and script-friendly
- Maintain strong privilege separation
- Prefer deterministic behavior over automation magic
- Avoid unnecessary runtime dependencies
- Maintain predictable and transparent configuration

---

## Community Feedback

Feedback is welcome through:

- GitHub Issues
- Feature discussions
- Pull requests

Early user experience feedback is especially valuable while the project is in alpha development.

---

## Stability Expectations

While in the 0.x release series:

- Configuration formats may change
- CLI behavior may evolve
- Backwards compatibility is not guaranteed

Major behavior changes will be documented in release notes.

