# Router Restart Monitor

A lightweight Bash-based network monitor that detects router restarts by tracking ping failures to LAN and WAN targets. Runs as a systemd service on Ubuntu, logs events in CSV format, and includes a separate analysis script for a clean post-monitoring report.

Originally built to monitor a home router over a 10-day period and detect unexpected restarts.

---

## Features

- Pings a LAN target (your router) and two WAN targets (e.g. `8.8.8.8` and `1.1.1.1`) every 30 seconds
- WAN outage is only confirmed when **both** WAN targets fail simultaneously — avoids false positives
- Outage is only logged after **3 consecutive failures** (~90 seconds) — filters out single dropped packets
- Logs `OUTAGE_START` and `OUTAGE_END` events with duration and a `probable_restart` flag for LAN outages
- Writes a `DAILY_SUMMARY` line at midnight with total downtime for the day
- CSV log format — importable directly into Excel or Google Sheets
- Runs as a systemd service — survives SSH disconnection, starts automatically on boot
- Separate analyser script generates a clean human-readable report at any point

---

## Requirements

- Ubuntu 22.04 LTS or 24.04 LTS (bare metal, VM, or LXC container)
- systemd
- `ping` (pre-installed on Ubuntu: `/usr/bin/ping`)
- Root access **for initial setup only** — the service itself runs as a dedicated
  non-root user once installed (see Setup)

---

## Configuration

Before setting up, decide on your values for the following parameters. These are defined at the top of `ping_monitor.sh`:

| Parameter | Default | Description |
|---|---|---|
| `LAN_TARGET` | `192.168.1.1` | Your router's LAN IP address |
| `WAN_TARGET_1` | `8.8.8.8` | First WAN ping target (Google DNS) |
| `WAN_TARGET_2` | `1.1.1.1` | Second WAN ping target (Cloudflare DNS) |
| `PING_INTERVAL` | `30` | Seconds between each ping cycle |
| `FAILURE_THRESHOLD` | `3` | Consecutive failures before logging an outage |
| `LOG_DIR` | `/var/log/ping_monitor` | Directory where the log file is written |

> **Tip:** A `PING_INTERVAL` of 30 seconds and a `FAILURE_THRESHOLD` of 3 means an outage is confirmed in ~90 seconds — sufficient to catch most router reboots which typically take 60–120 seconds. If you want more or less sensitivity, adjust these two values accordingly.

---

## Setup

The monitor runs as a **dedicated non-root system user** — pinging a target needs
either root or the `CAP_NET_RAW` capability, and on any modern Ubuntu/Debian system
`ping` already carries that capability by default (verified: an ordinary unprivileged
user can run it with no extra setup). Root is only needed for the one-time install
steps below (creating the user, writing to `/etc/systemd/system/`), never for the
running service.

### Step 1 — Create the service user and directories

```bash
useradd --system --no-create-home --shell /usr/sbin/nologin pingmon
mkdir -p /opt/ping_monitor /var/log/ping_monitor
chown pingmon:pingmon /var/log/ping_monitor
```

`/opt/ping_monitor` holds the scripts (root-owned is fine — `pingmon` only needs to
*read and execute* them, not write to them). `/var/log/ping_monitor` holds the log and
must be owned by `pingmon`, since that's the only thing the running service actually
writes to.

### Step 2 — Copy the scripts

Place the following three files into `/opt/ping_monitor/`:
- `ping_monitor.sh`
- `ping_monitor.service`
- `analyze_ping_log.sh`

### Step 3 — Edit the configuration

Open `ping_monitor.sh` and set your router's LAN IP and any other parameters:

```bash
nano /opt/ping_monitor/ping_monitor.sh
```

Update the configuration block at the top:

```bash
LAN_TARGET="192.168.1.1"    # ← replace with your router's LAN IP
WAN_TARGET_1="8.8.8.8"
WAN_TARGET_2="1.1.1.1"
PING_INTERVAL=30
FAILURE_THRESHOLD=3
```

Save with `Ctrl+X` → `Y` → `Enter`.

### Step 4 — Make scripts executable

```bash
chmod +x /opt/ping_monitor/ping_monitor.sh
chmod +x /opt/ping_monitor/analyze_ping_log.sh
```

### Step 5 — Set the correct timezone

```bash
timedatectl set-timezone Europe/Amsterdam    # ← replace with your timezone
```

Verify:

```bash
timedatectl
```

> Find your timezone string with: `timedatectl list-timezones | grep <City>`

### Step 6 — Install the systemd service

```bash
cp /opt/ping_monitor/ping_monitor.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ping_monitor
systemctl start ping_monitor
```

### Step 7 — Verify the service is running

```bash
systemctl status ping_monitor
```

Expected output:
```
● ping_monitor.service - Router Restart Monitor
     Loaded: loaded (/etc/systemd/system/ping_monitor.service; enabled)
     Active: active (running) since ...
   Main PID: 944 (bash)
     CGroup: ...
             |-944 bash /opt/ping_monitor/ping_monitor.sh
             `-953 sleep 30
