#!/usr/bin/env bash
# Test Bash TAB completion, including regression for `kapus -- ts<TAB>`.
# No interactive terminal or git remote needed; supports Bash 3.2+.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
mkdir -p src
printf 'class Test {}\n' > src/tsTest.java
printf 'example\n' > tsPrasa.txt
printf 'example\n' > 'ts z odstępem.txt'
printf 'example\n' > '--ts-leading.txt'

# Completion definition is normally sourced by bash-completion.
# shellcheck source=../completions/gryps.bash
source "$ROOT/completions/gryps.bash"

PASS=0 FAIL=0
assert_reply() {
    local description="$1" expected="$2" candidate found=0
    shift 2
    COMP_WORDS=("$@")
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    : > "$WORK/errors"
    _gryps_completions 2>"$WORK/errors"
    for candidate in "${COMPREPLY[@]}"; do
        if [[ "$candidate" == "$expected" ]]; then found=1; break; fi
    done
    if [[ "$found" -eq 1 && ! -s "$WORK/errors" ]]; then
        printf '  ✅ %s\n' "$description"
        PASS=$((PASS + 1))
    else
        printf '  ❌ %s  expected=%q got=(%s) stderr=(%s)\n' "$description" "$expected" "${COMPREPLY[*]}" "$(cat "$WORK/errors")"
        FAIL=$((FAIL + 1))
    fi
}

assert_reply 'kapus -- ts<TAB>' 'tsPrasa.txt' gryps kapus -- ts
assert_reply 'kapus ts<TAB> bez --' 'tsPrasa.txt' gryps kapus ts
assert_reply 'kapus -L 1,3 -- ts<TAB>' 'tsPrasa.txt' gryps kapus -L 1,3 -- ts
assert_reply 'kapus -- src/ts<TAB>' 'src/tsTest.java' gryps kapus -- src/ts
assert_reply 'kapus -- ts (spacja w nazwie)' 'ts z odstępem.txt' gryps kapus -- ts
assert_reply 'kapus -- --ts (nazwa od --)' '--ts-leading.txt' gryps kapus -- --ts
assert_reply 'kapus --cicho -- ts<TAB>' 'tsPrasa.txt' gryps --cicho kapus -- ts
assert_reply 'odkitraj -- ts<TAB>' 'tsPrasa.txt' gryps odkitraj -- ts
assert_reply 'odkrec -- ts<TAB>' 'tsPrasa.txt' gryps odkrec -- ts
assert_reply 'kwity -- ts<TAB>' 'tsPrasa.txt' gryps kwity -- ts
assert_reply 'skitrac -- ts<TAB>' 'tsPrasa.txt' gryps skitrac -- ts
assert_reply 'podpowiedź nazwy grypsu' 'kapus' gryps kap
assert_reply 'podpowiedź po --cicho' 'kapus' gryps --cicho kap
assert_reply 'kmina kap<TAB>' 'kapus' gryps kmina kap

if [[ "$(complete -p gryps)" == *'-o filenames'* ]]; then
    printf '  ✅ Bash cytuje ścieżki ze spacjami\n'
    PASS=$((PASS + 1))
else
    printf '  ❌ Brakuje opcji -o filenames\n'
    FAIL=$((FAIL + 1))
fi

printf 'TAB completion: %d/%d zaliczonych\n' "$PASS" "$((PASS+FAIL))"
[[ "$FAIL" -eq 0 ]]
