#!/bin/sh
set -eu
PREFIX=${PREFIX:-"$HOME/.local"}
case "$PREFIX" in
    /*) ;;
    *) echo "PREFIX musi być absolutną ścieżką." >&2; exit 2 ;;
esac
rm -f "$PREFIX/bin/gryps" \
    "$PREFIX/share/man/man1/gryps.1" \
    "$PREFIX/share/zsh/site-functions/_gryps" \
    "$PREFIX/share/bash-completion/completions/gryps"
echo "Usunięto pliki GRYPS z $PREFIX."
echo "Jeśli dodałeś konfigurację Zsh, usuń blok gryps macOS z ~/.zshrc ręcznie."
