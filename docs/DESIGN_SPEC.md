# Scripts & Guides
## Design Specification v1.0 — As-Built

**Author:** T. Philip — <https://github.com/t-philip>
**Date:** 5 August 2026
**Status:** Reconciled against the shipped content. Describes each tool as it actually
works, including three real defects found while writing this document and fixed
before this spec's first release.
**Licence:** GPL-3.0, same as the code (see §7 for the one folder this took fixing to
make true).

---

## 0. How to read this document

[README.md](../README.md) is the index — what each folder does and how to run it. This
explains *why* each tool works the way it does, and states plainly what has and hasn't
been verified for each one.

### 0.1 Why this repo holds four unrelated things

Unlike this profile's other public repos, `scripts` is **not one project** — it's four
independent tools that happen to share a licence and a support process. That shape
itself needs explaining once: each was extracted from a single earlier `public` monorepo
during the 2026-07-30 restructuring (tracked as PR-040 in the author's private project
register) and kept together here because none was substantial enough to justify its own
repo, not because they relate to each other. Consequently this document has **one section
per tool** rather than one architecture describing the whole repo — there isn't a whole
to describe.

---

## 1. Ping Monitor (`Ping_Monitor_Router/`)

### 1.1 Purpose and scope

A Bash daemon that distinguishes **LAN outages** (your own router restarting) from
**WAN-only outages** (your ISP), and logs both to CSV — built to answer "did my router
reboot, or did my internet provider have an outage" after the fact, over an unattended
multi-day monitoring period.

**Out of scope:** it is not a general uptime monitor, has no alerting (email, push,
Telegram), and does not distinguish *which* of the two WAN targets failed — only whether
both did simultaneously.

### 1.2 Design decisions

- **Two independent WAN targets, outage confirmed only when both fail.** A single public
  resolver (e.g. `8.8.8.8`) can itself have an outage indistinguishable from your own
  ISP's — requiring both `WAN_TARGET_1` and `WAN_TARGET_2` down simultaneously rules out
  a single resolver's own bad day.
- **A 3-consecutive-failure threshold (~90 seconds at the default 30s interval), not a
  single missed ping.** A dropped ICMP packet is common and meaningless; the threshold
  exists specifically so one packet loss doesn't log a false outage. The README states
  this trades off against detection speed — a real router reboot (60–120s typical) is
  still caught.
- **CSV output, not a database or JSON log.** The stated purpose is opening it directly
  in Excel or Google Sheets for a 10-day monitoring exercise — there is no query
  interface to build, so a database would be unjustified complexity for the actual use
  case.
- **A separate analyser script (`analyze_ping_log.sh`) rather than analysis built into
  the monitor.** The monitor's only job is to run unattended and log; report generation
  is a separate, safe-to-re-run-anytime concern, and keeping it out of the always-running
  process means a bug in reporting can never affect the log it's reading.

### 1.3 Security model

Runs as `User=root` in the systemd unit. Ping requires either root or the
`CAP_NET_RAW` capability; the README's own troubleshooting section documents the
capability-based alternative (`setcap cap_net_raw+ep /usr/bin/ping`) for the "permission
denied" case, which means the tool **could** run under a dedicated non-root user with
that capability granted, rather than needing full root for a script whose only actions
are pinging and appending to a log file.

**Not changed in this pass** — see §7.3 for why, and §8 for what a fix would look like.

### 1.4 Verification status — stated honestly

No test harness exists for a systemd daemon like this; verification is necessarily "run
it and check the log," not a passing test suite. What is actually known:

- **The core outage-detection logic** (dual-WAN-target confirmation, the 3-failure
  threshold, `OUTAGE_START`/`OUTAGE_END`/`DAILY_SUMMARY` events, `probable_restart`
  flagging) has run against the author's own home network and produced the CSV format
  shown in the README's sample output.
- **The fix in §7.1 (the broken `.service` file) has not been re-verified against a live
  `systemctl` install** from the machine that wrote this document — there is no Ubuntu
  host here to install it on. It is correct by inspection: the file now contains exactly
  the `[Unit]`/`[Service]`/`[Install]` sections a `cp` into `/etc/systemd/system/` expects,
  with no shell syntax remaining. Recommended before trusting it: `systemd-analyze verify
  ping_monitor.service` on a real Ubuntu host, or simply installing it and confirming
  `systemctl status` shows it loaded and active.
- **`analyze_ping_log.sh`'s CSV parsing** was traced by hand against the exact sample log
  format in the README and handles the documented event types (`MONITOR_START`,
  `OUTAGE_START`, `OUTAGE_END`, `DAILY_SUMMARY`) correctly, but was not run against a
  generated log file during this session.

---

## 2. Windows Install Apps (`WindowsOS_Install_Apps/`)

### 2.1 Purpose and scope

A PowerShell script that reinstalls a curated application set via `winget` after a fresh
Windows install or factory reset — the "afternoon of clicking through installers"
replaced by one script run.

### 2.2 Design decisions

