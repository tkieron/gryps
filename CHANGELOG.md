## [1.4.1] — Ratunek bez kipiszu (2026-10-19)

### Zmiana niekompatybilna
- **`skitrac` → `skitraj`** (`git add`), bez aliasu zgodności. `gryps skitrac` (także `kmina skitrac` i `skitrac -h`) kończy się kodem 1, niczego nie dodaje do stagingu i podpowiada `gryps skitraj`. Migracja skryptów: zamień `gryps skitrac` na `gryps skitraj` — argumenty, domyślne `git add -A` i kody wyjścia są identyczne. Stara nazwa zniknęła z TAB, pomocy, man i README.

### Nowe grypsy
- `odklep [N] [-f]` — `git reset --soft HEAD~N` (domyślnie 1). Zamknięta lista argumentów (`--hard` nie dociera do Gita); odmowa przy pierwszym commicie, merge w zakresie, operacji w toku i commitach obecnych na remote (wg `refs/remotes`, bez fetch). `-f` świadomie pozwala, bez push. W TTY lista odklepanych commitów i podpowiedzi `kwity --staged`, `przyklep -C ORIG_HEAD`.
- `wykipruj [-n] [-f] [-x|-X] [[--] ścieżki]` — `git clean -d` w całym repo (`:(top)`) albo we wskazanych ścieżkach. Bez `-f` podgląd na stdout, zgoda w terminalu i ponowne porównanie listy przed usunięciem; bez terminala odmowa. Nigdy `-ff` (zagnieżdżone repozytoria zostają); inne opcje `git clean` odrzucane.
- `tabor <baza> [opcje]` — `git rebase`. Baza wymagana, brudne drzewo tracked tylko z `--autostash`, `-i` tylko z terminalem, ostrzeżenie o `--force-with-lease` dla wywiezionych commitów. Rozróżnia sukces, brak pracy, konflikt (lista plików) i zatrzymanie; `--continue/--abort/--skip` przechodzą do Gita. GRYPS nie przechwytuje `-f` (`--force-rebase`).
- `podkopsaj <commit|zakres>… [opcje]` — `git cherry-pick` bez domyślnego `-x`. Merge commit bez `-m` zatrzymywany przed Gitem; osobne komunikaty dla `--no-commit`, pustego przemytu (`--skip`) i konfliktu.

### Zmiany w istniejących komendach
- `kipisz`: po udanym resecie w TTY podpowiada `gryps wykipruj`, gdy zostały nowe pliki (bez `git clean`).
- `kmina kasacja` wskazuje `odklep` dla commitów niewywiezionych.
- Komunikat `wywozka` o luźnych zmianach podaje nową nazwę `skitraj`.
- Literówki `odklepp/odklp/odklap`, `wykipuj/wykiperuj/wykipr`, `tabur/tbor`, `podkopsj/podkopsa`; normalizator nazw zachowuje polskie litery (np. `odklęp` → podpowiedź `odklep`).
- `podpowiedzi` generowane z wbudowanego katalogu (44 pozycje); `wywozka`, `rakowiec`, `ucho` wróciły do grupy CODZIENNA ROBOTA.

### TAB, dokumentacja, testy
- Katalog, Bash, ble.sh i Zsh: `skitraj` i cztery nowe grypsy, podpowiedzi argumentów (gałęzie dla `tabor`, gałęzie i commity dla `podkopsaj`, pliki dla `wykipruj`).
- README przebudowane: pełny słownik komend na górze, potem historia zmian, instalacja, Smart TAB i bezpieczeństwo; poprawione linki `tkieron/gryps` i nazwy paczek.
- `man gryps` uporządkowany tematycznie, z nowymi komendami.
- Nowy `tests/test-v141.sh` (T51–T110), specyfikacja `docs/GRYPS_v1.4.1_SDD.md`.

## [1.4.0] — Kartoteka grypsującego (2026-10-19)

