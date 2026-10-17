#!/usr/bin/env bash
# Warunki w check() są celowo w apostrofach – wylicza je eval w chwili sprawdzania.
# shellcheck disable=SC2016
# Testy Grypsu: prawdziwe repozytoria w katalogu tymczasowym, zero zależności poza gitem.
# Uruchom: make test   (albo: GRYPS=/sciezka/do/gryps bash tests/run.sh)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS="${GRYPS:-$ROOT/dist/gryps}"
[ -x "$GRYPS" ] || { echo "Brak $GRYPS – odpal najpierw: make build"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Odizolowany git: własny HOME, angielskie i polskie locale nie mają znaczenia
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1 NO_COLOR=1
mkdir -p "$HOME"
git config --global user.name "Tester"
git config --global user.email "tester@example.com"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

PASS=0 FAIL=0 OUT="" CODE=0

run() { OUT="$("$GRYPS" "$@" 2>&1 < /dev/null)"; CODE=$?; }
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; printf '     kod=%s wyjście:\n%s\n' "$CODE" "$OUT" | sed 's/^/     /'; }
expect_code()     { if [ "$CODE" -eq "$1" ]; then ok "$2"; else bad "$2"; fi; }
expect_contains() { if [[ "$OUT" == *"$1"* ]]; then ok "$2"; else bad "$2"; fi; }
check()           { if eval "$1"; then ok "$2"; else bad "$2"; fi; }

fresh_repo() {
    local dir="$WORK/$1"
    git init -q --bare "$dir-remote.git"
    "$GRYPS" mury "$dir" >/dev/null 2>&1
    cd "$dir" || exit 1
    git remote add origin "$dir-remote.git"
}

echo "▶ Pomoc i wersja"
run pomoc;              expect_code 0 "gryps pomoc działa";  expect_contains "PODSTAWOWA KMINA" "pomoc pokazuje sekcje"
run;                    expect_code 0 "gryps bez argumentów pokazuje pomoc"
run wersja;             expect_contains "wersja" "gryps wersja"
run przyklep -h;        expect_contains "git commit -m" "per-komendowe -h"
run kmina rakieta;      expect_contains "git pull" "kmina dla zamiennika"
run bajera;             expect_contains "BAJERA" "samouczek"
run nieznane;           expect_code 1 "nieznana komenda = kod 1"; expect_contains "Nieznana komenda" "rzeczowy komunikat dla nieznanej komendy bez TTY"
check '[[ "$(NO_COLOR= "$GRYPS" pomoc)" != *$'"'"'\033'"'"'* ]]' "brak kolorów w potoku (nawet bez NO_COLOR)"

echo "▶ Poza repo"
cd "$WORK" || exit 1
run lipo;               expect_code 1 "lipo poza repo = kod 1"; expect_contains "murów nie ma" "czytelny błąd poza repo"
run jumaj;              expect_code 1 "jumaj bez adresu = kod 1"
git init -q --bare "$WORK/tylko-bare.git"
cd "$WORK/tylko-bare.git" || exit 1
run lipo;               expect_code 1 "repo bare nie jest working tree"
expect_contains "bare" "komunikat dla repo bare"

echo "▶ Codzienna robota"
fresh_repo cela
mkdir sub && echo a > a.txt && echo b > sub/b.txt
cd sub || exit 1
run skitrac;            expect_code 0 "skitrac bez argumentów"
check '[ "$(git diff --cached --name-only | wc -l)" -eq 2 ]' "skitrac z podkatalogu bierze całe repo"
cd .. || exit 1
run przyklep;           expect_code 1 "przyklep bez opisu = kod 1"
run przyklep Czysta robota bez cudzysłowu
expect_code 0 "przyklep"
check '[ "$(git log -1 --format=%s)" = "Czysta robota bez cudzysłowu" ]' "opis commita z wielu słów"
# Opcje występujące po opisie mają zostać przekazane do git commit, nie do tekstu.
printf '#!/bin/sh\nexit 19\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo test-hook >> a.txt; git add a.txt
run przyklep "Feat z flagą" --no-verify
expect_code 0 "przyklep opis --no-verify omija hook"
check '[ "$(git log -1 --format=%s)" = "Feat z flagą" ]' "flaga po opisie nie trafia do commita"
rm -f .git/hooks/pre-commit
OLD_COUNT=$(git rev-list --count HEAD)
run przyklep "Feat po poprawce" --amend
expect_code 0 "przyklep opis --amend"
check '[ "$(git log -1 --format=%s)" = "Feat po poprawce" ] && [ "$(git rev-list --count HEAD)" = "$OLD_COUNT" ]' "--amend modyfikuje HEAD bez nowego commita"
run przyklep -m "Przez pełny Git" --amend
expect_code 0 "przyklep -m opis --amend przechodzi bez zmian"
check '[ "$(git log -1 --format=%s)" = "Przez pełny Git" ]' "tryb -m nie jest sklejany"
run lipo;               expect_code 0 "lipo w repo"
run wywozka;            expect_code 0 "pierwsza wywózka"
check 'git rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1' "wywózka ustawia upstream"
LC_ALL=C.UTF-8 LANGUAGE=pl run przerzutka -c nowa
expect_code 0 "przerzutka -c"
echo c > c.txt; "$GRYPS" skitrac >/dev/null; "$GRYPS" przyklep nowa >/dev/null
LANGUAGE=pl run kopsnij; expect_code 0 "kopsnij na nowej celce (polski git)"
check '[ "$(git rev-parse --abbrev-ref "@{u}")" = "origin/nowa" ]' "upstream origin/nowa"
run stojka;             expect_code 0 "stojka"
run bialko;             expect_contains "nowa" "bialko pokazuje graf"
run przerzutka main;    expect_code 0 "przerzutka main"
run zblatuj nowa;       expect_code 0 "zblatuj (merge)"
check '[ -f c.txt ]' "po blatach jest urobek z nowej celi"

