# privacy-check changelog

## 1.0.0

First shared release, merged from the copies that had drifted apart in separate repositories.

- One canonical `check_privacy.sh`, with `sync.sh` to report drift and overwrite stale copies.
- The fiction-window year and the first real-data year are settings (`.privacy-config`), not constants.
- A trailing `# ui-text` comment lets plain interface labels skip the quoted-phrase and free-text rules;
  every use is printed on every run.
- Front-end files (`.js`, `.html`, `.css`) are not scanned by the quoted-phrase and free-text rules.
- A `LICENSE` file is excluded from the scan.
- `test.sh`: one case per rule, including the settings and the marker.
- Templates for the pre-push hook and the server-side workflow.
- Comments reworded to describe behaviour rather than any one installation.
