# GRYPS 1.3.0 — Specyfikacja funkcjonalna (FINAL + komunikacja zwrotna)

**Status:** zatwierdzony zakres funkcjonalny; uzupełnienie: „Gryps gada” • **Punkt wyjścia:** GRYPS v1.2.2 • **Platformy:** Linux + macOS
**Hasło wydania:** *Mniej klepania, więcej kminienia.*
**Cel:** użyteczna, zabawna nakładka na Git — sensowne domyślne zachowania, minimalna liczba flag, brak nieoczekiwanej utraty pracy oraz czytelna, dowcipna komunikacja zwrotna.

> **Uwaga:** to dokument do implementacji i testów v1.3.0, **nie** informacja o ukończonej wersji. Wszystkie komendy Git pozostają dostępne przez oryginalne `git`.

## 1. Zasady projektowe

1. **Grypsera z sensem.** Nazwa musi skojarzyć się z realnym zachowaniem. W opisach rozróżniamy słowa związane z gwarą więzienną (`kapuś`, `dziara`), szerszy slang (`kwity`, `cynk`, `układy`, `odkręcić`) i neologizmy GRYPS (`odkitraj`). Nie twierdzimy, że każde słowo jest historycznym terminem więziennym.
2. **Dobry default.** Bez argumentów komenda wykonuje najczęstsze, przewidywalne zadanie, jeśli jest ono bezpieczne. Nie wykonujemy destrukcyjnej operacji przez samo wpisanie nazwy.
3. **Git pod spodem.** GRYPS nie przepisuje algorytmów Git. Przekazuje argumenty jako tablice (bez `eval`), zachowuje kody wyjścia i umożliwia świadome użycie flag Git.
4. **Bez niespodzianek.** Wyraźnie rozróżniamy zmiany w working tree, index (staging), commitach i remote. Destrukcyjne komendy pokazują zakres strat i wymagają potwierdzenia, chyba że użytkownik jawnie wymusi działanie.
5. **CLI nadające się do automatyzacji.** Czytelny tekst i humor dla ludzi, a dla `--porcelain`, `-z`, przekierowania i skryptów: brak śmieci na standardowym wyjściu i zbędnych ozdobników na stderr. Błędy na stderr.
6. **Kompatybilność.** macOS: systemowy Bash 3.2, Zsh jako powłoka użytkownika. Linux: Bash, bez obowiązkowego Homebrew/GNU coreutils. Nie dodajemy ciężkich zależności.

## 2. Nowe komendy — zatwierdzony słownik (8)

| Gryps | Znaczenie w języku | Odpowiednik Git | Domyślna kmina |
|---|---|---|---|
| `kwity` | kwity = dokumenty, dowody; „pokaż papiery” | `git diff` | pokaż osobno zmiany **unstaged** i **staged** |
| `odkitraj` | neologizm od „kitrać” = chować; wyjmij rzeczy z poczekalni | `git restore --staged` / `git reset --` | zdejmij z indexu **wszystkie** zmiany, bez dotykania plików |
| `kapus` | kapuś = donosiciel; „kto sypnął tę linijkę?” | `git blame` | pokaż autora zmian wskazanego pliku |
| `dziara` | dziara = tatuaż, znak; trwałe oznaczenie | `git tag` | bez argumentów lista tagów; z nazwą utwórz tag |
| `cynk` | cynk = informacja, ostrzeżenie, wskazówka | `git reflog` | pokaż ostatnie **20** zdarzeń w reflog HEAD |
| `kasacja` | termin prawny — podważenie orzeczenia; metaforyczne odwrócenie decyzji | `git revert` | odwróć wskazany commit **nowym** commitem |
| `uklady` | układy = kontakty i powiązania | `git remote` | wyświetl remotes wraz z fetch/push URL |
| `odkrec` | odkręcić = cofnąć własne działania | `git restore --worktree` | odrzuć **unstaged** zmiany tylko w jawnie podanym pliku/plikach, po potwierdzeniu |

Pisownia CLI jest bez polskich znaków: `kapus`, `uklady`, `odkrec`. **Zatwierdzone przez właściciela produktu:** `kwity` (nie `przeswietl`), `kasacja` (nie `odwolaj`), `cynk` (nie `slady`).

## 3. Kontrakty nowych komend

### 3.1 `gryps kwity [flagi-diff] [-- pliki…]`

- Bez argumentów: dwie podpisane sekcje: **„Na blacie (unstaged)”** = `git diff`; **„Skitrane (staged)”** = `git diff --cached`.
- Z typowymi flagami prezentacji, np. `--stat`, `--name-only`, oraz ze ścieżkami pokazuje **oba** zakresy, z tymi samymi filtrami.
- Gdy użytkownik poda `--cached` albo `--staged`, wykonuje **wyłącznie** żądany zakres (nie powtarza diff).
- `--no-index` (porównanie ścieżek niezależnie od repo) oraz tryby czysto maszynowe (`--quiet`, `--exit-code`, `--raw`) wymagają zachowania semantyki exit code i braku komentarzy w stdout; specyfikacja implementacji ustali tryb pojedynczego wywołania tam, gdzie dwie sekcje zmieniałyby znaczenie flag.
- **Nieśledzone pliki nie pojawiają się w `git diff`** — odsyłamy do `gryps lipo`; nie tworzymy automatycznie pseudo-diff dla nowych plików.

Przykłady:
```sh
gryps kwity
gryps kwity --stat
gryps kwity --staged
gryps kwity -- src/main/java/Serwis.java
```

### 3.2 `gryps odkitraj [-- pliki…]`

