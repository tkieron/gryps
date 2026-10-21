#!/bin/sh
# Single version-injection process used by make and by native Git Bash CI.
set -eu
ROOT=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
VERSION=${VERSION:-$(cat VERSION)}
printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo 'Nieprawidłowy VERSION' >&2; exit 1; }
mkdir -p dist
STAGE=$(mktemp -d "$ROOT/dist/.build.XXXXXX")
trap 'rm -rf "$STAGE"' 0
trap 'exit 1' HUP INT TERM
sed "s/__VERSION__/$VERSION/g" bin/gryps > "$STAGE/gryps"
sed "s/__VERSION__/$VERSION/g" man/gryps.1 > "$STAGE/gryps.1"
chmod 0755 "$STAGE/gryps"
mv "$STAGE/gryps" dist/gryps
mv "$STAGE/gryps.1" dist/gryps.1
