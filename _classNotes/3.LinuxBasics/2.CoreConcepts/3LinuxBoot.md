# Linux Boot

- BIOS POST > Boot Loader (GRUB2) > Kernel Initialization > Init Process (systemd)

## BIOS POST

- Power On Self Test: Checks the hardware components
- BIOS: Basic Input Output System

## Boot Loader

- GRUB2: Grand Unified Boot Loader v2
- It is the first program that runs after the BIOS POST
- It loads the kernel into memory
- It reads the configuration file `/boot/grub2/grub.cfg`

## Kernel Initialization

- Kernel is the core of the operating system
- It is decompressed and loaded into memory
- Set the user space and kernel space

## Init Process

- `systemd` is the init process in Linux
  - `ls -l /sbin/init` to check the init process
- It is responsible for initializing the system
- `sysfile` was the init process in the older versions of Linux

## Systemd Targets

- Nowadays: `systemd` is used to manage the system services. In the older versions, `runlevel` was used.
- `runlevel` shows the current target
  - 5: Graphical - Boots into a Graphical User Interface (GUI)
    - display-manager.service enabled
    - graphical.target enabled
  - 3: Multi-user - Boots into a Command Line Interface (CLI)
    - multi-user.target enabled
- `systemctl get-default` to check the default target
- `ls -ltr /etc/systemd/system/default.target` to check the default target
- `systemctl set-default multi-user.target` to set the default target to multi-user
- Complete list of targets:
  - runlevel 0 -> poweroff.target
  - runlevel 1 -> rescue.target
  - runlevel 2 -> multi-user.target
  - runlevel 3 -> multi-user.target
  - runlevel 4 -> multi-user.target
  - runlevel 5 -> graphical.target
  - runlevel 6 -> reboot.target
