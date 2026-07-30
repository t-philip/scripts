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
| [`python/`](python/) | `pdf_search.py` — search a PDF for lines matching text or a regex, with page numbers. `formatted_print.py` — an auto-aligning formatted print utility for tabular console output. | Python |

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

## PDF Search

`python/pdf_search.py` searches a PDF for lines matching some text and prints each
one with its page number. Handy for pulling specific entries out of a long statement,
report or export without scrolling through it.

Needs [pdfplumber](https://github.com/jsvine/pdfplumber):

```bash
python -m pip install pdfplumber
```

```bash
# every line containing "Invoice" (case-sensitive substring — the default)
python pdf_search.py statement.pdf "Invoice"

# case-insensitive
python pdf_search.py statement.pdf "invoice" -i

# only lines that START with the text
python pdf_search.py report.pdf "Total" --starts-with

# regular expression — any euro amount
python pdf_search.py statement.pdf "EUR ?[0-9.,]+" -r

# write the results to a file instead of printing them
python pdf_search.py report.pdf "Total" -o totals.txt
```

| Option | Effect |
|---|---|
| `-i`, `--ignore-case` | Match regardless of case |
| `-r`, `--regex` | Treat the search text as a regular expression |
| `--starts-with` | Only match lines beginning with the text, rather than anywhere in the line |
| `-o FILE` | Write results to `FILE` instead of standard output |
| `-q`, `--quiet` | Print only matching lines, with no header or count |

It exits `1` when nothing matched, so it composes with shell scripts:

```bash
python pdf_search.py report.pdf "OVERDUE" -q && echo "found something"
```

Pages that contain no extractable text — scans and image-only pages — are skipped
with a warning on stderr rather than failing the run. A PDF that is entirely scanned
images will return no matches; that needs OCR, which this script deliberately does
not attempt.

---

## Reporting issues

Found a bug, a mistake in the documentation, or want to suggest something?
**[Open an issue](https://github.com/t-philip/scripts/issues/new/choose)** — pick a
template and it will ask for the details that actually help.

This repository holds several unrelated tools, so please say which script or
guide you mean — the template asks. These were written for one setup and
generalised afterwards, so environment details are usually the key to
reproducing anything.

---

Built and maintained by [t-philip](https://github.com/t-philip).
