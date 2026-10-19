#!/usr/bin/env bash
# GRYPS 1.3: isolate Git state; verify actual results, codes and stdout.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS="${GRYPS:-$ROOT/dist/gryps}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1 NO_COLOR=1 LC_ALL=C
mkdir -p "$HOME"
git config --global user.name Test
git config --global user.email test@example.com
git config --global init.defaultBranch main
PASS=0 FAIL=0 OUT='' CODE=0
run() { OUT="$("$GRYPS" "$@" 2>&1 < /dev/null)"; CODE=$?; }
ok() { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; printf '%s\n' "$OUT" | head -5 | sed 's/^/    /'; }
assert() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
is() { [ "$1" = "$2" ]; }
contains() { [[ "$OUT" == *"$1"* ]]; }
nonzero() { [ "$CODE" -ne 0 ]; }
zero() { [ "$CODE" -eq 0 ]; }
repo() { cd "$WORK" || exit 1; mkdir -p "$1"; cd "$1" || exit 1; git init -q; echo first > one.txt; git add .; git commit -qm base; }

printf '▶ Bezpieczne wyjście, tryby maszynowe, słownik\n'
run kwty; assert 'nieznany gryps zwraca błąd' nonzero; assert 'podpowiedź przy literówce' contains 'gryps kwity'
# literalny payload do testu injection
# shellcheck disable=SC2016
run '$(touch /tmp/NO-SUCH-FILE)'; assert 'nazwa nie uruchamia shell' nonzero
run --cicho pomoc; assert '--cicho przed komendą działa' zero
run kmina kwity; assert 'kmina kwity istnieje' contains 'git diff'
run kmina odkrec; assert 'kmina odkrec istnieje' contains 'git restore'
run pomoc; for x in kwity odkitraj kapus dziara cynk kasacja uklady odkrec; do assert "pomoc zawiera $x" contains "$x"; done

printf '▶ Nowy repo bez HEAD (odkitraj)\n'
mkdir -p "$WORK/unborn"; cd "$WORK/unborn" || exit 1; git init -q
printf test > 'nowy plik.txt'; git add 'nowy plik.txt'
run odkitraj; assert 'odkitraj przed pierwszym commitem działa' zero
assert 'index pusty przed pierwszym commitem' is "$(git ls-files)" ''
assert 'plik fizycznie istnieje' test -f 'nowy plik.txt'
cd "$WORK/unborn" || exit 1; git add 'nowy plik.txt'; run odkitraj -- 'nowy plik.txt'; assert 'odkitraj pathspec w unborn' zero

printf '▶ Repo standardowe: kwity i odkitraj\n'
repo basic
printf unstaged >> one.txt
printf staged > 'nowy plik.txt'; git add 'nowy plik.txt'
run kwity; assert 'kwity wykonuje się' zero; assert 'kwity pokazuje unstaged' contains '+unstaged'; assert 'kwity pokazuje staged' contains '+staged'
run kwity --staged; assert 'kwity --staged tylko staged' zero; assert 'kwity --staged zawiera staged' contains '+staged'
if ! contains '+unstaged'; then ok '--staged bez unstaged'; else bad '--staged bez unstaged'; fi
run kwity --stat -- 'nowy plik.txt'; assert 'kwity --stat z pathspec' zero
run kwity --exit-code; assert 'kwity --exit-code status 1' is "$CODE" 1
"$GRYPS" lipo --porcelain -z > "$WORK/gryps_z" 2> "$WORK/gryps_e"
git status --porcelain -z > "$WORK/git_z"
assert 'lipo --porcelain -z identyczne bajty' cmp -s "$WORK/gryps_z" "$WORK/git_z"
assert 'lipo --porcelain -z nie zaśmieca stderr' is "$(wc -c < "$WORK/gryps_e" | tr -d ' ')" 0
run odkitraj -- 'nowy plik.txt'; assert 'odkitraj jeden plik' zero
assert 'unstaged zostaje nienaruszony' test -f 'nowy plik.txt'
assert 'nowy plik już nie staged' is "$(git diff --cached --name-only)" ''
printf stage > one.txt; git add one.txt
mkdir sub; cd sub || exit 1
run odkitraj; assert 'odkitraj z podkatalogu' zero
assert 'odkitraj czyści cały index' is "$(git diff --cached --name-only)" ''
cd .. || exit 1

printf '▶ Odkrec - bez strat w stage\n'
printf staged-new > one.txt; git add one.txt
printf 'unstaged-new\n' >> one.txt
run odkrec; assert 'odkrec bez ścieżki odmawia' nonzero
run odkrec -- one.txt; assert 'odkrec bez TTY odmawia' nonzero
assert 'odmowa nie usuwa pliku' grep -q unstaged-new one.txt
run odkrec -f -- one.txt; assert 'odkrec -f' zero
assert 'odkrec usunął tylko unstaged' is "$(cat one.txt)" 'staged-new'
assert 'odkrec zachował staged' is "$(git show :one.txt)" 'staged-new'
run odkrec -f -- one.txt; assert 'odkrec bez zmian jest no-op' zero