- Bez argumentów usuwa **wszystkie** zmiany z indexu w całym repo (również gdy polecenie uruchomiono w podkatalogu). Robocze pliki i ich zawartość pozostają nietknięte.
- Z argumentami ścieżek wycofuje tylko wybrane elementy.
- Preferujemy `git restore --staged` w repo z istniejącym `HEAD`; w **nowym repo przed pierwszym commitem** bezpieczny fallback `git reset -- <pathspec>` (ponieważ `restore --staged` nie może rozwiązać `HEAD`). Implementacja może używać `git reset --` także w pozostałych przypadkach, jeżeli efekty indeks/working tree są identyczne i testy to potwierdzają.
- Nie wykonuje `git restore --worktree`, `reset --hard` ani usuwania plików z dysku. Bez dodatkowego potwierdzenia — operacja niedestrukcyjna.

Przykłady:
```sh
gryps odkitraj
gryps odkitraj -- src/config.yml
gryps odkitraj -- "plik z odstępami.txt"
```

### 3.3 `gryps kapus [flagi-blame] -- <plik>`

- Wymaga wskazania pliku; brak pliku = pomoc + exit różny od 0.
- Przekazuje obsługiwane opcje `git blame`, np. `-L 20,45`, `-w`, `--line-porcelain`.
- Nie modyfikuje repozytorium. Przy wyjściu w formacie porcelain żadnych ozdobników w stdout.

```sh
gryps kapus -- src/App.java
gryps kapus -L 20,45 -- src/App.java
```

### 3.4 `gryps dziara [nazwa] [opcje-taga]`

- Bez argumentów: `git tag --list --sort=-creatordate` (sortowanie wg daty znacznika lub commita; dla tagów lightweight nie jest to osobna data utworzenia taga).
- `gryps dziara v1.3.0`: tworzy **lekki tag**, zgodnie ze standardową semantyką `git tag`.
- Jawne `-a -m "opis"` tworzy tag adnotowany (zalecany dla oficjalnych wydań); przekazujemy natywne argumenty Gita.
- Żadnego automatycznego `git push --tags` ani wymuszania istniejącego taga.

```sh
gryps dziara
gryps dziara v1.3.0
gryps dziara -a v1.3.0 -m "Wydanie GRYPS 1.3.0"
```

### 3.5 `gryps cynk [opcje-reflog]`

- Bez argumentów: `git reflog show -n 20 HEAD` (20 lokalnych wpisów dotyczących HEAD).
- Opcje jawne (`-n 50`, `--all`, inna referencja) mają pierwszeństwo; nie dodajemy `-n 20`, jeśli użytkownik wybrał własny limit. Możliwość pokazania reflog innych referencji.
- Nie przedstawiamy refloga jako wiecznego backupu: wpisy mogą wygasnąć/przestać być dostępne po porządkowaniu Git.

```sh
gryps cynk
gryps cynk -n 50
gryps cynk --all
```

### 3.6 `gryps kasacja <commit> [opcje-revert]`

- Bez commita: tylko pomoc i błąd; **nigdy** domyślnie nie odwracamy `HEAD`.
- Dla typowego commita: `git revert --no-edit <commit>`, aby uniknąć zbędnego edytora i utworzyć nowy commit z domyślnym opisem Gita.
- Flagi jawne mają pierwszeństwo (`--edit`, `--no-commit`, `-m <parent>` przy revert merge).
- W razie konfliktu: nie robimy automatycznego `--abort` ani resetu; komunikat z następnym krokiem (`git revert --continue` / `git revert --abort`). Kod wyjścia Git pozostaje zachowany.
- Bez force-push, bez przepisywania historii Git.

```sh
gryps kasacja abc1234
gryps kasacja abc1234 --no-commit
gryps kasacja -m 1 abc1234     # commit scalający, jawny parent
```

### 3.7 `gryps uklady [podkomenda-remote] [argumenty…]`

- Bez argumentów: `git remote -v`.
- Argumenty są przekazywane do `git remote`, np. `add`, `remove`, `rename`, `set-url`, `get-url`.
- Niczego nie dopisujemy do `git config` automatycznie. Brak domyślnego `origin`.

```sh
gryps uklady
gryps uklady add origin git@example.com:ekipa/projekt.git
gryps uklady get-url origin
```

### 3.8 `gryps odkrec <plik…> [-f|--force]`

- **Wymaga co najmniej jednej ścieżki** — bez niej nie dotykamy żadnego pliku.
- Celowo przywraca tylko **working tree do zawartości indexu**: semantyka `git restore --worktree -- <pathspec>`; zmiany staged pozostają staged.
- Przed operacją pokazuje konkretne dotknięte pliki i ostrzeżenie, że niezapisane w commicie zmiany **unstaged** znikną. Wymaga potwierdzenia `[t/N]`.
- `-f` lub `--force` jako jawne flagi GRYPS umożliwiają działanie bez pytania także bez TTY; brak TTY i brak wymuszenia = bezpieczny błąd.
- Jeżeli celem użytkownika jest także cofnięcie zmian staged, **nie wolno** tego robić niejawnie przez `odkrec`. Do stagingu służy `odkitraj`; `kipisz` to odrębna, szersza operacja destrukcyjna.
- Obsługujemy nazwy z odstępami i ścieżki zaczynające się od `-` przez separator `--`.

```sh
gryps odkrec -- src/App.java
gryps odkrec -f -- config.yml
```

## 4. Zmiany w istniejących komendach — zatwierdzone defaulty

