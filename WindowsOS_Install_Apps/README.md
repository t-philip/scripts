# Windows OS — Fresh Setup Scripts

**Author:** t-philip

Scripts for setting up a new or freshly reset Windows 11 machine. Installs a curated set of applications via **winget** and guides you through anything that requires manual installation.

---

## Contents

| File | Description |
|---|---|
| `install-apps.ps1` | Installs applications via winget — runs silently, reports success/failure per app |

---

## Prerequisites

- **Windows 11** (or Windows 10 version 1809 or later with [App Installer](https://apps.microsoft.com/detail/9nblggh4nns1) installed)
- **winget** — built into Windows 11; verify by running `winget --version` in a terminal
- **Administrator access** — the script will auto-elevate if not already running as Administrator

---

## How to Run

### Option A — Right-click (simplest)
1. Download or copy `install-apps.ps1` to your machine
2. Right-click the file → **Run with PowerShell**
3. Accept the UAC prompt when asked for Administrator access

### Option B — Terminal
1. Open **Windows Terminal** or **PowerShell** as Administrator
2. Navigate to the folder containing the script
3. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install-apps.ps1
   ```

The script will install each app in sequence and print a summary when done.

---

## What Gets Installed

| Category | Application |
|---|---|
| Browser | Brave |
| Security | Bitdefender, NordVPN, Tailscale, Bitwarden, KeePassXC, Malwarebytes, NextDNS, FIDO2 Token Manager |
| Development | Git, Visual Studio Code, Windows Terminal, Python 3.13, GitHub Desktop |
| AI Tools | Claude Desktop |
| Productivity | Greenshot, Notepad++, 7-Zip, VLC, PowerToys |
| Remote Access | mRemoteNG |
| Entertainment | Spotify |

> Apps already installed on the machine are automatically skipped — safe to re-run.

---

## Manual Installs

The following apps cannot be installed silently via winget and require manual steps:

| App | Link | Reason |
|---|---|---|
| Microsoft 365 | https://www.microsoft.com/microsoft-365 | Click-to-Run installer does not support silent winget install |
| Perplexity | https://www.perplexity.ai/downloads | No winget package available |

---

## Customising the App List

> **Before running the script, review the app list and remove or comment out any apps you do not need.** The list reflects a specific setup — not every app will be relevant to every user. Installing unnecessary software wastes time and disk space.

Open `install-apps.ps1` in any text editor. The app list starts around line 13:

```powershell
$apps = @(
    @{ Id = "Brave.Brave"; Name = "Brave Browser" },
    ...
)
```

- **Add an app:** find its winget ID (see below), then add a new line in the same format
- **Remove an app:** delete or comment out (`#`) the relevant line
- **Uncomment optional apps:** MicroDicom is included but commented out — remove the `#` to enable it

### Finding a winget ID

Every app in the list is identified by its winget ID (e.g. `Git.Git`, `Brave.Brave`). To find the ID for any app:

**Option 1 — Search by name:**
```powershell
winget search <appname>
```
Example:
```
winget search firefox
```
This returns a table of matching packages. Use the value in the **Id** column.

**Option 2 — Browse the winget repository:**
Visit [winget.run](https://winget.run) or [winstall.app](https://winstall.app) to search and browse packages with a UI.

**Option 3 — View an app's full details before installing:**
```powershell
winget show <Id>
```
Example:
```
winget show Mozilla.Firefox
```
This confirms the publisher, version, and source before you add it to the script.
