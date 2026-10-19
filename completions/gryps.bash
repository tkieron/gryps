# GRYPS 1.4.1 — TAB: Bash 3.2+, ble.sh 0.4+ (optional)
# Trzymamy czyste wartości COMPREPLY w zwykłym Bashu. Nie dopisujemy opisów
# do nazw kandydatów, ponieważ TAB wstawiłby opis zamiast samej komendy.
# W ble.sh, jeśli dostępne jest jego API kandydatów, przekazujemy osobny opis.
# shellcheck shell=bash

_gryps_collect_completions() {
    local suggestion
    COMPREPLY=()
    while IFS= read -r suggestion; do
        COMPREPLY+=("$suggestion")
    done
}

_gryps_meta() {
    # $1 — nazwa grypsu. Ustawia REPLY (etykieta grupy + opis + komenda Git).
    case "$1" in
        mury) REPLY='[📦 CODZIENNA ROBOTA] Postaw nową celę — git init' ;;
        jumaj) REPLY='[📦 CODZIENNA ROBOTA] Zwiń repo z wolki — git clone' ;;
        lipo) REPLY='[📦 CODZIENNA ROBOTA] Co słychać pod celą? — git status -sb' ;;
        kwity) REPLY='[📦 CODZIENNA ROBOTA] Wyciągnij dowody zmian — git diff + git diff --cached' ;;
        skitraj) REPLY='[📦 CODZIENNA ROBOTA] Schowaj fanty do indeksu — git add [-A]' ;;
        odkitraj) REPLY='[📦 CODZIENNA ROBOTA] Wyjmij z indeksu, nie z dysku — git restore --staged' ;;
        przyklep) REPLY='[📦 CODZIENNA ROBOTA] Podpisz się pod robotą — git commit' ;;
        wywozka) REPLY='[📦 CODZIENNA ROBOTA] Wyślij urobek na wolkę — git push' ;;
        rakowiec) REPLY='[📦 CODZIENNA ROBOTA] Odbierz paczkę bez merge — git pull --ff-only' ;;
        ucho) REPLY='[📦 CODZIENNA ROBOTA] Posłuchaj co na serwerze — git fetch' ;;
        ksywa) REPLY='[🪪 KARTOTEKA] Ustal ksywę autora — git config user.name' ;;
        meta) REPLY='[🪪 KARTOTEKA] Ustal metę autora — git config user.email' ;;
        meldunek) REPLY='[🪪 KARTOTEKA] Zameldowanie naraz — git config user.name + user.email' ;;
        kartoteka) REPLY='[🪪 KARTOTEKA] Sprawdź papiery i ich źródła — git config --show-origin' ;;
        celka) REPLY='[🚪 CELE I UKŁADY] Lista cel i nowe cele — git branch' ;;
        przerzutka) REPLY='[🚪 CELE I UKŁADY] Zmień celę — git switch' ;;
        spacer) REPLY='[🚪 CELE I UKŁADY] Przejdź w historię — git checkout' ;;
        blaty) REPLY='[🚪 CELE I UKŁADY] Dogadaj gałęzie — git merge' ;;
        uklady) REPLY='[🚪 CELE I UKŁADY] Sprawdź kontakty z wolką — git remote -v' ;;
        tabor) REPLY='[🚪 CELE I UKŁADY] Przewieź commity na wskazaną bazę — git rebase' ;;
        podkopsaj) REPLY='[🚪 CELE I UKŁADY] Przemyć commit(y) z innej celi — git cherry-pick' ;;
        kapus) REPLY='[🕵️ DOCHODZENIE] Kto sypnął tę linijkę? — git blame' ;;
        wizjer) REPLY='[🕵️ DOCHODZENIE] Zajrzyj w wybraną akcję — git show' ;;
        bialko) REPLY='[🕵️ DOCHODZENIE] Prześwietl historię — git log' ;;
        cynk) REPLY='[🕵️ DOCHODZENIE] Tropy po ruchach HEAD — git reflog' ;;
        dziara) REPLY='[🕵️ DOCHODZENIE] Wydziaraj wersję — git tag' ;;
        dziupla) REPLY='[🕳️ DZIUPLA] Schowaj także nowe fanty — git stash push -u' ;;
        wyjmij) REPLY='[🕳️ DZIUPLA] Wyjmij fanty z dziupli — git stash pop' ;;
        spis) REPLY='[🕳️ DZIUPLA] Co leży w dziupli? — git stash list' ;;
        spusc) REPLY='[🕳️ DZIUPLA] Spuść wybraną dziuplę — git stash drop' ;;
        kasacja) REPLY='[🚨 RATUNEK] Odwróć wyrok nowym commitem — git revert' ;;
        odkrec) REPLY='[🚨 RATUNEK] Odkręć niezapisane zmiany — git restore --worktree' ;;
        kipisz) REPLY='[🚨 RATUNEK] Twardy reset! Ostrożnie — git reset --hard' ;;
        odklep) REPLY='[🚨 RATUNEK] Odklep 1–N commitów, zmiany zostają skitrane — git reset --soft HEAD~N' ;;
        wykipruj) REPLY='[🚨 RATUNEK] Pokaż i usuń nieśledzone (po zgodzie) — git clean -d' ;;
        pomoc) REPLY='[📖 POMOC] Pełen regulamin celi — gryps pomoc' ;;
        kmina) REPLY='[📖 POMOC] Rozkmiń jeden gryps — gryps kmina' ;;
        bajera) REPLY='[📖 POMOC] Nauka pod celą — gryps bajera' ;;
        podpowiedzi) REPLY='[📖 POMOC] Spis grypsów i ich znaczeń — gryps podpowiedzi' ;;
        wersja) REPLY='[📖 POMOC] Numer aktualnej odsiadki — gryps wersja' ;;
        kopsnij) REPLY='[🔁 ZAMIENNIKI] Alias wywózki — git push' ;;
        rakieta) REPLY='[🔁 ZAMIENNIKI] Alias rakowca — git pull --ff-only' ;;
        stojka) REPLY='[🔁 ZAMIENNIKI] Alias ucha — git fetch' ;;
        zblatuj) REPLY='[🔁 ZAMIENNIKI] Alias blatów — git merge' ;;
        *) REPLY='' ;;
    esac
}

