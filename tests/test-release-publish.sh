#!/usr/bin/env bash
# External gh is doubled: assert our fail-closed orchestration, no remote writes.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/packaging/publish-release.sh" ]] || { echo 'FAIL: brak bezpiecznej publikacji'; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/stub"
export TEST_GH_LOG="$WORK/gh.log" TEST_GH_ASSETS="$WORK/assets.tsv"
cat > "$WORK/stub/gh" <<'STUB'
#!/bin/sh
set -eu
printf '%s\n' "$*" >> "$TEST_GH_LOG"
case "$1 $2" in
    'release create') case " $* " in *' --draft '*) ;; *) exit 2 ;; esac ;;
    'release upload')
        [ "${TEST_UPLOAD_FAIL:-no}" != yes ] || exit 1
        shift 3
        : > "$TEST_GH_ASSETS"
        for asset in "$@"; do printf '%s\t%s\n' "$(basename "$asset")" "$(wc -c < "$asset" | tr -d ' ')" >> "$TEST_GH_ASSETS"; done ;;
    'release view')
        if [ "${TEST_BAD_ASSETS:-no}" = yes ]; then printf 'brak\t0\n'; else cat "$TEST_GH_ASSETS"; fi ;;
    'release edit') ;; # publication is logged but never reaches GitHub
    *) exit 2 ;;
esac
STUB
chmod +x "$WORK/stub/gh"
export PATH="$WORK/stub:$PATH"
printf 'notes\n' > "$WORK/notes"
VERSION=$(cat "$ROOT/VERSION")
refuse() { if sh "$ROOT/packaging/publish-release.sh" "$@" > "$WORK/error" 2>&1; then echo 'FAIL: oczekiwana odmowa publikacji' >&2; exit 1; fi; }
refuse v0.0.0 "$WORK/notes"
[[ ! -f "$TEST_GH_LOG" ]]
for failure in TEST_UPLOAD_FAIL TEST_BAD_ASSETS; do
    : > "$TEST_GH_LOG"
    export "$failure=yes"
    refuse "v$VERSION" "$WORK/notes"
    if grep -q '^release edit' "$TEST_GH_LOG"; then echo 'FAIL: publish po błędzie' >&2; exit 1; fi
    unset "$failure"
done
: > "$TEST_GH_LOG"
sh "$ROOT/packaging/publish-release.sh" "v$VERSION" "$WORK/notes" > /dev/null
grep -q '^release edit .*--draft=false' "$TEST_GH_LOG"
[[ $(wc -l < "$TEST_GH_ASSETS") == 5 ]]
echo 'PASS W16 orchestration: błędy upload/listy blokują publish; komplet pięciu Assets publikuje draft (gh stub)'
