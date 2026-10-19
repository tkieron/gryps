#!/usr/bin/env bash
# GRYPS 1.4.1 — odklep, wykipruj, tabor, podkopsaj, skitrac -> skitraj,
# katalog, pomoc i README. Prawdziwe repozytoria w katalogu tymczasowym,
# remote = lokalne repo bare. Bash 3.2+; testy PTY tylko z util-linux script.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS="${GRYPS:-$ROOT/dist/gryps}"
[ -x "$GRYPS" ] || { echo "Brak $GRYPS – odpal najpierw: make build"; exit 2; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1 NO_COLOR=1
unset GIT_CONFIG_GLOBAL GRYPS_CICHO || true
mkdir -p "$HOME"
git config --global user.name 'Tester'
git config --global user.email 'tester@example.com'
git config --global init.defaultBranch main
git config --global advice.detachedHead false
git config --global core.editor true

PASS=0 FAIL=0 SKIP=0 OUT='' ERR='' CODE=0
ok() { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; printf 'kod=%s\n%s\n' "$CODE" "$OUT" | head -12 | sed 's/^/    /'; }
skip() { SKIP=$((SKIP+1)); printf '  ⏭️  SKIP %s\n' "$1"; }
expect() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
# OUT = stdout+stderr; bez terminala na wejściu.
run() { OUT="$("$GRYPS" "$@" 2>&1 < /dev/null)"; CODE=$?; }
# OUT = tylko stdout, ERR = tylko stderr.
run_split() { "$GRYPS" "$@" > "$WORK/stdout" 2> "$WORK/stderr" < /dev/null; CODE=$?; OUT="$(cat "$WORK/stdout")"; ERR="$(cat "$WORK/stderr")"; }
contains() { [[ "$OUT" == *"$1"* ]]; }
lacks() { [[ "$OUT" != *"$1"* ]]; }
is() { [ "$1" = "$2" ]; }
zero() { [ "$CODE" -eq 0 ]; }
nonzero() { [ "$CODE" -ne 0 ]; }
code1() { [ "$CODE" -eq 1 ]; }
exists() { [ -e "$1" ]; }
missing() { [ ! -e "$1" ]; }
head_is() { [ "$(git rev-parse HEAD)" = "$1" ]; }
staged() { git diff --cached --name-only | LC_ALL=C sort | tr '\n' ' '; }
git_path_exists() { [ -e "$(git rev-parse --git-path "$1")" ]; }
no_git_path() { [ ! -e "$(git rev-parse --git-path "$1")" ]; }

HAVE_PTY=0
if command -v script >/dev/null 2>&1 && script -q -e -c true /dev/null >/dev/null 2>&1; then HAVE_PTY=1; fi
# Wywołanie w pseudo-terminalu; $1 = tekst na stdin (np. odpowiedź t/n), reszta = argumenty.
run_tty() {
    local input="$1" cmd arg
    shift
    cmd="$(printf '%q' "$GRYPS")"
    for arg in "$@"; do cmd="$cmd $(printf '%q' "$arg")"; done
    OUT="$(printf '%s' "$input" | LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm script -q -e -c "$cmd" /dev/null 2>&1 | tr -d '\r'; printf '\nrc=%s' "${PIPESTATUS[1]}")"
    tty_split
}
# Kod wyjścia z wnętrza podstawienia: ostatnia linia „rc=N”.
tty_split() { CODE="${OUT##*rc=}"; OUT="${OUT%$'\n'rc=*}"; }

N=0
repo() {
    N=$((N+1)); cd "$WORK" || exit 2
    mkdir "r$N"; cd "r$N" || exit 2
    git init -q
    printf 'baza\n' > base.txt
    git add base.txt; git commit -qm baza
}
commit() { printf '%s\n' "$2" > "$1"; git add "$1"; git commit -qm "$3"; }
remote() { git init -q --bare "$WORK/r$N.git"; git remote add origin "$WORK/r$N.git"; git push -q -u origin main 2>/dev/null; }

printf '▶ Etap A1 — odklep\n'
repo; commit a.txt 'A' 'dodaj a'; prev="$(git rev-parse HEAD~1)"
run odklep
expect 'T51 odklep: kod 0' zero
expect 'T51 HEAD = HEAD~1' head_is "$prev"
expect 'T51 zmiany commita w stagingu' is "$(staged)" 'a.txt '
expect 'T51 working tree nietknięty' is "$(cat a.txt)" 'A'

repo; commit a.txt A 'a'; commit b.txt B 'b'; prev="$(git rev-parse HEAD~2)"
run odklep 2
expect 'T52 odklep 2: kod 0' zero
expect 'T52 cofnięte dwa commity' head_is "$prev"
expect 'T52 zmiany obu commitów w stagingu' is "$(staged)" 'a.txt b.txt '

repo; commit a.txt A 'a'; printf 'C\n' > c.txt; git add c.txt
run odklep
expect 'T53 odklep przy skitranych innych zmianach' zero
expect 'T53 oba zestawy w stagingu' is "$(staged)" 'a.txt c.txt '
if [ "$HAVE_PTY" -eq 1 ]; then
    commit a.txt A2 'a2'; printf 'D\n' > d.txt; git add d.txt
    run_tty '' odklep
    expect 'T53 TTY: informacja o zmieszaniu' contains 'W stagingu leżały już inne fanty'
    expect 'T53 TTY: lista odklepanych commitów' contains 'a2'
    expect 'T53 TTY: podpowiedź ORIG_HEAD' contains 'gryps przyklep -C ORIG_HEAD'
else skip 'T53 TTY'; fi

N=$((N+1)); mkdir "$WORK/r$N"; cd "$WORK/r$N" || exit 2; git init -q
run odklep
expect 'T54 repo bez commitów: kod 1' code1
expect 'T54 nadal brak HEAD' is "$(git rev-parse -q --verify HEAD || true)" ''

repo; root="$(git rev-parse HEAD)"
run odklep
expect 'T55 root commit: kod 1' code1
expect 'T55 HEAD bez zmian' head_is "$root"
expect 'T55 gałąź istnieje' is "$(git rev-parse -q --verify refs/heads/main)" "$root"
expect 'T55 podpowiedź przyklep --amend' contains 'gryps przyklep --amend'
run odklep 3
expect 'T55 odklep 3 przy jednym commicie: kod 1' code1
expect 'T55 liczba dostępnych commitów' contains 'commitów w historii HEAD: 1'

repo; git switch -q -c bok; commit bok.txt B 'bok'; git switch -q main; commit m.txt M 'main'
git merge -q --no-ff -m scalenie bok; merged="$(git rev-parse HEAD)"
run odklep
expect 'T56 merge: kod 1' code1
expect 'T56 HEAD bez zmian' head_is "$merged"
expect 'T56 podpowiedź kasacja -m 1' contains 'gryps kasacja -m 1'
expect 'T56 staging pusty' is "$(staged)" ''

repo; commit a.txt A 'a'; remote; pushed="$(git rev-parse HEAD)"
run odklep
expect 'T57/T100 wywiezione bez -f: kod 1' code1
expect 'T57/T100 HEAD bez zmian' head_is "$pushed"
expect 'T57 podpowiedź kasacja i -f' contains 'gryps odklep -f'
run odklep -f
expect 'T57/T100 z -f: kod 0' zero
expect 'T57/T100 z -f: HEAD cofnięty lokalnie' head_is "$(git rev-parse "$pushed~1")"
expect 'T57/T100 brak push (remote bez zmian)' is "$(git --git-dir="$WORK/r$N.git" rev-parse main)" "$pushed"
commit l.txt L 'lokalny'; prev="$(git rev-parse HEAD~1)"
run odklep
expect 'T57 commit tylko lokalny po wywiezionym: kod 0' zero
expect 'T57 cofnięty lokalny' head_is "$prev"

repo; git switch -q -c bok; commit k.txt bok 'bok'; git switch -q main; commit k.txt main 'main'; at="$(git rev-parse HEAD)"
git merge -q bok >/dev/null 2>&1
run odklep
expect 'T58 w trakcie merge: kod 1' code1
expect 'T58 merge nadal w toku' git_path_exists MERGE_HEAD
expect 'T58 HEAD bez zmian' head_is "$at"
expect 'T58 nazwa operacji' contains 'merge'
git merge --abort
git cherry-pick bok >/dev/null 2>&1
run odklep
expect 'T58 w trakcie cherry-pick: kod 1' code1
expect 'T58 cherry-pick nadal w toku' git_path_exists CHERRY_PICK_HEAD
expect 'T58 podpowiedź podkopsaj --abort' contains 'gryps podkopsaj --abort'
git cherry-pick --abort

repo; commit a.txt A 'a'; commit b.txt B 'b'; at="$(git rev-parse HEAD)"
printf 'brudne\n' >> a.txt; printf 'S\n' > s.txt; git add s.txt
for bad_arg in 0 abc --hard --mixed HEAD~2 '2 3' -1; do
    # shellcheck disable=SC2086 # celowo '2 3' jako dwa argumenty
    run odklep $bad_arg
    expect "T59 odklep $bad_arg: kod 1" code1
    expect "T59 odklep $bad_arg: HEAD bez zmian" head_is "$at"
    expect "T59 odklep $bad_arg: index bez zmian" is "$(staged)" 's.txt '
    expect "T59 odklep $bad_arg: pliki bez zmian" is "$(cat a.txt)" "$(printf 'A\nbrudne')"
done

repo; GIT_AUTHOR_NAME='Autor Oryginalny' GIT_AUTHOR_EMAIL='autor@example.com' commit a.txt A 'temat oryginalny'
orig_author="$(git log -1 --format='%an <%ae>')"
run odklep
run przyklep -C ORIG_HEAD
expect 'T60 przyklep -C ORIG_HEAD: kod 0' zero
expect 'T60 ten sam temat' is "$(git log -1 --format=%s)" 'temat oryginalny'
expect 'T60 ten sam autor' is "$(git log -1 --format='%an <%ae>')" "$orig_author"

repo; commit a.txt A 'a'
run_split --cicho odklep
expect 'T61 --cicho: kod 0' zero
expect 'T61 --cicho: stdout pusty' is "$OUT" ''
expect 'T61 --cicho: stderr pusty' is "$ERR" ''
commit a.txt A2 'a2'
run_split odklep
expect 'T61 bez TTY: kod 0, stdout pusty' is "$CODE:$OUT" '0:'
expect 'T61 bez TTY: bez ozdobników' is "$ERR" ''

printf '▶ Etap A2 — wykipruj\n'
wyk_repo() {
    repo
    printf '*.log\n' > .gitignore; mkdir -p sub; printf 's\n' > sub/tracked.txt
    git add .gitignore sub/tracked.txt; git commit -qm ignore
    printf 'u\n' > u.txt; printf 'i\n' > ign.log; printf 'x\n' > sub/new.txt
}
wyk_repo
run_split wykipruj
expect 'T62 bez -n/-f, bez TTY: kod 1' code1
expect 'T62 lista na stdout' contains 'u.txt'
expect 'T62 nic nie usunięto' exists u.txt
run wykipruj -n
expect 'T63 -n: kod 0' zero
expect 'T63 -n: lista nieśledzonych' contains 'u.txt'
expect 'T63 -n: także w podkatalogu' contains 'sub/new.txt'
expect 'T63 -n: bez ignorowanych' lacks 'ign.log'
expect 'T63 -n: nic nie usunięto' exists u.txt
(cd sub && "$GRYPS" wykipruj -f >/dev/null 2>&1); CODE=$?
expect 'T64 -f z podkatalogu: kod 0' zero
expect 'T64 usunięte nieśledzone w całym repo' missing u.txt
expect 'T64 usunięte nieśledzone w podkatalogu' missing sub/new.txt
expect 'T64 ignorowane zostają' exists ign.log
expect 'T64 śledzone zostają' exists sub/tracked.txt

wyk_repo; mkdir d1 d2; printf 1 > d1/a; printf 2 > d2/b
run wykipruj -f -- d1/
expect 'T65 -f -- d1/: kod 0' zero
expect 'T65 usunięta wskazana ścieżka' missing d1
expect 'T65 reszta zostaje' exists d2/b
expect 'T65 reszta zostaje (u.txt)' exists u.txt

wyk_repo; mkdir nested; (cd nested && git init -q && printf n > n.txt)
run wykipruj -f
expect 'T66 zagnieżdżone repo zostaje' exists nested/n.txt
expect 'T66 reszta usunięta' missing u.txt

repo
run_split wykipruj
expect 'T67 brak nieśledzonych: kod 0' zero
expect 'T67 brak nieśledzonych: stdout pusty' is "$OUT" ''
run wykipruj -f
expect 'T67 -f bez nieśledzonych: kod 0' zero

wyk_repo
run wykipruj -X -f
expect 'T68 -X -f: kod 0' zero
expect 'T68 -X: usunięte ignorowane' missing ign.log
expect 'T68 -X: nieśledzone zostają' exists u.txt
printf 'i\n' > ign.log
run wykipruj -x -X
expect 'T68 -x -X: błąd użycia' code1
expect 'T68 -x -X: nic nie usunięto' exists ign.log
run wykipruj -x -f
expect 'T68 -x -f: kod 0' zero
expect 'T68 -x: usunięte ignorowane' missing ign.log
expect 'T68 -x: usunięte nieśledzone' missing u.txt

wyk_repo
for bad_arg in -ff -e -i -q --interactive; do
    run wykipruj "$bad_arg" wzorzec
    expect "T69 wykipruj $bad_arg: kod 1" code1
    expect "T69 wykipruj $bad_arg: nic nie usunięto" exists u.txt
done
expect 'T69 podpowiedź git clean' contains 'git clean'

repo; printf 1 > 'z spacja.txt'; printf 2 > 'zażółć gęślą.txt'; printf 3 > '-minus.txt'
run wykipruj -n
expect 'T70 -n: nazwa ze spacją' contains 'z spacja.txt'
expect 'T70 -n: nazwa od minusa' contains '-minus.txt'
expect 'T70 -n: nazwa Unicode (cytowana przez Git)' contains 'Would remove'
run wykipruj -f
expect 'T70 -f: usunięta nazwa ze spacją' missing 'z spacja.txt'
expect 'T70 -f: usunięta nazwa Unicode' missing 'zażółć gęślą.txt'
expect 'T70 -f: usunięta nazwa od minusa' missing '-minus.txt'

if [ "$HAVE_PTY" -eq 1 ]; then
    wyk_repo
    run_tty $'n\n' wykipruj
    expect 'T71 TTY: odmowa = kod 1' code1
    expect 'T71 TTY: odmowa = nic nie usunięto' exists u.txt
    expect 'T71 TTY: lista i ostrzeżenie' contains 'Nie odzyska ich ani Git'
    run_tty $'t\n' wykipruj
    expect 'T71 TTY: zgoda = kod 0' zero
    expect 'T71 TTY: zgoda = usunięte' missing u.txt
    expect 'T71 TTY: ignorowane zostają' exists ign.log
    expect 'T71 TTY: komunikat sukcesu' contains 'Wykiprowane'
    printf 'u\n' > u.txt
    # Zmiana listy między podglądem a zgodą: plik dochodzi, zanim padnie „t”.
    cmd="$(printf '%q' "$GRYPS") wykipruj"
    OUT="$({ sleep 2; printf 'x\n' > "$PWD/doszedl.txt"; printf 't\n'; } | LC_ALL=C.UTF-8 TERM=xterm script -q -e -c "$cmd" /dev/null 2>&1 | tr -d '\r'; printf '\nrc=%s' "${PIPESTATUS[1]}")"
    tty_split
    expect 'T71/T99 zmiana listy: kod 1' code1
    expect 'T71/T99 zmiana listy: nic nie usunięto' exists u.txt
    expect 'T71/T99 zmiana listy: komunikat' contains 'Lista się zmieniła'
    run_tty '' wykipruj -x -n
    expect 'T71 TTY -x: ostrzeżenie o ignorowanych' contains '.env'
else skip 'T71 TTY (brak util-linux script)'; fi

printf '▶ Etap B1 — tabor\n'
tabor_repo() {
    repo; git switch -q -c feat; commit f.txt F 'feat'; git switch -q main; commit m.txt M 'main'; git switch -q feat
}
tabor_repo; at="$(git rev-parse HEAD)"
run tabor
expect 'T72 tabor bez bazy: kod 1' code1
expect 'T72 brak rebase' head_is "$at"
expect 'T72 przykład w błędzie' contains 'gryps tabor main'
run tabor main
expect 'T73 tabor main: kod 0' zero
expect 'T73 commity na nowej bazie' git merge-base --is-ancestor main HEAD
expect 'T73 jeden przewieziony commit' is "$(git rev-list --count main..HEAD)" 1

tabor_repo; at="$(git rev-parse HEAD)"; printf 'luz\n' >> f.txt
run tabor main
expect 'T74 brudne drzewo: kod 1' code1
expect 'T74 brudne drzewo: HEAD bez zmian' head_is "$at"
expect 'T74 podpowiedź --autostash' contains '--autostash'
expect 'T74 zmiana nietknięta' is "$(tail -n 1 f.txt)" 'luz'
run tabor main --autostash
expect 'T74 --autostash: kod 0' zero
expect 'T74 --autostash: zmiany wróciły' is "$(tail -n 1 f.txt)" 'luz'
expect 'T74 --autostash: przewiezione' git merge-base --is-ancestor main HEAD
git checkout -q -- f.txt
printf 'nowy\n' > untracked.txt
run tabor main
expect 'T74 nieśledzone nie blokują' zero

repo; git switch -q -c feat; commit k.txt feat 'feat'; git switch -q main; commit k.txt main 'main'; git switch -q feat
at="$(git rev-parse HEAD)"
run tabor main
expect 'T75 konflikt: kod ≠ 0' nonzero
expect 'T75 rebase w toku' git_path_exists rebase-merge
expect 'T75 komunikat konfliktu' contains 'konflikt'
expect 'T75 lista plików' contains 'k.txt'
expect 'T75 podpowiedź --abort' contains 'gryps tabor --abort'
run tabor main
expect 'T75 drugi tabor w trakcie: w-toku' code1
run tabor --abort
expect 'T75 --abort: kod 0' zero
expect 'T75 --abort: stan sprzed' head_is "$at"
expect 'T75 --abort: brak rebase' no_git_path rebase-merge

tabor_repo; git rebase -q main; at="$(git rev-parse HEAD)"
run tabor main
expect 'T76 nic do przewozu: kod 0' zero
expect 'T76 HEAD bez zmian' head_is "$at"
if [ "$HAVE_PTY" -eq 1 ]; then
    run_tty '' tabor main
    expect 'T76 TTY: empty' contains 'Tabor stoi'
else skip 'T76 TTY'; fi

tabor_repo; git switch -q main; remote; git switch -q feat; git push -q -u origin feat 2>/dev/null
pushed="$(git rev-parse HEAD)"; git switch -q main; commit m2.txt M2 'main2'; git switch -q feat
if [ "$HAVE_PTY" -eq 1 ]; then
    run_tty '' tabor main
    expect 'T77 TTY: ostrzeżenie --force-with-lease' contains 'force-with-lease'
else
    run tabor main
fi
expect 'T77 tabor wywiezionych: przewiezione' git merge-base --is-ancestor main HEAD
expect 'T77 brak push' is "$(git --git-dir="$WORK/r$N.git" rev-parse feat)" "$pushed"

tabor_repo; at="$(git rev-parse HEAD)"
run tabor -i main
expect 'T78 -i bez TTY: kod 1' code1
expect 'T78 -i bez TTY: HEAD bez zmian' head_is "$at"

tabor_repo; git rebase -q main; at="$(git rev-parse HEAD)"
GIT_COMMITTER_DATE='2031-01-01T00:00:00Z' run tabor -f main
expect 'T79 -f dociera do Gita (force-rebase): kod 0' zero
expect 'T79 -f: nowe commity mimo aktualnej bazy' test "$(git rev-parse HEAD)" != "$at"
expect 'T79 -f: ta sama treść' is "$(git rev-parse 'HEAD^{tree}')" "$(git rev-parse "$at^{tree}")"

printf '▶ Etap B2 — podkopsaj\n'
pk_repo() {
    repo; git switch -q -c bok; commit s.txt S 'przemyt'; git switch -q main; commit m.txt M 'main'
}
pk_repo; at="$(git rev-parse HEAD)"
run podkopsaj
expect 'T80 bez argumentu: kod 1' code1
expect 'T80 bez argumentu: HEAD bez zmian' head_is "$at"
run podkopsaj bok
expect 'T81 jeden commit: kod 0' zero
expect 'T81 nowy commit na bieżącej' is "$(git rev-list --count "$at..HEAD")" 1
expect 'T81 zawartość przemycona' is "$(cat s.txt)" 'S'
if [ "$HAVE_PTY" -eq 1 ]; then
    git reset -q --hard "$at"
    run_tty '' podkopsaj bok
    expect 'T81 TTY: komunikat z liczbą' contains 'nowe commity: 1'
else skip 'T81 TTY'; fi

run podkopsaj bok
expect 'T82 już zastosowany: kod ≠ 0' nonzero
expect 'T82 podpowiedź --skip' contains 'gryps podkopsaj --skip'
expect 'T82 cherry-pick w toku' git_path_exists CHERRY_PICK_HEAD
run podkopsaj --skip
expect 'T82 --skip: kod 0' zero
expect 'T82 --skip: brak operacji w toku' no_git_path CHERRY_PICK_HEAD

repo; git switch -q -c bok; commit k.txt bok 'bok'; git switch -q main; commit k.txt main 'main'; at="$(git rev-parse HEAD)"
run podkopsaj bok
expect 'T83 konflikt: kod ≠ 0' nonzero
expect 'T83 komunikat konfliktu' contains 'konflikt'
expect 'T83 podpowiedź --continue' contains 'gryps podkopsaj --continue'
run podkopsaj bok
expect 'T83 drugi przemyt w trakcie: w-toku' code1
run podkopsaj --abort
expect 'T83 --abort: kod 0' zero
expect 'T83 --abort: stan sprzed' head_is "$at"
expect 'T83 --abort: plik jak przed' is "$(cat k.txt)" 'main'
expect 'T83 --abort: brak operacji w toku' no_git_path CHERRY_PICK_HEAD

repo; git switch -q -c bok; commit b1.txt 1 'b1'; git switch -q -c bok2 main; commit b2.txt 2 'b2'
git merge -q --no-ff -m 'scal bok' bok; merge="$(git rev-parse HEAD)"; git switch -q main; at="$(git rev-parse HEAD)"
run podkopsaj "$merge"
expect 'T84 merge bez -m: kod 1' code1
expect 'T84 merge bez -m: przed Gitem' no_git_path CHERRY_PICK_HEAD
expect 'T84 merge bez -m: HEAD bez zmian' head_is "$at"
expect 'T84 podpowiedź -m 1' contains 'gryps podkopsaj -m 1'
run podkopsaj -m 1 "$merge"
expect 'T84 z -m 1: kod 0' zero
expect 'T84 z -m 1: przemycona zawartość bok' exists b1.txt

pk_repo; at="$(git rev-parse HEAD)"
run podkopsaj --no-commit bok
expect 'T85 --no-commit: kod 0' zero
expect 'T85 brak nowego commita' head_is "$at"
expect 'T85 zmiany w stagingu' is "$(staged)" 's.txt '
if [ "$HAVE_PTY" -eq 1 ]; then
    git reset -q --hard "$at"
    run_tty '' podkopsaj -n bok
    expect 'T85 TTY: bez słowa o przyklepaniu' contains 'jeszcze nieprzyklepany'
    expect 'T85 TTY: nie ogłasza commitów' lacks 'nowe commity'
else skip 'T85 TTY'; fi

printf '▶ Etap C — wspólne, pomoc, katalog\n'
repo; at="$(git rev-parse HEAD)"
for pair in odklepp:odklep odklp:odklep odklap:odklep 'odklęp:odklep' wykipuj:wykipruj wykiperuj:wykipruj \
            wykipr:wykipruj tabur:tabor tbor:tabor podkopsj:podkopsaj podkopsa:podkopsaj 'skitrać:skitraj'; do
    run "${pair%%:*}"
    expect "T86 literówka ${pair%%:*}: kod 1" code1
    expect "T86 literówka ${pair%%:*} -> ${pair#*:}" contains "gryps ${pair#*:}"
done
expect 'T86 literówki niczego nie wykonały' head_is "$at"
run 'odklęp'
expect 'T86 polskie znaki nie znikają z nazwy' contains 'Nieznana komenda: odklęp'

CAT="$ROOT/completions/gryps-catalog.tsv"
names="$(grep -v '^#' "$CAT" | cut -d'|' -f2)"
expect 'T87/T109 katalog: 44 pozycje' is "$(printf '%s\n' "$names" | wc -l | tr -d ' ')" 44
expect 'T87 katalog: unikalne nazwy' is "$(printf '%s\n' "$names" | sort | uniq -d)" ''
expect 'T109 katalog: dokładnie jedno skitraj' is "$(printf '%s\n' "$names" | grep -c '^skitraj$')" 1
expect 'T109 katalog: zero skitrac' is "$(grep -c skitrac "$CAT")" 0
embedded="$(sed -n "/^    cat <<'CATALOG'$/,/^CATALOG$/p" "$ROOT/bin/gryps" | sed '1d;$d')"
expect 'T87 katalog w bin/gryps = gryps-catalog.tsv' is "$embedded" "$(grep -v '^#' "$CAT")"
words="$(sed -n "s/^_gryps_words='\(.*\)'$/\1/p" "$ROOT/completions/gryps.bash")"
expect 'T87 Bash: _gryps_words w kolejności katalogu' is "$words" "$(printf '%s\n' "$names" | tr '\n' ' ' | sed 's/ $//')"
zsh_names="$(sed -n "s/^    '\([a-z]*\):.* — .*'$/\1/p" "$ROOT/completions/_gryps")"
expect 'T87 Zsh: te same nazwy w kolejności katalogu' is "$zsh_names" "$names"
missing_meta=''
for name in $names; do
    grep -q "^        $name) REPLY='\[" "$ROOT/completions/gryps.bash" || missing_meta="$missing_meta $name"
    git_part="$(grep "|$name|" "$CAT" | cut -d'|' -f4)"
    grep -q "^        $name) REPLY='.* — $(printf '%s' "$git_part" | sed 's/[][\.*^$]/\\&/g')' ;;" "$ROOT/completions/gryps.bash" || missing_meta="$missing_meta $name(git)"
    grep -q "^    '$name:.* — $(printf '%s' "$git_part" | sed 's/[][\.*^$]/\\&/g')'$" "$ROOT/completions/_gryps" || missing_meta="$missing_meta $name(zsh)"
done
expect 'T87 ble.sh i Zsh: opis każdej pozycji kończy się Gitem z katalogu' is "$missing_meta" ''

run_split pomoc
for name in odklep wykipruj tabor podkopsaj skitraj kartoteka ksywa meta meldunek; do
    expect "T88/T96 pomoc zawiera $name" contains "$name"
done
expect 'T88 pomoc: git reset --soft' contains 'git reset --soft'
expect 'T88 pomoc: git clean' contains 'git clean'
expect 'T88 pomoc: git rebase' contains 'git rebase'
expect 'T88 pomoc: git cherry-pick' contains 'git cherry-pick'
expect 'T107 pomoc bez skitrac' lacks 'skitrac'
run_split podpowiedzi
for name in odklep wykipruj tabor podkopsaj skitraj kartoteka; do
    expect "T88/T96 podpowiedzi zawierają $name" contains "  $name "
done
expect 'T88 podpowiedzi: git reset --soft na końcu' contains 'git reset --soft HEAD~N'
expect 'T107 podpowiedzi bez skitrac' lacks 'skitrac'
expect 'T88 podpowiedzi: wywozka w CODZIENNEJ ROBOCIE, przed kartoteką' \
    test "$(printf '%s\n' "$OUT" | grep -n 'wywozka' | cut -d: -f1)" -lt "$(printf '%s\n' "$OUT" | grep -n 'KARTOTEKA' | cut -d: -f1)"
for pair in odklep:'git reset --soft' wykipruj:'git clean' tabor:'git rebase' podkopsaj:'git cherry-pick' skitraj:'git add'; do
    run kmina "${pair%%:*}"
    expect "T88/T107 kmina ${pair%%:*}" contains "${pair#*:}"
done
run kmina kasacja
expect 'T88 kmina kasacja wskazuje odklep' contains 'gryps odklep'
run kmina skitrac
expect 'T107 kmina skitrac: kod ≠ 0' nonzero
expect 'T107 kmina skitrac: podpowiedź skitraj' contains 'skitraj'
run skitrac -h
expect 'T107 skitrac -h: kod ≠ 0' nonzero
MAN="$ROOT/man/gryps.1"
for pair in odklep:'git reset \-\-soft' wykipruj:'git clean' tabor:'git rebase' podkopsaj:'git cherry\-pick' skitraj:'git add' kartoteka:'show\-origin'; do
    expect "T88/T107 man: ${pair%%:*}" grep -qF -e ".BR ${pair%%:*} " -e ".B ${pair%%:*}" -e "\\fB${pair%%:*}\\fR" "$MAN"
    expect "T88 man: ${pair#*:}" grep -qF "${pair#*:}" "$MAN"
done
expect 'T107 man: skitrac tylko jako informacja o migracji' is "$(grep skitrac "$MAN" | grep -vc 'dawniej\|1\.4\.1')" 0

if [ "$HAVE_PTY" -eq 1 ]; then
    repo; printf 'u\n' > nowy.txt; printf 'zmiana\n' >> base.txt
    run_tty '' kipisz -f
    expect 'T89 TTY: kipisz -f z nieśledzonymi -> wykipruj' contains 'gryps wykipruj'
    expect 'T89 TTY: kipisz nie usuwa nieśledzonych' exists nowy.txt
else skip 'T89 TTY'; fi
repo; printf 'u\n' > nowy.txt
run kipisz -f
expect 'T89 bez TTY: brak podpowiedzi wykipruj' lacks 'wykipruj'
expect 'T89 kipisz bez git clean' exists nowy.txt

printf '▶ Etap C — README, CHANGELOG, wersja\n'
README="$ROOT/README.md"
dict="$(awk '/^## Pełen słownik komend/{on=1; next} on && /^## /{exit} on' "$README")"
# shellcheck disable=SC2016 # literalne backticki Markdown
rows="$(printf '%s\n' "$dict" | sed -n 's/^| `\([a-z]*\)[ `].*/\1/p')"
expect 'T92 README: słownik ma 44 wiersze' is "$(printf '%s\n' "$rows" | wc -l | tr -d ' ')" 44
expect 'T92 README: każda nazwa dokładnie raz' is "$(printf '%s\n' "$rows" | sort)" "$(printf '%s\n' "$names" | sort)"
expect 'T92/T109 README: brak skitrac w słowniku' is "$(printf '%s\n' "$dict" | grep -c skitrac)" 0
line_of() { grep -n "$1" "$README" | head -n 1 | cut -d: -f1; }
expect 'T93 README: słownik przed historią zmian' test "$(line_of '^## Pełen słownik komend')" -lt "$(line_of '^## Co nowego')"
expect 'T93 README: słownik przed instalacją' test "$(line_of '^## Pełen słownik komend')" -lt "$(line_of '^## Instalacja')"
expect 'T93 README: brak starej tabeli 1.3.0' is "$(grep -c '^## GRYPS 1\.3' "$README")" 0
expect 'T93 README: jeden słownik' is "$(grep -c '^## .*[Ss]łownik komend' "$README")" 1
expect 'T93 README: gwiazdka dopiero po dokumentacji' test "$(line_of '⭐')" -gt "$(line_of '^## Rozwój')"
CL="$ROOT/CHANGELOG.md"
expect 'T94 CHANGELOG: 1.4.1 nad 1.4.0' test "$(grep -n '^## \[1\.4\.1\]' "$CL" | cut -d: -f1)" -lt "$(grep -n '^## \[1\.4\.0\]' "$CL" | cut -d: -f1)"
for v in 1.3.6 1.3.5 1.3.4 1.3.3 1.3.2; do expect "T94 CHANGELOG zachował $v" grep -q "^## .*$v" "$CL"; done
expect 'T95 brak __GH_USER__' is "$(grep -c '__GH_USER__' "$README")" 0
expect 'T95 brak gryps-1.3.0-macos' is "$(grep -c 'gryps-1\.3\.0-macos' "$README")" 0
broken=''
while IFS= read -r link; do
    [ -e "$ROOT/$link" ] || broken="$broken $link"
done < <(grep -o '](\([^)#:]*\))' "$README" | sed 's/^](//; s/)$//')
expect 'T95 lokalne linki README istnieją' is "$broken" ''
expect 'T110 README opisuje migrację skitrac -> skitraj' grep -q 'skitrac.*skitraj' "$README"
expect 'T110 CHANGELOG opisuje migrację' grep -q 'skitrac.*skitraj' "$CL"
expect 'T102 VERSION = 1.4.1' is "$(cat "$ROOT/VERSION")" 1.4.1
run wersja
expect 'T102 gryps wersja = 1.4.1' is "$OUT" 'Gryps wersja 1.4.1'
expect 'T102 SDD w repo' exists "$ROOT/docs/GRYPS_v1.4.1_SDD.md"

printf '▶ Etap C — skitraj (zmiana nazwy)\n'
repo; mkdir -p src sub; printf 1 > src/plik; printf 2 > src/inny; printf 3 > sub/x; git add src sub; git commit -qm pliki
printf 'm\n' >> base.txt; rm src/inny; printf n > nowy.txt; printf y > sub/y
(cd sub && "$GRYPS" skitraj >/dev/null 2>&1); CODE=$?
expect 'T103 skitraj bez argumentów: kod 0' zero
expect 'T103 skitraj = git add -A z całego repo' is "$(staged)" 'base.txt nowy.txt src/inny sub/y '
git reset -q
(cd sub && "$GRYPS" skitraj . >/dev/null 2>&1)
expect 'T104 skitraj . w podkatalogu: tylko podkatalog' is "$(staged)" 'sub/y '
git reset -q; printf 'z\n' >> src/plik
run skitraj -- src/plik
expect 'T104 skitraj -- src/plik: tylko ten plik' is "$(staged)" 'src/plik '
git reset -q
run skitraj -u
expect 'T105 skitraj -u: bez nowych plików' is "$(staged)" 'base.txt src/inny src/plik '
git reset -q
run skitraj -n -A
expect 'T105 skitraj --dry-run: nic nie skitrane' is "$(staged)" ''
run skitraj nie-ma-takiego
expect 'T105 kod błędu git add zachowany' is "$CODE" 128
before_index="$(staged)"
run_split skitrac .
expect 'T106 skitrac: kod ≠ 0' nonzero
expect 'T106 skitrac: staging bez zmian' is "$(staged)" "$before_index"
expect 'T106 skitrac: sugestia skitraj' test -n "$(printf '%s' "$ERR" | grep 'gryps skitraj \.')"
expect 'T110 skitrac w potoku: bez emoji' test -z "$(printf '%s' "$ERR" | grep '🚨')"
run_split --cicho skitrac
expect 'T110 --cicho skitrac: kod ≠ 0, nic na stdout' is "$CODE:$OUT" '1:'
if [ "$HAVE_PTY" -eq 1 ]; then
    run_tty '' skitrac .
    expect 'T106 TTY: stara bajera' contains 'STARA BAJERA'
    expect 'T106 TTY: nic nie ruszone' contains 'Nic nie ruszyłem'
    expect 'T106 TTY: staging bez zmian' is "$(staged)" "$before_index"
    run_tty '' skitraj src/plik
    expect 'T103 TTY: komunikat skitraj' contains 'Skitrane'
else skip 'T106 TTY'; fi

printf '▶ Bez TTY i --cicho (T101)\n'
repo; commit a.txt A 'a'; printf u > u.txt
for cmd in 'odklep' 'wykipruj -n' 'skitraj' 'podpowiedzi'; do
    # shellcheck disable=SC2086 # celowo dzielimy komendę na słowa
    run_split --cicho $cmd
    expect "T101 --cicho $cmd: bez żartów" test -z "$(printf '%s' "$ERR" | grep '\[GRYPS\]')"
done
run_split wykipruj
expect 'T101 bez TTY: brak promptu [t/N]' test -z "$(printf '%s' "$ERR" | grep '\[t/N\]')"

printf 'Testy 1.4.1: %s/%s zaliczonych' "$PASS" "$((PASS+FAIL))"
[ "$SKIP" -eq 0 ] || printf ', pominiętych: %s' "$SKIP"
printf '\n'
[ "$FAIL" -eq 0 ]
