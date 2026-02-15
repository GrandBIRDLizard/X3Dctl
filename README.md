# x3dctl

x3dctl is a lightweight command-line utility for controlling AMD X3D CPU operating modes on Linux systems.

It provides a safe, simple interface for switching between cache-priority and frequency-priority CPU behavior using the Linux kernel sysfs interface.
It also applies CCD-aware CPU affinity policies to launched applications using an inheritance model.

---

## Features
### Full usage description provided with man page documentation.

- Toggle AMD X3D CPU operating modes
  ```bash
  x3dctl toggle
  ```
- Explicit cache and frequency mode switching
  ```bash
  x3dctl gaming
  x3dctl performance
  ```
- Application passthrough launching with deterministic affinity inheritance
  ```bash
  x3dctl gaming steam
  #all child processes inherit CPU affinity assigned to application 
  ```
  ### When using:
  ```bash
  x3dctl run steam
  ```
  ### x3dctl will:
  1. Switch the global X3D mode.
  2. Detect CPU topology (cache CCD vs frequency CCD).
  3. Pin the current shell to the selected CCD.
  4. Execute the application.
  5. All child processes inherit CPU affinity.
  - If no configuration entry exists, the default mode is cache.

---
  
- Verbose and Quiet modes for scripting, automation, logging
  ```bash
  x3dctl -q run <command> 
  x3dctl -v gaming <command>
  ```
- Man page documentation
  ```bash
  man x3dctl
  ``` 
- Clean build, install and uninstall workflow
  ```bash
  make
  sudo make install
  sudo make uninstall
  ```
---

## Supported Commands

| Command     | Description                                                 |
| ----------- | ----------------------------------------------------------- |
| gaming      | Switch to cache-priority mode (latency-sensitive workloads) |
| performance | Switch to frequency-priority mode (throughput workloads)    |
| toggle      | Switch between current modes                                |
| status      | Display current CPU mode                                    |
| run         | Launch application using policy from `/etc/x3dctl.conf`     |

---

## Design Goals

- Deterministic behavior
- No background daemon
- No polling or PID chasing
- Minimal privileged attack surface
- Clean packaging compatibility
- Clear separation between source tree and installed system files

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
git clone https://github.com/<GrandBirdLizard>/x3dctl.git
cd x3dctl
make install
sudo make install
```
### The install step:
- Installs binaries to `/usr/local/bin`
- Installs a restricted sudoers rule
- Installs a default `/etc/x3dctl.conf` if one does not already exist
