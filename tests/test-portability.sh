#!/usr/bin/env bash
# Shared real Git scenarios; Windows launcher additionally enforces native MSYS.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS=${GRYPS:-$ROOT/dist/gryps}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_TERMINAL_PROMPT=0 GIT_PAGER=cat PAGER=cat NO_COLOR=1
mkdir -p "$HOME"
# A path under the actual current drive on Windows, not a fabricated /c fixture.
for autocrlf in false true; do
    REPO="$WORK/Ala Nowak Zażółć [1]/repo-$autocrlf"
    mkdir -p "$REPO/src"
    cd "$REPO"
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git config user.name 'Tester'
    git config user.email 'tester@example.test'
    git config core.autocrlf "$autocrlf"
    git config core.filemode false
    # Mixed filenames/line endings. No checkout occurs during add/commit.
    printf 'first\n' > 'ts Zażółć [1].txt'
    printf 'first\r\n' > 'src/ts CRLF.txt'
    cp 'src/ts CRLF.txt' "$WORK/bytes"
    "$GRYPS" skitraj -- 'ts Zażółć [1].txt' 'src/ts CRLF.txt' < /dev/null
    cmp 'src/ts CRLF.txt' "$WORK/bytes"
    "$GRYPS" przyklep 'portability baseline' < /dev/null >/dev/null
    cmp 'src/ts CRLF.txt' "$WORK/bytes"
    git --no-pager status -sb > "$WORK/expected"
    "$GRYPS" lipo < /dev/null > "$WORK/actual"
    cmp "$WORK/expected" "$WORK/actual"
    printf 'next\n' >> 'ts Zażółć [1].txt'
    git --no-pager diff > "$WORK/expected"
    "$GRYPS" kwity < /dev/null > "$WORK/actual"
    cmp "$WORK/expected" "$WORK/actual"
    "$GRYPS" skitraj -- 'ts Zażółć [1].txt' < /dev/null
    git --no-pager diff --cached > "$WORK/expected"
    "$GRYPS" kwity --staged < /dev/null > "$WORK/actual"
    cmp "$WORK/expected" "$WORK/actual"
    "$GRYPS" kartoteka < /dev/null > "$WORK/card"
    grep -q 'tester@example.test' "$WORK/card"
    "$GRYPS" --cicho przyklep 'next commit' < /dev/null >/dev/null
    # Bare remote: fetch/push, no network and no host Git config changes.
    git init -q --bare "$WORK/remote-$autocrlf.git"
    git remote add origin "$WORK/remote-$autocrlf.git"
    "$GRYPS" --cicho wywozka < /dev/null >/dev/null 2>&1
    [[ $(git --git-dir="$WORK/remote-$autocrlf.git" rev-parse refs/heads/main) == "$(git rev-parse HEAD)" ]]
    "$GRYPS" ucho < /dev/null >/dev/null 2>&1
    printf 'stash\n' >> 'ts Zażółć [1].txt'
    "$GRYPS" dziupla < /dev/null >/dev/null
    [[ -z $(git status --porcelain) ]]
    "$GRYPS" wyjmij < /dev/null >/dev/null
    grep -q stash 'ts Zażółć [1].txt'
    "$GRYPS" cynk < /dev/null > "$WORK/reflog"
    [[ -s "$WORK/reflog" ]]
    # Safety without a terminal and explicit -f, including untracked paths.
    for cmd in odkrec kipisz; do
        if "$GRYPS" "$cmd" -- 'ts Zażółć [1].txt' < /dev/null > "$WORK/out" 2> "$WORK/err"; then
            echo "FAIL: $cmd bez TTY" >&2; exit 1
        fi
        grep -q stash 'ts Zażółć [1].txt'
    done
    "$GRYPS" odkrec -f -- 'ts Zażółć [1].txt' < /dev/null
    # A forced checkout must honor Git conversion, without modifying its config.
    if [[ $autocrlf == true ]]; then printf 'first\r\nnext\r\n' > "$WORK/checkout-expected";
    else printf 'first\nnext\n' > "$WORK/checkout-expected"; fi
    cmp "$WORK/checkout-expected" 'ts Zażółć [1].txt'
    git show 'HEAD:ts Zażółć [1].txt' > "$WORK/blob"
    printf 'first\nnext\n' > "$WORK/blob-expected"
    cmp "$WORK/blob-expected" "$WORK/blob"
    # Explicit pathspec magic from a subdirectory and absolute POSIX arguments.
    ABS_FILE="$REPO/ts Zażółć [1].txt"
    printf 'absolute path\n' >> "$ABS_FILE"
    (cd src && "$GRYPS" skitraj -- ':(top)ts Zażółć [1].txt' < /dev/null)
    [[ -n $(git diff --cached --name-only) ]]
    (cd src && "$GRYPS" odkitraj -- "$ABS_FILE" < /dev/null)
    [[ -z $(git diff --cached --name-only) ]]
    if [[ $(uname -s) == MINGW*_NT-* || $(uname -s) == MSYS_NT-* ]]; then
        # Native launcher puts this repo under real /c/Users/...; test both forms.
        WIN_FILE=$(cygpath -w "$ABS_FILE")
        "$GRYPS" skitraj -- "$WIN_FILE" < /dev/null
        [[ -n $(git diff --cached --name-only) ]]
        "$GRYPS" odkitraj -- "$WIN_FILE" < /dev/null
        [[ -z $(git diff --cached --name-only) ]]
    fi
    "$GRYPS" odkrec -f -- "$ABS_FILE" < /dev/null
    cmp "$WORK/checkout-expected" "$ABS_FILE"
    printf 'untracked\n' > 'src/nowe [1].txt'
    if "$GRYPS" wykipruj -- 'src/nowe [1].txt' < /dev/null > "$WORK/out" 2> "$WORK/err"; then
        echo 'FAIL: wykipruj bez TTY' >&2; exit 1
    fi
    [[ -f 'src/nowe [1].txt' ]]
    (cd src && "$GRYPS" wykipruj -n < /dev/null) > "$WORK/preview"
    [[ -s "$WORK/preview" ]]
    "$GRYPS" wykipruj -f -- 'src/nowe [1].txt' < /dev/null >/dev/null
    [[ ! -e 'src/nowe [1].txt' ]]
    [[ $(git config core.autocrlf) == "$autocrlf" && $(git config core.filemode) == false ]]
    # Current-directory paths, -- and branch names in completion.
    # shellcheck source=/dev/null
    source "$ROOT/completions/gryps.bash"
    COMP_WORDS=(gryps kapus -- ts); COMP_CWORD=3; _gryps_completions
    [[ "|${COMPREPLY[*]}|" == *'ts Zażółć [1].txt'* ]]
    git branch temat
    COMP_WORDS=(gryps przerzutka tem); COMP_CWORD=2; _gryps_completions
    [[ ${COMPREPLY[0]} == temat ]]
    cd src
    COMP_WORDS=(gryps kapus -- ts); COMP_CWORD=3; _gryps_completions
    [[ ${COMPREPLY[0]} == 'ts CRLF.txt' ]]
    printf 'PASS W08/W09/W11/W12/W13: core.autocrlf=%s, Unicode, LF/CRLF, bezpieczeństwo i Git config\n' "$autocrlf"
done