echo "▶ Wywózka wybiera remote zgodnie z konfiguracją Git"
fresh_repo zdalne1
git init -q --bare "$WORK/zdalne1-backup.git"
git remote add backup "$WORK/zdalne1-backup.git"
git config branch.main.pushRemote backup
git config remote.pushDefault origin
echo "wersja" > f.txt; git add f.txt; git commit -qm baza
run wywozka;            expect_code 0 "pierwszy push respektuje branch.main.pushRemote"
check '[ "$(git rev-parse --abbrev-ref "@{u}")" = "backup/main" ]' "upstream wskazuje backup/main"
check 'git --git-dir="$WORK/zdalne1-backup.git" show-ref --verify --quiet refs/heads/main' "commit dotarł do backup"
check '! git --git-dir="$WORK/zdalne1-remote.git" show-ref --verify --quiet refs/heads/main' "commit NIE dotarł do origin"

fresh_repo zdalne2
git init -q --bare "$WORK/zdalne2-backup.git"
git remote add backup "$WORK/zdalne2-backup.git"
git config remote.pushDefault backup
git config push.default current
echo "wersja" > f.txt; git add f.txt; git commit -qm baza
run wywozka;            expect_code 0 "push.default=current oraz remote.pushDefault"
check '[ "$(git rev-parse --abbrev-ref "@{u}")" = "backup/main" ]' "remote.pushDefault wskazuje backup"
check '! git --git-dir="$WORK/zdalne2-remote.git" show-ref --verify --quiet refs/heads/main' "remote.pushDefault nie wybiera origin"

fresh_repo zdalne3
git init -q --bare "$WORK/zdalne3-backup.git"
git remote add backup "$WORK/zdalne3-backup.git"
git config branch.main.pushRemote backup
git config push.default upstream
echo "wersja" > f.txt; git add f.txt; git commit -qm baza
run wywozka;            expect_code 0 "push.default=upstream, brak wcześniejszego upstream"
check '[ "$(git rev-parse --abbrev-ref "@{u}")" = "backup/main" ]' "ustawienie upstream z trybu upstream"

fresh_repo zdalne4
git init -q --bare "$WORK/zdalne4-backup.git"
git remote add backup "$WORK/zdalne4-backup.git"
git config remote.pushDefault backup
git config push.default nothing
echo "wersja" > f.txt; git add f.txt; git commit -qm baza
run wywozka;            expect_code 128 "push.default=nothing nie jest obchodzony"
check '! git --git-dir="$WORK/zdalne4-backup.git" show-ref --verify --quiet refs/heads/main' "w trybie nothing nie wypchnięto zmian"
git config --unset push.default
run wywozka backup main
expect_code 0 "jawne parametry push przechodzą do Git"
check 'git --git-dir="$WORK/zdalne4-backup.git" show-ref --verify --quiet refs/heads/main' "jawny push trafił do backup"

fresh_repo zdalne5
echo x > f.txt; git add f.txt; git commit -qm baza
git checkout -q --detach HEAD
run wywozka;            expect_code 1 "detached HEAD bez argumentów = czytelna odmowa"
expect_contains "detached HEAD" "wywozka rozpoznaje detached HEAD"
run wywozka origin HEAD:refs/heads/detached-test
expect_code 0 "detached HEAD z jawnym refspec pozostaje obsługiwany"

 echo "▶ Wywózka bez serwera / bez celki"
fresh_repo samotnia
git remote remove origin
echo x > x.txt; "$GRYPS" skitrac >/dev/null; "$GRYPS" przyklep x >/dev/null
run wywozka;            expect_code 1 "wywozka bez remote = kod 1"; expect_contains "Nie ma zdalnego serwera" "czytelny błąd bez remote"

