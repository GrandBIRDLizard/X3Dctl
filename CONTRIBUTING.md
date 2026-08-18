# Contributing to x3dctl

Thanks for your interest in x3dctl!

x3dctl is intentionally a small, explicit, native UNIX-style utility for deterministic workload policy on AMD X3D systems. Contributions, bug reports, testing, and documentation feedback are all welcome - but the project is intentionally scoped and not every request will fit the design.

---

## Design philosophy

x3dctl prioritizes:

- **Deterministic behavior over hidden automation**
- **Native code and shell integration over heavyweight abstractions**
- **Explicit, inspectable policy over “one-click tuning”**
- **Composability over background daemons and opaque heuristics**
- **Practical support for real AMD X3D workloads on Linux**
- **Incremental growth with minimal complexity**

x3dctl is not intended to be a generic “CPU optimizer” or a magic tuning layer.

---

## What belongs in Issues vs Discussions

### Use **Issues** for:
- Confirmed bugs
- Regressions
- Reproducible failures
- Documentation mistakes / missing prerequisites
- Concrete implementation work aligned with project scope

### Use **Discussions** for:
- General usage questions
- Distro / kernel / scheduler-specific observations
- Mixed workload and gaming results
- Benchmark screenshots
- Tuning discussion
- Design ideas and feature brainstorming

If something is primarily a support question or design discussion, it may be closed and redirected to Discussions.

---

## Before opening an issue

Before reporting a bug or unexpected behavior, please:

- Read the installed man page:  
  `man x3dctl`
- Review the README
- Confirm relevant platform / BIOS prerequisites
- Test with your exact workload, not just a synthetic assumption
- Be ready to provide system details

For supported systems, **CPPC Preferred Cores should be set to `Driver` in BIOS/firmware** where applicable.

x3dctl is intended for users who are reasonably familiar with their platform and comfortable making explicit system-level changes.

---

## Bug reports should include

Please include as much of the following as possible:

- CPU model
- Distro
- Kernel version
- Scheduler (if non-default or custom)
- Exact `x3dctl` command or profile used
- Expected behavior
- Actual behavior
- Whether `irqbalance` is active
- Relevant BIOS notes (for example CPPC Preferred Cores mode)
- Any logs / terminal output that help reproduce the issue

Reports that cannot be reproduced or are missing critical context may be closed until more information is available.

---

## Feature requests

Feature requests are welcome **if they align with the project’s design goals**.

Good feature requests usually:
- solve a real AMD X3D workload problem
- improve deterministic behavior
- keep the tool explicit and inspectable
- avoid unnecessary complexity
- fit a native / shell-friendly workflow

Feature requests are less likely to be accepted if they:
- add major abstraction layers
- move x3dctl toward opaque automation
- turn the project into a generic system optimizer
- require heavyweight runtimes or frameworks for the primary user path
- significantly increase maintenance burden without clear benefit

---

## Out of scope (generally)

The following are generally out of scope unless they directly support the core design:

- GUI/frontends as the primary interface
- Background daemons for “automatic” tuning
- Hidden auto-detection behavior that removes explicit control
- Heavy runtime dependencies for the main workflow
- Non-native rewrites as the primary implementation path
- Platform-general “optimizer” features unrelated to AMD X3D workload policy
- Complexity that does not clearly improve deterministic behavior

This does not prevent future helper tools or optional frontends, but the core project remains CLI-first and native.

---

## Code contributions

When submitting code changes:

- Keep changes focused and minimal
- Preserve explicit behavior
- Prefer readable native code over clever abstraction
- Avoid unnecessary dependencies
- Match the project’s current structure and style
- Keep install and packaging behavior consistent
- Update docs when behavior or requirements change

The helper and native codebase currently target **`-std=gnu11`**. 
Contributions should remain compatible with that standard. 
A toolchain change must be explicitly discussed and accepted first.

Please do not introduce newer C language features, 
or compiler-specific assumptions that break the current build target without prior discussion.

If a change affects:
- install flow
- configuration
- packaging
- privileges / capabilities
- BIOS / platform prerequisites

…please update the relevant documentation as part of the change.

---

## Documentation contributions

Documentation improvements are always useful.

Especially helpful:
- missing prerequisites
- unclear command behavior
- distro-specific caveats
- scheduler-specific observations
- better examples
- BIOS / platform clarification
- FAQ-style explanations for advanced topics

If something confused you, that is often worth documenting.

---

## Testing and results

Real-world reports are valuable, especially for:

- Gaming + browser / Discord
- Gaming + OBS / recording
- Compiling while using the desktop
- Background workload isolation
- Mixed interactive workloads
- Different schedulers / custom kernels
- Distro-specific behavior

If you share results, useful context includes:

- CPU model
- Distro
- Kernel
- Scheduler
- Workload tested
- `x3dctl` profile / command used
- What improved (or didn’t)

Results vary by system, scheduler, kernel, distro, and workload.

---

## Maintainer policy

To keep the project focused:

- Usage/support topics may be redirected to Discussions.
- Out-of-scope feature requests may be closed.
- Incomplete bug reports may be marked as needing more information, 
or closed if they cannot be reproduced.
- Design decisions typically favor simplicity and explicitness over convenience.

This is not meant to discourage contributions - it is meant to keep x3dctl aligned with its design goals.

---

## Final note

x3dctl is primarily a **workload placement and policy tool**, not a BIOS power-state override or a generic “auto-tuner.”

If you’re unsure whether something fits, open a Discussion first.
