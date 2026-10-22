# GRYPS 1.5.0 Windows Git Bash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dostarczyć per-user paczkę Git Bash, natywne testy Windows i kompletny proces wydania przy zachowaniu Linux/macOS.

**Architecture:** Jeden silnik `bin/gryps`; Windows dodaje warstwę pakowania i instalacji. ZIP powstaje z `dist/gryps`, testy semantyczne używają wspólnego artefaktu, release publikuje dopiero komplet zweryfikowanych paczek.

**Tech Stack:** Bash 3.2+, POSIX sh dla instalatorów, Git for Windows, make, ZIP, ShellCheck, GitHub Actions.

**Spec:** [zatwierdzony SDD](../specs/2026-10-21-windows-gitbash-design.md) i pełny SDD z rozmowy.

## Global Constraints

- Bash 3.2+; jeden wspólny silnik `bin/gryps`.
- Windows Git Bash jest główną ścieżką; WSL2 to wariant Linux.
- Nie implementować PowerShell, natywnego `.exe` ani GUI.
- Bez `eval`, niecytowanych ścieżek, automatycznych zmian konfiguracji Git i nieudowodnionej konwersji ścieżek.
- Instalacja do `$HOME/.local` bez sudo; własny PREFIX tylko jawnie.
- Brak interaktywnych pytań bez TTY; konfiguracja tylko za zgodą.
- Nie pobierać opcjonalnego ble.sh offline; osobna zgoda niezależna od konfiguracji GRYPS.
- Bez git push, tagowania i publikacji bez świadomej decyzji właściciela.
- W01–W16: brak fikcyjnego PASS i brak SKIP krytycznych testów.
- VERSION 1.5.0 po zielonych testach, następnie powtórna weryfikacja paczek.

## Review Focus

1. PREFIX/HOME ze spacjami, polskimi znakami, `[]`, apostrofem i `$`: literalne ścieżki, brak wykonania tekstu z konfiguracji (Task 2).
2. Obce istniejące pliki, symlinki `.bashrc`, przerwane/malformed markery: bez utraty konfiguracji i obcych plików (Task 2).
3. Brak zgody, EOF, sprzeczne flagi, brak narzędzi: przewidywalny błąd przed zmianami i brak zawieszenia (Task 2).
4. Windows checkout CRLF, core.filemode=false, katalog na dysku C: bez zmiany ustawień użytkownika i bez konwersji magic pathspec (Task 3).
5. Niepełny/zestarzały ZIP lub błąd uploadu: brak publicznego niekompletnego wydania (Task 4).

---

### Task 1: Wersjonowany ZIP i powtarzalny build

**Files:** Create `packaging/windows/build-gitbash.sh`, `tests/test-windows-package.sh`; modify `Makefile`.

**Interfaces:** Consumes VERSION, `make build`, `dist/gryps`, `completions/gryps.bash`. Produces `dist/gryps-$VERSION-windows-gitbash.zip`, folder główny `gryps-$VERSION-windows-gitbash/`; wejścia kolejnych zadań: `bin/gryps`, completion, install/uninstall, README-Windows, VERSION, LICENSE. Make targets `windows` i `test-windows`.

- [x] Napisać test W01: archiwum niepuste, dokładny wymagany zestaw plików, brak `__VERSION__`, `bin/gryps wersja` zawiera VERSION i nie zawiera `dev`. Brak builda i brak zależności muszą dać błąd, nie niepełną paczkę.
- [x] Uruchomić `bash tests/test-windows-package.sh`; potwierdzić FAIL z powodu brakującego buildera/ZIP.
- [x] Dodać builder POSIX sh: walidacja zależności i VERSION, `make build`, staging przez `mktemp -d`, cleanup, kopiowanie wynikowego artefaktu, ZIP tworzony na nowo (bez starych wpisów) i dopiero potem zastępujący docelowy plik. Nazwa deterministyczna; nie obiecywać bitowej reprodukowalności timestampów.
- [x] Dodać `make windows` (build + inspekcja ZIP) i `make test-windows` (test pakietu oraz installer/runtime). Jawnie wypisać wymagania deweloperskie; instalacja gotowego ZIP nie wymaga make/zip.
- [x] Uruchomić test po dostarczeniu plików Task 2; do tego czasu brak installerów pozostaje oczekiwanym FAIL, bez pustych atrap.

### Task 2: Instalacja, konfiguracja i bezpieczne odinstalowanie

**Files:** Create `packaging/windows/install.sh`, `packaging/windows/uninstall.sh`, `packaging/windows/README-Windows.md`, `tests/test-windows-install.sh`; optionally create focused shared installer helper only if duplication warrants it, then include it in ZIP and tests.