```

`ps -o user= -p 944` (or check `systemctl status`'s own output) should show `pingmon`,
not `root`.

### Step 8 — Verify the log file

```bash
cat /var/log/ping_monitor/ping_monitor.log
```

Expected output:
```
timestamp,event,target_type,target_ip,duration_min,probable_restart
2026-01-15 22:04:21,MONITOR_START,,,,ubuntu-server
```

---

## Usage

### Watch the log in real time

```bash
tail -f /var/log/ping_monitor/ping_monitor.log
```

Press `Ctrl+C` to exit.

### Check service status

```bash
systemctl status ping_monitor
```

Quick active/inactive check:

```bash
systemctl is-active ping_monitor
```

### Restart the service if needed

```bash
systemctl restart ping_monitor
```

---

## Log Format

The log file is CSV with the following columns:

| Column | Description |
|---|---|
| `timestamp` | Date and time of the event |
| `event` | `MONITOR_START`, `OUTAGE_START`, `OUTAGE_END`, `DAILY_SUMMARY` |
| `target_type` | `LAN` or `WAN` |
| `target_ip` | IP address(es) of the target |
| `duration_min` | Duration of the outage in minutes (`OUTAGE_END` and `DAILY_SUMMARY` only) |
| `probable_restart` | `yes` for LAN outages (indicates a probable router restart), `no` for WAN-only |

### Sample log output

```
timestamp,event,target_type,target_ip,duration_min,probable_restart
2026-01-15 22:04:21,MONITOR_START,,,,ubuntu-server
2026-01-15 22:32:00,OUTAGE_START,LAN,192.168.1.1,,
2026-01-15 22:34:00,OUTAGE_END,LAN,192.168.1.1,2,yes
2026-01-16 02:11:00,OUTAGE_START,WAN,8.8.8.8+1.1.1.1,,
2026-01-16 02:14:00,OUTAGE_END,WAN,8.8.8.8+1.1.1.1,3,no
2026-01-15 23:59:59,DAILY_SUMMARY,,,5,
```

---

## Analysis

Run the analyser at any point — mid-monitoring or at the end of your monitoring period:

```bash
bash /opt/ping_monitor/analyze_ping_log.sh
```

Sample report output:

```
============================================================
  Ping Monitor Report
  Log file : /var/log/ping_monitor/ping_monitor.log
  From     : 2026-01-15 22:04:21
  To       : 2026-05-15 23:59:59
============================================================

  Total outages detected    : 7
  Probable restarts (LAN)   : 5
  WAN-only outages          : 2
  Total downtime            : 24 min

  Longest outage            : 2026-05-08 03:14:00 | LAN | 8 min ← probable restart

  Outage detail:
  #1  2026-01-15 22:32:00  LAN  Duration: 2 min  ← probable restart
  #2  2026-01-16 02:11:00  WAN  Duration: 3 min
  ...

============================================================
```

You can also open `ping_monitor.log` directly in Excel or Google Sheets — it is a standard CSV file.

---

## Stopping the Monitor

When your monitoring period is complete:

```bash
systemctl stop ping_monitor
systemctl disable ping_monitor
```

Then run the final analysis:

```bash
bash /opt/ping_monitor/analyze_ping_log.sh
```

---

## Troubleshooting

**Service fails to start:**
```bash
journalctl -u ping_monitor -n 50
```

**SSH password authentication not working (Ubuntu 24.04):**

> **Security note:** the settings below widen SSH access — root login and password
> auth are both disabled by default on a fresh Ubuntu install for good reason. Only
> enable them if you understand the trade-off, and prefer reverting to key-based,
> non-root SSH once the box is set up rather than leaving this in place permanently.

Edit the SSH config:
```bash
nano /etc/ssh/sshd_config
```

Set the following:
```
PermitRootLogin yes
PasswordAuthentication yes
```

Restart SSH:
```bash
systemctl restart ssh
```

Then set a root password if not already done:
```bash
passwd root
```

**`pingmon` gets "Permission denied" running ping:**
Modern Ubuntu/Debian ships `ping` with `CAP_NET_RAW` already set, so this normally
isn't needed — check first with `sudo -u pingmon ping -c 1 8.8.8.8`. If it does fail:
```bash
setcap cap_net_raw+ep /usr/bin/ping
```
This grants the capability to the `ping` binary itself, so it isn't scoped to
`pingmon` alone — any user on the box gains it too, which is the standard trade-off
for this fix and is normally accepted, since `ping` is meant to be runnable by anyone.

**LAN ping always failing on LXC container:**
Check that the container's network bridge in Proxmox is on the same VLAN/subnet as your router. In the Proxmox web UI: CT → Network tab → confirm the bridge assignment.

**Service running but log not growing:**
```bash
ping -c 3 <your-router-ip>
ping -c 3 8.8.8.8
```
If either fails, there is a network connectivity issue between the Ubuntu host and the target — not a script issue.

---

## Quick Reference

| Task | Command |
|---|---|
| Check service status | `systemctl status ping_monitor` |
| Quick active check | `systemctl is-active ping_monitor` |
| Watch live log | `tail -f /var/log/ping_monitor/ping_monitor.log` |
| Run analysis | `bash /opt/ping_monitor/analyze_ping_log.sh` |
| Restart service | `systemctl restart ping_monitor` |
| Stop monitor | `systemctl stop ping_monitor` |
| View service errors | `journalctl -u ping_monitor -n 50` |

---

## Author

**t-philip** — [github.com/t-philip](https://github.com/t-philip)

---

## Licence

GPL-3.0, same as the rest of this repository — see [LICENSE](../LICENSE).
