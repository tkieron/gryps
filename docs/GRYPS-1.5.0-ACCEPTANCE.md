# GRYPS 1.5.0 — raport akceptacji

Baza: `1.4.1`, HEAD `5ec60ac5cf668e3449b62268e69d5e22c1e80647`,
gałąź `150-win`. Implementacja i testy lokalne: Linux, 2026-10-21.
Brak push, tagu i publikacji. Pełny DoD pozostaje otwarty do potwierdzenia
natywnego Windows, macOS, rzeczywistego WSL2 i wydania przez właściciela.

`PASS lokalny` oznacza wykonany test na Linux. `PENDING` oznacza brak dowodu
na wymaganej platformie, nie pominięcie krytycznego testu ani sukces CI.
Joby w `.github/workflows/ci.yml` są przygotowane, ale ich wykonanie nie
zostało zlecone z tego środowiska.

| ID | Lokalny dowód / polecenie | Stan wymaganej platformy / brakujący krok |
|---|---|---|
| W01 | `make windows`, `tests/test-windows-package.sh`: komplet plików, wersjonowany artefakt | PASS lokalny; natywny build Windows PENDING CI |
| W02 | `tests/test-windows-install.sh`: rzeczywisty instalator, na Linux tylko uname zastąpiony | PENDING: `tests/test-windows.sh`, prawdziwy Git Bash, 1.5.0 |
| W03 | Reinstalacja z `--yes`, identyczny rc, pojedynczy blok | PASS logiki; Windows PENDING CI |
| W04 | Usunięcie tylko bloku, zachowane obce ustawienia, brak finalnego newline, zmienione pliki odrzucone | PASS logiki; Windows PENDING CI |
| W05 | HOME ze spacjami, Unicode, `[]`, apostrofem i `$`; source działa | PASS logiki; natywne C:/Users w `test-windows.sh` PENDING |
| W06 | `tests/test-completion.sh`: pełne wywozka; `test-smart-tab.sh`: API ble.sh i prefiksy | PASS lokalny; rzeczywisty TAB Git Bash PENDING |
| W07 | Completion plików po `--`, z podkatalogów, spacje i Unicode | PASS lokalny; rzeczywisty TAB Git Bash PENDING |
| W08 | `make test`, `test-portability.sh`: Git status/diff/staging/commit/kartoteka oraz exit code | PASS Linux; Windows i macOS PENDING CI |
| W09 | Stash push/pop i reflog w rzeczywistych tymczasowych repo | PASS Linux; Windows PENDING CI |
| W10 | `test-push-feedback.sh` w Linux PTY; bez TTY wspólne testy push | PASS Linux; komunikat w prawdziwym mintty/Windows Terminal PENDING |
| W11 | Brak TTY odmawia, pliki zachowane, jawne -f/podgląd; Linux PTY w test-v141 | PASS Linux; Windows bez TTY PENDING CI, interakcja PENDING ręcznie |
| W12 | Surowy status/diff bajtowo jak Git, --cicho i maszynowe wyjście we wspólnych testach | PASS Linux; Windows PENDING CI |
| W13 | `test-portability.sh`: autocrlf false/true, LF/CRLF, filemode=false, Unicode i TAB | PASS Linux; Windows PENDING CI |
| W14 | `make test`, `make lint`; ShellCheck 0.9.0 i Zsh 5.9 rozpakowane w /tmp | PASS Linux; macOS Bash 3.2 i Windows PENDING CI |
| W15 | `docs/INSTALL-WSL.md`; cross-build i rozpakowanie DEB lokalnie | PENDING: wykonać instrukcję na rzeczywistym WSL2 |
| W16 | `verify-release.sh`, `test-release-artifacts.sh`, `test-release-publish.sh` (gh stub) | PASS logiki/preflight; faktyczne Assets PENDING po decyzji o tagu |

## CI 2026-10-22 i poprawka ścieżek testowych