**Interfaces:** Consumes rozpakowany folder Task 1. `sh install.sh [--yes|--no-config]`; `PREFIX=/absolutna/sciezka` jawnie zmienia lokalizację. `--yes` zezwala wyłącznie na blok GRYPS, `--no-config` na same pliki; zestaw obu flag to exit 2. Bez TTY i bez flag instalacja plików bez konfiguracji, komunikat instruktażowy. `sh uninstall.sh` korzysta z tego samego PREFIX. Markery: `# >>> gryps Git Bash >>>` i `# <<< gryps Git Bash <<<`.

- [x] Napisać W02–W05: odrzucenie Linux jako Git Bash, MINGW/MSYS przez stub uname tylko w testach jednostkowych; brak git/bash/cp; `--help`; nieznane/sprzeczne flagi; EOF; `--yes`; `--no-config`; nieterminalowy default.
- [x] Dodać testy konfiguracji: zapis przed instalacją, backup bitowo zgodny, jedna para markerów po dwukrotnej instalacji, usunięcie tylko bloku i odtworzenie treści poza blokiem. Zachować brak końcowego newline. Symlink konfiguracji lub uszkodzone/zdublowane markery: odmowa automatycznej edycji i instrukcja ręczna. Nie uruchamiać istniejących rc w celu inspekcji.
- [x] Dodać testy HOME/PREFIX zawierających `Ala Nowak`, `Zażółć [1]`, apostrof i literalny `$`; źródłowanie wygenerowanego bloku ma ustawić właściwy PATH/completion bez wykonania tekstu ze ścieżki.
- [x] Dodać test kolizji: istniejące obce binarium/completion, zmodyfikowany plik po instalacji, niezgodny PREFIX, ponowny uninstall. Wymagać manifestu z sumami i listą dokładnie własnych plików; odmawiać nadpisania obcych plików i zachować pliki zmienione po instalacji. Manifest też należy do GRYPS i zostaje usunięty dopiero po skutecznym cleanup.
- [x] Uruchomić `bash tests/test-windows-install.sh`; potwierdzić czerwone testy przed kodem.
- [x] Wdrożyć POSIX sh: preflight, staging kopii i backupów, rollback dotkniętych plików przy błędzie; `cp`/`chmod` zamiast założenia GNU install. Sprawdzić wersję artefaktu przed instalacją i po. Aktualizacja istniejącej własnej instalacji zachowuje jej kopię do pomyślnego końca.
- [x] Zapis konfiguracji: tylko kompletny własny blok, bez `eval`; literalne shell quoting dla niestandardowego PREFIX; backup w unikalnym pliku bez nadpisywania wcześniejszych backupów. Uninstall backupuje rc i usuwa tylko kompletny blok związany z instalacją tego PREFIX.
- [x] Dodać diagnostykę `.bash_profile`/`.bash_login`/`.profile`: ostrzec, gdy nie można potwierdzić ładowania `.bashrc`, pokazać ręczny source bez automatycznego przepisywania profilu. Po uninstall podać `type -a gryps`.
- [x] Sprawdzić oficjalne wymagania ble.sh i rzeczywisty Git Bash. Jeżeli brak potwierdzenia, wykryć znane pliki, wyjaśnić dostępność zwykłego TAB i zrezygnować z pobierania; instalacja GRYPS zawsze offline. Jeżeli potwierdzono zgodność, osobny opt-in dla dodatku z oficjalnego źródła, nigdy objęty samym `--yes`; oddzielny dowód i test trybu offline.
- [ ] Uruchomić `make windows`, `bash tests/test-windows-install.sh`, `sh -n packaging/windows/*.sh`; te same testy natywnie w Task 4. Zatrzymać testy stubów jako testy logiki, nie oznaczać ich dowodem W02/W05 Windows.

### Task 3: Natywna semantyka Git Bash i completion

**Files:** Create `tests/test-windows.sh`, `tests/run-platform-tests.sh`; modify `tests/test-completion.sh`, `tests/test-push-feedback.sh`, odpowiednie testy PTY; `bin/gryps`/`completions/gryps.bash` tylko dla udowodnionych błędów.

**Interfaces:** `bash tests/run-platform-tests.sh` uruchamia wspólne zestawy na artefakcie `GRYPS` (default dist/gryps). `bash tests/test-windows.sh` wymaga prawdziwego uname MINGW/MSYS i failuje poza nim. Repo testowe, Git config i HOME wyłącznie w katalogach tymczasowych; bez ustawiania konfiguracji właściwego repo/użytkownika.

