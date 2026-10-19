#!/bin/sh
# Offline, per-user installer for Gryps on macOS (works on Linux too).
set -eu

BASE_DIR=$(CDPATH="" cd "$(dirname "$0")" && pwd)
PREFIX=${PREFIX:-"$HOME/.local"}
CONFIGURE_ZSH=no

usage() {
    cat <<'HELP'
Użycie: ./install.sh [--configure-zsh]

Instalacja w ~/.local bez sudo i bez Homebrew.
  --configure-zsh   dopisz PATH i zsh completion do ~/.zshrc
  PREFIX=/inna/sciezka ./install.sh    własny katalog docelowy
HELP
}
for arg in "$@"; do
    case "$arg" in
        --configure-zsh) CONFIGURE_ZSH=yes ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Nieznany argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

case "$PREFIX" in
    /*) ;;
    *) echo "PREFIX musi być absolutną ścieżką." >&2; exit 2 ;;
esac
if [ "$CONFIGURE_ZSH" = yes ] && [ "$PREFIX" != "$HOME/.local" ]; then
    echo "--configure-zsh działa tylko dla domyślnego PREFIX=~/.local" >&2
    exit 2
fi
if ! command -v git >/dev/null 2>&1; then
    echo "Brak Git. Na macOS uruchom: xcode-select --install" >&2
    exit 1
fi
if ! command -v bash >/dev/null 2>&1; then
    echo "Brak Bash. Jest dołączony do macOS." >&2
    exit 1
fi

mkdir -p "$PREFIX/bin" "$PREFIX/share/man/man1" \
    "$PREFIX/share/zsh/site-functions" "$PREFIX/share/bash-completion/completions"
install -m 0755 "$BASE_DIR/bin/gryps" "$PREFIX/bin/gryps"
install -m 0644 "$BASE_DIR/share/man/man1/gryps.1" "$PREFIX/share/man/man1/gryps.1"
install -m 0644 "$BASE_DIR/share/zsh/site-functions/_gryps" "$PREFIX/share/zsh/site-functions/_gryps"
install -m 0644 "$BASE_DIR/share/bash-completion/completions/gryps" "$PREFIX/share/bash-completion/completions/gryps"

echo "Zainstalowano: $PREFIX/bin/gryps"
"$PREFIX/bin/gryps" wersja

if [ "$CONFIGURE_ZSH" = yes ]; then
    RC="$HOME/.zshrc"
    MARK='# >>> gryps macOS >>>'
    if [ -f "$RC" ] && grep -Fq "$MARK" "$RC"; then
        echo "Konfiguracja istnieje już w $RC (bez zmian)."
    else
        # shellcheck disable=SC2016 # literalne $HOME/$PATH zapisywane do pliku rc
        {
            printf '\n%s\n' "$MARK"
            printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"'
            printf '%s\n' 'fpath=("$HOME/.local/share/zsh/site-functions" $fpath)'
            printf '%s\n' 'autoload -Uz compinit; compinit'
            printf '%s\n' '# GRYPS: lista pionowa i stała kolejność grup we własnym completion'
            printf '%s\n' "zstyle ':completion:*' group-name ''"
            printf '%s\n' "zstyle ':completion:*:descriptions' format '%B%d%b'"
            printf '%s\n' "zstyle ':completion:*' menu select"
            printf '%s\n' '# <<< gryps macOS <<<'
        } >> "$RC"
        echo "Dopisano konfigurację PATH i TAB do $RC"
    fi
    echo "Otwórz nowy terminal albo: source ~/.zshrc"
else
    echo "Dodaj $PREFIX/bin do PATH, jeśli jeszcze nie jest dostępny."
    echo "Aby ustawić automatycznie Zsh: ./install.sh --configure-zsh"
fi
