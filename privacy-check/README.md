# privacy-check

A small, honest check for repositories that grew out of **real personal data**: smart meters, home
automation, sensors, trackers, anything whose tests, comments and docs can quietly end up describing a real
household. It is a starting point, tuned from experience, not a guarantee.

## What it is, and what it is not

It reads the **lines you added** (against the published branch) and fails the push when they look like
a description of one real installation. It is a **heuristic denylist plus a few structural rules**.

**A pass means "no known pattern found", never "safe to publish".** Every run prints that. The other
half of the rule is a *semantic read* of the diff by someone (or something) with no memory of writing
it, answering one question:

> Could this have been written by someone who has never seen the author's home or network?

If not, generalise it first: state the behaviour, not the occasion.

## The method (the part worth copying)

1. **Test data is fictitious by default.** Dates in test data use a year *before* a cutoff
   (`fiction_before`, default 2002) and nothing else. If every real data source you have begins later,
   a date inside the window provably records nothing, and a date outside it is a hard signal, not a
   guess. Move an old suite by shifting every date back exactly **28 years** (the Gregorian repeat
   cycle: weekday, day of year and leap years are unchanged, so nothing the code observes changes).
2. **Free text defaults to a placeholder** (`Test Data ...`). Any field a person can fill (notes,
   labels, descriptions) is where a verbatim note from a real database ends up.
3. **Relative dates stay relative.** A fixture built from "now plus an offset" carries no calendar fact.
4. **Private vocabulary stays out of the repo.** Names of your own hosts, places and people go in an
   untracked file (`.privacy-denylist.private`). A tracked list of them would publish them.
5. **Check the diff, not the tree.** A big suite has many legitimate synthetic values; flagging them
   all gets the check switched off within a week.

## What it checks

People and relationships, private IP addresses, email addresses, a real-looking date in prose, month
and year in prose, a duration attached to a personal event, a quoted capitalised phrase (a likely
verbatim note), free-text fields that are not placeholders, absolute dates outside the fiction window,
and your private and per-repo denylists.

## Use it in a repository

1. Copy `check_privacy.sh` to `scripts/check_privacy.sh`, `templates/pre-push` to `.githooks/pre-push`
   and `templates/check-privacy.yml` to `.github/workflows/check-privacy.yml`.
2. Activate the hook once per clone: `git config core.hooksPath .githooks`.
3. Run it by hand: `bash scripts/check_privacy.sh` (added lines vs `origin/main`), `--staged`, or `--all`
   (the whole tree; noisy by design). On Windows use Git Bash, not WSL's bash.

The hook can be bypassed with `--no-verify`; the workflow runs the same script on the server so that a
skipped hook is noticed, though it cannot un-publish anything.

## Settings

| File | Purpose |
|---|---|
| `.privacy-config` (tracked, optional) | `fiction_before=2002`: test data may use only years before this. `real_data_from=2020`: a bare date from this year on, in prose, reads as a dated observation. Each takes a four-digit year from 1900 to 2099; anything else keeps the default. |
| `.privacy-denylist` (tracked, optional) | One extended regex per line that is safe to publish and specific to this repo. |
| `.privacy-denylist.private` (untracked) | Your own vocabulary. If absent (a fresh clone, CI) that one rule is skipped and the output says so. `PRIVACY_DENYLIST_LOCAL` points at another path. |

**Interface text.** The quoted-phrase and free-text rules also match ordinary interface labels. A line
of plain interface text may end with a `# ui-text` comment to skip those two rules only. Every use is
counted and printed on every run, and the semantic review reads them. Never use it for anything that
came from real data.

## Keeping every repository's copy in step

`check_privacy.sh` here is the canonical copy. Each repository keeps its own, because the hook must work
offline and the workflow needs the file in the checkout. Fetching it from the network at check time would
trade a drift problem for a supply-chain one.

```
bash privacy-check/sync.sh --check     # which copies differ (exit 1 if any)
bash privacy-check/sync.sh --apply     # overwrite the copies that differ; review and commit in each repo
```

It looks at sibling folders that already have `scripts/check_privacy.sh` (clone your repositories side by
side), or at `PRIVACY_REPOS` (paths separated by semicolons). A repository path that does not exist is an error, and a symbolic link is skipped. It never touches a repository's own settings and never commits.

## Tests

`bash privacy-check/test.sh` builds a throwaway repository for each case and checks that the rule fires
(or stays quiet). Run it after changing a rule.

## Limits

Bash and grep: heuristic, English-phrased, and tuned from one person's mistakes. It will miss leaks it was
not taught and flag some harmless lines. That is why the semantic read is not optional.