| Komenda | GRYPS 1.2.2 | Wymagane zachowanie w 1.3.0 |
|---|---|---|
| **`dziupla`** | `git stash push`, nowe pliki pozostają | `gryps dziupla` = **`git stash push -u`**: schowaj tracked + untracked, nie ignored |
| `lipo` | standardowe `git status` | bez argumentów zwięzły status z nazwą branch i ahead/behind względem **lokalnego** upstream (`git status -sb`); nie wykonuje fetch |
| `skitrac` | bez argumentów `git add -A` | **bez zmian**: staging całego repo; po sukcesie krótka informacja |
| `rakowiec` / `rakieta` | `git pull` | bez określonej strategii = `git pull --ff-only`, bez automatycznych merge/rebase |
| `wywozka` / `kopsnij` | pierwszy push dobiera remote przez konfigurację Git i ustawia upstream | zachować ten kierunek; nie narzucać `origin`, respektować `pushRemote`, `pushDefault` i jawny remote; gdy cel jest **rzeczywiście niejednoznaczny**, zgłosić błąd zamiast zgadywać |
| `kipisz` | ostrzeżenie, status i `[t/N]`; `-f` pomija pytanie | utrzymać; nie usuwać nieśledzonych plików; przed potwierdzeniem jasno pokazać zakres zmian tracked, które znikną |

### Szczegóły `dziupla` (istotne)

- **Zatwierdzone:** `gryps dziupla` domyślnie ma chować również nowe, nieśledzone pliki (`-u` / `--include-untracked`). Pliki ignorowane przez `.gitignore` pozostają na dysku.
- `gryps dziupla -m "przed przerzutką"` nadal obejmuje untracked.
- `gryps dziupla -- <pathspec>` chowa tylko wskazany zakres, łącznie z dopasowanymi plikami untracked; pozostałe pozostają nietknięte.
- Jawne opcje wyboru zakresu muszą mieć pierwszeństwo: `--all` może objąć także ignored (tylko na **wyraźne** żądanie), `--no-include-untracked` pomija untracked, `--staged` dotyczy tylko indexu, `--patch` to interaktywny wybór fragmentów; nie wstrzykujemy wtedy sprzecznych flag.
- Brak zmian do schowania: czytelny komunikat Gita i zerowy kod wyjścia, bez fałszywego potwierdzenia utworzenia stash.
- `gryps wyjmij` pozostaje `git stash pop` — możliwy konflikt wymaga działania użytkownika; nie usuwamy stasha po nieudanym przywróceniu.

### Szczegóły `rakowiec`

- Bez argumentów: `git pull --ff-only` niezależnie od ustawionego `pull.rebase` / `pull.ff` (domyślny kontrakt GRYPS, chyba że jawnie wybrano strategię).
- Przekazanie samego remote/ref, np. `gryps rakowiec origin main`, **nie** wyłącza zasady `--ff-only`.
- Jawne `--rebase`, `--no-rebase`, `--no-ff`, `--ff` oraz ewentualne opcje równoważne świadomie nadpisują domyślną strategię; implementacja nie może dokładać flag sprzecznych.
- Rozbieżne historie bez jawnej strategii: przerwanie z sugestią `gryps blaty ...`, zwykły Git rebase albo jawny `gryps rakowiec --rebase` — bez samowolnego scalania.

### Szczegóły `wywozka`

- Git wybiera cel zgodnie z konfiguracją użytkownika (`branch.<nazwa>.pushRemote`, `remote.pushDefault`, upstream i odpowiednimi ustawieniami `push.default`).
- Przy **pierwszym pushu**, gdy istnieje jednoznaczny cel i `push.default` pozwala na domyślny push, ustawia upstream dla nowej gałęzi; alternatywnie wspiera `push.autoSetupRemote` (jeżeli wersja Git go obsługuje).
- Przy **wielu remote'ach bez rozstrzygającej konfiguracji** i braku upstream: nie wywozi na `origin` „bo tak”, tylko prosi o jawny wybór.
- Respektuje `push.default=nothing` i jawne argumenty — nie obchodzi świadomej blokady użytkownika.
- Brak automatycznego `--force` / `--force-with-lease`. Oryginalny status błędu Git musi wracać jako exit code GRYPS.

## 5. Przykładowy workflow v1.3

```sh
gryps lipo                           # co się dzieje pod celą?
gryps kwity                          # kwity na robocie: unstaged i staged
gryps skitrac                        # przygotuj wszystko do commita
gryps kwity --staged                 # co już skitrane?
gryps odkitraj -- config.local.yml   # to akurat zostaw poza commitem
gryps przyklep "Posprzątana cela"    # commit
gryps wywozka                        # push do poprawnego remote

gryps dziupla                        # tracked + untracked, bez ignored
gryps spis                           # lista schowanych robót
gryps wyjmij                         # przywróć ostatnią

gryps kapus -L 10,25 -- src/App.java # kto odpowiada za linie?
gryps cynk                           # gdzie wcześniej był HEAD?
gryps kasacja deadbeef               # nowy commit odwracający

gryps dziara -a v1.3.0 -m "Wydanie"  # oznaczenie wydania
gryps uklady                         # adresy remote
```

## 6. Reguły bezpieczeństwa i UX

- **Brak podwójnej destrukcji:** `odkitraj` tylko index, `odkrec` tylko unstaged working tree, `kipisz` zakres tracked zgodny z `reset --hard`. Żadna z nich nie uruchamia niejawnie `git clean`.
- **Błędy są błędami:** odmowa, brak repo, brak wskazanego pliku/commita, konflikt, niejednoznaczny remote i błąd sieci zwracają niezerowy status.
- **Bezpieczne ścieżki:** cytowanie argumentów, `--`, `:(top)`/root pathspec w odpowiednich miejscach, pliki z odstępami, Unicode, znakiem `-`.
- **Interakcja:** dla operacji destrukcyjnych pytanie tylko z TTY. Skrypty mogą użyć świadomego `-f` tylko tam, gdzie GRYPS tę flagę definiuje.
- **Formaty maszynowe:** rozpoznawać co najmniej `lipo --porcelain`, `lipo -z`, `kwity --quiet/--exit-code`, `kapus --line-porcelain`; bez emoji, nagłówków i dekoracji na stdout. `NO_COLOR` respektowane.
- **Nie dublujemy nazw:** dotychczasowe aliasy `rakieta`, `kopsnij`, `stojka`, `zblatuj` zachowują znaczenie i działanie.

