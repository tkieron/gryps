#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
source "$ROOT/completions/gryps.bash"
PASS=0 FAIL=0
ok() { printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
fail() { printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }
expect() { local name="$1"; shift; if "$@"; then ok "$name"; else fail "$name"; fi; }
contains() { local v; for v in "${COMPREPLY[@]}"; do [[ "$v" == "$1" ]] && return 0; done; return 1; }
not_contains() { local v; for v in "${COMPREPLY[@]}"; do [[ "$v" == "$1" ]] && return 1; done; return 0; }
complete_words() { COMP_WORDS=("$@"); COMP_CWORD=$((${#COMP_WORDS[@]}-1)); _gryps_completions; }
complete_words gryps kw
expect 'Bash uzupełnia kwity' contains kwity
expect 'Bash bez opisów w nazwach' not_contains 'kwity — git diff'
complete_words gryps pod
expect 'Bash podpowiada nowe polecenie' contains podpowiedzi
complete_words gryps --cicho kap
expect 'Bash po --cicho' contains kapus
complete_words gryps kmina cyn
expect 'Bash podpowiada argument kmina' contains cynk
# Active ble.sh can accept descriptions separately. Mock its API without installing ble.sh.
_ble_complete_yield_varnames=(ACTION CAND INSERT DATA PREFIX_LEN)
cand_count=0
ble_seen=()
function ble/complete/cand/yield.initialize { :; }
function ble/complete/cand/yield { ble_seen+=("$2|$3"); cand_count=$((cand_count+1)); }
complete_words gryps kap
if [[ ${COMPREPLY[*]} == '' && ${ble_seen[*]} == *'kapus|'*'git blame'* ]]; then ok 'ble.sh: osobno kandydat i opis zakończony Git'; else fail 'ble.sh: osobno kandydat i opis zakończony Git'; fi
unset cand_count
unset -f 'ble/complete/cand/yield.initialize' 'ble/complete/cand/yield'
# Catalog guarantees stable, unique names with last field = Git translation (except help/alias).
if awk -F'|' 'BEGIN{e=0} !/^#/ { if (NF!=4 || seen[$2]++ || $4 !~ /^(git |gryps )/) e=1; count++ } END {if (count!=36) e=1; exit e}' "$ROOT/completions/gryps-catalog.tsv"; then ok '36 unikalnych pozycji i mapowanie Git'; else fail 'katalog grypsów'; fi
for name in kwity odkitraj kapus dziara cynk kasacja uklady odkrec; do
  if grep -q "^.*|$name|" "$ROOT/completions/gryps-catalog.tsv" && grep -q "^[[:space:]]*$name) REPLY=" "$ROOT/completions/gryps.bash" && grep -q "'$name:" "$ROOT/completions/_gryps"; then ok "Katalog spójny dla $name"; else fail "Katalog spójny dla $name"; fi
done
# Zsh group declarations and tags must exist for every group.
for grp in robota cele dochodzenie dziupla ratunek pomoc aliasy; do
  if grep -q "gryps_$grp=(" "$ROOT/completions/_gryps" && grep -q "_gryps_line_group gryps-$grp " "$ROOT/completions/_gryps"; then ok "Zsh: osobna grupa $grp"; else fail "Zsh: grupa $grp"; fi
done
# CLI cheat sheet without .git and with Git equivalence at end.
"$ROOT/dist/gryps" podpowiedzi > "$WORK/help"
if grep -q 'CODZIENNA ROBOTA' "$WORK/help" && grep -q 'git blame$' "$WORK/help" && grep -q 'git stash push -u$' "$WORK/help"; then ok 'Polecenie podpowiedzi poza repo'; else fail 'Polecenie podpowiedzi'; fi
if grep -q "zstyle ':completion:\*' group-name ''" "$ROOT/packaging/macos/install.sh"; then ok 'Instalator Mac grupuje podpowiedzi'; else fail 'Mac grupowanie'; fi
# Pionowe listy i zachowanie porządku grup w każdym z trzech trybów.
if complete -p gryps | grep -q -- '-o nosort'; then ok 'Bash: kolejność grup bez sortowania'; else fail 'Bash: nosort'; fi
if grep -q 'menu_desc_multicolumn_width=' "$ROOT/completions/gryps.blerc-example"; then ok 'ble.sh: jedna kolumna'; else fail 'ble.sh: jedna kolumna'; fi
if grep -q 'compadd -Q -l -V' "$ROOT/completions/_gryps" && grep -q -- '-X "$heading"' "$ROOT/completions/_gryps"; then ok 'Zsh: wiersze i nagłówki'; else fail 'Zsh: wiersze i nagłówki'; fi
if grep -q 'completion-display-width 0' "$ROOT/docs/GRYPS-TAB-1.3.3.md"; then ok 'Bash: instrukcja pionowej listy'; else fail 'Bash: instrukcja pionowej listy'; fi
printf 'Smart TAB: %s/%s zaliczonych\n' "$PASS" "$((PASS+FAIL))"
[[ "$FAIL" -eq 0 ]]
