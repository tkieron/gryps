#!/bin/sh
# Check every required artifact before creating even a draft release.
set -eu
ROOT=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
DIST=${1:-"$ROOT/dist"}
DIST=$(CDPATH='' cd "$DIST" && pwd)
VERSION=$(cat "$ROOT/VERSION")
for asset in "gryps_${VERSION}-1_all.deb" "gryps-$VERSION-macos.tar.gz" "gryps-$VERSION-macos.zip" "gryps-$VERSION-windows-gitbash.zip" gryps; do
    [ -s "$DIST/$asset" ] || { echo "Brak/pusty artefakt: $asset" >&2; exit 1; }
done
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' 0
trap 'exit 1' HUP INT TERM
check_binary() {
    [ -s "$1" ] && ! grep -q '__VERSION__' "$1" && [ "$(bash "$1" wersja)" = "Gryps wersja $VERSION" ]
}
check_binary "$DIST/gryps"
[ "$(dpkg-deb -f "$DIST/gryps_${VERSION}-1_all.deb" Version)" = "$VERSION-1" ]
dpkg-deb -x "$DIST/gryps_${VERSION}-1_all.deb" "$WORK/deb"
check_binary "$WORK/deb/usr/bin/gryps"
mkdir "$WORK/tar" "$WORK/maczip" "$WORK/winzip"
tar -xzf "$DIST/gryps-$VERSION-macos.tar.gz" -C "$WORK/tar"
unzip -tq "$DIST/gryps-$VERSION-macos.zip" >/dev/null
unzip -q "$DIST/gryps-$VERSION-macos.zip" -d "$WORK/maczip"
unzip -tq "$DIST/gryps-$VERSION-windows-gitbash.zip" >/dev/null
unzip -q "$DIST/gryps-$VERSION-windows-gitbash.zip" -d "$WORK/winzip"
for pkg in "$WORK/tar/gryps-$VERSION-macos" "$WORK/maczip/gryps-$VERSION-macos" "$WORK/winzip/gryps-$VERSION-windows-gitbash"; do
    [ "$(cat "$pkg/VERSION")" = "$VERSION" ]
    check_binary "$pkg/bin/gryps"
    cmp "$pkg/bin/gryps" "$DIST/gryps"
    cmp "$pkg/share/bash-completion/completions/gryps" "$ROOT/completions/gryps.bash"
    for file in share/bash-completion/completions/gryps install.sh uninstall.sh LICENSE; do [ -s "$pkg/$file" ]; done
done
for pkg in "$WORK/tar/gryps-$VERSION-macos" "$WORK/maczip/gryps-$VERSION-macos"; do
    for file in share/zsh/site-functions/_gryps share/man/man1/gryps.1 README-macOS.md; do [ -s "$pkg/$file" ]; done
    cmp "$pkg/share/zsh/site-functions/_gryps" "$ROOT/completions/_gryps"
done
for file in common.sh README-Windows.md; do [ -s "$WORK/winzip/gryps-$VERSION-windows-gitbash/$file" ]; done
printf 'PASS: DEB, macOS TAR/ZIP, Windows ZIP i gryps: %s\n' "$VERSION"
