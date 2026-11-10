#!/usr/bin/env bash
# Tests for check_privacy.sh: each case builds a throwaway git repo, adds one line and says whether the
# check must pass or fail. Run:  bash privacy-check/test.sh   (under Git Bash on Windows, not WSL)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
checker="$here/check_privacy.sh"
failures=0
total=0

run_case() {  # run_case <name> <expected: pass|fail> <file-name> <line> [config-line]
    local name="$1" expect="$2" file="$3" line="$4" config="${5:-}" dir out code
    dir=$(mktemp -d)
    (
        cd "$dir" || exit 1
        git init -q . && git config user.email t@example.invalid && git config user.name t && git config core.autocrlf false
        mkdir scripts && cp "$checker" scripts/check_privacy.sh
        echo base > README.md
        [ -n "$config" ] && printf '%s\n' "$config" > .privacy-config
        git add -A && git commit -q -m base
        printf '%s\n' "$line" > "$file"
        git add -A
    )
    out=$(cd "$dir" && bash scripts/check_privacy.sh --staged 2>&1)
    code=$?
    rm -rf "$dir"
    total=$((total + 1))
    if { [ "$expect" = pass ] && [ "$code" -eq 0 ]; } || { [ "$expect" = fail ] && [ "$code" -ne 0 ]; }; then
        printf 'ok   %s\n' "$name"
    else
        failures=$((failures + 1))
        printf 'FAIL %s (expected %s, exit %s)\n%s\n' "$name" "$expect" "$code" "$out" | head -12
    fi
}

run_case "plain code passes"                         pass notes.py 'value = compute(total)'
run_case "a private address is flagged"               fail notes.py 'host = "10.1.2.3"'
run_case "a documentation address passes"             pass notes.py 'host = "192.0.2.10"'
run_case "an email address is flagged"                fail notes.py 'mail = "someone@mail.test"'
run_case "a relative in a comment is flagged"         fail notes.py '# my mom was away'
run_case "a bare recent date in prose is flagged"     fail notes.py '# fired on 2024-03-02 for the first time'
run_case "a quoted real-era date is flagged"          fail test_a.py 'DAY = "2024-03-02"'
run_case "a fiction-window date passes"               pass test_a.py 'DAY = "1999-03-02"'
run_case "the window is configurable (wider)"         pass test_a.py 'DAY = "2005-03-02"' 'fiction_before=2010'
run_case "the window is configurable (default)"       fail test_a.py 'DAY = "2005-03-02"'
run_case "real_data_from is configurable"             pass notes.py  '# fired on 2024-03-02 for the first time' 'real_data_from=2030'
run_case "a year outside 1900-2099 keeps the default" fail test_a.py 'DAY = "2005-03-02"' 'fiction_before=2100'
run_case "a bad config value keeps the default"       fail test_a.py 'DAY = "2005-03-02"' 'fiction_before=abc'
run_case "month and year in prose are flagged"        fail notes.py '# happened in March 2025'
run_case "free text must be a placeholder"            fail data.py   'note = "bought a gift for the family"'
run_case "a placeholder passes"                       pass data.py   'note = "Test Data note"'
run_case "a quoted proper-noun phrase is flagged"     fail data.py   'x = "Alice sang"'
run_case "interface text may opt out, visibly"        pass ui.py     'label = "Brake fluid"  # ui-text'
run_case "the marker must end the line to count"      fail ui.py     'x = "Alice sang"; y = "# ui-text"'
run_case "front-end files are not scanned as data"    pass page.html '<p class="note">Brake fluid</p>'

printf '\n%s case(s), %s failure(s)\n' "$total" "$failures"
[ "$failures" -eq 0 ]