- **Self-elevating.** The script checks `WindowsPrincipal`/`WindowsBuiltInRole` at the
  top and relaunches itself with `-Verb RunAs` if not already Administrator, rather than
  failing with a permissions error partway through the app list.
- **Per-app failure isolation.** Each `winget install` runs independently inside the
  loop; one failed package is reported and added to a `$failed` summary list at the end,
  but does not stop the remaining installs. A single unavailable or renamed package ID
  cannot silently prevent the other twenty from installing.
- **The specific exit code `-1978335189` is treated as "already installed," not a
  failure.** This is `winget`'s own code for "no applicable update found" — re-running
  the script on a machine that already has some apps installed is explicitly supported
  (the README states this directly: "safe to re-run").
- **Apps winget cannot install silently are listed, not attempted.** Microsoft 365's
  Click-to-Run installer and Perplexity (no winget package at all) are called out by
  name in both the script's own `$manualInstalls` array and the README, with direct
  download links, rather than the script silently failing on them or omitting them from
  the picture entirely.

### 2.3 Verification status

The winget IDs and IsInRole self-elevation pattern were reasoned from Microsoft's own
documented behaviour and are standard, widely-used patterns — but **this script was not
run during this session**; there is no Windows machine mid-fresh-install available to
test against. The README's own "Customising the App List" section already tells a new
user to review and prune the list before running, which is the practical mitigation for
an ID that has since changed or a package that's since been renamed.

---

## 3. EVE-NG on VMware (`network/eve-ng/installation`)

### 3.1 Purpose and scope

A step-by-step setup guide, not code — getting EVE-NG Community Edition (a free network
emulation platform) running as a VM under VMware Workstation Player on Windows,
including the two VM settings (nested-virtualization flags, network adapter mode) that
the guide's own "Error messages" section shows are the most common way to get this
wrong on the first try.

### 3.2 What changed in this pass

The original text had several typos and one factual slip that would have confused a
reader following it literally: "OVG" where every other reference says "OVF" (step 7,
referring to the same file extension named correctly one line earlier), "Cilck",
"Teminal", "newwly", and a stray tab character inside a settings-menu path. None change
the guide's meaning, but a setup guide is exactly the kind of document where a typo in a
filename extension ("OVG") could send a reader looking for a file that doesn't exist.
Corrected; no step's actual instructions changed.

### 3.3 Verification status

This guide reflects the author's own prior walkthrough (the two documented error
messages and their fixes are specific enough — nested-virtualization flags, NAT vs.
Bridge — to be lived experience, not generic advice). It was not re-walked during this
session; there is no VMware Workstation Player instance here to install EVE-NG into.

---

## 4. Python utilities (`python/`)

### 4.1 `pdf_search.py`

Searches a PDF for lines matching literal text, a case-insensitive match, a
starts-with match, or a full regular expression, printing each hit with its page
number.

**Design decisions:**

- **Soft hyphens are stripped before matching.** PDF text extraction can leave an
  invisible soft-hyphen character (`­`) inside words wrapped across a line break;
  left in, it silently breaks substring and regex matches against text that displays
  correctly to a human reader. Stripped once, centrally, rather than requiring every
  search pattern to account for it.
- **A page that fails to extract text is skipped with a warning, not a fatal error.**
  Scanned or image-only pages have no extractable text at all; a multi-hundred-page
  statement with one bad page should not lose every other page's results.
- **Exit code reflects match count (`0` = found, `1` = none), by design** — stated
  directly in the script's own `--help` epilog — so it composes into shell scripts
  (`pdf_search.py x.pdf "OVERDUE" -q && echo "found something"`).

**Verification:** by code review only. No PDF fixture was available in this session to
run it against; the soft-hyphen handling and the page-skip behaviour are both correct
by inspection but not exercised end-to-end here.

### 4.2 `formatted_print.py`

Aligns a list of `(description, value)` pairs into an evenly-padded console table —
pads every description to the length of the longest one before printing.

**Age and provenance, stated honestly:** this is the oldest file in the repository (its
own header dates it to 2020), predates the rest of this collection by years, and was
carried into the public repo more or less as originally written. Its docstring-as-usage
example still reflects that vintage.

**One real defect found and fixed:** the file's own embedded usage instructions told a
reader to `from fomatted_print import pretty_print` — missing the "r" in
`formatted_print`, which is the module's actual filename. Copy-pasted literally, that
import fails with `ModuleNotFoundError`. Fixed to match the real filename (§7.2).

**Verification:** the corrected import statement was checked character-for-character
against the actual filename (`formatted_print.py`); the file was also compiled with
`py -m py_compile` to confirm the fix introduced no syntax error. The function's actual
padding logic (unchanged by this fix) was not re-tested here, but takes no external
input beyond what the caller constructs in Python — there is no untrusted-input surface
to verify against.

---

## 5. Licensing note — the whole point of §7 below

Every tool in this repository is published under GPL-3.0 (see [LICENSE](../LICENSE)),
confirmed at the repository root and in this repo's main README. One folder's own
sub-README disagreed with that — see §7.2.

---

## 6. README claims checked against the code

