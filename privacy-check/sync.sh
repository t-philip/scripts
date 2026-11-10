#!/usr/bin/env bash
# Keeps every repo's copy of the privacy check in step with the canonical one in this folder.
#
#   bash privacy-check/sync.sh --check [repo-dir ...]   # report which copies differ; exit 1 if any
#   bash privacy-check/sync.sh --apply [repo-dir ...]   # overwrite the copies that differ (never commits)
#
# With no repo-dir it looks at every sibling folder of this repository that already has a
# scripts/check_privacy.sh, so clone your repositories side by side. PRIVACY_REPOS (space-separated
# paths) overrides that. Three files are kept in step, each only where the repo already has it:
#   privacy-check/check_privacy.sh        -> <repo>/scripts/check_privacy.sh
#   privacy-check/templates/pre-push      -> <repo>/.githooks/pre-push
#   privacy-check/templates/check-privacy.yml -> <repo>/.github/workflows/check-privacy.yml
# A repo's own settings (`.privacy-config`, `.privacy-denylist`, `.privacy-denylist.private`) are never touched.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
home_repo="$(cd "$here/.." && pwd)"
mode="${1:---check}"
[ "$#" -gt 0 ] && shift
case "$mode" in --check|--apply) ;; *) echo "usage: sync.sh --check|--apply [repo-dir ...]" >&2; exit 2 ;; esac

repos=("$@")
if [ "${#repos[@]}" -eq 0 ]; then
    if [ -n "${PRIVACY_REPOS:-}" ]; then
        IFS=';' read -r -a repos <<< "$PRIVACY_REPOS"
    else
        for dir in "$home_repo"/../*/; do
            [ -f "$dir/scripts/check_privacy.sh" ] && repos+=("$(cd "$dir" && pwd)")
        done
    fi
fi

pairs=("$here/check_privacy.sh|scripts/check_privacy.sh"
       "$here/templates/pre-push|.githooks/pre-push"
       "$here/templates/check-privacy.yml|.github/workflows/check-privacy.yml")

drift=0
checked=0
for repo in "${repos[@]}"; do
    if [ ! -d "$repo" ]; then
        echo "error: not a directory: $repo" >&2
        exit 2
    fi
    name="$(basename "$repo")"
    checked=$((checked + 1))
    for pair in "${pairs[@]}"; do
        source_file="${pair%%|*}"
        target="$repo/${pair##*|}"
        [ -f "$target" ] || continue
        if [ -L "$target" ]; then
            echo "skipped  $name: ${pair##*|} is a symbolic link"
            continue
        fi
        if cmp -s "$source_file" "$target"; then
            continue
        fi
        drift=1
        if [ "$mode" = "--apply" ]; then
            cp "$source_file" "$target" && printf 'updated  %s: %s\n' "$name" "${pair##*|}"
        else
            printf 'differs  %s: %s\n' "$name" "${pair##*|}"
        fi
    done
done

if [ "$drift" -eq 0 ]; then
    echo "all copies match the canonical files ($checked repositories)"
    exit 0
fi
[ "$mode" = "--apply" ] && { echo "done: review each repository's diff, then commit it there"; exit 0; }
echo "some copies differ: run with --apply, then review and commit in each repository"
exit 1
