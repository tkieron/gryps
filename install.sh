#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PREFIX=${PREFIX:-"$HOME/.local"}
AUTO=no
case "${1:-}" in --yes) AUTO=yes;; "" ) ;; *) echo "Użycie: sh install.sh [--yes]"; exit 2;; esac
ask() {
  if [ "$AUTO" = yes ]; then return 0; fi
  if [ ! -t 0 ]; then return 1; fi
  printf "%s [t/N]: " "$1"
  IFS= read -r answer || return 1
  case "$answer" in t|T|tak|TAK|y|Y|yes) return 0;; *) return 1;; esac
}
append_once() {
  file=$1; marker=$2; content=$3
  touch "$file"
  if ! grep -Fq "$marker" "$file"; then printf '\n%s\n' "$content" >> "$file"; fi
}
[ -f "$ROOT/bin/gryps" ] || { echo "Brak plików GRYPS w paczce."; exit 1; }
[ -f "$ROOT/VERSION" ] || { echo "Brak pliku VERSION — instalacja przerwana." >&2; exit 1; }
VERSION=$(cat "$ROOT/VERSION")
case "$VERSION" in
  *[!0-9.]*|.*|*..*|*.|"") echo "Niepoprawny numer wersji: $VERSION" >&2; exit 1 ;;
esac
command -v git >/dev/null || { echo "Brak Git. Zainstaluj Git i spróbuj ponownie."; exit 1; }
command -v bash >/dev/null || { echo "Brak Bash."; exit 1; }
mkdir -p "$PREFIX/bin" "$PREFIX/share/bash-completion/completions" "$PREFIX/share/zsh/site-functions" "$PREFIX/share/man/man1"
# Zamiast kopiować surowy skrypt (__VERSION__ -> dev), wstrzykujemy numer wersji.
_tmp_gryps=$(mktemp)
trap 'rm -f "$_tmp_gryps"' EXIT HUP INT TERM
sed "s/__VERSION__/$VERSION/g" "$ROOT/bin/gryps" > "$_tmp_gryps"
install -m755 "$_tmp_gryps" "$PREFIX/bin/gryps"
rm -f "$_tmp_gryps"
trap - EXIT HUP INT TERM
install -m644 "$ROOT/completions/gryps.bash" "$PREFIX/share/bash-completion/completions/gryps"
install -m644 "$ROOT/completions/_gryps" "$PREFIX/share/zsh/site-functions/_gryps"
install -m644 "$ROOT/man/gryps.1" "$PREFIX/share/man/man1/gryps.1"
echo "✅ GRYPS $VERSION zainstalowany w $PREFIX/bin/gryps"
case "$(basename "${SHELL:-/bin/bash}")" in
  zsh)
    append_once "$HOME/.zshrc" '# >>> gryps installer >>>' '# >>> gryps installer >>>
export PATH="$HOME/.local/bin:$PATH"
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
autoload -Uz compinit; compinit
zstyle ":completion:*" group-name ""
zstyle ":completion:*:descriptions" format "%B%d%b"
zstyle ":completion:*" menu select
# <<< gryps installer <<<'
    echo "Zsh: skonfigurowano podpowiedzi i grupy."
    ;;
  *)
    append_once "$HOME/.bashrc" '# >>> gryps installer >>>' '# >>> gryps installer >>>
export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/share/bash-completion/completions/gryps" ]; then
  source "$HOME/.local/share/bash-completion/completions/gryps"
fi
# <<< gryps installer <<<'
    echo "Bash: skonfigurowano TAB."
    if ask "Doinstalować polecane ble.sh (rozbudowane, pionowe podpowiedzi)?"; then
      if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "ble.sh już jest zainstalowane."
      else
        if ! command -v curl >/dev/null || ! command -v tar >/dev/null; then
          echo "⚠️ Do ble.sh wymagane są curl i tar. GRYPS działa bez rozszerzenia."
        else
          tmp=$(mktemp -d)
          echo "Pobieram ble.sh z oficjalnego repozytorium..."
          if curl -fLsS --connect-timeout 10 --max-time 90 \
            https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz -o "$tmp/ble.tar.xz" &&
             tar -xJf "$tmp/ble.tar.xz" -C "$tmp"; then
            blefile=$(find "$tmp" -type f -name ble.sh -print -quit)
            if [ -n "$blefile" ]; then
              mkdir -p "$HOME/.local/share/blesh"
              cp -R "$(dirname "$blefile")/." "$HOME/.local/share/blesh/"
              echo "✅ ble.sh pobrane."
            else
              echo "⚠️ Archiwum nie zawiera ble.sh. Pomijam rozszerzenie."
            fi
          else
            echo "⚠️ Nie udało się pobrać ble.sh. GRYPS pozostaje sprawny."
          fi
          rm -rf "$tmp"
        fi
      fi
      if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
        append_once "$HOME/.bashrc" '# >>> gryps ble.sh >>>' '# >>> gryps ble.sh >>>
[[ $- == *i* ]] && source "$HOME/.local/share/blesh/ble.sh"
# <<< gryps ble.sh <<<'
        append_once "$HOME/.blerc" '# >>> gryps smart tab >>>' '# >>> gryps smart tab >>>
ble-import core-complete -C '"'"'bleopt complete_menu_style=desc menu_desc_multicolumn_width='"'"'
# <<< gryps smart tab <<<'
        echo "ble.sh: ustawiono pionowe opisy."
      fi
    fi
    ;;
esac
echo "Otwórz nowy terminal i sprawdź: gryps wersja; gryps podpowiedzi"