_gryps_words='mury jumaj lipo kwity skitraj odkitraj przyklep wywozka rakowiec ucho ksywa meta meldunek kartoteka celka przerzutka spacer blaty uklady tabor podkopsaj kapus wizjer bialko cynk dziara dziupla wyjmij spis spusc kasacja odkrec kipisz odklep wykipruj pomoc kmina bajera podpowiedzi wersja kopsnij rakieta stojka zblatuj'

_gryps_candidates() {
    # Komendy są podawane w kolejności grup i NIE są wykonywane.
    local cur="$1" name
    COMPREPLY=()
    local ble_mode=0
    if [[ ${cand_count+x} && ${_ble_complete_yield_varnames+x} ]] &&
       declare -F 'ble/complete/cand/yield' >/dev/null 2>&1 &&
       declare -F 'ble/complete/cand/yield.initialize' >/dev/null 2>&1; then
        ble_mode=1
        # ble.sh: COMP_PREFIX oznacza fragment do odjęcia od kandydata
        # (np. prefiks ścieżki), a nie już wpisane znaki aktualnego słowa.
        # Dla nazw grypsów kandydat jest PEŁNĄ nazwą; nie wolno odcinać "wy"
        # od "wywozka" ani "kap" od "kapus".
        # ble.sh odczytuje COMP_PREFIX dynamicznie
        # shellcheck disable=SC2034
        local COMP_PREFIX=''
        local "${_ble_complete_yield_varnames[@]/%/=}"
        ble/complete/cand/yield.initialize word
    fi
    for name in $_gryps_words; do
        [[ "$name" == "$cur"* ]] || continue
        # API opisów ble.sh; przekazujemy osobno nazwę i opis.
        if [[ "$ble_mode" == 1 ]]; then
            _gryps_meta "$name"
            ble/complete/cand/yield word "$name" "$REPLY"
            # Nie duplikuj kandydatów przez COMPREPLY.
        else
            COMPREPLY+=("$name")
        fi
    done
}

