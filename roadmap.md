# x3dctl Roadmap

This document outlines the development direction and architectural goals for **x3dctl**.

x3dctl is currently in the **1.x release series**.
Core CLI behavior is expected to remain stable while the project continues to mature around deterministic control, clearer privilege boundaries, and future scheduler aware backend support.

---

# Current Progress Snapshot

Recent work has focused on stabilizing the current command model and tightening predictable system behavior:

- Stable global mode control via:
  - `gaming`.
  - `performance`.
  - `toggle`.
- Stable **process-only** policy application via:
  - `run`.
- Dynamic topology-aware CCD detection.
- Safe single-CCD fallback behavior.
- Deterministic GPU IRQ steering with explicit full-mask restore behavior.
- PATH-aware helper resolution for both local and packaged installs.
- Cleaner install / uninstall behavior for local and AUR-style packaging.
- Optional capability-based convenience path for passwordless process policy.(`x3dctl run`) via `cap_sys_nice`.
- Continued refinement of documentation, privilege boundaries, and packaging behavior.

The current helper layout is being kept intentionally stable while future scheduler/backend work is planned.

---

# Current Capabilities (1.x.x)

## Deterministic Mode Control
- Explicit cache (`gaming`) and frequency (`performance`) switching.
- Toggle support.
- No background daemon.
- No hidden automatic switching.

## Topology-Aware CCD Detection
- Dynamic cache vs frequency CCD detection.
- No hardcoded CPU numbering.
- Simple single-CCD fallback behavior.

## Process Policy Engine
- Affinity control (`gaming`, `frequency`, `workstation`, `unrestricted`).
- Scheduler class selection.
- Nice management.
- I/O priority management.
- Exec-based policy application for launched processes.
- Multiple concurrent workloads can run with distinct per-process policy while a separate global mode remains active.

## Mode-Bound GPU IRQ Steering
- `gaming` posture steers GPU IRQs away from the cache CCD.
- `performance` posture restores deterministic full CPU mask routing.
- `--no-irq` override restores deterministic full-mask baseline.
- No state drift between mode changes.

## Status Inspection
- Mode reporting.
- GPU IRQ mask audit.
- `irqbalance` service detection.
- CPU model reporting.

## Packaging Support
- DESTDIR-aware Makefile.
- AUR-compatible packaging layout.
- Static sudoers policy install.
- Local install and packaged install path support.
- Optional capability-based convenience path for passwordless use.

---

# Near-Term Focus

## Stability and Validation
- Continue real-world validation on dual-CCD X3D systems.
- Refine status output and mismatch reporting where useful.
- Improve edge-case handling for unusual launch wrappers.
- Keep the current helper layout stable until scheduler/backend work begins.

## Documentation and UX Polish
- Keep the README concise and front-page focused.
- Keep full operational details in `man x3dctl`.
- Expand examples for Steam, launchers, and `unrestricted`.
- Continue clarifying the distinction between:
  - global mode commands.
  - process-only policy application.

## Packaging Maintenance
- Keep the AUR package aligned with tagged releases.
- Maintain clean install / uninstall behavior.
- Keep local install and packaged install behavior consistent.
- Maintain optional capability-based convenience for `run` without making it a hard requirement.

---

# Mid-Term Goals

## Built-In Profile Expansion
Expand the built-in profile model without introducing arbitrary runtime scheduling rules.

Possible future additions may include:

## Extended Hardware Awareness
- Safer behavior on single-CCD systems.
- Better topology heuristics where needed.
- More defensive handling for unusual CPU layouts.
- Continued validation across additional X3D and non-X3D edge cases where practical.

## Scheduler-Aware Backend Support
x3dctl is being developed with the long-term goal of supporting multiple Linux scheduler behaviors **without changing its core command model**.

The intent is to keep the user-facing workflow stable while allowing built-in profile behavior to adapt more intelligently to the active scheduler backend.

Planned goals include:

- Detect the active scheduler or kernel scheduling model at runtime where practical.
- Preserve deterministic process policy behavior across scheduler implementations.
- Adjust built-in profile defaults where scheduler behavior materially changes affinity or wakeup characteristics.
- Avoid introducing arbitrary runtime tuning or opaque heuristics into the frontend.

Initial support and testing focus is expected to center around:

- **CFS / EEVDF** (mainline default behavior).
- **BMQ** (primary research focus).
- **BORE**.
- **CacULE**.

Scheduler support will be treated as a **backend-awareness problem**, not as a redesign of the core CLI.

---

# Kernel Research / Related Work (Experimental)

In parallel with x3dctl itself, related kernel-side experimentation is underway around Zen-focused scheduler behavior and topology-aware workload control.

## Bitmap-Basilisk (Work in Progress)
**Bitmap-Basilisk** is an experimental Zen-oriented kernel patch / research effort currently being explored alongside x3dctl development.

Current intent:

- Investigate scheduler behavior that better respects strict affinity and manual. topology-aware workload placement.
- Explore low-latency behavior on dual-CCD X3D systems.
- Evaluate how scheduler simplicity interacts with explicit CPU affinity and IRQ steering.
- Inform future scheduler-aware profile behavior inside x3dctl.

Important notes:

- **Bitmap-Basilisk is experimental**
- **It is not currently a dependency of x3dctl**
- **It may change substantially or not ship at all**
- x3dctl will continue to support stable workflows independently of this work.

This research is intended to improve understanding of how different scheduler models interact with x3dctl’s deterministic design goals.

---

# Long-Term Exploration

These areas are intentionally exploratory and may change based on testing, measurement, and user feedback.

## Carefully Scoped Automation
- Optional dynamic switching experiments.
- Only if deterministic guarantees can be preserved.
- No automation at the expense of predictability.

## Broader Backend Maturity
- Clear scheduler/backend abstraction inside the helper.
- Cleaner backend-specific profile behavior.
- Future internal refactoring when scheduler support becomes concrete enough to justify it.

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
- Favor plain text, inspectable workflows.
- Preserve a small, UNIX-oriented command surface.

---

# Stability Expectations

While in the **1.x release series**:

- Core CLI behavior should remain stable.
- Configuration formats may evolve carefully.
- Behavioral changes and bug fixes will be documented in release notes.
- Larger internal restructuring should follow real backend needs, not happen for its own sake.

---

# Community Feedback

Feedback is welcome through:

- GitHub Issues.
- Feature discussions.
- Pull requests.

Measurement-driven feedback is especially valuable, particularly around:

- scheduler behavior.
- mixed workload results.
- frametime consistency.
- IRQ routing outcomes.
- X3D topology edge cases