## 7. Testy akceptacyjne zachowania Gita (minimum)

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T01 | `kwity` z oddzielnymi zmianami staged + unstaged | dwa zakresy, bez duplikatów |
| T02 | `kwity --staged` | tylko staged |
| T03 | `kwity --stat -- <plik ze spacjami>` | poprawne filtrowanie |
| T04 | `kwity --exit-code` | właściwy status, czyste stdout |
| T05 | `odkitraj` z katalogu podrzędnego | cały index opróżniony, pliki nienaruszone |
| T06 | `odkitraj -- jeden_plik` | tylko ten plik wycofany ze stagingu |
| T07 | `odkitraj` przed pierwszym commitem | działa mimo braku HEAD |
| T08 | `kapus` bez pliku / z `-L` | brak pliku = błąd, zakres linii działa |
| T09 | `dziara` lista / lightweight / annotated | zgodny typ taga, brak automatycznego push |
| T10 | `cynk` domyślne / `-n 50` | odpowiednio 20 / 50 wpisów maks. |
| T11 | `kasacja` zwykłego commita | nowy revert commit, historia nienaruszona |
| T12 | `kasacja` przy konflikcie | brak kasowania pracy, podpowiedź continue/abort |
| T13 | `uklady` bez argumentów / `get-url` | remotes z URL; polecenia Git przekazane |
| T14 | `odkrec` bez ścieżki | błąd, nic nie usunięto |
| T15 | `odkrec` z odrzuceniem potwierdzenia | plik pozostaje bez zmian |
| T16 | `odkrec -f` po zmianach staged + unstaged | cofa tylko unstaged; staged pozostają |
| T17 | `dziupla` z tracked + untracked + ignored | dwa pierwsze ukryte, ignored nietknięte |
| T18 | `dziupla --all` / `--no-include-untracked` | jawne flagi mają pierwszeństwo |
| T19 | `dziupla -- pathspec` | inne ścieżki bez zmian |
| T20 | `rakowiec` na rozbieżnych branchach | domyślnie brak merge/rebase |
| T21 | `rakowiec --rebase` | jawna strategia, bez sprzecznego `--ff-only` |
| T22 | `wywozka` z `branch.pushRemote` różnym od `origin` | push na wybrany remote |
| T23 | `wywozka` bez upstream, dwa niezdefiniowane remotes | błąd zamiast losowego celu |
| T24 | `wywozka` przy `push.default=nothing` | respektuje blokadę |
| T25 | `lipo --porcelain -z` | stdout bez dekoracji, poprawne NUL |
| T26 | `kipisz` odmówiony / bez TTY | nie usuwa zmian |
| T27 | Bash 3.2 i Zsh completion | komendy i opisy dostępne na macOS |
| T28 | README, `gryps pomoc`, `gryps kmina`, manpage | pełny, zgodny słownik v1.3 |

Testy mutujące Git wykonujemy w izolowanych lokalnych repo; testy remotes na lokalnych repo bare (bez realnego push do sieci). Każdy test sprawdza także kod wyjścia i stan repozytorium po poleceniu. Testy istniejące z v1.2.2 muszą przejść nadal.

## 8. Komunikacja zwrotna — „Gryps gada” (wymaganie v1.3.0)

### 8.1 Cel i ton

**Każde interaktywne wywołanie rozpoznanej komendy ma mieć własną, krótką kwestię w grypserze** — przed działaniem, po nim albo jako komunikat o wyniku. GRYPS ma być postacią, która komentuje robotę, a nie monotonnym lektorem czy loggerem. Nazewnictwo ma być zabawne, zadziorne i związane z kontekstem Git. Humor **nie może zastępować informacji diagnostycznej**, zaciemniać wyniku ani sugerować sukcesu, kiedy Git nie wykonał operacji.

**Kontrakt interaktywnego wyświetlania:**

1. **START** (opcjonalny, głównie operacje dłuższe): co GRYPS właśnie robi, np. „Sprawdzam kwity...”.
2. **SUKCES**: zwięzłe potwierdzenie *dopiero po pomyślnym zakończeniu* operacji. W przypadku poleceń tylko do odczytu wystarczy zabawna zapowiedź/nagłówek; nie drukujemy na siłę dodatkowego „sukcesu”.
3. **PUSTO / NIC DO ZROBIENIA**: osobny żart zamiast fałszywego potwierdzenia zmiany; np. dla pustego stash nie mówimy „Fanty schowane”.
4. **OSTRZEŻENIE / POTWIERDZENIE**: jasno oznaczony zakres konsekwencji, pytanie `[t/N]`; żart jest dodatkiem do precyzyjnego ostrzeżenia.
5. **ODWOŁANE**: zrozumiała informacja „nic nie zmieniono”, nie komunikat o sukcesie.
6. **BŁĄD**: krótki gryps + autentyczny błąd Git + konkretna następna czynność, *o ile przyczyna została rozpoznana*.

