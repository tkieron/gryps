#!/bin/sh
# Cross-platform packaging; end users need only Git Bash and the extracted ZIP.
set -eu
ROOT=$(CDPATH='' cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
for tool in zip mktemp cp chmod mv; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Brak narzędzia budowania: $tool" >&2; exit 1; }
done
VERSION=$(cat VERSION)
printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || exit 1
sh packaging/build.sh
[ "$(bash dist/gryps wersja)" = "Gryps wersja $VERSION" ] || { echo 'Niezgodny dist/gryps' >&2; exit 1; }
STAGE=$(mktemp -d "$ROOT/dist/.windows.XXXXXX")
trap 'rm -rf "$STAGE"' 0
trap 'exit 1' HUP INT TERM
NAME="gryps-$VERSION-windows-gitbash"
PKG="$STAGE/$NAME"
mkdir -p "$PKG/bin" "$PKG/share/bash-completion/completions"
cp dist/gryps "$PKG/bin/gryps"
chmod 0755 "$PKG/bin/gryps"
cp completions/gryps.bash "$PKG/share/bash-completion/completions/gryps"
cp packaging/windows/install.sh packaging/windows/uninstall.sh packaging/windows/common.sh packaging/windows/README-Windows.md VERSION LICENSE "$PKG/"
(cd "$STAGE" && zip -X -qr "$NAME.zip" "$NAME")
mv "$STAGE/$NAME.zip" "$ROOT/dist/$NAME.zip"
printf 'Zbudowano dist/%s.zip\n' "$NAME"
