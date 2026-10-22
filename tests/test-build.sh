#!/usr/bin/env bash
# Shared builder must retain the existing explicit VERSION override contract.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/man" "$WORK/packaging"
cp "$ROOT/bin/gryps" "$WORK/bin/gryps"
cp "$ROOT/man/gryps.1" "$WORK/man/gryps.1"
cp "$ROOT/packaging/build.sh" "$WORK/packaging/build.sh"
printf '1.2.3\n' > "$WORK/VERSION"
sh "$WORK/packaging/build.sh"
[[ $(bash "$WORK/dist/gryps" wersja) == 'Gryps wersja 1.2.3' ]]
VERSION=2.3.4 sh "$WORK/packaging/build.sh"
[[ $(bash "$WORK/dist/gryps" wersja) == 'Gryps wersja 2.3.4' ]] || { echo 'FAIL: jawny VERSION ignorowany'; exit 1; }
cp "$WORK/dist/gryps" "$WORK/previous"
if VERSION='bad/version' sh "$WORK/packaging/build.sh" > /dev/null 2>&1; then echo 'FAIL: nieprawidłowy VERSION zaakceptowany'; exit 1; fi
cmp "$WORK/previous" "$WORK/dist/gryps"
echo 'PASS: wspólny build, jawny VERSION i odmowa nieprawidłowej wersji bez utraty artefaktu'