Ograniczenie gadulstwa: docelowo **jedna krótka żartobliwa kwestia na wynik operacji** (dopuszczalna jedna zapowiedź dla operacji trwających dłużej); bez wieloliniowych bannerów przy każdej komendzie, bez losowych „mądrości”, bez zasypywania terminala emoji. Żarty są przewidywalne i testowalne; rotację wariantów odkładamy poza 1.3.

### 8.2 Wzorzec komunikatu i format

Interaktywne szablony:

```text
👁️ [LIPO] Cela pod obserwacją. Sprawdzam, co jest na blacie...
✅ [CZYSTA ROBOTA] Skitrane. Fanty czekają na przyklepanie.
ℹ️ [PUSTO] Nic do kitrania. Cela czysta jak po apelu.
⚠️ [UWAGA] Kipisz skasuje zmiany w śledzonych plikach. Jedziemy? [t/N]
🚨 [PRZYPAŁ] Nie poszło. Git mówi dlaczego, zobacz komunikat poniżej.
```

- **Rozdzielenie tekstu GRYPS od wyniku Git:** komunikaty GRYPS wypisujemy na `stderr` (czytelne także gdy Git wypisuje dane na `stdout`); natywny strumień stdout polecenia Git pozostaje bez zmian.
- **Tryb człowieka:** żartobliwe teksty tylko, gdy **stdout i stderr są terminalem (TTY)**, oraz nie włączono trybu cichego / maszynowego. Piped stdout, plik wyjściowy lub automatyzacja = brak dekoracji, w tym na stderr, z wyjątkiem prawdziwych błędów i wymaganych ostrzeżeń o bezpieczeństwie.
- **Tryb maszynowy:** m.in. `--porcelain`, `-z`, `--line-porcelain`, `--raw`, `--quiet`, `--exit-code` w kontekstach wymagających semantyki Git; żadnych komentarzy GRYPS na stdout **ani niepotrzebnych żartów na stderr**. Nie dodajemy własnych bajerów do formatu wyjściowego Git, nie zmieniamy `\0`, kolejności rekordów, kolorów ani kodu zakończenia.
- **Cisza na życzenie:** globalne `gryps --cicho <gryps> [argumenty]` i zmienna `GRYPS_CICHO=1` wyłączają **wyłącznie** komentarze GRYPS; wyjście Git, wymagane potwierdzenia, diagnostyka błędów i kody wyjścia nie są wyciszane. `--cicho` rozpoznajemy wyłącznie **przed** nazwą komendy; flagi po nazwie są przekazywane zgodnie z jej kontraktem. Nie przechwytujemy natywnych `git --quiet`.
- **Kolory / środowisko:** `NO_COLOR` i brak TTY wyłączają kolor/ozdobniki. Zwykłe komunikaty pozostają zrozumiałe bez emoji i kolorów; nie ma zależności od terminala z obsługą Unicode. `TERM=dumb` ma wariant bez ozdobników. Pomoc i dokumentacja mogą mieć własne dłuższe teksty.
- **Strumienie Git:** nie przechwytujemy na siłę ani nie parsujemy standardowego wyjścia komend, które mogą otwierać pager (`log`, `diff`, `blame`) lub pytać użytkownika o dane. Nie gubimy pasków postępu `clone/fetch/push`, komunikatów hooków i promptów SSH. Bez `eval`.
- **Bezpieczeństwo tekstu:** argumenty użytkownika drukowane w naszych szablonach muszą być cytowane/oczyszczane z znaków sterujących i sekwencji ANSI (zwłaszcza nieznany gryps); nie wypisujemy tokenów, haseł ani pełnych URL zawierających poświadczenia.

### 8.3 Słownik pozytywnych zwrotek — wszystkie komendy

