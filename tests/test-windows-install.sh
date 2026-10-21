#!/usr/bin/env bash
# Real installer/config effects; uname is the only platform double on Linux.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/packaging/windows/install.sh" ]] || { echo 'FAIL W02: brak instalatora'; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/stub"
# shellcheck disable=SC2016 # literalne zmienne w generowanym skrypcie
printf '#!/bin/sh\nprintf "%%s\\n" "${TEST_UNAME:-MINGW64_NT-10.0}"\n' > "$WORK/stub/uname"
chmod +x "$WORK/stub/uname"
export PATH="$WORK/stub:$PATH"
PKG="$WORK/paczka ze spacją"
mkdir -p "$PKG/bin" "$PKG/share/bash-completion/completions"
cp "$ROOT/dist/gryps" "$PKG/bin/gryps"
cp "$ROOT/completions/gryps.bash" "$PKG/share/bash-completion/completions/gryps"
cp "$ROOT"/packaging/windows/*.sh "$PKG/"
cp "$ROOT/VERSION" "$PKG/VERSION"
export HOME="$WORK/Ala Nowak Zażółć [1]'\$literal"
export PREFIX="$HOME/.local"
mkdir -p "$HOME"
printf 'export KEEP=tak\n# ustawienia bez końcowego newline' > "$HOME/.bashrc"
cp "$HOME/.bashrc" "$WORK/original"
install_pkg() { sh "$PKG/install.sh" "$@" < /dev/null; }
refuse() { if "$@" > "$WORK/refused.log" 2>&1; then echo "FAIL: oczekiwana odmowa: $*" >&2; exit 1; fi; }
refuse env TEST_UNAME=Linux sh "$PKG/install.sh" --yes
refuse install_pkg --unknown
refuse install_pkg --yes --no-config
[[ ! -e "$PREFIX/bin/gryps" ]]
install_pkg > "$WORK/default.log"
cmp "$WORK/original" "$HOME/.bashrc"
[[ "$("$PREFIX/bin/gryps" wersja)" == "Gryps wersja $(cat "$ROOT/VERSION")" ]]
install_pkg --no-config > /dev/null
cmp "$WORK/original" "$HOME/.bashrc"
install_pkg --yes > /dev/null
[[ $(grep -c '^# >>> gryps Git Bash >>>$' "$HOME/.bashrc") == 1 ]]
backup_ok=0
for backup in "$HOME"/.bashrc.gryps-backup.*; do
    if cmp -s "$WORK/original" "$backup"; then backup_ok=1; fi
done
[[ $backup_ok == 1 ]]
cp "$HOME/.bashrc" "$WORK/configured"
install_pkg --yes > /dev/null
cmp "$WORK/configured" "$HOME/.bashrc"
bash --noprofile --norc -c '. "$HOME/.bashrc"; test "$(command -v gryps)" = "$PREFIX/bin/gryps"; complete -p gryps' >/dev/null
sh "$PKG/uninstall.sh" > /dev/null
cmp "$WORK/original" "$HOME/.bashrc"
[[ ! -e "$PREFIX/bin/gryps" ]]
sh "$PKG/uninstall.sh" > /dev/null
# Obce pliki i symlinki nie mogą zostać przejęte.
mkdir -p "$PREFIX/bin"
printf obce > "$PREFIX/bin/gryps"
refuse install_pkg --yes
[[ $(cat "$PREFIX/bin/gryps") == obce ]]
rm "$PREFIX/bin/gryps"
if ln -s "$WORK/original" "$HOME/rc-link" 2>/dev/null && [[ -L "$HOME/rc-link" ]]; then
    rm "$HOME/.bashrc"
    ln -s "$HOME/rc-link" "$HOME/.bashrc"
    [[ -L "$HOME/.bashrc" ]]
    refuse install_pkg --yes
    cmp "$WORK/original" "$HOME/rc-link"
else
    echo 'SKIP: symlink fixture: system/MSYS nie tworzy dowiązań (możliwy tryb deepcopy); pozostałe testy instalacji są obowiązkowe'
fi
rm "$HOME/.bashrc"
printf '# >>> gryps Git Bash >>>\nprzerwany blok\n' > "$HOME/.bashrc"
refuse install_pkg --yes
[[ ! -e "$PREFIX/bin/gryps" ]]
cp "$WORK/original" "$HOME/.bashrc"
# Błąd w trakcie aktualizacji przywraca binarium, completion i konfigurację.
install_pkg --yes > /dev/null
cp "$PREFIX/bin/gryps" "$WORK/bin-before"
cp "$HOME/.bashrc" "$WORK/rc-before"
printf '\n# kolejna paczka\n' >> "$PKG/bin/gryps"
REAL_CHMOD=$(command -v chmod)
export REAL_CHMOD
cat > "$WORK/stub/chmod" <<'STUB'
#!/bin/sh
if [ "${TEST_FAIL_CHMOD:-no}" = yes ] && [ "$2" = "$PREFIX/bin/gryps" ]; then exit 1; fi
exec "$REAL_CHMOD" "$@"
STUB
"$REAL_CHMOD" +x "$WORK/stub/chmod"
export TEST_FAIL_CHMOD=yes
refuse install_pkg --yes
unset TEST_FAIL_CHMOD
cmp "$WORK/bin-before" "$PREFIX/bin/gryps"
cmp "$WORK/rc-before" "$HOME/.bashrc"
rm "$WORK/stub/chmod"
# Ustawienia dopisane po instalacji pozostają bitowo identyczne.
printf 'export LATER=tak' >> "$HOME/.bashrc"
cat "$WORK/original" > "$WORK/with-later"
printf 'export LATER=tak' >> "$WORK/with-later"
sh "$PKG/uninstall.sh" > /dev/null
cmp "$WORK/with-later" "$HOME/.bashrc"
cp "$WORK/original" "$HOME/.bashrc"
# Brak zależności wykrywany zanim skrypt dotknie docelowych plików.
for missing in git bash cp; do
    thin="$WORK/missing-$missing"
    mkdir "$thin"
    for tool in uname git bash cp chmod mkdir mktemp rm mv rmdir cksum cmp awk dd cat grep sed wc; do
        [[ $tool == "$missing" ]] || printf '#!/bin/sh\nexit 77\n' > "$thin/$tool"
    done
    # shellcheck disable=SC2016 # literalne argumenty stubu dirname
    printf '#!/bin/sh\nprintf "%%s\\n" "${1%%/*}"\n' > "$thin/dirname"
    chmod +x "$thin/"*
    refuse env PATH="$thin" /bin/sh "$PKG/install.sh" --yes
    grep -q "Brak narzędzia: $missing" "$WORK/refused.log"
    [[ ! -e "$PREFIX/bin/gryps" ]]
done
# Zmiana pliku po instalacji: uninstall zachowuje zmieniony plik i stan.
install_pkg --yes > /dev/null
printf '\n# lokalna zmiana\n' >> "$PREFIX/bin/gryps"
refuse sh "$PKG/uninstall.sh"
grep -q 'lokalna zmiana' "$PREFIX/bin/gryps"
# Uszkodzony blok: odmowa przed usunięciem czegokolwiek.
cp "$PKG/bin/gryps" "$PREFIX/bin/gryps"
printf '# >>> gryps Git Bash >>>\n' >> "$HOME/.bashrc"
refuse sh "$PKG/uninstall.sh"
[[ -f "$PREFIX/bin/gryps" ]]
printf 'PASS W02–W05 installer logic (%s; uname double poza Windows)\n' "$(uname -s)"