- Nowe `ksywa`, `meta`, `meldunek`, `kartoteka`: lokalna tożsamość domyślnie, `--global` wyłącznie na żądanie.
- `przyklep` wykrywa brak działającej tożsamości Git i podpowiada konfigurowanie ksywy i mety.
- Interaktywny meldunek, brak pytań w nieterminalowych skryptach, diagnostyka błędów i komunikaty więzienne.
- Podpowiedzi Bash/ble.sh i Zsh oraz testy tożsamości lokalnej, globalnej i źródeł konfiguracji.

## 1.3.6 — Naprawa CI / ShellCheck i macOS Bash 3.2 (2026-10-19)

- Usunięto błędne `else if` w `odkitraj` (SC1075) bez zmiany semantyki komendy.
- Usunięto nieużywany kolor `GREEN`; oznaczono intencjonalne użycia dynamiczne oraz literalne testowe ciągi dla ShellCheck.
- Testy push korzystają z `if/else` zamiast skrótu `A && B || C`.
- Bash TAB wykrywa brak `complete -o nosort` i na macOS Bash 3.2 rejestruje podpowiedzi z `-o filenames`.
- Nowy test regresyjny emuluje Bash 3.2 i weryfikuje działanie fallbacku TAB.

## 1.3.5 — Uczciwa wywózka (2026-10-19)

- `wywozka` i `kopsnij`: rozróżnienie push z nowymi commitami od `Everything up-to-date`.
- Gdy staging zawiera nieprzyklepane zmiany, GRYPS sugeruje commit zamiast udawać sukces.
- Bez staged: wskazówki dla zmian unstaged i nowych plików, osobna informacja dla czystego repo.
- Jeśli są gotowe commity, push odbywa się normalnie, z ostrzeżeniem o niewysłanym stagingu.
- Zachowane kody wyjścia i surowe wyjście Git w skryptach/`--cicho`.

## 1.3.4 — Poprawka TAB w ble.sh (2026-10-19)

- Naprawiono podpowiadanie częściowo wpisanych grypsów w ble.sh: `gryps wy<TAB>` wstawia teraz `wywozka`, nie `wozka`.
- Zachowano pełne nazwy, opisy i pionowe grupowanie; bez zmian w działaniu komend Git.
- Dodano testy regresyjne ble.sh dla prefiksów, aliasów i opcji `--cicho`.

## 1.3.3 — Smart TAB pionowo (2026-10-17)

- Bash: `-o nosort` zachowuje kolejność grup; opcjonalny Readline `completion-display-width 0` wyświetla pozycje pojedynczo.
- Bash + ble.sh: `menu_desc_multicolumn_width=` wyłącza kolumny w widoku opisów.
- Zsh: dedykowane grupy z nagłówkami; `compadd -l -V` wymusza jeden wpis na wiersz i zachowuje kolejność.
- Nie zmieniono mapowania komend Git ani obsługi ścieżek i argumentów.

## 1.3.2 — GRYPS Smart TAB
- Pogrupowane menu Zsh z polskimi opisami i odpowiednikami Git na końcu.
- Integracja opisów z ble.sh; zwykły Bash bez utraty prostego TAB.
- `gryps podpowiedzi`: pogrupowana ściąga na każdej powłoce.
- Podpowiedzi branchy, tagów, remotes, commitów i stashy, zgodnie z argumentami.
- Brak zmian w działaniu operacji Git.

# Kartoteka zmian

