# GRYPS na Windows Git Bash

Git Bash nie wymaga WSL. Wymagany Git for Windows (Git 2.23+, Bash 3.2+).
Rozpakuj ZIP i w jego katalogu uruchom `sh ./install.sh` w Git Bash.
Po instalacji otwórz nowy Git Bash i sprawdź `gryps wersja`,
`gryps podpowiedzi` oraz `gryps lipo` wewnątrz repo.

Instalacja offline do ~/.local, bez sudo i bez administratora.
`sh ./install.sh --yes` zezwala na własny blok PATH/completion w ~/.bashrc.
`sh ./install.sh --no-config` instaluje wyłącznie pliki.
Bez terminala domyślnie nie ma pytań ani zmian konfiguracji.
`--yes` i `--no-config` wykluczają się. Własny katalog:
`PREFIX="$HOME/moje narzędzia" sh ./install.sh --yes`.
Dezinstalacja: `sh ./uninstall.sh` z tego samego ZIP i tym samym PREFIX.
Kopie `.bashrc.gryps-backup.*` zostają do dyspozycji użytkownika.

## Pobranie i sprawdzenie

1. Zainstaluj [Git for Windows](https://gitforwindows.org/) i otwórz **Git Bash**.
   GRYPS nie wymaga WSL ani uprawnień administratora; zasady instalowania Git
   for Windows określa system lub organizacja.
2. Pobierz `gryps-1.5.0-windows-gitbash.zip` z
   [GitHub Releases](https://github.com/tkieron/gryps/releases/tag/v1.5.0).
3. Rozpakuj ZIP i wejdź do folderu `gryps-1.5.0-windows-gitbash`.
   Możesz użyć menu „Git Bash Here” w Eksploratorze.
4. Uruchom `sh ./install.sh`. Zgoda dotyczy wyłącznie oznaczonego bloku
   w `.bashrc`, zawierającego PATH i source completion. Istniejące pliki
   konfiguracyjne dostają unikalne kopie `.bashrc.gryps-backup.*`.
5. Otwórz nowy Git Bash. `gryps wersja` powinno wypisać `Gryps wersja 1.5.0`.
   Sprawdź `gryps podpowiedzi` i `gryps lipo` w repo.

## PATH, profile i wiele instalacji

Przy `command not found` sprawdź:

```bash
echo "$PATH"
type -a gryps
ls -l "$HOME/.local/bin/gryps"
```

Git Bash może startować jako powłoka logowania: Bash wybiera pierwszy
istniejący `~/.bash_profile`, `~/.bash_login` albo `~/.profile`.
Instalator informuje, gdy nie potwierdzi ładowania `.bashrc`.
Jeżeli nie jest ona ładowana, dodaj ręcznie do aktywnego profilu:

```bash
[ ! -f "$HOME/.bashrc" ] || . "$HOME/.bashrc"
```

W bieżącej sesji można wykonać `source "$HOME/.bashrc"`.
Instalator nie zmienia profili logowania. Symlink `.bashrc` lub zmieniony,
przerwany albo powielony blok wymagają ręcznej korekty; skrypt odmawia
automatycznego przepisywania takiego pliku. `--no-config` pozwala zainstalować
same pliki, a PATH i source completion ustawić we własnej konfiguracji.

Domyślnie instalowane są tylko `~/.local/bin/gryps`, completion i ewidencja
własności w `~/.local/share/gryps/gitbash/`. Reinstalacja aktualizuje własne
pliki. Obca kopia w miejscu docelowym lub plik zmieniony po instalacji
powodują odmowę; zrób jego kopię i rozwiąż konflikt ręcznie albo użyj innego
PREFIX. Nie usuwaj ewidencji własności przed odinstalowaniem.

Zachowaj rozpakowaną paczkę z `uninstall.sh` i `common.sh`.
Dezinstalator usuwa tylko pliki rozpoznane jako własne i dokładnie zapisany
blok GRYPS. Zachowuje resztę `.bashrc` oraz jej kopie zapasowe. Po zmianie
PREFIX użyj tej samej wartości przy odinstalowaniu, np.:

```bash
PREFIX="$HOME/moje narzędzia" sh ./uninstall.sh
hash -r
type -a gryps
```

Jeżeli komenda nadal działa, `type -a gryps` wskaże pozostałe instalacje
(np. osobną kopię ze źródeł). Pakiet `.deb` należy do Ubuntu/WSL i jest
usuwany przez jego menedżer pakietów, nie przez ten dezinstalator.

## TAB, ścieżki i terminal

Zwykły Bash TAB działa bez dodatków: nazwy grypsów, gałęzie i ścieżki,
także z podkatalogów i po `--`:

```bash
gryps wy<TAB>                 # wywozka, pełny prefiks
gryps kapus -- ts<TAB>
gryps kapus -- src/ts<TAB>
gryps skitraj -- 'Zażółć [1].txt'
```

Cytuj ścieżki ze spacjami, polskimi znakami i nawiasami. W Git Bash używaj
np. `/c/Users/Ala Nowak/repo`; GRYPS przekazuje argumenty Gitowi i nie
konwertuje ich samodzielnie. Używaj TAB, aby Bash prawidłowo zacytował nazwę.
Bash 3.2 używa fallbacku bez `nosort`, więc kolejność może zależeć od Readline.
`gryps podpowiedzi` zawsze podaje opis i odpowiednik Git.

ble.sh jest opcjonalne. Instalator wykrywa znane lokalizacje jego plików,
ale niczego nie pobiera ani nie instaluje. Zaawansowane menu w Git Bash
nie zostało tu potwierdzone na rzeczywistym terminalu. Oficjalny projekt:
[akinomyoga/ble.sh](https://github.com/akinomyoga/ble.sh).
Samo istnienie pliku nie oznacza aktywnego rozszerzenia; opisy wymagają jego
rzeczywiście aktywnego, zgodnego API. Podstawowy TAB nie zależy od ble.sh.

Git Bash/mintty i Windows Terminal mogą różnić się fontem i wyświetlaniem
emoji; znaczenie komunikatów pozostaje w tekście. Potoki i przekierowania
nie dostają terminalowych ozdobników. Destrukcyjne polecenia wymagają
terminala i świadomej zgody albo jawnego `-f` zgodnie z pomocą komendy.
Nie dodawaj `-f` jedynie w celu obejścia problemu z TTY.

## Zakończenia linii i konfiguracja Git

GRYPS nie zmienia `core.autocrlf`, `core.filemode`, tożsamości ani innych
ustawień Git podczas instalacji. Sprawdź ich źródła przez `git config --show-origin`.
LF w obiektach Git i CRLF w plikach roboczych mogą być prawidłową konwersją
Git; zasady zespołu najlepiej zapisać w `.gitattributes`. Windows zwykle
nie odwzorowuje uniksowego bitu wykonywalności tak jak Linux. Ustawienia
Git for Windows i Ubuntu/WSL są niezależne; `gryps kartoteka` pomaga
zdiagnozować tożsamość, `gryps meldunek` ustawia ją na świadome żądanie.

Jeżeli organizacja zabrania Git for Windows lub skryptów, postępuj zgodnie
z jej polityką. WSL2 jest osobną ścieżką Linux opisaną w repozytorium
w `docs/INSTALL-WSL.md`; nie jest wymagane do tej instalacji.
