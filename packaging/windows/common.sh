#!/bin/sh
# Shared offline installer helpers; this file is part of the Windows archive.
fail() { printf '%s\n' "$*" >&2; exit 1; }
setup() {
    PREFIX=${PREFIX:-"$HOME/.local"}
    case "$PREFIX" in /*) ;; *) fail 'PREFIX musi być absolutną ścieżką Git Bash, np. /c/Users/Ala/.local.' ;; esac
    case "$PREFIX$HOME" in *'
'*) fail 'HOME/PREFIX nie może zawierać znaku nowej linii.' ;; esac
    for tool in uname git bash cp chmod mkdir mktemp rm mv rmdir cksum cmp awk dd cat grep sed wc; do
        command -v "$tool" >/dev/null 2>&1 || fail "Brak narzędzia: $tool"
    done
    case "$(uname -s)" in MINGW*_NT-*|MSYS_NT-*) ;; *) fail 'Ten instalator wymaga Windows Git Bash/MSYS. W WSL użyj paczki Linux .deb.' ;; esac
    BIN="$PREFIX/bin/gryps"
    COMP="$PREFIX/share/bash-completion/completions/gryps"
    STATE="$PREFIX/share/gryps/gitbash"
    RC="$HOME/.bashrc"
    BEGIN='# >>> gryps Git Bash >>>'
    END='# <<< gryps Git Bash <<<'
    for target in "$BIN" "$COMP" "$STATE"; do
        [ ! -L "$target" ] || fail "Odmowa: dowiązanie $target"
    done
}
sum() { cksum < "$1"; }
check_owned() {
    if [ -e "$STATE" ]; then
        if [ ! -d "$STATE" ] || [ ! -f "$STATE/bin.sum" ] || [ ! -f "$STATE/completion.sum" ]; then fail 'Nieznany stan instalacji GRYPS.'; fi
        for record in bin.sum completion.sum block; do
            [ ! -L "$STATE/$record" ] || fail 'Dowiązanie w stanie instalacji.'
        done
        [ ! -e "$BIN" ] || [ "$(sum "$BIN")" = "$(cat "$STATE/bin.sum")" ] || fail "Zmieniony/obcy plik: $BIN; zachowano instalację."
        [ ! -e "$COMP" ] || [ "$(sum "$COMP")" = "$(cat "$STATE/completion.sum")" ] || fail "Zmieniony/obcy plik: $COMP; zachowano instalację."
    else
        if [ -e "$BIN" ] || [ -e "$COMP" ]; then fail 'Istnieje inna instalacja. Sprawdź type -a gryps; wybierz inny PREFIX.'; fi
    fi
}
# Quote literal paths for shell startup files; never execute a path as code.
quote() { printf "'"; printf '%s' "$1" | sed "s/'/'\\\\''/g"; printf "'"; }
make_block() {
    printf '\n%s\n' "$BEGIN"
    printf 'export PATH='
    quote "$PREFIX/bin"
    # shellcheck disable=SC2016 # literalny PATH do odczytania przy starcie powłoki
    printf ':"$PATH"\n'
    printf 'if [ -r '; quote "$COMP"; printf ' ]; then . '; quote "$COMP"; printf '; fi\n'
    printf '%s\n' "$END"
}
# Byte offsets keep all surrounding bytes, including a missing final newline.
# Our block owns the preceding newline too. A changed/foreign block is refused.
strip_block() {
    [ ! -L "$RC" ] || fail 'Odmowa edycji symlinka .bashrc; skonfiguruj ręcznie.'
    [ -f "$RC" ] || fail 'Brak .bashrc z zapisanym blokiem GRYPS.'
    offsets=$(LC_ALL=C awk -v b="$BEGIN" -v e="$END" '
        $0==b {n++; start=offset-1}
        $0==e {m++; stop=offset+length($0)+1; if(n!=1) bad=1}
        {offset+=length($0)+1}
        END {if(n!=1 || m!=1 || bad || start<0 || stop<=start) exit 1; print start, stop-start, stop}
    ' "$RC") || fail 'Niepełny/powielony blok GRYPS w .bashrc; popraw ręcznie.'
    # awk emits three decimal offsets, safe deliberate field splitting.
    # shellcheck disable=SC2086
    set -- $offsets
    dd if="$RC" bs=1 skip="$1" count="$2" 2>/dev/null > "$TXN/found-block"
    cmp -s "$TXN/found-block" "$STATE/block" || fail 'Blok GRYPS zmieniony lub należy do innego PREFIX; popraw ręcznie.'
    dd if="$RC" bs=1 count="$1" 2>/dev/null > "$TXN/rc-new"
    dd if="$RC" bs=1 skip="$3" 2>/dev/null >> "$TXN/rc-new"
}
backup_rc() {
    if [ -e "$RC" ]; then
        backup=$(mktemp "$RC.gryps-backup.XXXXXX")
        cp -p "$RC" "$backup"
        printf 'Kopia konfiguracji: %s\n' "$backup"
    fi
}
transaction() {
    mkdir -p "$PREFIX"
    TXN=$(mktemp -d "$PREFIX/.gryps-txn.XXXXXX")
    MUTATING=no
    COMMITTED=no
    trap 'finish' 0
    trap 'exit 1' HUP INT TERM
    [ ! -e "$BIN" ] || cp -p "$BIN" "$TXN/bin-old"
    [ ! -e "$COMP" ] || cp -p "$COMP" "$TXN/comp-old"
    [ ! -e "$STATE" ] || cp -R "$STATE" "$TXN/state-old"
    [ ! -e "$RC" ] || cp -p "$RC" "$TXN/rc-old"
}
finish() {
    result=$?
    trap - 0 HUP INT TERM
    if [ "$MUTATING" = yes ] && [ "$COMMITTED" != yes ]; then
        printf 'Błąd instalacji: przywracam poprzednie pliki.\n' >&2
        if [ -f "$TXN/bin-old" ]; then cp -p "$TXN/bin-old" "$BIN"; else rm -f "$BIN"; fi
        if [ -f "$TXN/comp-old" ]; then cp -p "$TXN/comp-old" "$COMP"; else rm -f "$COMP"; fi
        rm -f "$STATE/bin.sum" "$STATE/completion.sum" "$STATE/block"
        if [ -d "$TXN/state-old" ]; then cp -R "$TXN/state-old/." "$STATE/"; else rmdir "$STATE" 2>/dev/null || :; fi
        if [ "${EDIT_RC:-no}" = yes ]; then
            if [ -f "$TXN/rc-old" ]; then cp -p "$TXN/rc-old" "$RC"; else rm -f "$RC"; fi
        fi
    fi
    rm -rf "$TXN"
    exit "$result"
}
