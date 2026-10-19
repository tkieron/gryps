#!/usr/bin/env bash
# Testy komunikatów wywózki w prawdziwym pseudo-terminalu (Linux util-linux script).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS="${GRYPS:-$ROOT/dist/gryps}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name Tester
git config --global user.email tester@example.test
git config --global init.defaultBranch main
PASS=0 FAIL=0
ok() { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; printf '%s\n' "$OUT" | tail -8; FAIL=$((FAIL+1)); }
contains() { if [[ "$OUT" == *"$2"* ]]; then ok "$1"; else bad "$1"; fi; }
not_contains() { if [[ "$OUT" != *"$2"* ]]; then ok "$1"; else bad "$1"; fi; }
if ! command -v script >/dev/null 2>&1 || ! script -q -e -c true /dev/null >/dev/null 2>&1; then
    echo "Pomijam PTY (brak zgodnego util-linux script); zwykłe testy push działają w tests/run.sh"; exit 0
fi
mkdir "$WORK/work"; cd "$WORK/work" || exit 2
git init -q --bare "$WORK/remote.git"
git init -q
git branch -M main
git remote add origin "$WORK/remote.git"
printf baseline > base.txt
git add base.txt; git commit -qm baseline
"$GRYPS" --cicho wywozka >/dev/null 2>&1 || exit 2

run_tty() { OUT="$(LANG=C.UTF-8 TERM=xterm script -q -e -c "'$GRYPS' $*" /dev/null 2>&1 | tr -d '\r')"; }
run_tty wywozka
contains 'czyste repo = brak nowej wywózki' 'Na wolce już wszystko mają'
not_contains 'czyste repo nie ogłasza wysyłki' 'Wywózka zakończona'
printf staged > staged.txt; git add staged.txt
run_tty wywozka
contains 'staged = najpierw przyklep' 'Najpierw: gryps przyklep'
contains 'staged = Salomon' 'Z pustego i Salomon nie naleje'
not_contains 'staged nie ogłasza sukcesu' 'Wywózka zakończona'
if [ "$(git --git-dir="$WORK/remote.git" rev-parse refs/heads/main)" = "$(git rev-parse HEAD)" ]; then
    ok 'nie wysłano nieprzyklepanych zmian'
else
    bad 'nie wysłano nieprzyklepanych zmian'
fi
git reset -q -- staged.txt; rm staged.txt
printf unstaged >> base.txt
run_tty wywozka
contains 'unstaged -> sugeruje skitraj' 'Najpierw gryps skitraj'
git restore -- base.txt
printf ignored > new.txt
run_tty wywozka
contains 'untracked -> nowe fanty' 'Na blacie leżą nowe fanty'
git add new.txt; git commit -qm 'commit do wypchnięcia'
printf next > notready.txt; git add notready.txt
run_tty wywozka
contains 'gotowy commit -> sukces' 'Wywózka zakończona'
contains 'staged obok wypchniętego commita -> ostrzeżenie' 'wysłane są tylko wcześniejsze'
if [ "$(git --git-dir="$WORK/remote.git" rev-parse refs/heads/main)" = "$(git rev-parse HEAD)" ]; then
    ok 'wysłano gotowy commit'
else
    bad 'wysłano gotowy commit'
fi
if [ -n "$(git diff --cached --name-only)" ]; then
    ok 'staging nie został naruszony'
else
    bad 'staging nie został naruszony'
fi
run_tty kopsnij
contains 'alias kopsnij ma te same reguły' 'Najpierw: gryps przyklep'
OUT="$("$GRYPS" --cicho wywozka 2>&1)"
not_contains '--cicho nie emituje grypsowych żartów' '[GRYPS]'
OUT="$("$GRYPS" wywozka 2>&1)"
not_contains 'potok bez TTY nie emituje grypsowych żartów' '[GRYPS]'
if [ "$FAIL" -eq 0 ]; then echo "Push feedback: $PASS/$PASS zaliczonych"; else echo "Push feedback: $PASS zaliczonych, $FAIL błędów"; exit 1; fi