[Run 39727989552](https://github.com/tkieron/gryps/actions/runs/39727989552),
commit `0dd5948a7c`: Linux (ubuntu-22.04/latest), macOS (14/latest), lint
oraz job DEB/kompletności wydania zakończyły się sukcesem. Windows zaliczył
wspólny zestaw semantyczny (w tym 298/298 asercji test-v141; 7 opcjonalnych
przypadków PTY pominiętych), po czym `test-portability.sh` zakończył się
`fatal: Invalid path '/tmp'` i kodem 128. Pakowanie/instalacja Windows
w tym runie nie zostały uruchomione.

Źródłem błędu jest granica MSYS/native Git: automatyczna konwersja nie
obejmuje absolutnych argumentów POSIX zawierających nawiasy `[]`.
Fixture ma celowo takie nazwy, więc teraz normalizuje swój katalog
przez `cygpath -m` na Windows, zachowując wszystkie nietypowe znaki.
Launcher Windows przekazuje również jawnie przekonwertowane ścieżki archiwum
i katalogu do natywnego unzip; tę granicę obejmuje osobna regresja.
Nie zmieniono silnika GRYPS ani konwersji dowolnych argumentów użytkownika.

Regresja `tests/test-portability-paths.sh` odtwarza tę granicę na Linux,
przekazując pozostałe operacje prawdziwemu Gitowi: przed poprawką odtwarza
błąd, po poprawce przechodzi. Jest to test fixture, nie dowód nowego
natywnego runu Windows. Ponowne wykonanie Windows CI z poprawką pozostaje
PENDING; powyższe sukcesy macOS/Linux dotyczą wskazanego commita.

## Przegląd i końcowa weryfikacja lokalna

Niezależny przegląd superpowers nie znalazł problemów krytycznych.
Trzy zgłoszenia ważne zostały poprawione: test symlinków sprawdza rzeczywistą
zdolność systemu zamiast zakładać ją w MSYS; walidator wymaga pełnego zestawu
plików instalatora macOS; scenariusze Git sprawdzają jawny `:(top)`, absolutne
ścieżki i bajty po checkout LF/CRLF. Wariant ścieżki `C:\...` jest wykonywany
wyłącznie w prawdziwym jobie Windows. ZIP powstaje na tym samym systemie
plików co `dist`, aby końcowe zastąpienie było atomowe.

Obejście MSYS `ln -s` przez zwykłe kopiowanie odtworzono lokalnym fixture:
przed poprawką test był czerwony, po poprawce pomija wyłącznie test symlinków
z jawnym uzasadnieniem; wszystkie testy instalacji nadal obowiązują.
Negatywny test ZIP macOS bez completion Zsh również był czerwony, a po
poprawce walidatora przechodzi przez poprawne odrzucenie paczki.

Workflow sprawdzony także przez actionlint 1.7.12 i ShellCheck 0.9.0.
Pełny `make test` obejmuje zestawy 91, 80, 21, 56, 15, 58, 323 oraz 12
asercji i dodatkowe scenariusze build/przenośności. Testy Git celowo wywołują
ostrzeżenia o zamianie LF na CRLF w fixture `core.autocrlf=true`; sprawdzane
są oczekiwane bajty oraz zachowanie niezmienionych ustawień.

## Odtworzenie testów

Linux (make, Git, Bash, zip/unzip, dpkg-deb i ShellCheck w PATH):

```bash
make test
make lint
make deb macos windows
make test-windows-package
sh packaging/verify-release.sh
bash tests/test-release-artifacts.sh
bash tests/test-release-publish.sh
```

Natywny Git Bash (bez make; zip/unzip potrzebne do budowy/testów, nie instalacji):

```bash
sh packaging/windows/build-gitbash.sh
bash tests/run-platform-tests.sh
bash tests/test-windows-package.sh
bash tests/test-windows-install.sh
bash tests/test-windows.sh
```

`make test-windows` jest równoważnym wejściem, gdy dostępne jest make.
`test-windows.sh` odmawia na Linux/WSL: fałszywe uname w testach instalatora
nie dowodzi natywnej zgodności.

## Ręczne potwierdzenie Windows

W osobnym testowym repo, w mintty i ewentualnie Windows Terminal:

1. Zanotuj Windows/Git/Bash, emulator terminala, rzeczywiste `uname -s`,
   lokalizację repo `/c/Users/...` ze spacją i polskimi znakami, `type -a gryps`.
2. Sprawdź `gryps wersja`, `gryps pomoc`, `gryps podpowiedzi`.
3. Wpisz `gryps wy` i naciśnij TAB: pełne `wywozka`.
   Utwórz plik `ts Zażółć [1].txt`, sprawdź `gryps kapus -- ts<TAB>`
   oraz ścieżkę z podkatalogu i completion gałęzi.
4. Repo z commitem wysłanym do lokalnego bare remote: dodaj zmianę do stagingu,
   uruchom `gryps wywozka` bez nowego commita. Oczekiwane: wskazówka
   `gryps przyklep`, brak komunikatu o sukcesie wysyłki, remote HEAD bez zmian.
5. W oddzielnych repo/plikach sprawdź `odkrec`, `wykipruj`, `kipisz`:
   odmowa i odpowiedź „nie” zachowują dane; zgoda wykonuje wyłącznie opisany
   zakres; `wykipruj` pokazuje podgląd. `-f` wyłącznie na świadomie
   przygotowanych danych testowych. Bez TTY brak automatycznej zgody.
6. Sprawdź czytelność tekstu z fontem bez emoji. Zwykły TAB wystarcza.
   ble.sh można ocenić osobno dopiero po rzeczywistym uruchomieniu; jego
   brak nie blokuje podstawowej instalacji i nie jest dowodem zgodności menu.

## Rzeczywisty WSL2 i release

W15: zapisz wynik `wsl -l -v` (VERSION=2), wersję Windows i Ubuntu,
instalację dokładnego DEB, `gryps wersja/pomoc/lipo` i lokalizację repo.
Bez tych danych W15 pozostaje PENDING.

W16: właściciel decyduje o utworzeniu/push tagu `v1.5.0`.
Workflow wymaga zielonego reusable CI dla tego samego SHA, kompletu DEB,
macOS ZIP/TAR i Windows ZIP oraz standalone `gryps`. Dopiero po weryfikacji
przesłanych nazw i rozmiarów Assets draft staje się publiczny. Błąd
pozostawia draft; nie wolno nazywać lokalnej symulacji opublikowanym wydaniem.
