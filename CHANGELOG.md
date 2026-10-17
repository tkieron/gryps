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
