#!/bin/sh
# Offline per-user Git Bash installation, also invokable as sh ./install.sh.
set -eu
BASE=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck source=packaging/windows/common.sh
. "$BASE/common.sh"
MODE=ask
for arg in "$@"; do
    case "$arg" in
        --yes|--no-config)
            [ "$MODE" = ask ] || { echo 'Wybierz tylko jedną flagę --yes lub --no-config.' >&2; exit 2; }
            MODE=$arg ;;
        -h|--help) echo 'sh ./install.sh [--yes|--no-config] (domyślnie ~/.local)'; exit 0 ;;
        *) echo "Nieznany argument: $arg" >&2; exit 2 ;;
    esac
done
setup
VERSION=$(cat "$BASE/VERSION")
printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail 'Nieprawidłowy VERSION.'
[ "$(bash "$BASE/bin/gryps" wersja)" = "Gryps wersja $VERSION" ] || fail 'Paczka bez poprawnie wstrzykniętej wersji.'
[ -s "$BASE/share/bash-completion/completions/gryps" ] || fail 'Brak completion w paczce.'
check_owned
EDIT_RC=no
case "$MODE" in
    --yes) EDIT_RC=yes ;;
    ask)
        if [ -t 0 ] && [ -t 1 ]; then
            printf 'Dodać PATH i zwykły TAB do ~/.bashrc? [t/N] '
            answer=''; read -r answer || :
            case "$answer" in t|T|tak|y|Y|yes) EDIT_RC=yes ;; esac
        fi ;;
esac
if [ "$EDIT_RC" = yes ]; then
    [ ! -L "$RC" ] || fail 'Odmowa edycji symlinka .bashrc; użyj --no-config i skonfiguruj ręcznie.'
    [ ! -e "$RC" ] || [ -f "$RC" ] || fail '.bashrc nie jest zwykłym plikiem.'
fi
transaction
if [ "$EDIT_RC" = yes ]; then
    make_block > "$TXN/block"
    if [ -f "$STATE/block" ]; then
        strip_block
        cat "$TXN/block" >> "$TXN/rc-new"
    else
        if [ -f "$RC" ] && grep -Fq "$BEGIN" "$RC"; then fail 'Obcy/niepełny blok GRYPS; popraw .bashrc ręcznie.'; fi
        if [ -f "$RC" ] && grep -Fq "$END" "$RC"; then fail 'Obcy/niepełny blok GRYPS; popraw .bashrc ręcznie.'; fi
        : > "$TXN/rc-new"
        [ ! -f "$RC" ] || cat "$RC" > "$TXN/rc-new"
        cat "$TXN/block" >> "$TXN/rc-new"
    fi
    backup_rc
fi
MUTATING=yes
mkdir -p "$PREFIX/bin" "$PREFIX/share/bash-completion/completions" "$STATE"
cp "$BASE/bin/gryps" "$BIN"
chmod 0755 "$BIN"
cp "$BASE/share/bash-completion/completions/gryps" "$COMP"
chmod 0644 "$COMP"
sum "$BIN" > "$STATE/bin.sum"
sum "$COMP" > "$STATE/completion.sum"
if [ "$EDIT_RC" = yes ]; then
    cp "$TXN/block" "$STATE/block"
    cat "$TXN/rc-new" > "$RC"
fi
[ "$("$BIN" wersja)" = "Gryps wersja $VERSION" ] || fail 'Weryfikacja zainstalowanej wersji nie powiodła się.'
COMMITTED=yes
printf 'Zainstalowano: %s (wersja %s)\n' "$BIN" "$VERSION"
if [ "$EDIT_RC" = yes ]; then
    echo 'Otwórz nowy Git Bash. Jeśli profil nie ładuje .bashrc, dodaj ręcznie do aktywnego profilu:'
    # shellcheck disable=SC2016 # dosłowna instrukcja do profilu użytkownika
    printf '%s\n' '  [ ! -f "$HOME/.bashrc" ] || . "$HOME/.bashrc"'
    profile=''
    for candidate in .bash_profile .bash_login .profile; do
        if [ -f "$HOME/$candidate" ]; then profile="$HOME/$candidate"; break; fi
    done
    if [ -n "$profile" ]; then
        if ! grep -Eq '(source|\.)[[:space:]].*bashrc' "$profile"; then
            printf 'UWAGA: nie potwierdzono ładowania .bashrc przez %s.\n' "$profile"
        fi
    else
        echo 'UWAGA: brak profilu logowania; utwórz ~/.bash_profile z powyższą linią.'
    fi
else
    printf 'Konfiguracja bez zmian. Dodaj do PATH: %s\n' "$PREFIX/bin"
    echo 'Aby skonfigurować PATH i TAB: sh ./install.sh --yes'
fi
for ble in "$HOME/.local/share/blesh/ble.sh" "$HOME/.local/share/ble.sh/ble.sh"; do
    [ ! -f "$ble" ] || printf 'Wykryto ble.sh: %s\n' "$ble"
done
echo 'Zwykły Bash TAB działa bez dodatków. Zgodność zaawansowanego menu ble.sh z Git Bash nie jest tu potwierdzona; niczego nie pobieram.'
echo 'Diagnostyka wielu instalacji: type -a gryps'
