# Scripts & Guides

A small collection of automation scripts and setup guides I built for my own use
and cleaned up enough to share. Everything here is self-contained — pick the one
folder you need and ignore the rest.

Licensed under [GPL-3.0](LICENSE). Please credit **t-philip** if you use or share these.

---

## Contents

| Folder | What it does | Platform |
|---|---|---|
| [`Ping_Monitor_Router/`](Ping_Monitor_Router/) | Monitors your router's LAN IP and two WAN targets, logging outages to CSV with duration and a probable-restart flag. Runs as a systemd service. | Linux |
| [`WindowsOS_Install_Apps/`](WindowsOS_Install_Apps/) | Automated fresh-install app setup via `winget` — one PowerShell script to rebuild a Windows machine's software stack. | Windows |
| [`network/eve-ng/`](network/eve-ng/) | Step-by-step guide to running EVE-NG network emulation on VMware Workstation. | VMware |
| [`python/`](python/) | `formatted_print.py` — an auto-aligning formatted print utility for tabular console output. | Python |

---

## Ping Monitor

Detects and logs internet and LAN outages so you can tell the difference between
"my router rebooted" and "my ISP went down" after the fact.

- Pings your router's LAN IP and two public DNS resolvers independently
- Distinguishes **LAN outages** (router down/restarting) from **WAN-only outages** (ISP)
- Flags `probable_restart` when a LAN outage recovers quickly
- Writes a daily summary line
- CSV output, so it drops straight into a spreadsheet or a log analyser

Configure `LAN_TARGET` in `ping_monitor.sh` to your own router IP before running —
the committed value is a placeholder default.

---

## Windows Install Apps

Rebuilds a Windows machine's application set in one pass using `winget`, so a fresh
install doesn't mean an afternoon of clicking through installers. Edit the app list
in `install-apps.ps1` to match what you actually want.

---

## EVE-NG on VMware Workstation

A walkthrough for getting EVE-NG running as a VM under VMware Workstation, including
the disk and networking settings that are easy to get wrong the first time.

---

Built and maintained by [t-philip](https://github.com/t-philip).
