---
name: Feature request
about: Suggest a concrete feature aligned with x3dctl's design goals
title: "[FEATURE] "
labels: enhancement
assignees: ''
---

## Summary
Describe the feature briefly.




---
## Problem / Use Case
What real AMD X3D workload problem does this solve?
Examples:
- mixed gaming + recording
- compile + desktop responsiveness
- scheduler-specific behavior
- IRQ / placement consistency
- per-process control








---
## Proposed Behavior
Describe the behavior you want.
Be explicit:
- what command / flag / mode should exist?
- what should it do?
- what should it not do?




---
## Why This Fits x3dctl
Explain how this aligns with x3dctl’s design goals:
- explicit behavior
- deterministic workload policy
- native / shell-friendly workflow
- minimal complexity
- AMD X3D relevance





---
## Scope / Tradeoffs
Please address any known tradeoffs:
- added complexity
- maintenance burden
- scheduler-specific assumptions
- distro-specific behavior
- BIOS / firmware dependencies
- privilege implications




---
## Alternatives Considered
Have you considered:
- existing x3dctl commands or profiles?
- shell wrappers / scripting?
- manual affinity or policy tools?
- using Discussions first?




---
## Additional Context
Anything else that helps explain the request.





---
### Notes

x3dctl is intentionally scoped.

Requests are less likely to be accepted if they:
- move the project toward hidden automation
- add heavy runtime dependencies
- make the project less explicit or less inspectable
- turn x3dctl into a generic “optimizer”
- significantly increase complexity without clear deterministic benefit

If you are unsure whether an idea fits, please open a Discussion first.