echo "▶ Błędy wywózki"
fresh_repo push-error
echo test > f.txt; git add f.txt; git commit -qm baza
git remote set-url origin "$WORK/zdalny-nie-istnieje.git"
run wywozka;            expect_code 128 "wywozka zachowuje fatal(128) z git push"
expect_contains "Could not read from remote repository" "niezmieniony błąd push Gita"
check '[[ "$OUT" != *"Odbierz najpierw rakietę"* ]]' "błąd serwera nie oznacza automatycznie rejected"

echo "▶ Konflikt na blatach"
fresh_repo dymy
echo baza > f.txt; "$GRYPS" skitrac >/dev/null; "$GRYPS" przyklep baza >/dev/null
"$GRYPS" przerzutka -c inna >/dev/null 2>&1
echo inna > f.txt; "$GRYPS" przyklep -am inna >/dev/null
"$GRYPS" przerzutka main >/dev/null 2>&1
echo main > f.txt; "$GRYPS" przyklep -am main >/dev/null
run blaty inna;         expect_code 1 "konflikt = kod 1"; expect_contains "DYMY POD CELĄ" "komunikat o konflikcie"
git merge --abort
run blaty no-such-branch
expect_code 1 "brak gałęzi dla blaty = błąd Git"
expect_contains "Git nie wykonał merge" "nieistniejąca gałąź = neutralna diagnostyka"
check '[[ "$OUT" != *"DYMY POD CELĄ"* ]]' "brak gałęzi nie jest konfliktem"

echo "▶ Kipisz i dziupla"
echo zmiana >> f.txt
run kipisz;             expect_code 1 "kipisz bez terminala odmawia"
check '[ -n "$(git status --porcelain)" ]' "po odmowie zmiany zostały"
run kipisz -f;          expect_code 0 "kipisz -f"
check '[ -z "$(git status --porcelain)" ]' "po kipiszu cela czysta"
echo stracone >> f.txt
echo "zostaje" > untracked.txt
run kipisz -f;          expect_code 0 "kipisz -f z nieśledzonym plikiem"
check '! grep -q stracone f.txt && [ -f untracked.txt ]' "kipisz usuwa śledzone zmiany, ale zachowuje ??"
expect_contains "Nie usuwa plików nieśledzonych" "kipisz ostrzega o granicy działania"
rm untracked.txt
echo schowek >> f.txt
run dziupla;            expect_code 0 "dziupla"
run spis;               expect_contains "stash@{0}" "spis pokazuje dziuplę"
run wyjmij;             expect_code 0 "wyjmij"
check 'grep -q schowek f.txt' "fanty wróciły z dziupli"
echo "nowe fanty" > nowy.txt
run dziupla;            expect_code 0 "dziupla domyślnie chowa nowe pliki"
check '[ ! -e nowy.txt ]' "domyślna dziupla chowa untracked"
check '[ "$(git stash list | wc -l)" -ge 1 ]' "dziupla faktycznie utworzyła stash"
run wyjmij;             expect_code 0 "wyjmij po dziupla domyślnej"
run dziupla -u;         expect_code 0 "dziupla -u chowa nowe pliki"
check '[ ! -e nowy.txt ]' "dziupla -u chowa nieśledzony plik"
run wyjmij;             expect_code 0 "wyjmij odtwarza dziuplę z -u"
check '[ -f nowy.txt ]' "nowy plik wrócił z dziupli"
rm nowy.txt
"$GRYPS" dziupla >/dev/null 2>&1
run spusc;              expect_code 1 "spusc bez terminala odmawia"
run spusc -f;           expect_code 0 "spusc -f"
check '[ -z "$(git stash list)" ]' "dziupla spuszczona"

echo "▶ Kompatybilność macOS Bash 3.2"
check '! grep -q -E "^[[:space:]]*(mapfile|readarray)([[:space:]]|$)" "$ROOT/completions/gryps.bash"' "brak poleceń Bash >=4 w completions"
check '[ -f "$ROOT/completions/_gryps" ]' "jest natywne Zsh completion"
check 'sh -n "$ROOT/packaging/macos/install.sh" && sh -n "$ROOT/packaging/macos/uninstall.sh" && sh -n "$ROOT/packaging/macos/build-macos.sh"' "instalatory macOS mają poprawną składnię sh"

echo "▶ Podpowiedzi pod TABem"
# shellcheck source=/dev/null
source "$ROOT/completions/gryps.bash"
comp() { COMP_WORDS=("$@"); COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 )); _gryps_completions; echo "${COMPREPLY[*]}"; }
check '[ "$(comp gryps rak)" = "rakowiec rakieta" ]' "TAB: komendy"
check '[[ " $(comp gryps przerzutka "") " == *" inna "* ]]' "TAB: nazwy cel"
check '[[ " $(comp gryps celka -d "") " == *" inna "* ]]' "TAB: celka -d"

echo
echo "Wynik: $PASS zaliczonych, $FAIL oblanych"
[ "$FAIL" -eq 0 ]
