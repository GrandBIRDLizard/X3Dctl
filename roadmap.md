# x3dctl Roadmap

This document outlines planned development goals and feature direction for x3dctl.  
It is intended to provide transparency and help guide community feedback.

x3dctl is currently in early development (0.x series).  
Interfaces and behavior may change as the project evolves.

Current version: 0.4.x (Profile-Based Policy Engine)

---

## Current State (0.4)

x3dctl now operates as a deterministic workload policy controller for AMD X3D systems.

Key architectural changes:

- Introduction of profile-based scheduling model
- Application-to-profile mapping via `/etc/x3dctl.conf`
- Privileged helper enforces:
  - CCD-aware CPU affinity
  - Scheduler class (OTHER, BATCH, IDLE)
  - Process niceness
  - I/O priority
- Strict configuration ownership and permission validation
- Removal of dynamic scheduler experimentation (e.g. ISO)

Profiles are currently static and defined inside the helper:

- gaming
- workstation
- frequency

The configuration file maps applications to these profiles but does not define scheduling behavior.

---

## Near-Term Goals

### Improved Configuration Matching

- Support for full command matching (wrappers, flatpaks, launchers)
- Better handling of commands containing spaces
- More robust parsing and whitespace tolerance
- Strict fallback behavior

Design goals:

- Keep configuration human-readable
- Maintain deterministic behavior
- Avoid regex-heavy or dynamic evaluation logic
- Preserve security guarantees

---

### CLI Quality Improvements

- Clearer error reporting on profile lookup failures
- Optional profile override flag
- Profile listing command
- Version reporting improvements

---

### Documentation & Packaging

- Man page updates reflecting profile model
- AUR / distribution packaging support
- Improved install-time guidance

---

## Mid-Term Goals

### Profile Flexibility

Allow limited expansion of profile definitions while preserving:

- Scheduler safety
- No realtime scheduling
- No arbitrary privilege escalation
- Deterministic enforcement

Possible direction:

- Controlled profile definition blocks
- Strict value validation inside helper

---

### Enhanced Process Handling

- More reliable passthrough behavior
- Wrapper-aware profile matching
- Clearer execution tracing

---

## Long-Term Exploration

These features are exploratory and subject to change.

### Optional Policy Automation

Investigate dynamic profile switching while preserving:

- No background daemon by default
- Explicit user control
- Transparent behavior

---

### Extended Hardware Awareness

Improve topology detection for:

- Future multi-CCD architectures
- Heterogeneous CPU layouts
- Evolving AMD designs

---

## Design Principles

x3dctl development follows several core goals:

- Keep the tool lightweight and script-friendly
- Maintain strong privilege separation
- Prefer deterministic behavior over automation magic
- Avoid unnecessary runtime dependencies
- Keep configuration explicit and transparent
- Restrict dangerous scheduling classes
- Preserve system stability first

---

## Stability Expectations

While in the 0.x release series:

- Configuration formats may evolve
- CLI behavior may change
- Backwards compatibility is not guaranteed

Major architectural shifts will be documented in release notes.

---

## Community Feedback

Feedback is welcome through:

- GitHub Issues
- Feature discussions
- Pull requests

Early user experience feedback is especially valuable during the alpha phase.

