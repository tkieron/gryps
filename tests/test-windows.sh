#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in MINGW*_NT-*|MSYS_NT-*) ;; *) echo 'FAIL: ten test wymaga natywnego Windows Git Bash, nie Linux/WSL' >&2; exit 1 ;; esac
printf 'Natywny Windows: %s\n' "$(uname -s)"
command -v bash git
bash --version | head -1
git --version
NATIVE_HOME_ROOT=$(cygpath -u "${USERPROFILE:?USERPROFILE wymagany na Windows}")
WORK=$(mktemp -d "$NATIVE_HOME_ROOT/gryps Ala Nowak Zażółć [1].XXXXXX")
trap 'rm -rf "$WORK"' EXIT
VERSION=$(cat "$ROOT/VERSION")
# unzip from Chocolatey is native Windows too; [] suppresses MSYS conversion.
unzip -q "$(cygpath -m "$ROOT/dist/gryps-$VERSION-windows-gitbash.zip")" -d "$(cygpath -m "$WORK")"
PKG="$WORK/gryps-$VERSION-windows-gitbash"
TEST_HOME="$WORK/Ala Nowak"
mkdir -p "$TEST_HOME"
printf 'export KEEP=native\n' > "$TEST_HOME/.bashrc"
cp "$TEST_HOME/.bashrc" "$WORK/original"
env HOME="$TEST_HOME" PREFIX="$TEST_HOME/.local" sh "$PKG/install.sh" --yes
env HOME="$TEST_HOME" PREFIX="$TEST_HOME/.local" sh "$PKG/install.sh" --yes
[[ "$("$TEST_HOME/.local/bin/gryps" wersja)" == "Gryps wersja $VERSION" ]]
# shellcheck disable=SC2016 # tekst wykonywany dopiero w testowej powłoce
env HOME="$TEST_HOME" PREFIX="$TEST_HOME/.local" bash --noprofile --norc -c '. "$HOME/.bashrc"; test "$(command -v gryps)" = "$PREFIX/bin/gryps"'
env HOME="$TEST_HOME" PREFIX="$TEST_HOME/.local" sh "$PKG/uninstall.sh"
cmp "$WORK/original" "$TEST_HOME/.bashrc"
[[ ! -e "$TEST_HOME/.local/bin/gryps" ]]
printf 'PASS W02–W05: natywna instalacja ZIP w %s\n' "$TEST_HOME"
TMPDIR="$WORK" bash "$ROOT/tests/test-portability.sh"
echo 'PENDING: W10 i interaktywna część W11 wymagają potwierdzenia w mintty/Windows Terminal; patrz docs/GRYPS-1.5.0-ACCEPTANCE.md'