printf '▶ Dziupla: ignored, untracked, pathspec i -a\n'
printf 'ignored.bin\n' > .gitignore
git add .gitignore; git commit -qm ignored
printf 'nowy\n' > nieznany.txt; printf 'ignored\n' > ignored.bin; printf tracked >> one.txt
run dziupla; assert 'dziupla -u bez argumentów' zero
assert 'tracked + untracked schowane' test ! -e nieznany.txt
assert 'ignored pozostaje' test -f ignored.bin
run wyjmij; assert 'wyjmij restore' zero
assert 'untracked wrócił' test -f nieznany.txt
run dziupla --no-include-untracked; assert '--no-include-untracked zaakceptowane' zero
assert '--no-include-untracked pozostawił nowy plik' test -f nieznany.txt
run wyjmij; assert 'wyjmij po no-include' zero
printf second > drugi.txt
run dziupla -- nieznany.txt; assert 'dziupla pathspec działa' zero
assert 'dziupla pathspec nie zabrała drugiego pliku' test -f drugi.txt
assert 'dziupla pathspec zabrała właściwy plik' test ! -e nieznany.txt
run wyjmij; assert 'wyjmij po pathspec' zero
run dziupla --all; assert '--all chowa ignored' zero
assert '--all zabiera ignored' test ! -e ignored.bin
run wyjmij; assert 'wyjmij po --all' zero

printf '▶ Historia, tagi, zdalne, kapuś\n'
run kapus; assert 'kapus wymaga pliku' nonzero
run kapus -L 1,1 -- one.txt; assert 'kapus z zakresem' zero; assert 'kapus wyświetla autora lub Not Committed Yet' contains 'Not Committed Yet'
run dziara v1.3-test; assert 'dziara tworzy tag' zero
assert 'tag istnieje' is "$(git tag -l v1.3-test)" v1.3-test
run dziara; assert 'dziara bez argumentów lista' contains v1.3-test
run dziara -a v1.3-annot -m 'wersja'; assert 'dziara tag adnotowany' zero
assert 'typ tagu adnotowanego' is "$(git cat-file -t refs/tags/v1.3-annot)" tag
run cynk; assert 'cynk reflog' zero; assert 'cynk ma zapis commit' contains commit
run cynk -n 1; assert 'cynk -n 1 działa' zero
run uklady; assert 'uklady bez argumentów' zero
mkdir "$WORK/bare.git"; git init -q --bare "$WORK/bare.git"
run uklady add mirror "$WORK/bare.git"; assert 'uklady add' zero
run uklady get-url mirror; assert 'uklady get-url' contains bare.git

printf '▶ Kasacja: commit i --no-commit\n'
printf revert-this > revert.txt; git add revert.txt; git commit -qm 'new file'
old=$(git rev-parse HEAD); count=$(git rev-list --count HEAD)
run kasacja "$old"; assert 'kasacja bez edytora' zero
assert 'kasacja stworzyła nowy commit' is "$(git rev-list --count HEAD)" "$((count+1))"
assert 'kasacja odwróciła plik' test ! -e revert.txt
printf revert-again > revert.txt; git add revert.txt; git commit -qm 'another file'
old=$(git rev-parse HEAD); count=$(git rev-list --count HEAD)
run kasacja "$old" --no-commit; assert 'kasacja no-commit' zero
assert 'kasacja --no-commit nie tworzy commita' is "$(git rev-list --count HEAD)" "$count"
assert 'kasacja --no-commit przygotowała index' test ! -e revert.txt

printf '▶ Pull domyślnie fast-forward only\n'
git reset -q --hard HEAD; git remote add origin "$WORK/bare.git"
git push -q -u origin main
cd "$WORK" || exit 1
git clone -q "$WORK/bare.git" peer
cd peer || exit 1
printf peer >> one.txt; git add one.txt; git commit -qm peer; git push -q
cd "$WORK/basic" || exit 1
printf local >> one.txt; git add one.txt; git commit -qm local
run rakowiec; assert 'rakowiec rozbieżny = nonzero' nonzero
assert 'rakowiec nie zrobił merge' is "$(git log -1 --format=%s)" local

printf '▶ Wywozka: 2 remote bez konfiguracji\n'
mkdir -p "$WORK/push2"; cd "$WORK/push2" || exit 1; git init -q
echo x > x; git add x; git commit -qm x
git remote add origin "$WORK/bare.git"; git remote add backup "$WORK/bare.git"
run wywozka; assert 'wywozka odmawia przy 2 remote' nonzero; assert 'komunikat o niejednoznacznym celu' contains 'kilka remote'
git config push.default nothing
run wywozka; assert 'wywozka nie omija push.default=nothing' nonzero

printf '▶ Wynik nowych testów: %s zaliczonych, %s oblanych\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