| Komenda (oraz alias) | Sytuacja | Wzorcowa kwestia GRYPS |
|---|---|---|
| `mury` | udany `init` | „Mury stoją. Teraz można kombinować.” |
| `jumaj` | udany `clone` | „Fanty przywiezione z wolki. Repo siedzi już z nami.” |
| `lipo` | odczyt statusu | „Zerkam przez lipo. Zobaczymy, co leży na blacie.” |
| `skitrac` | udany `add` | „Skitrane. Fanty czekają na przyklepanie.” |
| `przyklep` | powstał commit | „Przyklepane. Teraz nawet klawisz tego nie zamiecie.” |
| `wywozka` (`kopsnij`) | udany push | „Wywózka zakończona. Na bramie nie zatrzymali.” |
| `rakowiec` (`rakieta`) | udany pull `--ff-only` | „Rakieta odebrana. Bez szemranych blatów po drodze.” |
| `ucho` (`stojka`) | udany fetch | „Ucho przy drzwiach. Wiemy, co na wolce piszczy.” |
| `celka` | lista gałęzi | „Sprawdzam obsadę celek. Kto gdzie siedzi?” |
| `celka` | utworzono gałąź | „Nowa celka gotowa. Jeszcze trzeba się do niej przerzucić.” |
| `przerzutka` | udany switch | „Przerzutka klepnięta. Nowa cela, ta sama ekipa.” |
| `spacer` | udany checkout | „Spacerniak zaliczony. Uważaj, w której epoce jesteś.” |
| `blaty` (`zblatuj`) | udany merge | „Blat zawarty. Dwie roboty pod jednym dachem.” |
| `wizjer` | odczyt commit | „Przez wizjer wszystko widać. Oto akta sprawy.” |
| `bialko` | odczyt historii | „Białko na stół. Cała historia siedzi w papierach.” |
| `dziupla` | stash **faktycznie powstał** | „Fanty w dziupli. Nawet klawisz nie znajdzie.” |
| `wyjmij` | stash pop powiódł się | „Fanty z powrotem na blacie. Dziupla opróżniona.” |
| `spis` | lista stash | „Sprawdzam schowki. Nic nie zginie bez kwitu.” |
| `spusc` | stash drop powiódł się | „Poszło z wodą. Tego grypsu już nie wyciągniesz.” |
| `kipisz` | reset po akceptacji udany | „Kipisz skończony. Papiery przywrócone, reszta przepadła.” |
| **`kwity`** | diff | „Kwity na stół. Sprawdzimy, co kombinowałeś.” |
| **`odkitraj`** | unstage | „Fanty zdjęte z listy. Nadal leżą u ciebie.” |
| **`kapus`** | blame | „Kapuś sypie nazwiskami. Zobacz, kto ruszał tę linijkę.” |
| **`dziara`** | lista tagów | „Przegląd dziarek. Każdy znak ma swoją historię.” |
| **`dziara`** | utworzono tag | „Dziara gotowa. Wersja oznaczona na stałe.” |
| **`cynk`** | reflog | „Mam cynk. HEAD kręcił się tędy.” |
| **`kasacja`** | revert utworzył commit | „Kasacja weszła. Wyrok odwrócony nowym papierem.” |
| **`kasacja --no-commit`** | zmiany nałożone, bez commita | „Kasacja przygotowana. Nic jeszcze nie przyklepano.” |
| **`uklady`** | lista remote | „Sprawdzam układy. Z kim mamy dojście na wolce?” |
| **`uklady add/remove/set-url`** | operacja zakończona | „Układy zaktualizowane. Adresy w papierach się zgadzają.” |
| **`odkrec`** | przywrócono wskazane ścieżki | „Odkręcone. Te ruchy zniknęły z blatu.” |
| `pomoc` / `--help` | pomoc główna | „Świeżak? Bez spiny. Tu masz pełną bajerę.” |
| `kmina` | pomoc konkretnego grypsu | „Siadaj, młody. Rozkminimy tę robotę.” |
| `bajera` | samouczek | „Najpierw bajera, potem robota. Patrz uważnie.” |
| `wersja` | odczyt wersji | „Numer spod celi: GRYPS v<wersja>.” |

**Uwagi semantyczne:** warianty zmieniające stan muszą opierać się na rzeczywistym wyniku Git. `spacer` może być też przywracaniem pliku — wtedy nie mówimy o zmianie celi; `celka -d` ma komunikat o likwidacji celki, nie utworzeniu. Dla `uklady` inne podkomendy otrzymują właściwą zwrotkę lub neutralne potwierdzenie. Gdy `git push/pull/fetch` zwróci 0 bez zmian, wybieramy neutralny wynik, nie twierdzimy, że wysłano nowe commity.

### 8.4 Puste wyniki, ostrzeżenia i rezygnacja

| Kontekst | Kwestia | Warunek |
|---|---|---|
| `lipo` — czysto | „Cela czysta. Nic nie wystaje spod pryczy.” | tylko po wiarygodnym sprawdzeniu statusu |
| `kwity` — brak różnic | „Kwity puste. Nikt tu niczego nie namieszał.” | gdy oba zakresy diff puste |
| `skitrac` — brak nowych elementów do indexu | „Nie ma czego kitrać. Wszystko już ogarnięte.” | bez deklarowania zmiany |
| `przyklep` — nothing to commit | „Papierów brak, młody. Nie przyklepię powietrza.” | błąd Git zachowany, bez „przyklepane” |
| `dziupla` — no local changes | „Dziupla pusta. Fantów do chowania brak.” | NIE wypisujemy „schowane” |
| `spis` — brak stash | „Pusto w schowkach. Ktoś tu grzecznie żyje.” | brak wpisów |
| `dziara` — brak tagów | „Żadnych dziarek. Ta robota jeszcze bez znaków.” | brak tagów |
| `cynk` — brak HEAD/reflog | „Cynku brak. Historia jeszcze nie zostawiła śladów.” | nie udajemy udanego odczytu, jeśli Git zwrócił błąd |
| `kipisz` / `odkrec` / `spusc` — odmowa | „Odwołane. Cela nietknięta, klawisz wraca z niczym.” | nic nie zmieniono; istniejąca semantyka niezerowego exit |
| `rakowiec` — brak aktualizacji | „Z wolki nic nowego. Rakieta wróciła pusta.” | tylko jeśli wykryto brak zmian |
| `wywozka` — brak nowych commitów | „Na wolce już wszystko mają. Nie było czego wieźć.” | tylko jeśli wiarygodnie stwierdzono no-op |

### 8.5 Błędy — żart + diagnoza + konkret

