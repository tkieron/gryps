#!/bin/sh
# Invoked by the tag workflow only. Tests replace gh; never run for local builds.
set -eu
ROOT=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then echo 'Użycie: publish-release.sh TAG NOTES [DIST]' >&2; exit 2; fi
TAG=$1
NOTES=$2
DIST=${3:-"$ROOT/dist"}
VERSION=$(cat "$ROOT/VERSION")
[ "$TAG" = "v$VERSION" ] || { echo 'Tag niezgodny z VERSION' >&2; exit 1; }
[ -s "$NOTES" ] || { echo 'Brak notatek wydania' >&2; exit 1; }
sh "$ROOT/packaging/verify-release.sh" "$DIST"
set -- "$DIST/gryps_${VERSION}-1_all.deb" "$DIST/gryps-$VERSION-macos.tar.gz" "$DIST/gryps-$VERSION-macos.zip" "$DIST/gryps-$VERSION-windows-gitbash.zip" "$DIST/gryps"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' 0
trap 'exit 1' HUP INT TERM
for asset in "$@"; do
    printf '%s\t%s\n' "$(basename "$asset")" "$(wc -c < "$asset" | tr -d '[:space:]')"
done | LC_ALL=C sort > "$WORK/expected"
# --verify-tag prevents gh from implicitly creating a missing tag.
gh release create "$TAG" --verify-tag --draft --title "Gryps $TAG" --notes-file "$NOTES"
gh release upload "$TAG" "$@"
gh release view "$TAG" --json assets --jq '.assets[] | [.name, .size] | @tsv' > "$WORK/remote"
LC_ALL=C sort "$WORK/remote" > "$WORK/actual"
cmp "$WORK/expected" "$WORK/actual" || { echo 'Niepełne Assets; wydanie pozostaje draftem.' >&2; exit 1; }
gh release edit "$TAG" --draft=false