- [x] Dodać W06/W07: pełne wywozka, `kapus -- ts`, ścieżki z podkatalogów, nazwy Unicode/ze spacją/`[]`, gałęzie. Zweryfikować `-o filenames` oraz istniejący fallback nosort. Najpierw uruchomić dodane przypadki na obecnym kodzie i zapisać wynik; poprawiać dopiero wykazane defekty.
- [x] Dodać W08/W09/W12/W13 na natywnym Windows: staging, commit, status, oba diff, kartoteka, fetch/push do lokalnego bare, stash push/pop i reflog. Sprawdzać kody oraz stan Git, nie tylko komunikaty. Repo pod dyskiem C z Unicode/spacją; użyć ścieżki MSYS ustalonej przez `pwd`, bez twardego założenia /tmp jako dysku C.
- [x] Przetestować osobne repo `core.autocrlf=false` i `true`, `core.filemode=false`; ustawienia tylko fixture. Sprawdzić bajty LF/CRLF przed i po operacjach bez checkout; operacje checkout porównywać z kontraktem Git i atrybutami. Nie oczekiwać identycznej reprezentacji working tree przy różnych ustawieniach Git.
- [x] Dodać W11 bez TTY: odmowa destrukcji, brak zmiany plików/HEAD/index oraz jawny `-f`. Sprawdzić `--`, `:(top)`, ścieżki `/c/...` i brak nieuzasadnionego globalnego wyłączenia konwersji MSYS.
- [ ] W10 i interaktywne W11: przygotować dowód w prawdziwym mintty lub Windows Terminal dla pusta wywozka + staging, odmowy/zgody, podglądu i `-f`. Istniejące testy wymagają util-linux `script`; nie udawać PTY przez stub. Jeżeli runner nie oferuje PTY, CI oznacza tylko opcjonalne przypadki jako SKIP z przyczyną; krytyczny scenariusz pozostaje oczekujący na ręczny dowód Windows.
- [x] Wrapper wspólnych zestawów ma zachować fail-fast/exit code. Wszystkie platformowe pominięcia wypisywać jako `SKIP: <test>: <powód>`; zsh i util-linux mogą być opcjonalne, semantyka Git nie.
- [ ] Dla każdego defektu najpierw minimalna czerwona regresja, następnie poprawka zgodna z Bash 3.2. Uruchomić `make test`, `make lint`, `make macos` na właściwych platformach i nowy wrapper na Windows.

### Task 4: CI i kompletne wydanie

