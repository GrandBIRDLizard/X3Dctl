<img width="1408" height="538" alt="X3Dctl_logo_final_butcltleft" src="https://github.com/user-attachments/assets/4ae01d22-af40-4112-a47a-4791f61a98e1" />

[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/GrandBIRDLizard/X3Dctl?sort=semver)](https://github.com/GrandBIRDLizard/X3Dctl/tags)

[![RelatedRepos](https://img.shields.io/badge/related-repos-yellow)](https://relatedrepos.com/gh/GrandBIRDLizard/X3Dctl)

x3dctl is a lightweight command-line utility for controlling AMD X3D CPU operating modes on Linux systems.

It provides a safe, deterministic interface for:

- Switching global X3D operating modes.
- Applying CCD-aware Process policies.
- Steering GPU IRQ affinity based on system posture.

x3dctl does **not** run a daemon and performs **no background polling**.  
All behavior is explicit, command-driven, and runtime-only. with no background overhead.

---
## What it is

x3dctl separates **system posture** from **process policy**.

- **Mode commands** control the global X3D operating mode and GPU IRQ steering
- **Profiles** define how individual applications should be scheduled and pinned

This allows users to choose between:

- strict cache-CCD pinning for latency-sensitive workloads
- frequency-CCD pinning for throughput-oriented tasks
- a light-touch profile that leaves all cores available while preserving system-level IRQ steering

## Documentation
### How it works
```bash
man x3dctl
```
---
### Global mode control


| Command     | Description                                               |
| ----------- | --------------------------------------------------------- |
| gaming      | Switch to cache-priority mode and steer GPU IRQs          |
| performance | Switch to frequency-priority mode and restore IRQ routing |
| toggle      | Switch between current modes                              |
| status      | Display current X3D operating mode                        |
| run         | Launch application using policy from `/etc/x3dctl.conf`   |

---

x3dctl supports two system postures:

- **gaming** → switches X3D to cache-priority mode
- **performance** → switches X3D to frequency-priority mode

### Deterministic GPU IRQ steering

- In **gaming** mode, GPU IRQs are steered to the frequency CCD
- In **performance** mode, GPU IRQs are restored to the full CPU mask
- IRQ changes are runtime-only and do not persist across reboot

### Process policy application

Profiles are defined in:
`/etc/x3dctl.conf`
Applications are mapped in:
  `/etc/x3dctl.conf`

---

 ```bash
x3dctl status 
```
-displays:

. Current X3D mode

. GPU IRQ steering state

. irqbalance service status


### Note on irqbalance:

The irqbalance service distributes hardware interrupts across available CPUs.
It dynamically migrates IRQs to improve load balancing on multi-core systems.

On heterogeneous CPU designs (such as AMD X3D processors), automatic IRQ
migration may introduce cache-to-cache latency depending on workload and
configuration.

x3dctl applies deterministic GPU IRQ affinity when switching modes. If
irqbalance is active, it may override these affinity settings.

For fully deterministic behavior, it is recommended to disable or appropriately
configure irqbalance while using x3dctl.

IRQ affinity changes made by x3dctl are runtime-only and do not persist across
system reboots.

The irqbalance service may override manually applied IRQ affinity.
- For the most deterministic behavior:
disable irqbalance.
or.
configure it appropriately for your system.

x3dctl does not depend on irqbalance, it only reports whether the service is active.


### Supported profiles:

| Profile      | CPU Affinity | Nice | Scheduler   | IO   |
| ------------ | ------------ | ---- | ----------- | ---- |
| gaming       | cache CCD    | -5   | SCHED_OTHER | BE/0 |
| unrestricted | none         | -1   | SCHED_OTHER | BE/0 |
| frequency    | freq CCD     | 0    | SCHED_OTHER | BE/0 |
| workstation  | freq CCD     | 5    | SCHED_BATCH | BE/4 |

gaming → aggressive foreground/cache-focused.
unrestricted → full core mild bias, no CPU pinning.
frequency → neutral frequency-CCD policy.
workstation → background throughput/sustained workloads.

unrestricted does not disable policy application, 
it skips CPU affinity while still applying scheduler, niceness, and I/O priority.

allowing execution across all cores, while applying a slight priority bias.
(some games may run better on this mode depending on workload and system usage)

Profiles are enforced inside the privileged helper, 
and cannot be defined dynamically or during runtime.
The application key must match the executable basename.

---

## Instalation:

### Local Build and Install/uninstall
```bash 
make
sudo make install
sudo make uninstall
```

- Local install places files under:
`/usr/local/bin`
`/usr/local/share/man/man1` 

### Install from the AUR
.Using an AUR helper
```bash
yay -S x3dctl
```
-Manual AUR install:
```bash
git clone https://aur.archlinux.org/x3dctl.git
cd x3dctl
makepkg -si
```
-Remove AUR package
```bash
sudo pacman -R x3dctl
```
The package removes installed binaries, man page, and sudoers policy.
The configuration file is preserved.

---

## Design Goals

- Deterministic behavior
- No daemon
- No polling or PID chasing
- Clear separation between system posture and process policy
- Minimal privileged attack surface
- Transparent configuration
- Low runtime overhead 

---

## Requirements

- Linux kernel with AMD X3D sysfs interface support
- sudo configured for helper execution
- GCC for building helper binary
- Make

---  

## Stability Notice

- x3dctl is currently in the 1.x release series.
- Behavior should not change between releases.
- CLI semantics will not evolve.
- Backwards compatibility is guaranteed.
- Consult Mid-long term goals for the project in the roadmap for more details.


