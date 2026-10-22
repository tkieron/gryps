#!/usr/bin/env bash
# Catches missing files, raw source binaries and stale entries in release ZIP.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(cat "$ROOT/VERSION")
ARCHIVE="${1:-$ROOT/dist/gryps-$VERSION-windows-gitbash.zip}"
[[ -s "$ARCHIVE" ]] || { echo "FAIL W01: brak ZIP $ARCHIVE" >&2; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
unzip -tq "$ARCHIVE" >/dev/null
unzip -q "$ARCHIVE" -d "$WORK"
PKG="$WORK/gryps-$VERSION-windows-gitbash"
for f in bin/gryps share/bash-completion/completions/gryps install.sh uninstall.sh common.sh README-Windows.md VERSION LICENSE; do
    [[ -s "$PKG/$f" ]] || { echo "FAIL W01: brak $f" >&2; exit 1; }
done
[[ "$(cat "$PKG/VERSION")" == "$VERSION" ]]
if grep -q '__VERSION__' "$PKG/bin/gryps"; then echo 'FAIL: surowe źródło w paczce' >&2; exit 1; fi
[[ "$(bash "$PKG/bin/gryps" wersja)" == "Gryps wersja $VERSION" ]]
cmp "$ROOT/completions/gryps.bash" "$PKG/share/bash-completion/completions/gryps"
echo 'PASS W01: Windows ZIP, komplet plików i wersjonowane binarium'
