<img width="1408" height="538" alt="X3Dctl_logo_final_butcltleft" src="https://github.com/user-attachments/assets/4ae01d22-af40-4112-a47a-4791f61a98e1" />


x3dctl is a lightweight command-line utility for controlling AMD X3D CPU operating modes on Linux systems.

It provides a safe, deterministic interface for:

- Switching global X3D operating modes
- Applying CCD-aware CPU affinity policies to applications
- Steering GPU IRQ affinity based on selected mode

x3dctl does not run a daemon and performs no background polling.  
All behavior is explicit and command-driven.

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
 - IRQ steering can be disabled for testing:   
   ```bash
   x3dctl --no-irq gaming
   ```

## Application Launch With CCD-Aware Affinity
```bash
x3dctl gaming steam
```

## When launching an application:

1. The global X3D mode is set.
2. CPU topology is detected (cache CCD vs frequency CCD).
3. The launching process is pinned to the appropriate CCD.
4. the application is executed.
5. All child processes inherit the assigned CPU affinity.

## Altertively:
```bash
x3dctl run steam
```

- run applies the configured profile without changing global mode.
- If no configuration entry exists, the default profile is gaming.

## Verbose and Quiet Modes
```bash
x3dctl -q run <command>
x3dctl -v gaming <command>
```
    
## Documentation
```bash
man x3dctl
```
    
## Build and Install
```bash
git clone https://github.com/GrandBIRDLizard/X3Dctl.git
cd X3Dctl
make
sudo make install
sudo make uninstall
```
  
### Installation:

- Installs binaries to `/usr/local/bin`
- Installs a restricted sudoers rule for x3dctl-helper
- Installs a default `/etc/x3dctl.conf` if one does not already exist

### Uninstall 
- Program will clean itself from your system.
- Remove binaries at `usr/local/bin`.
- Remove sudoers rule for helper.
- Program does not remove config at `/etc/x3dctl.conf` per UNIX tradition

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
  ```

### Supported profiles:

 gaming -> Cache CCD, nice -5, SCHED_OTHER
 
 workstation -> Frequency CCD, nice 5, SCHED_BATCH
 
 frequency -> Frequency CCD, nice 0, SCHED_OTHER
 
 Profiles are enforced inside the privileged helper and cannot be defined dynamically or during runtime.

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

- x3dctl is currently in the 0,x release series.
- Behavior may change between releases
- CLI semantics may evolve
- Backwards compatibility is not garanteed