| Rodzaj problemu | Treść zwrotki | Dalszy krok |
|---|---|---|
| **Nieznana komenda** | **„Chyba ci, młody, źle bajerę przewinęli, bo nie ma takiego grypsu: 'cosTam'.”** | `gryps pomoc`; opcjonalnie maks. 3 zbliżone nazwy |
| Literówka w grypsie, np. `kwty` | „Lewy gryps, młody. Może chodziło ci o `kwity`?” | sugestia tylko dla jednoznacznego dopasowania |
| Poza repozytorium | „Tu nawet murów nie postawili. W której celi ty siedzisz?” | `gryps mury` albo przejść do katalogu repo |
| Brak wymaganego argumentu | „Bez konkretów nie ruszę tej roboty, młody.” | przykład prawidłowej komendy |
| Brak uprawnień SSH / serwer odmawia (potwierdzone) | **„Klawisz na bramie odbił przepustkę. Nie masz wejścia na tę celę.”** | sprawdź klucz SSH, uprawnienia do repo lub token; pokaż oryginalny błąd Git |
| Błąd zapisu do pliku / katalogu (`EACCES`, potwierdzone) | „Do tego schowka klucza nie dostałeś. Brak uprawnień do zapisu.” | sprawdź właściciela i prawa katalogu; bez automatycznego `sudo/chmod` |
| Nieznany remote / brak celu push | „Wywózka stoi pod bramą. Nikt nie podał adresu.” | `gryps uklady`, jawne wskazanie remote |
| Brak sieci / host nieosiągalny (potwierdzone) | „Łączność z wolką padła. Rakieta nie ma którędy lecieć.” | sprawdź sieć, VPN, DNS, adres remote |
| Nieudane przełączenie przy lokalnych zmianach | „Przerzutka wstrzymana. Fanty leżą na widoku.” | `gryps lipo`, `gryps dziupla` lub commit |
| Merge/revert konflikt (potwierdzone unmerged index) | „Dymy pod celą! Dwie ekipy walczą o te same linijki.” | pokaż pliki konfliktowe i `git merge/revert --continue` lub `--abort`, zależnie od aktywnej operacji |
| `rakowiec --ff-only` odmówiony | „Tu nie ma prostego przejścia, młody. Celi nie połączę na siłę.” | wyjaśnij rozbieżność, zaproponuj świadomy merge/rebase |
| `dziara` — tag istnieje | „Ta dziara już jest. Drugi raz po tym samym miejscu nie jadę.” | nowa nazwa lub jawne Git `-f` (o ile użytkownik świadomie poda) |
| `kasacja` — commit nie istnieje | „Wyroku nie ma w aktach. Kogo mam kasować?” | sprawdź hash `gryps bialko`, `gryps cynk` |
| `odkrec` bez plików | „Nie powiesz co, nie odkręcę niczego.” | `gryps odkrec -- <plik>` |
| Brak dostępnego `git` | „Bez Gita to nawet grypsa nie przepchniesz.” | zainstaluj Git |
| Inny błąd Git | „Przypał na robocie. Szczegóły wysypał już Git.” | zachowaj oryginalny stderr i exit code |

**Nie zgadujemy przyczyny po samym exit code 1/128.** Jeśli nie da się wiarygodnie wykryć odmowy uprawnień czy błędu sieci bez niszczenia strumieni/promptów Git, wyświetlamy ogólną zwrotkę o niepowodzeniu i pozostawiamy oryginalny komunikat Git. Konkretna diagnoza może bazować tylko na sprawdzonym warunku lokalnym lub jednoznacznym błędzie; zależność od angielskiej treści stderr musi mieć fallback na inne locale i testy. Nie sugerujemy `sudo`, wyłączania weryfikacji SSH ani `--force` jako uniwersalnej naprawy.

### 8.6 Szczególny przypadek: nieznany gryps

```console
$ gryps cosTam
🚨 [LEWY GRYPS] Chyba ci, młody, źle bajerę przewinęli,
bo nie ma takiego grypsu: 'cosTam'.
Podpowiedź: gryps pomoc
```

```console
$ gryps kwty
🚨 [LEWY GRYPS] Chyba ci, młody, źle bajerę przewinęli,
bo nie ma takiego grypsu: 'kwty'.
Może chodziło o: gryps kwity
```

- Błąd i niezerowy kod wyjścia. **Nigdy** nie uruchamiamy podobnej komendy automatycznie.
- Sugestie tylko z zamkniętej listy nazw i aliasów; maksymalnie 3, najlepiej 1. Przy braku rozsądnego podobieństwa podajemy wyłącznie `gryps pomoc`.
- Żadnego `eval` ani interpretowania podanej nazwy; dane użytkownika wypisujemy bez sekwencji sterujących, a długie nazwy skracamy do rozsądnej długości.
- W trybie bez TTY/cichym: rzeczowy `Nieznana komenda: cosTam` na stderr; bez niepotrzebnych żartów.

### 8.7 Zasady implementacyjne

- Jeden centralny moduł/funkcje Bash 3.2 `gryps_info`, `gryps_ok`, `gryps_pusto`, `gryps_warning`, `gryps_error` oraz wspólny słownik komunikatów; **bez 27 różnych, chaotycznych `echo -e` rozsianych po `case`**.
- Formatowanie przez `printf`, bez niekontrolowanego `echo -e`, niebezpiecznych podstawień i bez polegania na GNU-only narzędziach.
- Jedna ścieżka wykonania powinna zachować faktyczny status Git (`status=$?`) i dopiero na jego podstawie wybrać `ok/error` oraz zakończyć z właściwym kodem. Nie wolno wyświetlać sukcesu przed `git ...`.
- Oryginalne błędy/prompt/hooki Git pozostają widoczne. Nie tłumaczymy ich tak, że giną techniczne szczegóły.
- Format dziennika/wydruku ma być stabilny i testowalny; do sprawdzenia komunikatów po polsku ustaw `LC_ALL=C.UTF-8` / dostępną lokalizację UTF-8, a do testów macOS uwzględnij systemowy Bash 3.2.
- Dopuszczamy techniczne informacje w trybie bez bajery przy błędach walidacji, ale **nie** doklejamy tekstu do binarnych/surowych wyników Git.

### 8.8 Testy akceptacyjne systemu komunikatów

