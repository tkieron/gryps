#!/bin/sh
set -eu
BASE=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck source=packaging/windows/common.sh
. "$BASE/common.sh"
case "${1:-}" in
    -h|--help) echo 'sh ./uninstall.sh (ten sam PREFIX co przy instalacji)'; exit 0 ;;
    '') [ "$#" -eq 0 ] || exit 2 ;;
    *) echo 'Nieznany argument.' >&2; exit 2 ;;
esac
setup
check_owned
if [ ! -d "$STATE" ]; then echo 'Brak instalacji GRYPS w tym PREFIX. Diagnostyka: type -a gryps'; exit 0; fi
EDIT_RC=no
# Reject a changed/symlink rc before taking copies or touching installed files.
if [ -f "$STATE/block" ]; then
    if [ -L "$RC" ] || [ ! -f "$RC" ]; then fail 'Nie można bezpiecznie usunąć bloku .bashrc; popraw ręcznie.'; fi
    EDIT_RC=yes
fi
transaction
if [ "$EDIT_RC" = yes ]; then strip_block; backup_rc; fi
MUTATING=yes
rm -f "$BIN" "$COMP"
if [ "$EDIT_RC" = yes ]; then cat "$TXN/rc-new" > "$RC"; fi
rm -f "$STATE/bin.sum" "$STATE/completion.sum" "$STATE/block"
rmdir "$STATE" || fail 'Pozostały obce pliki w stanie instalacji; przywracam instalację.'
COMMITTED=yes
echo 'Usunięto pliki i własny blok GRYPS; pozostałe ustawienia zachowano.'
echo 'Jeśli gryps nadal działa, sprawdź inne kopie: type -a gryps'
