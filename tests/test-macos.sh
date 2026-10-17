#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$ROOT/VERSION")"
ARCHIVE="$ROOT/dist/gryps-$VERSION-macos.tar.gz"
if [[ ! -f "$ARCHIVE" ]]; then echo "Brak archiwum: $ARCHIVE" >&2; exit 1; fi
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/home"

tar -xzf "$ARCHIVE" -C "$STAGE"
PKG="$STAGE/gryps-$VERSION-macos"
[[ "$($PKG/bin/gryps wersja)" == *"$VERSION"* ]]
[[ -f "$PKG/share/zsh/site-functions/_gryps" ]]
[[ -f "$PKG/share/bash-completion/completions/gryps" ]]

HOME="$STAGE/home" "$PKG/install.sh" --configure-zsh > "$STAGE/install.log"
[[ -x "$STAGE/home/.local/bin/gryps" ]]
[[ -f "$STAGE/home/.local/share/zsh/site-functions/_gryps" ]]
[[ -f "$STAGE/home/.local/share/man/man1/gryps.1" ]]
[[ "$(grep -c '^# >>> gryps macOS >>>$' "$STAGE/home/.zshrc")" -eq 1 ]]
HOME="$STAGE/home" "$PKG/install.sh" --configure-zsh >> "$STAGE/install.log"
[[ "$(grep -c '^# >>> gryps macOS >>>$' "$STAGE/home/.zshrc")" -eq 1 ]]
HOME="$STAGE/home" "$PKG/uninstall.sh" > "$STAGE/uninstall.log"
[[ ! -e "$STAGE/home/.local/bin/gryps" ]]
[[ -f "$STAGE/home/.zshrc" ]] # must not erase user shell preferences
printf 'macOS archive: install / idempotence / uninstall OK\n'