| ID | Scenariusz | Kryterium |
|---|---|---|
| T29 | `gryps cosTam` w TTY | dokładna fraza o „źle przewiniętej bajerze”, poprawna nazwa, nonzero |
| T30 | literówka `gryps kwty` | sugestia `gryps kwity`, nic się nie wykonuje |
| T31 | potencjalnie złośliwa nazwa grypsu zawierająca ANSI, `$(...)`, długi ciąg | brak wykonania, brak sterowania terminalem, poprawny status |
| T32 | wszystkie 27 rozpoznanych komend w trybie interaktywnym | każda ma adekwatną krótką zapowiedź lub zwrotkę wyniku |
| T33 | czysty `lipo`, `kwity`, pusty `spis`, puste `dziara` | pozytywny żart o braku danych, bez fałszywej zmiany stanu |
| T34 | `dziupla` bez zmian | „brak fantów”, bez zapewnienia o utworzonym stash |
| T35 | `przyklep` gdy nothing to commit | brak komunikatu sukcesu, natywny stderr/status Git |
| T36 | `kasacja --no-commit` | nie twierdzi, że powstał commit |
| T37 | `git push` nieudany | tylko komunikat błędu, zachowany exit code, brak „wywiezione” |
| T38 | SSH Permission denied / HTTP 403 i osobno błąd DNS | odpowiednia diagnoza wyłącznie przy potwierdzonej przyczynie |
| T39 | nierozpoznany błąd Git | generyczny „przypał” + niezmieniony oryginalny stderr/status |
| T40 | `blaty` / `kasacja` z konfliktem | gryps o konflikcie tylko przy rzeczywistym unmerged index |
| T41 | `kipisz` / `spusc` / `odkrec` odmówione | nic niezmienione, informacja o anulowaniu |
| T42 | `gryps --cicho lipo`, `GRYPS_CICHO=1` | brak ozdobników, niezmienione dane Git i status |
| T43 | `gryps lipo --porcelain -z` | wynik bajt-w-bajt równoważny Git, zachowane NUL |
| T44 | `gryps kwity --exit-code` i `kapus --line-porcelain` | wyjście maszynowe bez nagłówków/komentarzy i poprawny exit |
| T45 | przekierowanie `gryps ... > file`, potok `|` | dane stdout nietknięte, bez żartów w stderr przy braku TTY stdout |
| T46 | `NO_COLOR=1`, `TERM=dumb` i terminal bez UTF-8 | brak sekwencji ANSI i zbędnych emoji, diagnostyka czytelna |
| T47 | zachowanie promptów Git SSH/hooków/pagera | bez utraty informacji i niedziałających promptów |
| T48 | `gryps przyklep` z hookiem odrzucającym commit | nie zgłasza sukcesu, zachowuje status |
| T49 | aliasy `rakieta`, `kopsnij`, `stojka`, `zblatuj` | ta sama zwrotka i semantyka co nazwa główna |
| T50 | Bash 3.2 macOS, Bash Linux, Zsh jako shell | ten sam słownik, brak zależności od Bash 4 |

**Kryterium ukończenia komunikacji v1.3:** wszystkie powyższe testy oraz istniejące testy Git są zielone; w terminalu każda komenda „mówi po grypserze”, w automatyzacji zachowuje się jak przewidywalny interfejs CLI.

## 9. Dokumentacja i dystrybucja

W zakresie wydania:

- Aktualizacja `README.md`, `man/gryps.1`, `gryps pomoc`, `gryps kmina <komenda>`, `gryps bajera` oraz wspólnego słownika komunikatów sukcesu, błędu i pustego wyniku.
- Autouzupełnianie argumentów w Bash i Zsh dla ośmiu nowych komend; aktualizacja dawnych aliasów.
- `CHANGELOG.md`, `VERSION=1.3.0` i testy integracyjne.
- Pakiet Debian oraz macOS ZIP (Intel i Apple Silicon), bez nowych zależności runtime.
- CI Linux + macOS: testy (w tym komunikatów T29–T50), shellcheck tam gdzie dostępny, instalacja i odinstalowanie paczek.

## 10. Świadomie poza v1.3

- `rebase` jako własny gryps, `cherry-pick`, `worktree`, `grep`: kandydaci do v1.4 (roboczo `przemiel`, `przechwyc`, `izolatka`, `szperaj`).
- Interaktywne TUI, edytor Git, automatyczne rozwiązywanie konfliktów, automatyczny force-push, automatyczne publikowanie tagów.
- Refaktoryzacja całej aplikacji na inny język.
- Montaż i generator reklamy — niezależny temat od funkcjonalnego v1.3.

## 11. Definicja ukończenia (DoD)

Wydanie v1.3.0 jest gotowe dopiero, gdy **wszystkie 8 nowych grypsów**, zmienione defaulty, system komunikatów z sekcji 8 i kryteria bezpieczeństwa działają na Linuxie i macOS; przechodzą stare oraz nowe testy; help/man/README/completions są spójne; zbudowane paczki są sprawdzone; nie ma regresji `wywozka` do złego remote. Bez commita/pusha do zewnętrznego repo bez osobnej decyzji właściciela.

---

### Dokumentacja źródłowa Git

- [git-stash](https://git-scm.com/docs/git-stash) — `--include-untracked`, `--all`, `--staged`, `--patch` i pathspec.
- [git-restore](https://git-scm.com/docs/git-restore) — różnica między `--staged` i `--worktree`.
- [git-push](https://git-scm.com/docs/git-push) — `push.default`, upstream, wybór remote.
- [git-diff](https://git-scm.com/docs/git-diff), [git-revert](https://git-scm.com/docs/git-revert), [git-reflog](https://git-scm.com/docs/git-reflog).

**Zatwierdzenia właściciela produktu (17.10.2026):** `kwity`, `kasacja`, `cynk`; pozostałe 5 nazw jak w tabeli; `dziupla` domyślnie obejmuje pliki untracked, nie ignored; GRYPS ma być jednocześnie zabawny i użyteczny, z lepszymi defaultami niż surowy Git.
