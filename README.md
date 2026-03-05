<img width="1408" height="538" alt="X3Dctl_logo_final_butcltleft" src="https://github.com/user-attachments/assets/4ae01d22-af40-4112-a47a-4791f61a98e1" />


x3dctl is a lightweight command-line utility for controlling AMD X3D CPU operating modes on Linux systems.

It provides a safe, deterministic interface for:

- Switching global X3D operating modes
- Applying CCD-aware CPU affinity policies to applications
- Steering GPU IRQ affinity based on selected mode

x3dctl does not run a daemon and performs no background polling.  
All behavior is explicit and command-driven, with no background overhead.

---

## Features

## Mode Control (System-Level)

## Toggle AMD X3D CPU operating modes
```bash
x3dctl toggle
``` 

## Explicit cache and frequency mode switching
```bash
x3dctl gaming
x3dctl performance
```

## Deterministic GPU IRQ Steering

 - In gaming mode, GPU IRQs are steered to the frequency CCD.
 - In performance mode, GPU IRQs are restored to the full CPU mask.
 - Unrestricted profile in x3dctl.conf inherits current global steering policy.
 - IRQ steering can be disabled for testing:   
   ```bash
   x3dctl --no-irq gaming
   ```

## Application Launch With CCD-Aware Affinity:
```bash
x3dctl gaming steam
```

## When launching an application:

1. The global X3D mode is set.
2. CPU topology is detected (cache CCD vs frequency CCD).
3. The launching process is pinned to the appropriate CCD.
4. The application is executed.
5. All child processes inherit the assigned CPU affinity.

## Alternatively:
```bash
x3dctl run steam
```

- <run> applies the configured profile without changing global mode.
- If no configuration entry exists, the default profile is <gaming>.

## Verbose and Quiet Modes
```bash
x3dctl -q run <command>
x3dctl -v gaming <command>
```
    
## Documentation
```bash
man x3dctl
```

---

## Local Build and Install
```bash
make
sudo make install
sudo make uninstall
```
  
### Install:

- Installs binaries to `/usr/local/bin`.
- Installs a restricted sudoers rule for x3dctl-helper `etc/sudoers.d`.
- Installs a default `/etc/x3dctl.conf` if one does not already exist.
- Installs man page to `/usr/local/share/man/man1`.

### Uninstall 
- Program will clean itself from your system.
- Remove binaries at `usr/local/bin`.
- Remove sudoers rule for helper.
- Program does not remove config at `/etc/x3dctl.conf` per UNIX tradition

## AUR(helper):
```bash
helper -S x3dctl
```
### This will:

Build the package
Install binaries to `/usr/bin`.
Install the man page.
Install the sudoers policy for x3dctl-helper.
Install `/etc/x3dctl.conf` (if not already present).

## AUR(manual):
```bash
git clone https://aur.archlinux.org/x3dctl.git
cd x3dctl
makepkg -si
```

## Uninstalling(AUR):
```bash
sudo pacman -R x3dctl
```

### This removes:

`/usr/bin/x3dctl`
`/usr/bin/x3dctl-helper`
Man page
Sudoers policy file
The configuration file will be preserved.

---


| Command     | Description                                               |
| ----------- | --------------------------------------------------------- |
| gaming      | Switch to cache-priority mode and steer GPU IRQs          |
| performance | Switch to frequency-priority mode and restore IRQ routing |
| toggle      | Switch between current modes                              |
| status      | Display current X3D operating mode                        |
| run         | Launch application using policy from `/etc/x3dctl.conf`   |

---


## Profile Model

- Applications are mapped in:
  `/etc/x3dctl.conf`

- Format:
  ```ini
  application=profile
  ``
---

  <status> displays:

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


### Supported profiles:


| Profile      | CPU Affinity | Nice | Scheduler   | IO   |
| ------------ | ------------ | ---- | ----------- | ---- |
| gaming       | cache CCD    | -5   | SCHED_OTHER | BE/0 |
| unrestricted | none         | -1   | SCHED_OTHER | BE/0 |
| frequency    | freq CCD     | 0    | SCHED_OTHER | BE/0 |
| workstation  | freq CCD     | 5    | SCHED_BATCH | BE/4 |

gaming → aggressive foreground
unrestricted → mild bias
frequency → neutral
workstation → background throughput

The unrestricted profile does not modify CPU affinity, 
allowing execution across all cores, while applying a slight priority bias.
(some games may run better on this mode depending on workload and system usage)

Profiles are enforced inside the privileged helper, 
and cannot be defined dynamically or during runtime.
The application key must match the executable basename. 
Directory paths are ignored.

---


## Design Goals

- Deterministic behavior
- No background daemon
- No polling or PID chasing
- Mode defines system posture
- Clear separation between system policy and process policy
- Minimal privileged attack surface
- Transparent configuration

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
