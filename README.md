# x3dctl

x3dctl is a lightweight command-line utility for controlling AMD X3D CPU operating modes on Linux systems.

It provides a safe, simple interface for switching between cache-priority and frequency-priority CPU behavior using the Linux kernel sysfs interface.

---

## Features

- Toggle AMD X3D CPU operating modes
  ```bash
  x3dctl toggle
  ```
- Safe privilege separation using a restricted helper binary
  Via x3dctl-helper.c
- Application passthrough launching
  ```bash
  x3dctl gaming steam
  ```
- Quiet mode for scripting and automation
  ```bash
  x3dctl -q <command>
  ```
- Man page documentation
  ```bash
  man x3dctl
  ``` 
- Clean install and uninstall support
  ```bash
  make install
  make uninstall
  ```
---

## Supported Modes

| Mode | Description |
|--------|------------|
| gaming | Prioritizes 3D V-Cache performance (latency-sensitive workloads) |
| performance | Prioritizes CPU frequency (throughput workloads) |
| toggle | Switches between current modes |
| status | Displays current CPU mode |

---

## Requirements

- Linux kernel with AMD X3D sysfs interface support
- sudo configured for helper execution
- GCC for building helper binary
- Make

---

## Installation

Clone repository:

```bash
git clone https://github.com/<username>/x3dctl.git
cd x3dctl
make install
```