**Files:** Modify `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `Makefile`; create `packaging/verify-release.sh`, `tests/test-release-artifacts.sh`.

**Interfaces:** `sh packaging/verify-release.sh` sprawdza dokładnie wersję z VERSION i cztery niepuste archiwa: `gryps_VERSION-1_all.deb`, `gryps-VERSION-macos.tar.gz`, `gryps-VERSION-macos.zip`, `gryps-VERSION-windows-gitbash.zip`; sprawdza też wersjonowany standalone gryps. Niespójność/brak/uszkodzenie = nonzero.

- [x] Napisać negatywne testy walidatora: usunięty każdy wymagany asset, zerowa długość, inna wersja, uszkodzony ZIP, niewstrzyknięta wersja. Potwierdzić FAIL przed implementacją walidatora, potem PASS z prawdziwymi buildami.
- [x] CI Windows: `windows-latest`, `shell: bash`, potwierdzenie uname i `command -v bash/git`; nie MSYS alternatywny do Git for Windows. Jawnie przygotować make i archiwizator, sprawdzić ich ścieżki/wersje; shellcheck może zostać jobem Linux. Nie polegać na domniemanej obecności make/zip. Build korzysta z `make build`, nie surowego źródła.
- [x] Dodać Windows W01–W14: build, inspekcja, instalacja w nietypowym HOME, runtime wrapper, testy Windows, upload ZIP z `if-no-files-found: error`. Na Linux/macOS zachować obecne macierze; lint obejmuje nowe skrypty i testy zgodnie z ich shebang. Ewentualne CRLF checkout rozwiązać regułami `.gitattributes` dla skryptów, z uzasadnieniem; nie przez globalny git config użytkownika.
- [x] Wydzielić workflow walidacji możliwy do wywołania z CI i release lub równoważne jobs. Publikacja release ma `needs` Linux, macOS, Windows i lint dla dokładnie tagowanego SHA, nie wyniku dawnego runu na main. Do joba publikacji pobierać zweryfikowane paczki.
- [x] Sprawdzić tag=VERSION, odpalić walidator kompletności i zawartości przed jakimkolwiek `gh release create`. Utworzyć draft, przesłać pełny zestaw i porównać listę/rozmiary Assets, dopiero wtedy opublikować. Niepowodzenie uploadu pozostawia niepubliczny draft, nigdy częściowy publiczny release.
- [x] Testować orkiestrację lokalnie przez stub `gh`, który zapisuje wywołania i symuluje błąd uploadu; sprawdzić, że publish nie występuje po błędzie. To dowód logiki, nie PASS W16 rzeczywistej publikacji.

### Task 5: Dokumentacja, wersja i raport akceptacji

**Files:** Modify `README.md`, `packaging/windows/README-Windows.md`, `CHANGELOG.md`, `VERSION`, `tests/test-v141.sh`; create `docs/INSTALL-WSL.md`, `docs/GRYPS-1.5.0-ACCEPTANCE.md`.

**Interfaces:** Dokumentacja używa identycznych nazw/flag/markerów jak Task 1–4. Raport ma kolumny ID, platforma, polecenie/dowód, wynik, brakujący krok; wyniki PENDING dla niewykonanych scenariuszy, nie fikcyjne PASS/SKIP.

- [x] Dodać dwie odrębne instrukcje Windows, zachowując pełny słownik nad changelogiem. Przykład ZIP 1.5.0, Git Bash bez WSL, `sh ./install.sh`, reinstalacja/uninstall z PREFIX, PATH i profile, `type -a gryps`, Git config, ograniczenia fontów/TTY. Opisać zwykły TAB jako dostępny bez dodatków.
- [x] WSL: oficjalne wymagania, admin PowerShell tylko do włączenia systemowej funkcji, `wsl --install -d Ubuntu`, `wsl -l -v`; apt/Git/Bash i DEB wyłącznie w Ubuntu; testy wersja/pomoc/lipo; ~/workspace zamiast /mnt/c i osobna tożsamość Git. Linki do oficjalnych źródeł.
- [ ] Wykonać instrukcję na rzeczywistym WSL2 i zapisać wersję Windows/WSL/Ubuntu, instalację DEB oraz wyniki. Brak dostępu pozostawia W15 PENDING i blokuje pełny DoD, nie blokuje niezależnej implementacji.
- [x] Poprawić T102 w `tests/test-v141.sh:514`: obecnie wymaga literalnie 1.4.1. Zachować test semantyki 1.4.1, lecz porównywać wynik `wersja` z bieżącym VERSION, a kontrakt nowego wydania 1.5.0 weryfikować w testach Windows/release. Najpierw wykazać, że stary T102 odrzuca nową wersję.
- [x] Po zielonej weryfikacji kodu ustawić VERSION=1.5.0 i dodać CHANGELOG z zakresem oraz ograniczeniami; ponownie zbudować/testować artefakty z faktycznym 1.5.0.
- [ ] Końcowe komendy: `make test`, `make lint`, `make deb`, `make macos`, `make windows`, `make test-windows` na natywnym Windows, `sh packaging/verify-release.sh`; sprawdzić wersję binariów we wszystkich paczkach. Zbierać wyniki z właściwych systemów, nie utożsamiać cross-build z testem runtime.
- [x] Wypełnić raport W01–W16. W16 rzeczywiste Assets dopiero po decyzji właściciela o tagu/publikacji; przed nią dowód preflight i dry-run oznaczyć osobno. Bez pełnych dowodów nie deklarować zakończenia całego DoD.
- [x] Przegląd końcowego diff, bezpieczeństwa instalatora i zgodności SDD; użyć verification-before-completion i requesting-code-review. Commity/gałęzie tylko zgodnie z uprawnieniami środowiska; nie omijać blokad przez ręczną edycję .git. Oddać raport zmian, testów i pozostałych bramek bez push.

## Stan przygotowania

Plan sprawdzony względem W01–W16. Repo już na osobnej gałęzi `150-win`; nie ma potrzeby tworzenia kolejnej. W chwili planowania lokalnie dostępne make/zip/unzip; brak shellcheck i zsh. Bazowe `make test` zakończone kodem 0; testy Zsh jawnie SKIP z powodu braku interpretera. Plan zatwierdzony przez użytkownika, wykonanie bezpośrednie. Implementacja i lokalna weryfikacja zakończone; nieodhaczone kroki wymagają rzeczywistych platform. Aktualny stan i ograniczenia: docs/GRYPS-1.5.0-ACCEPTANCE.md.
