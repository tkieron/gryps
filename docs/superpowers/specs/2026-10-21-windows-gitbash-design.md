# GRYPS 1.5.0 — Gryps przekracza granice

Status: zatwierdzony SDD dostarczony przez właściciela w rozmowie; poniżej zapis kontraktów do planu wykonawczego. Źródłem wymagań pozostaje pełny SDD z rozmowy.

## Cel i baza

Oficjalna instalacja Windows 10/11 przez Git Bash, bez WSL, administratora i obowiązkowych dodatków. WSL2/Ubuntu to udokumentowany wariant Linux. Wspólny silnik Bash i completion dla Linux, macOS i Windows; bez PowerShell, EXE, GUI i funkcji Git specyficznych dla Windows.

Zweryfikowana baza: VERSION `1.4.1`, HEAD `5ec60ac5cf668e3449b62268e69d5e22c1e80647`, czysta gałąź `150-win`. Bez push, tagowania i publikacji bez decyzji właściciela.

## Pakiet i instalacja

- `dist/gryps-VERSION-windows-gitbash.zip`: wersjonowany wynik `make build` jako `bin/gryps`, aktualny `share/bash-completion/completions/gryps`, `install.sh`, `uninstall.sh`, `README-Windows.md`, `VERSION`, `LICENSE`. Man opcjonalny.
- `sh ./install.sh` wykrywa `MINGW*_NT-*` / `MSYS_NT-*`, Git, Bash i narzędzia kopiowania. Linux/WSL nie udaje Git Bash.
- Domyślny PREFIX `$HOME/.local`, własny PREFIX jawnie. Bez sudo, apt, brew, rejestru i systemowego PATH.
- Jedyny dopisek do `.bashrc`: oznaczony blok PATH i completion, po zgodzie, z backupem istniejącej konfiguracji i bez duplikatów przy reinstalacji. Wykryć problem ładowania `.bashrc` z `.bash_profile` i podać instrukcję.
- `--yes` świadomie zezwala na konfigurację; `--no-config` instaluje same pliki. Bez TTY brak pytań i brak niejawnej modyfikacji konfiguracji.
- ble.sh opcjonalne: wykrywanie, weryfikacja zgodności Git Bash przed rekomendacją, instalacja tylko za osobną zgodą, z oficjalnego źródła i nigdy offline. Bez dowodu kompatybilności zwykły TAB bez obietnicy menu.
- Zainstalowane `gryps wersja` podaje VERSION, nigdy `dev`. Uninstaller usuwa wyłącznie własne pliki i własny blok; zachowuje inne ustawienia oraz podaje diagnostykę `type -a gryps`.

## Runtime i TAB

Bash 3.2+ pozostaje minimum. Bez `eval`, niecytowanych ścieżek i nieuzasadnionej konwersji ścieżek. Zweryfikować MSYS argument conversion, `/c/...`, spacje, polskie znaki, nawiasy `[]`, narzędzia systemowe i wywołanie Windows Git. Nie zmieniać `core.autocrlf` ani `core.filemode`; testować LF i CRLF.

Zachować TTY/-f dla poleceń destrukcyjnych, `--cicho`, stdout/stderr i exit code. Zwykły completion używa `-o filenames`, `nosort` z fallbackiem; nazwy w grupach, gałęzie i ścieżki z podkatalogów. Rzeczywiście aktywne zgodne ble.sh może dostarczać opisy. Czytelność terminala nie może zależeć od emoji.

## Repo i dokumentacja

Nowe `packaging/windows/{build-gitbash.sh,install.sh,uninstall.sh,README-Windows.md}`, `docs/INSTALL-WSL.md`. Makefile: `windows`, test Windows i weryfikacja ZIP. CI: natywny Git Bash na windows-latest, jawne przygotowanie narzędzi lub wrappery bez make; utrzymanie Linux/macOS. Release: testy i kontrola obecności DEB, obu archiwów macOS oraz ZIP Windows przed publikacją; żadnego częściowego publicznego wydania.

README zachowuje pełny słownik wysoko, nad historią zmian. Osobne instrukcje „Windows (Git Bash — zalecane)” i „Windows (WSL2 — alternatywa)”. Git Bash: Git for Windows, ZIP, `sh ./install.sh`, nowy terminal, wersja/podpowiedzi/lipo; diagnostyka PATH, `.bashrc`, `.bash_profile`, TTY, konfiguracji Git i wielu instalacji. Nigdy DEB w Git Bash.

WSL: Windows 10/11 i uprawnienia organizacji, `wsl --install -d Ubuntu` w administracyjnym PowerShell jako instrukcja systemowa (nie implementacja GRYPS), restart w razie potrzeby, `wsl -l -v`; w Ubuntu Git/Bash i instalacja `gryps_1.5.0-1_all.deb`, smoke testy. Preferować `~/workspace` nad `/mnt/c`; tożsamość Git skonfigurować osobno w Ubuntu.

VERSION i CHANGELOG aktualizować do 1.5.0 po zielonych testach. Zewnętrzne wyniki i niedostępne środowiska raportować prawdziwie.

## Akceptacja

| ID | Dowód wymagany przez SDD |
|---|---|
| W01 | Build ZIP i inspekcja pełnej zawartości oraz wersjonowanego binarium |
| W02 | Instalacja Git Bash bez sudo, wersja 1.5.0 |
| W03 | Reinstalacja bez duplikacji konfiguracji |
| W04 | Uninstall zachowuje pozostałą `.bashrc` |
| W05 | HOME w `C:/Users/Ala Nowak`, poprawne cytowanie |
| W06 | `gryps wy<TAB>` daje pełne `wywozka` |
| W07 | `gryps kapus -- ts<TAB>` daje pliki |
| W08 | Status, diff, add, commit, kartoteka i kody wyjścia |
| W09 | Dziupla, wyjmij, cynk |
| W10 | Pusta wywozka ze stagingiem mówi o commicie, bez pozornego sukcesu |
| W11 | Odkrec, wykipruj, kipisz: bezpieczeństwo i zgoda/-f |
| W12 | Bez TTY brak emoji/komentarzy w danych maszynowych |
| W13 | Wielojęzyczne nazwy, CRLF/LF i poprawny TAB bez utraty danych |
| W14 | make test/lint, jawne uzasadnienie wyłącznie opcjonalnych SKIP |
| W15 | Instrukcja DEB wykonana na rzeczywistym WSL2 |
| W16 | Po świadomie utworzonym tagu v1.5.0 komplet Assets, brak pustego release |

DoD wymaga wszystkich krytycznych testów, Linux/macOS i rzeczywistego WSL2. Lokalny test na Linux nie jest dowodem Windows ani WSL2. W16 nie wolno realizować przez publikację bez decyzji właściciela.

## Źródła do weryfikacji platform

- https://gitforwindows.org/
- https://learn.microsoft.com/windows/wsl/install
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://github.com/akinomyoga/ble.sh
