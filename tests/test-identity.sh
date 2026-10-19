#!/usr/bin/env bash
# GRYPS 1.4.0 — identity tests; NEVER touch the developer's global git config.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRYPS="${GRYPS:-$ROOT/dist/gryps}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home" "$WORK/work" "$WORK/other"
export HOME="$WORK/home" GIT_CONFIG_GLOBAL="$WORK/home/global" GIT_CONFIG_NOSYSTEM=1 NO_COLOR=1 LC_ALL=C
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL EMAIL || true
PASS=0 FAIL=0 OUT='' CODE=0
ok() { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; printf '%s\n' "$OUT" | head -7 | sed 's/^/    /'; }
expect() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
run() { OUT="$("$GRYPS" "$@" 2>&1 < /dev/null)"; CODE=$?; }
contains() { [[ "$OUT" == *"$1"* ]]; }
is() { [ "$1" = "$2" ]; }
nonzero() { [ "$CODE" -ne 0 ]; }
zero() { [ "$CODE" -eq 0 ]; }
cd "$WORK/work" || exit 1
git init -q
git config --local user.useConfigOnly true
printf 'text\n' > demo.txt
git add demo.txt
printf '▶ Brak tożsamości przed commit\n'
run przyklep 'nowy commit'
expect 'odmowa nieprzyklepanego anonima' nonzero
expect 'podpowiedź meldunku' contains 'gryps meldunek'
expect 'podpowiedź ksywy' contains 'gryps ksywa'
expect 'podpowiedź mety' contains 'gryps meta'
expect 'nie powstał commit' is "$(git rev-list --count --all)" 0
run kartoteka; expect 'kartoteka sygnalizuje brak danych' nonzero
expect 'kartoteka ma wyjaśnienie' contains 'Niepełne papiery'
run meldunek; expect 'meldunek bez TTY wymaga 2 argumentów' nonzero
run meldunek 'Anonim'; expect 'meldunek wymaga obu danych' nonzero
run meldunek 'Anonim' 'to-nie-email'; expect 'walidacja adresu' nonzero
expect 'nie zapisał częściowej ksywy' is "$(git config --local --get user.name || true)" ''
printf '▶ Ksywa i meta tylko lokalnie\n'
run ksywa 'Tomasz K.'; expect 'lokalna ksywa' zero
expect 'ksywa w repo' is "$(git config --local --get user.name)" 'Tomasz K.'
expect 'globale nietknięte' is "$(git config --global --get user.name || true)" ''
run ksywa; expect 'ksywa odczyt' contains 'Tomasz K.'
run przyklep 'tylko ksywa'; expect 'nadal brak meta' nonzero
expect 'podpowiedź tylko meta' contains 'gryps meta'
run meta 'test@example.com'; expect 'lokalna meta' zero
expect 'meta w repo' is "$(git config --local --get user.email)" test@example.com
expect 'globalna meta nietknięta' is "$(git config --global --get user.email || true)" ''
run przyklep 'Pierwszy commit'; expect 'commit po meldunku działa' zero
expect 'commit ma lokalną tożsamość' is "$(git show -s --format='%an <%ae>' HEAD)" 'Tomasz K. <test@example.com>'
run kartoteka; expect 'kartoteka czyta konfigurację' contains '[LOCAL]'
printf '▶ Global i precedence\n'
run meldunek --global 'Global G.' global@example.org
expect 'jawny meldunek --global' zero
expect 'globalna nazwa' is "$(git config --global --get user.name)" 'Global G.'
expect 'globalny email' is "$(git config --global --get user.email)" global@example.org
expect 'lokalna nazwa niezmieniona' is "$(git config --local --get user.name)" 'Tomasz K.'
run kartoteka; expect 'lokalna ma pierwszeństwo' contains 'Tomasz K. [LOCAL]'
run ksywa --global; expect 'odczyt globalnej ksywy' contains 'Global G.'
cd "$WORK/other" || exit 1
git init -q
run kartoteka; expect 'kartoteka global w innym repo' contains '[GLOBAL]'
run przyklep -m 'pusty commit' --allow-empty
expect 'global umożliwia commit' zero
printf '▶ Usuwanie braków i środowisko Git\n'
git config --local user.name 'Local G.'
run meldunek 'Nowa Ksywa' nowa@example.pl
expect 'meldunek nadpisuje lokalną tożsamość' zero
expect 'meldunek poprawił email' is "$(git config --local user.email)" nowa@example.pl
run meta --global dev@example.net; expect 'globalna meta osobno' zero
expect 'lokalna meta ma priorytet' is "$(git config --get user.email)" nowa@example.pl
run meldunek --global; expect 'nieterminalowy brak danych nie kasuje global' nonzero
expect 'global po odrzuconym meldunku pozostaje' is "$(git config --global user.name)" 'Global G.'
run meta 'in valid@example.com'; expect 'email z białymi znakami odrzucony' nonzero
run kartoteka extra; expect 'kartoteka odrzuca argumenty' nonzero
run ksywa one two; expect 'ksywa odrzuca 2 nazwy' nonzero
run ksywa --unknown foo; expect 'nieznana opcja' nonzero
printf '▶ Nadpisania przez GIT_AUTHOR/COMMITTER\n'
cd "$WORK/work" || exit 1
printf 'env\n' >> demo.txt; git add demo.txt
# środowisko ma pierwszeństwo. Nawet bez ustawień Git w plikach nie blokujemy commita.
git config --local --unset-all user.name
git config --local --unset-all user.email
export GIT_AUTHOR_NAME='Env Author' GIT_AUTHOR_EMAIL='author@env.test'
export GIT_COMMITTER_NAME='Env Committer' GIT_COMMITTER_EMAIL='committer@env.test'
run przyklep 'commit with env'; expect 'git env ident ma pierwszeństwo' zero
expect 'autor z env' is "$(git show -s --format=%an HEAD)" 'Env Author'
expect 'committer z env' is "$(git show -s --format=%cn HEAD)" 'Env Committer'
expect 'odczyt --global nie zmienia local' is "$(git config --local --get user.name || true)" ''
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
run --cicho kartoteka; expect 'global wystarcza po odpięciu env' zero
printf '▶ Pomoc i podpowiedzi\n'
for word in ksywa meta meldunek kartoteka; do
  run pomoc; expect "pomoc $word" contains "$word"
  run kmina "$word"; expect "kmina $word" zero
  run podpowiedzi; expect "ściąga $word" contains "$word"
done
printf 'Identity tests: %s/%s zaliczonych\n' "$PASS" "$((PASS+FAIL))"
[ "$FAIL" -eq 0 ]