| README claim | Verdict |
|---|---|
| Ping Monitor: "safe to re-run" (Windows script), apps already installed are skipped | Accurate — `-1978335189` handled explicitly as the already-installed case |
| Ping Monitor: WAN outage requires both targets down | Accurate — `if $wan1_ok \|\| $wan2_ok` only closes the outage when at least one recovers; both must fail to open one |
| Ping Monitor: outage confirmed after 3 consecutive failures | Accurate — `[[ $lan_fail_count -eq $FAILURE_THRESHOLD ]]` |
| pdf_search.py: "exits 1 when nothing matched" | Accurate — `return 0 if results else 1` |
| pdf_search.py: scanned/image-only pages skipped with a warning | Accurate — caught in `search_pdf()`, printed to stderr, loop continues |
| "Everything here is self-contained — pick the one folder you need" | Accurate — no folder imports or calls into another |

No other divergence found.

---

## 7. Gaps found while writing this document — and fixed

Three real defects, found across three of the four tools while writing this
specification. All three are fixed, in both this public repository and the private
source repository they were carried in from.

### 7.1 Ping Monitor's systemd unit file was not a systemd unit file — **fixed**

`ping_monitor.service` contained a shell heredoc command
(`cat > ~/ping_monitor/ping_monitor.service << 'EOF' ... EOF`) rather than plain
`[Unit]`/`[Service]`/`[Install]` content. The README's own Step 6 instructs
`cp ~/ping_monitor/ping_monitor.service /etc/systemd/system/` — copying the file as
committed installs the *shell command that would have generated the real unit file*,
not the unit file itself, which `systemd` cannot parse. Anyone following the README
literally would have hit a broken service install at exactly the step meant to make the
monitor unattended.

**Fix.** Stripped to plain unit-file content — the same content the heredoc would have
written, minus the wrapper. `cp` now installs a working unit.

*Verified:* by inspection against standard systemd unit syntax (three sections, no shell
syntax remaining). Not re-verified against a live `systemctl` install — no Ubuntu host
available in this session; see §1.4.

### 7.2 `formatted_print.py`'s own usage example had a typo in its own filename — **fixed**

`from fomatted_print import pretty_print` — missing "r". A reader who copy-pasted the
file's own documented usage instructions would get `ModuleNotFoundError` importing a
module that does exist, under a name that is one letter off from what's actually there.

**Fix.** Corrected to `from formatted_print import pretty_print`. See §4.2.

*Verified:* the corrected string was checked against the real filename; `py -m
py_compile` confirmed no syntax error was introduced.

### 7.3 Ping Monitor's own README carried an MIT licence block, contradicting the repository's GPL-3.0 — **fixed**

The root `LICENSE` file and the repository's main `README.md` both state GPL-3.0. The
`Ping_Monitor_Router/README.md` sub-page, unrelated to that relicensing pass, still
carried a full embedded MIT License block at its own bottom — a real, findable
inconsistency that a reader landing on that page specifically (rather than the repo
root) would have taken at face value.

**Fix.** Replaced with a one-line pointer to the actual, correct licence:
"GPL-3.0, same as the rest of this repository — see LICENSE." The same stale block was
also found and removed from the private source repository this content is maintained
in, so it can't regenerate here on a future sync.

*Verified:* by inspection — the repository now states GPL-3.0 in exactly one place
(root `LICENSE`) and every page that mentions licensing points to it rather than
repeating (and risking re-diverging from) the text.

### 7.4 Two READMEs pointed at a repository that no longer exists under that name — **fixed, not counted as a defect above**

`WindowsOS_Install_Apps/README.md` and `network/README.md` both described themselves as
"part of the t-philip/public open source collection" — a reference to the pre-2026-07-30
monorepo that was renamed to `blocklists` and split into purpose-built repos (this one
included) during that restructuring. The line was simply never updated in either file
afterward. Removed rather than reworded, since both files already live inside the correct
repository and a self-referential link back to it added nothing.

---

## 8. Possible future work

1. **§1.3** — run Ping Monitor's daemon under a dedicated non-root user with
   `AmbientCapabilities=CAP_NET_RAW` rather than `User=root`, matching the
   already-documented capability-based fix for the "permission denied" ping case. Not
   done in this pass because it also touches `LOG_DIR`'s `$HOME`-relative path (currently
   `/root/ping_monitor` under the shipped unit) and the setup steps that assume root
   throughout — a real design change, not a one-line fix, and there is no Ubuntu host
   here to verify a change to the running-user model against.
2. **§7.1** — install the corrected unit file on a real Ubuntu host and confirm
   `systemctl status ping_monitor` shows it loaded and active; run
   `systemd-analyze verify` for good measure.
3. **§4.2** — `formatted_print.py` predates the rest of this collection by several
   years; if it's touched again, it's a reasonable candidate for a light modernisation
   pass (type hints, an f-string-based implementation) rather than only ever receiving
   typo fixes.

---

## 9. Licence and provenance

Published under **GPL-3.0** alongside the code it describes.

Written and maintained by **T. Philip** — <https://github.com/t-philip>.
Repository: <https://github.com/t-philip/scripts>.
