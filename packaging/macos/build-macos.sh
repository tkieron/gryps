#!/bin/sh
# Portable macOS CLI archive, no mac required to package.
set -eu
ROOT=$(CDPATH="" cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
VERSION=$(cat VERSION)
make build
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
NAME="gryps-${VERSION}-macos"
PKG="$STAGE/$NAME"
mkdir -p "$PKG/bin" "$PKG/share/man/man1" \
    "$PKG/share/zsh/site-functions" "$PKG/share/bash-completion/completions"
install -m 0755 dist/gryps "$PKG/bin/gryps"
install -m 0644 dist/gryps.1 "$PKG/share/man/man1/gryps.1"
install -m 0644 completions/_gryps "$PKG/share/zsh/site-functions/_gryps"
install -m 0644 completions/gryps.bash "$PKG/share/bash-completion/completions/gryps"
install -m 0755 packaging/macos/install.sh "$PKG/install.sh"
install -m 0755 packaging/macos/uninstall.sh "$PKG/uninstall.sh"
install -m 0644 packaging/macos/README-macOS.md "$PKG/README-macOS.md"
install -m 0644 LICENSE "$PKG/LICENSE"
install -m 0644 VERSION "$PKG/VERSION"
mkdir -p dist
COPYFILE_DISABLE=1 tar -czf "dist/$NAME.tar.gz" -C "$STAGE" "$NAME"
( cd "$STAGE" && zip -X -qr "$ROOT/dist/$NAME.zip" "$NAME" )
echo "✅ dist/$NAME.tar.gz + dist/$NAME.zip (Intel x86_64 i Apple Silicon arm64)"
