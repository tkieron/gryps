#!/usr/bin/env bash
# Reject incomplete, damaged, unversioned release sets; never calls GitHub.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/packaging/verify-release.sh" ]] || { echo 'FAIL W16 preflight: brak walidatora'; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
VERSION=$(cat "$ROOT/VERSION")
for asset in "gryps_${VERSION}-1_all.deb" "gryps-$VERSION-macos.tar.gz" "gryps-$VERSION-macos.zip" "gryps-$VERSION-windows-gitbash.zip" gryps; do
    cp "$ROOT/dist/$asset" "$WORK/$asset"
done
sh "$ROOT/packaging/verify-release.sh" "$WORK" > /dev/null
refuse() { if sh "$ROOT/packaging/verify-release.sh" "$WORK" > "$WORK/error" 2>&1; then echo 'FAIL: niepełny zestaw przyjęty' >&2; exit 1; fi; }
for asset in "gryps_${VERSION}-1_all.deb" "gryps-$VERSION-macos.tar.gz" "gryps-$VERSION-macos.zip" "gryps-$VERSION-windows-gitbash.zip" gryps; do
    mv "$WORK/$asset" "$WORK/saved"
    refuse
    : > "$WORK/$asset"
    refuse
    printf uszkodzone > "$WORK/$asset"
    refuse
    mv "$WORK/saved" "$WORK/$asset"
done
# Brak pliku wymaganego przez instalator nie może przejść preflight.
for file in share/zsh/site-functions/_gryps share/man/man1/gryps.1 README-macOS.md; do
    zip -qd "$WORK/gryps-$VERSION-macos.zip" "gryps-$VERSION-macos/$file"
    refuse
    cp "$ROOT/dist/gryps-$VERSION-macos.zip" "$WORK/gryps-$VERSION-macos.zip"
done
cp "$ROOT/bin/gryps" "$WORK/gryps"
refuse
printf 'PASS W16 preflight: braki, puste/uszkodzone pliki i surowe źródło odrzucone\n'