_gryps_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev='' cmd='' cmd_index=1
    COMPREPLY=()
    if (( COMP_CWORD > 0 )); then prev="${COMP_WORDS[COMP_CWORD-1]}"; fi
    if [[ "${COMP_WORDS[1]:-}" == '--cicho' ]]; then cmd_index=2; fi

    if (( COMP_CWORD == cmd_index )); then
        _gryps_candidates "$cur"
        return 0
    fi
    cmd="${COMP_WORDS[cmd_index]:-}"
    case "$cmd" in
        kmina)
            _gryps_candidates "$cur" ;;
        ksywa|meta|meldunek)
            _gryps_collect_completions < <(compgen -W '--global --local' -- "$cur") ;;
        kapus|skitraj|odkrec|odkitraj|kwity|spacer|wykipruj)
            if [[ "$cmd" == kapus && "$prev" == -L ]]; then return 0; fi
            _gryps_collect_completions < <(compgen -f -- "$cur") ;;
        przerzutka|blaty|zblatuj)
            _gryps_collect_completions < <(compgen -W "$(git branch --format='%(refname:short)' 2>/dev/null)" -- "$cur") ;;
        tabor)
            if [[ "$cur" == -* ]]; then
                _gryps_collect_completions < <(compgen -W '--autostash --interactive --continue --abort --skip --onto' -- "$cur")
            else
                _gryps_collect_completions < <(compgen -W "$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null)" -- "$cur")
            fi ;;
        podkopsaj)
            if [[ "$cur" == -* ]]; then
                _gryps_collect_completions < <(compgen -W '--no-commit --mainline --continue --abort --skip -x' -- "$cur")
            else
                _gryps_collect_completions < <(compgen -W "$(git branch --format='%(refname:short)' 2>/dev/null) $(git log --all -n 30 --format='%h' 2>/dev/null)" -- "$cur")
            fi ;;
        odklep)
            _gryps_collect_completions < <(compgen -W '1 2 3 --force' -- "$cur") ;;
        celka)
            if [[ "${COMP_WORDS[cmd_index+1]:-}" == -d || "${COMP_WORDS[cmd_index+1]:-}" == -D ]]; then
                _gryps_collect_completions < <(compgen -W "$(git branch --format='%(refname:short)' 2>/dev/null)" -- "$cur")
            fi ;;
        uklady|wywozka|kopsnij|ucho|stojka|rakowiec|rakieta)
            _gryps_collect_completions < <(compgen -W "$(git remote 2>/dev/null)" -- "$cur") ;;
        dziara)
            _gryps_collect_completions < <(compgen -W "$(git tag -l 2>/dev/null)" -- "$cur") ;;
        kasacja|wizjer)
            _gryps_collect_completions < <(compgen -W "$(git log -n 30 --format='%h' 2>/dev/null)" -- "$cur") ;;
        wyjmij|spusc)
            _gryps_collect_completions < <(compgen -W "$(git stash list --format='%gd' 2>/dev/null)" -- "$cur") ;;
    esac
    return 0
}

# Readline respektuje kolejność z _gryps_words dzięki nosort.
# Format "jedna nazwa na wiersz" można włączyć przez:
#   bind 'set completion-display-width 0'
# (dotyczy globalnie terminala i nie dodaje opisów w zwykłym Bashu).
# Bash 3.2 (systemowy macOS) nie zna flagi -o nosort. Próba rejestracji
# z nieobsługiwaną flagą usuwa całą definicję TAB, więc potrzebny fallback.
if ! complete -o filenames -o nosort -F _gryps_completions gryps 2>/dev/null; then
    complete -o filenames -F _gryps_completions gryps
fi