Format wg [Keep a Changelog](https://keepachangelog.com/pl/1.1.0/), wersje wg [SemVer](https://semver.org/lang/pl/).

## [1.3.1] – 2026-10-17
### Naprawione
- Bash TAB: `gryps kapus -- ts<TAB>` oraz podobne wywołania z separatorem `--` nie próbują uruchamiać `--` jako programu (`command not found`).
- Bash TAB: uzupełnianie plików działa dla kolejnych argumentów, po `-L` i po `--cicho`, także ze ścieżkami z podkatalogów oraz spacjami w nazwach.
- Zsh TAB: poprawne rozpoznawanie komendy przy globalnej opcji `--cicho` i jej argumentów.
- Testy regresyjne TAB dołączone do `make test`.

## [1.3.0] – 2026-10-17
### Dodane
- Osiem grypsów: `kwity`, `odkitraj`, `kapus`, `dziara`, `cynk`, `kasacja`, `uklady`, `odkrec`.
- „Gryps gada” — kontekstowe potwierdzenia, emoji w TTY, diagnozy błędów i podpowiedzi literówek.
- Tryb `--cicho` / `GRYPS_CICHO=1`, czyste wyjście maszynowe.
- Testy integracyjne nowych komend na izolowanych repozytoriach.
### Zmienione
- `dziupla` domyślnie używa `stash push -u` (untracked, bez ignored).
- `rakowiec` używa `pull --ff-only`, chyba że wskazano strategię.
- `lipo` bez parametrów używa `git status -sb`.
- `wywozka` odmawia wyboru celu przy wielu nierozstrzygniętych remote.
- Rozszerzone pomoc, manpage i autouzupełnianie Bash/Zsh.

## [1.2.2] – 2026-10-17
### Dodane
- Uniwersalna paczka macOS `.tar.gz` (Intel x86_64 i Apple Silicon arm64), offline `install.sh` oraz `uninstall.sh`; domyślna instalacja bez sudo do `~/.local`.
- Natywne Zsh completion i opcjonalna, oznaczona konfiguracja `~/.zshrc`.
- CI dla systemowego Bash 3.2 na macOS, test instalatorów i paczka macOS do wydania GitHub.
### Naprawione
- Bash completion nie używa już `mapfile` i działa również na macOS z Bash 3.2 (bez Homebrew Bash 4+).

## [1.2.1] – 2026-10-17
### Naprawione
- `wywozka` wybiera docelowy remote według konfiguracji Git (`branch.*.pushRemote`, `remote.pushDefault`), zamiast wymuszać `origin`; ustawianie upstreamu jest zgodne również ze starszym Git.
- `przyklep` prawidłowo przekazuje flagi po opisie commita (`--no-verify`, `--amend`).
- `blaty` zgłasza konflikt tylko, jeśli Git faktycznie pozostawił niepołączone ścieżki; `check_repo` odrzuca repo bare.
- `dziupla` ostrzega o pozostawionych plikach nieśledzonych (dostępne `-u`), a `kipisz` jasno opisuje ograniczenie do zmian śledzonych plików.
- Błędy `wywozka` nie zakładają nieprawidłowo problemu rejected/pull i zachowują status wyjścia Git.
- Testy regresyjne i opisy komend uwzględniają powyższe przypadki.

## [1.2.0] – 2026-10-16
Pierwsze publiczne wydanie.

### Dodane
- Strona `man gryps`.
- Animowane demo w README, renderowane z prawdziwej sesji (`make demo`).
- Pionowy short reklamowy 9:16 z własnym bitem (`make promo`).
- 15-sekundowy animowany skecz „Pod celą” (`make skit`).
- `NO_COLOR` i automatyczne wyłączanie kolorów poza terminalem.
- `Makefile` z `install` / `uninstall` (także `PREFIX=~/.local`), testy, CI i automatyczne wydania na GitHubie.
- Podpowiedzi plików pod TABem dla `skitrac`.

## [1.1.1]
### Dodane
- Pomoc, bajera i `kmina` przewijane w `less`.

## [1.1.0]
### Dodane
- Zamienniki ze słownika grypsery: `rakieta`, `kopsnij`, `stojka`, `zblatuj`.
- Komenda `mury` (`git init`), podpowiedzi celek po `celka -d`.
- Potwierdzenie przed `kipisz` i `spusc` (flaga `-f` pomija).

### Naprawione
- `wywozka` ustawia upstream niezależnie od języka komunikatów Gita i nie połyka wyjścia `git push`.
- `skitrac` bez argumentów bierze całe repo (`git add -A`), nie tylko bieżący katalog.
- `ucho` i `skitrac` nie zgłaszają sukcesu, gdy git zwrócił błąd.
- Pliki w `.deb` należą do `root:root` także przy budowaniu jako zwykły użytkownik.

## [1.0.0]
- Pierwsza wersja.
