# GRYPS 1.4.1 — Software Design Document (SDD)

## *Ratunek bez kipiszu. Przemyt z innych celek. Prawilna kartoteka.*

| Metryka | Wartość |
|---|---|
| **Status** | SPECYFIKACJA DO IMPLEMENTACJI — nie zaimplementowano w ramach tego dokumentu |
| **Wersja docelowa** | `1.4.1` |
| **Punkt odniesienia** | GRYPS **v1.4.0** (lokalna paczka źródłowa, `VERSION=1.4.0`); przed implementacją harness sprawdza faktyczny HEAD repozytorium |
| **Platformy** | Linux: Bash; macOS: systemowy Bash 3.2 + interaktywny Zsh; opcjonalnie ble.sh |
| **Zakres nowy** | `odklep`, `wykipruj`, `tabor`, `podkopsaj`, **trwałe przemianowanie `skitrac` → `skitraj`**, spójna integracja i **reorganizacja README** |
| **Już istnieje — nie implementować drugi raz** | `ksywa`, `meta`, `meldunek`, `kartoteka`, diagnostyka tożsamości `przyklep` (v1.4.0) |
| **Dokument nadrzędny** | `docs/GRYPS_v1.3.0_SPEC.md` — zasady bezpieczeństwa, komunikacji i obsługi nieinteraktywnej pozostają wiążące |
| **Wykonawca** | Harness CLI, nie ta sesja ChatGPT |

> **Cel:** nowa, niewielka i spójna wersja funkcjonalna GRYPS. Cofanie niewywiezionych commitów, kontrolowane sprzątanie plików nieśledzonych, rebase i cherry-pick w grypserskim interfejsie — bez przypadkowej utraty zmian. Zamiast dopisywać kolejny fragment na samym końcu README, uporządkować dokumentację wokół **kompletnego słownika komend**.
>
> **Definicja „już mamy”:** zawartość paczki źródłowej GRYPS v1.4.0 zweryfikowana w tym przeglądzie (m.in. `bin/gryps`, `completions/gryps-catalog.tsv`, `README.md`, `CHANGELOG.md`, `tests/test-identity.sh`). Jeśli kod HEAD w repo harness różni się, należy najpierw sprawdzić różnicę i nie nadpisywać nowszych zmian.

---

## 0. Kontrakt wykonawczy — harness CLI

### 0.1. Wejście i kontrola stanu

1. Otwórz **aktualny** checkout repo. Ustal `git status --short`, `git branch --show-current`, `git rev-parse HEAD`, `cat VERSION`; nie zakładaj, że nadal jest tag v1.4.0. Nie usuwaj ani nie nadpisuj lokalnych zmian użytkownika. Jeśli wersja HEAD różni się od 1.4.0 — oceń możliwość bezpiecznego zastosowania specyfikacji względem aktualnego kodu.
2. Przeczytaj `docs/GRYPS_v1.3.0_SPEC.md` (zwłaszcza zasady projektowe, bezpieczeństwo, komunikaty), `bin/gryps` (`gryps_tell`, `gryps_error`, `gryps_run`, `gryps_read`, `potwierdz`, `check_repo`, `unknown_command`, `przyklep`, `kasacja`, `odkrec`, `kipisz`), cały katalog `completions/`, `README.md`, `CHANGELOG.md` i testy `tests/test-identity.sh`, `tests/test-v13.sh`, `tests/test-smart-tab.sh`.
3. **Sprawdź bazę:** cztery istniejące komendy kartoteki oraz tożsamościowy preflight `przyklep` muszą pozostać funkcjonalne i uwzględnione w dokumentacji, pomocy, katalogu oraz completions. Nie tworzyć „pucka/celowka” jako alternatyw dla zatwierdzonych nazw `meldunek/kartoteka`.
4. Nie modyfikuj żadnych plików przed ukończeniem analizy różnic i planu prac. Projekt jest bashowym wrapperem, nie frameworkiem Git.

### 0.2. Kolejność prac (wszystkie cztery nowe komendy należą do 1.4.1)

- **Etap A1:** `odklep` + T51–T61.
- **Etap A2:** `wykipruj` + T62–T71.
- **Etap B1:** `tabor` + T72–T79.
- **Etap B2:** `podkopsaj` + T80–T85.
- **Etap C:** trwałe przemianowanie `skitrac` → `skitraj` (kontrakt §5.1) oraz komunikaty, `kmina`, `pomoc`, `podpowiedzi`, katalog, TAB (Bash, ble.sh, Zsh), man, README i CHANGELOG + T86–T110. Aktualizacje dokumentacji można włączać stopniowo, ale finalna integracja jest obowiązkowa.

Etapy A/B są organizacją pracy, **a nie funkcjami opcjonalnymi**. `tabor` i `podkopsaj` są planowane do v1.4.1 na równi z pozostałymi. Każdy etap ma mieć odrębny zestaw testów. Lokalne commity tylko w sposób zgodny z polityką harness/projektu; **bez push, tworzenia tagów lub publikacji release** bez osobnego polecenia właściciela.

### 0.3. Nienegocjowalne zasady techniczne

- Argumenty Git przekazuj jako argumenty/tablice, **nigdy** `eval` ani komendę sklejaną jako string.
- Rozpoznawanie stanu przez kody wyjścia, `rev-parse`, `rev-list`, `ls-files`, `diff --quiet` i ścieżki `git rev-parse --git-path`. **Nie analizuj angielskich ani polskich treści stderr Gita.**
- Bash **3.2+**, Git **2.23+**. Bez `mapfile`, `readarray`, `declare -A`, `${x,,}`, `&>>` i nowych opcji bez zgodnego wariantu.
- Teksty GRYPS wyłącznie na stderr przez standardową warstwę komunikatów; stdout jest dla surowych danych Git. W `--cicho`, w trybie maszynowym i bez TTY nie dodawaj humorystycznych ozdobników.
- Destrukcja: pokaż dokładny zakres, żądaj zgody lub wyraźnego parametru wymuszającego. Nie wykonuj automatycznie force-push ani przywracania/abort wbrew użytkownikowi.
- Brak podpowiedzi „wszystko się udało” na podstawie samego kodu 0, gdy nic nie zostało zrobione; rozróżniaj sukces, pusty wynik, anulowanie, błąd i konflikt.
- Dokumentację użytkownika układaj z **jednego katalogu komend jako źródła prawdy**, bez ręcznie dublowanych, niezsynchronizowanych list.
- Nie zmieniaj zachowania istniejących poleceń poza wyraźnie opisanymi wyjątkami w §5, w tym świadomie zrywającym zgodność nazewniczą `skitrac` → `skitraj`; zachowaj starsze testy i dopisuj nowe zamiast je osłabiać.

### 0.4. Wyniki prac harness

Zmodyfikowany kod i testy, README oraz CHANGELOG, osobna notatka techniczna z wynikami `make lint`, `make test`, budową Linux/macOS (jeżeli CI dostępne), listą nierozwiązanych ryzyk i spisem zmienionych plików. **Ta specyfikacja nie jest implementacją.**

## 1. Analiza stanu i uzasadnienie zakresu

### 1.1. Co v1.4.0 **już ma**

W paczce źródłowej v1.4.0 (`VERSION=1.4.0`) potwierdzono:

- `ksywa [--global] [wartość]` → `git config user.name`, lokalnie domyślnie.
- `meta [--global] [wartość]` → `git config user.email`, lokalnie domyślnie.
- `meldunek [--global] [nazwa email]` → obie wartości, w tym wariant interaktywny.
- `kartoteka` → odczyt wartości i źródeł ich pochodzenia.
- `przyklep` → wstępna kontrola działającej tożsamości autora i commitera + humorystyczna diagnostyka anonima.
- Cały dotychczasowy zestaw: init/clone/status/add/commit/diff/unstage/push/pull/fetch/branch/switch/checkout/merge/remote/blame/log/show/reflog/tag/stash/revert/restore/reset.
- Mechanizmy `--cicho`, emoji w TTY i uzupełnianie TAB w Bash, ble.sh i Zsh.

**Wniosek:** stare SDD nazywało zakres tożsamości „równoległym”. W 1.4.1 jest to **zamknięta funkcjonalność odziedziczona po 1.4.0**, podlegająca regresji i ujęciu w kompletnej liście README, a nie zadanie implementacyjne. Nie używaj nazw `pucka`, `celowka` z historycznego szkicu — w kodzie zatwierdzono `meldunek`, `kartoteka`.

### 1.2. Braki zamykane w 1.4.1

| Potrzeba użytkownika | Stan 1.4.0 | Nowa komenda | Kategoria |
|---|---|---|---|
| Cofnąć 1–N ostatnich lokalnych commitów, ale **zostawić zmiany staged** | `kasacja` odwraca nowym commitem, `kipisz` jest destrukcyjny | `odklep` = `git reset --soft` | 🚨 Ratunek |
| Wyrzucić nowe, nieśledzone pliki i katalogi z kontrolą zakresu | `kipisz` nie wykonuje `git clean` | `wykipruj` = kontrolowany `git clean -d` | 🚨 Ratunek |
| Przenieść lokalne commity na wskazaną bazę | brak osobnego rebase | `tabor` = `git rebase` | 🚪 Cele i układy |
| Przenieść wybrany commit lub zakres z innej gałęzi | brak osobnego cherry-pick | `podkopsaj` = `git cherry-pick` | 🚪 Cele i układy |
| Spójna forma rozkazująca dla `git add` | `skitrac` jest bezokolicznikiem wśród komend typu `przyklep` | **trwała zmiana nazwy na `skitraj`**, bez starego aliasu | ✍️ Nazewnictwo |
| Szybko odszukać każdą komendę i odpowiadającego jej Gita | README ma niepełną tabelę, a v1.3.0 dopisano po końcowych sekcjach | przebudowany README, pełne 44 pozycje katalogu | 📖 Dokumentacja |

### 1.3. Znaczenie nazw

- `odklep` — celowy neologizm GRYPS, odwrotność `przyklep`; nie przedstawiamy go jako tradycyjnego synonimu operacji Git.
- `wykipruj` — od „wykiprować”, czyli wyrzucić / wysypać; czytelna metafora `git clean`.
- `tabor` — transport, przeniesienie; metaforyczny transport commitów na inną bazę.
- `podkopsaj` — od „podkopsać”, przekazać / przemycić; commit przeniesiony z innej celi.

Pochodzenie słów jest inspiracją i nie wymaga twierdzenia, że każda nazwa ma ściśle historyczne pochodzenie więzienne.

**Świadomie nie dodajemy:** `grep`, `worktree`, `bisect`, `submodule`, `rm`/`mv`, osobnej komendy na `commit --amend`, automatycznego force-push ani automatycznego `fetch` jako działania ubocznego.

## 2. Decyzje produktowe dla wydania 1.4.1

Poniższe wartości są **rozstrzygnięciami przyjętymi na potrzeby tej specyfikacji**, aby harness nie zatrzymywał się na pytaniach zawartych w starszym dokumencie. Właściciel może je później zmienić przed implementacją, ale bez takiej zmiany obowiązują poniższe kontrakty.

| ID | Decyzja dla v1.4.1 | Powód |
|---|---|---|
| D1 | Nazwa `git rebase` = **`tabor`** | metafora przeniesienia na inną bazę |
| D2 | Nazwa `git cherry-pick` = **`podkopsaj`** | przemycenie commita z innej celi |
| D3 | **Wszystkie cztery komendy** wchodzą do v1.4.1; A/B to etapy, nie opcja | użytkownik chce uzupełnić brakujące funkcje starego SDD |
| D4 | Numer docelowy **`1.4.1`**, punkt wyjścia `1.4.0` | kartoteka jest już wydana w 1.4.0 |
| D5 | `podkopsaj` **bez domyślnego `-x`** | nie modyfikujemy standardowych opisów commitów |
| D6 | `odklep` nigdy nie używa `--hard` / `--mixed`; domyślnie cofa 1 commit | bezpieczny default |
| D7 | `wykipruj` **bez `-f`** wymaga podglądu i potwierdzenia; `-x` jawne | nowe pliki są nieodzyskiwalne przez Git |
| D8 | README: **kompletny słownik tuż pod krótkim wprowadzeniem**, dalej zmiany wersji, instalacja, bezpieczeństwo i rozwój | szybkie znalezienie polecenia |
| D9 | Brak nowych aliasów dla `ksywa`, `meta`, `meldunek`, `kartoteka` | istniejący interfejs v1.4.0 pozostaje spójny |
| **D10** | **`skitrac` zostaje trwale zastąpione przez `skitraj` — bez aliasu zgodności** | jednolita forma rozkazująca; jawna migracja użytkowników i skryptów w 1.4.1 |

**Zmiana łamiąca zgodność:** `skitrac` w v1.4.1 jest **nieznanym poleceniem**. GRYPS nie uruchamia za niego `git add`; może jedynie zasugerować `gryps skitraj`. To decyzja świadoma, nie pomyłka i nie zadanie na później.

**Numeracja:** nie używaj „1.4.0 — Ratunek”, „1.3.6 jako Faza A” ani liczników z okresu 1.3.5. Docelowy release to **v1.4.1**. Historia w `CHANGELOG.md` pozostaje nienaruszona, tylko dostaje nowy wpis na górze.

## 3. Nowe komendy — słownik v1.4.1

| Gryps | Grupa | Odpowiednik Git | Domyślna kmina | Etap |
|---|---|---|---|---|
| `odklep [N]` | 🚨 RATUNEK | `git reset --soft HEAD~N` | cofnij **1** ostatni commit; zmiany zostają w stagingu, pliki nietknięte | A (wymagane) |
| `wykipruj` | 🚨 RATUNEK | `git clean -d` | pokaż nieśledzone pliki i katalogi w całym repo (bez ignorowanych), usuń po potwierdzeniu | A (wymagane) |
| `tabor <baza>` | 🚪 CELE I UKŁADY | `git rebase` | przenieś commity bieżącej celki na wskazaną bazę | B (wymagane) |
| `podkopsaj <commit…>` | 🚪 CELE I UKŁADY | `git cherry-pick` | przenieś wskazane commity na bieżącą celkę | B (wymagane) |

---

## 4. Kontrakty

### 4.1 `gryps odklep [N] [-f|--force]`

**Semantyka:** `git reset --soft HEAD~N`. Przesuwa tylko `HEAD`/gałąź. Index zachowuje stan cofniętych commitów (zmiany lądują w stagingu), working tree pozostaje **bez zmian**. Operacja nieniszcząca: cofnięte commity są odzyskiwalne (`ORIG_HEAD`, `gryps cynk`), więc **bez potwierdzenia** w zwykłym przypadku.

**Argumenty (zamknięta lista — żadnego przekazywania flag do `git reset`):**
- `N` — opcjonalna dodatnia liczba całkowita (`^[1-9][0-9]*$`), domyślnie `1`.
- `-f` / `--force` — świadome odklepanie commitów już obecnych na remote (krok 6).
- Cokolwiek innego (np. `--hard`, `--mixed`, `0`, `abc`, ref) → błąd użycia, exit 1, **nic nie zmieniono**. Uzasadnienie: przekazanie `--hard` zamieniłoby `odklep` w `kipisz` bez potwierdzenia.

**Algorytm (kolejność sprawdzeń jest wiążąca; każdy błąd = exit 1 i brak zmian):**
1. `check_repo`; parsowanie argumentów.
2. Brak commitów (`git rev-parse --verify -q HEAD` zawodzi) → `error:odklep-pusto`.
3. Operacja w toku — istnieje którykolwiek z: `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `rebase-merge/`, `rebase-apply/` (ścieżki przez `git rev-parse --git-path`) → `error:w-toku` z nazwą operacji i podpowiedzią `--continue`/`--abort`. (Git i tak odmawia `reset --soft` w trakcie merge — sprawdzono — ale komunikat ma być nasz i przed wywołaniem.)
4. `git rev-parse --verify -q "HEAD~N"` zawodzi:
   - `N=1` (HEAD to pierwszy commit w repo) → `error:odklep-root` z podpowiedzią `gryps przyklep --amend -m "nowy opis"` (poprawia pierwszy commit) — **nie** usuwamy refa gałęzi;
   - `N>1` → `error:odklep-za-malo` z liczbą dostępnych commitów (`git rev-list --count HEAD`).
5. W zakresie są commity scalające: `git rev-list --merges "HEAD~N..HEAD"` niepuste → `error:odklep-merge`. Uzasadnienie (sprawdzone): `reset --soft` z merge commita wrzuca do stagingu całą zawartość scalonej gałęzi, co jest nieczytelne. Podpowiedź: `gryps kasacja -m 1 <hash>` albo świadomie zwykły `git reset`.
6. **Commity już wywiezione:** `pub = N − $(git rev-list --count "HEAD~N..HEAD" --not --remotes)`. Jeśli `pub > 0`:
   - bez `-f` → `error:odklep-wywiezione`: liczba wywiezionych commitów, podpowiedź `gryps kasacja <hash>` (bezpieczne cofnięcie opublikowanej zmiany) oraz informacja, że świadome przepisanie wymaga `gryps odklep -f`, a potem `gryps wywozka --force-with-lease`;
   - z `-f` → kontynuuj; w TTY ostrzeżenie `warning:odklep-wywiezione`.
   - Sprawdzenie opiera się na lokalnych refach `refs/remotes/*` (stan z ostatniego `fetch`); **nie** wykonujemy `fetch`. Opis w `kmina` mówi to wprost.
7. Zapamiętaj `stary=$(git rev-parse HEAD)` oraz czy index był niepusty (`git diff --cached --quiet` ≠ 0).
8. `git reset --soft "HEAD~N"`; zachowaj kod wyjścia.
9. Sukces → `ok:odklep`, a w TTY dodatkowo (stderr, krótko):
   - lista cofniętych commitów: `<krótki hash> <temat>`, maksymalnie 5 pozycji + „…i X więcej”,
   - jeśli index był niepusty przed operacją: `info:odklep-zmieszane` („w stagingu leżały już inne zmiany — teraz są razem”),
   - podpowiedzi: `gryps kwity --staged` (co wróciło), `gryps przyklep -C ORIG_HEAD` (ten sam opis i autor — sprawdzone), `git reset --soft <stary>` (zmiana zdania).
   - Bez TTY / `--cicho`: brak wydruku GRYPS (Git przy `reset --soft` sam nic nie wypisuje); kod 0.
10. Błąd Gita → `error:odklep` i oryginalny kod wyjścia.

```sh
gryps odklep                      # cofnij ostatni commit, zmiany zostają skitrane
gryps odklep 3                    # cofnij trzy, np. żeby przyklepać je jako jeden
gryps przyklep -C ORIG_HEAD       # przyklep ponownie z tym samym opisem
gryps odklep -f                   # świadomie: commit był już wywieziony
```

### 4.2 `gryps wykipruj [-n|--dry-run] [-f|--force] [-x|-X] [[--] ścieżki…]`

**Semantyka:** `git clean -d` — usuwa **nieśledzone** pliki i katalogi. Pliki ignorowane zostają, chyba że jawnie `-x` (także ignorowane) lub `-X` (tylko ignorowane). Usuniętych plików **nie da się odzyskać przez Git** (nie ma ich w żadnym obiekcie ani reflogu) — dlatego potwierdzenie jest obowiązkowe.

**Argumenty (zamknięta lista):**
- `-n` / `--dry-run` — tylko lista, nigdy nie usuwa, nie pyta, exit 0.
- `-f` / `--force` — usuń bez pytania (świadomie, także w skryptach).
- `-x`, `-X` — jak w Git; wzajemnie wykluczające się (oba naraz → błąd użycia).
- Ścieżki — po opcjonalnym `--`; bez ścieżek zakres to **całe repo** (`':(top)'`), także po uruchomieniu w podkatalogu (spójnie z `skitraj` i `odkitraj`).
- Każda inna opcja (np. `-ff`, `-e`, `-i`, `-q`) → błąd użycia z podpowiedzią „pełna kontrola: `git clean`”, exit 1, nic nie usunięto.
- **Nigdy** nie przekazujemy `-ff`: zagnieżdżone repozytoria (katalogi z własnym `.git`) zostają nietknięte (sprawdzone: `git clean -d -f` je pomija). Git odmawia też usunięcia bieżącego katalogu — zostawiamy to zachowanie.

**Algorytm:**
1. `check_repo`; parsowanie; `spec=( ':(top)' )` albo podane ścieżki.
2. `lista=$(git clean -n -d [-x|-X] -- "${spec[@]}")`; błąd → `error:wykipruj`, kod Gita.
3. Pusta lista → `empty:wykipruj`, exit 0.
4. Wypisz listę na **stdout** (to dane). W TTY przed nią `intro:wykipruj` na stderr; przy `-x` dodatkowo `warning:wykipruj-ignorowane` („w tym pliki ignorowane, np. `.env`, `node_modules/`, wyniki builda”).
5. `-n` → exit 0.
6. Bez `-f`: `potwierdz` z ostrzeżeniem, że plików nie odzyska ani Git, ani `gryps cynk`. Brak TTY → komunikat `potwierdz` („Świadomie dodaj -f”), exit 1. Odmowa → `cancel:wykipruj`, exit 1.
7. **Ochrona przed zmianą w trakcie (best effort, nie gwarancja atomowości):** po potwierdzeniu ponownie wykonaj krok 2 i porównaj wynik z `lista`. W implementacji unikaj utraty rozróżnienia nietypowych nazw plików, w tym końcowych znaków nowej linii; jeśli bezpieczne porównanie nie jest możliwe, przerwij zamiast zgadywać. Różnica → `error:wykipruj-zmiana` („lista się zmieniła, nic nie usunąłem, odpal jeszcze raz”), exit 1.
8. `git clean -f -d [-x|-X] -- "${spec[@]}"` → `ok:wykipruj` / `error:wykipruj` z kodem Gita.
9. Z `-f` kroki 4–7 są pomijane (Git sam wypisuje „Removing …”); pusta lista (krok 3) nadal daje `empty:wykipruj`. Wariant `-f` to świadome wykonanie bez zatwierdzenia; nie wolno przedstawiać go jako operacji z podglądem.

```sh
gryps wykipruj                    # pokaż, co poleci, i zapytaj
gryps wykipruj -n                 # tylko podgląd
gryps wykipruj -- build/ tmp/     # tylko wskazane miejsca
gryps wykipruj -x                 # także ignorowane (ostrożnie: .env!)
gryps kipisz && gryps wykipruj    # pełny powrót do stanu z HEAD
```

### 4.3 `gryps tabor <baza> [opcje-rebase]` — etap B (wymagany w 1.4.1)

**Semantyka:** `git rebase`. Bez automatycznego `--autostash`, bez automatycznego force-pusha.

1. `check_repo`.
2. **Sterowanie operacją w toku:** jeśli w argumentach jest `--continue`, `--abort`, `--skip`, `--quit`, `--edit-todo` lub `--show-current-patch` → `git rebase "$@"` bez dodatkowych sprawdzeń, potem obsługa wyniku jak w krokach 9–10.
3. Brak argumentów → błąd z przykładem `gryps tabor main` / `gryps tabor origin/main`. Nie korzystamy z domyślnego upstreamu Gita: przepisanie historii nie może zajść przez samo wpisanie nazwy (zasada 1.2 spec 1.3).
4. Brak commitów → błąd. Operacja w toku (lista z 4.1 krok 3) → `error:w-toku`.
5. **Brudne drzewo:** zmiany tracked (`git diff --quiet` lub `git diff --cached --quiet` ≠ 0) i brak `--autostash` w argumentach → `error:tabor-brudno` przed wywołaniem Gita, z podpowiedziami: `gryps dziupla`, `gryps przyklep`, `gryps tabor <baza> --autostash`. Pliki nieśledzone nie blokują.
6. `-i` / `--interactive` przy braku TTY na stdin → błąd przed uruchomieniem (edytor nie zadziała).
7. **Wyznaczenie bazy do komunikatów:** jeśli argumenty to dokładnie jeden ref plus opcjonalnie `-i`, `--autostash`, `--rebase-merges`, to `baza` = ten ref (`git rev-parse --verify -q "$ref^{commit}"`, błąd → `error:tabor-baza`). W innych układach (`--onto`, `--root`, kilka refów) pomijamy kroki 8 i liczniki, ale wykonujemy rebase.
8. Znana baza: `do_przewozu=$(git rev-list --count baza..HEAD)`; `wywiezione = do_przewozu − $(git rev-list --count baza..HEAD --not --remotes)`. Jeśli `wywiezione > 0` → w TTY `warning:tabor-wywiezione` przed startem: po taborze wywózka będzie wymagała `gryps wywozka --force-with-lease`. **Bez pytania** — operacja jest lokalna i odwracalna przez `gryps cynk`, a do publikacji i tak potrzebny jest jawny force (którego GRYPS sam nie robi). **GRYPS nie definiuje własnej flagi `-f`**: w Git `rebase -f` znaczy `--force-rebase` i musi przechodzić bez zmian.
9. `przed=$(git rev-parse HEAD)`; `git rebase "$@"`; zachowaj kod.
10. Wynik:
    - kod 0 i `HEAD` bez zmian → `empty:tabor` („celka już jedzie na świeżej bazie”);
    - kod 0 → `ok:tabor` (z liczbą przewiezionych commitów, gdy baza znana); jeśli gałąź ma upstream i rozjechała się z nim (`@{u}..HEAD` > 0 i `HEAD..@{u}` > 0) → `warning:tabor-wywozka` z podpowiedzią `--force-with-lease`;
    - kod ≠ 0 i rebase w toku (`rebase-merge/` lub `rebase-apply/`) oraz `git ls-files -u` niepuste → `error:tabor-konflikt`: lista plików konfliktowych, `gryps lipo`, potem `gryps skitraj` i `gryps tabor --continue` albo `gryps tabor --abort` / `--skip`;
    - kod ≠ 0 i rebase w toku bez konfliktów → `error:tabor-stoi` z tymi samymi podpowiedziami;
    - inaczej → `error:tabor`. Zawsze oryginalny kod wyjścia; nigdy automatyczny `--abort`.

```sh
gryps ucho && gryps tabor origin/main   # świeża baza z serwera
gryps tabor main --autostash            # luźne zmiany pojadą w dziupli
gryps tabor --continue                  # po rozwiązaniu konfliktu
gryps tabor -i main                     # interaktywnie (edytor Git)
```

### 4.4 `gryps podkopsaj <commit|zakres>… [opcje-cherry-pick]` — etap B (wymagany w 1.4.1)

**Semantyka:** `git cherry-pick`, bez dodatkowych domyślnych flag (D5).

1. `check_repo`. Sterowanie (`--continue`, `--abort`, `--skip`, `--quit`) → `git cherry-pick "$@"` bez sprawdzeń, wynik jak w kroku 5.
2. Brak argumentów → błąd z przykładem `gryps podkopsaj a1b2c3d`.
3. Operacja w toku → `error:w-toku`.
4. **Merge commit bez rodzica:** dla każdego argumentu niebędącego opcją ani zakresem (bez `..`), który rozwiązuje się do commita (`git rev-parse --verify -q "$a^{commit}"`) i jest merge (`git rev-list --merges --max-count=1 "$a^!"` niepuste), przy braku `-m`/`--mainline` w argumentach → `error:podkopsaj-merge` przed wywołaniem Gita: „wskaż rodzica: `gryps podkopsaj -m 1 <hash>`”.
5. `przed=$(git rev-parse HEAD)`; `git cherry-pick "$@"`; wynik:
   - kod 0 i `--no-commit`/`-n` w argumentach → `ok:podkopsaj-nocommit` (bez słowa o przyklepaniu);
   - kod 0 → `ok:podkopsaj` z liczbą nowych commitów (`git rev-list --count przed..HEAD`);
   - kod ≠ 0, istnieje `CHERRY_PICK_HEAD`, `git ls-files -u` puste i brak różnic (`git diff --quiet && git diff --cached --quiet`) → `error:podkopsaj-pusty`: „ten fant już tu jest”, podpowiedź `gryps podkopsaj --skip` (sprawdzone: Git zostawia wtedy cherry-pick w toku);
   - kod ≠ 0 i `git ls-files -u` niepuste → `error:podkopsaj-konflikt`: pliki, `gryps skitraj` + `gryps podkopsaj --continue` / `--abort` / `--skip`;
   - inaczej → `error:podkopsaj`. Zawsze oryginalny kod wyjścia.

```sh
gryps podkopsaj a1b2c3d            # jeden commit z innej celi
gryps podkopsaj hotfix~2..hotfix   # zakres
gryps podkopsaj -x a1b2c3d         # z dopiskiem skąd przemycono
```

---

## 5. Zmiany w istniejących komendach — tylko świadomie wskazane

| Element | Wymagane zachowanie |
|---|---|
| `kipisz` | Po **udanym** resecie, tylko w TTY, jeżeli `git ls-files --others --exclude-standard` zwraca pliki: `info:kipisz-wykipruj` — „Nowe pliki zostały na blacie. Wyrzucisz je: `gryps wykipruj`”. Nie rozszerzać `reset --hard` o `git clean`. |
| `kasacja` | W `kmina kasacja` wskazówka: jeśli commit **nie został wypchnięty**, do cofnięcia z zachowaniem zmian staged służy `gryps odklep`. Sam `git revert` bez zmian. |
| `unknown_command` | `skitrac` to nazwa wycofana: pokaż jednoznaczną sugestię `gryps skitraj` (bez automatycznego wykonania). Dla nowych literówek: `odklepp`, `odklp`, `odklap` → `odklep`; `wykipuj`, `wykiperuj`, `wykipr` → `wykipruj`; `tabur`, `tbor` → `tabor`; `podkopsj`, `podkopsa` → `podkopsaj`. Nie wykonuj poprawionej komendy bez zgody; upewnij się, że normalizator wejścia obsługuje ciągi z polskimi znakami bez błędnych skojarzeń. |
| Pomoc i samouczek | Nowe polecenia w `pomoc`, `kmina`, `podpowiedzi` i `man`. `kartoteka` i komplet pozostałych poleceń v1.4.0 muszą pozostać widoczne. |
| `przyklep` / kartoteka | **Brak zmian semantycznych.** Zostawić obsługę `ksywa`, `meta`, `meldunek`, `kartoteka` i diagnostykę „anonima spod celi” tak jak w 1.4.0; tylko test regresyjny i dokumentacja. |
| Repozytorium | Jeśli pusty `testfile` naprawdę występuje i jest zbędny, jego usunięcie dopuszczalne tylko po sprawdzeniu `git ls-files testfile` i braku zależności. Nie czyść repo masowo. |

### 5.1. Trwałe przemianowanie `skitrac` → `skitraj` (wymagane)

**Motywacja:** `skitraj` to konsekwentna forma rozkazująca — tak jak `przyklep`, `odkitraj`, `odkrec`, `wykipruj`. Jest to **zmiana nazwy publicznego polecenia**, a nie nowe mapowanie operacji Git.

**Kontrakt:**

1. Jedyna kanoniczna komenda to `gryps skitraj [argumenty]` → dotychczasowe wywołanie `git add` z **identycznym zachowaniem**, domyślnymi parametrami, obsługą opcji/pathspeców, kodami wyjścia, walidacją i komunikatami jak dla `skitrac` w v1.4.0. Nazwy wewnętrznych helperów mogą pozostać techniczne, jeśli nie są publicznym API.
2. **Bez aliasu zgodności.** `gryps skitrac` ma zakończyć się kodem niezerowym jako nieznane / wycofane polecenie, **niczego nie stagingować**, a w interaktywnym trybie podpowiedzieć `gryps skitraj`. To samo dla `gryps kmina skitrac` i uzupełniania poleceń: stara nazwa nie jest kandydatem TAB. Nie wyświetlać starej nazwy jako działającego grypsu.
3. W `pomoc`, `kmina`, `podpowiedzi`, `man`, `completions/gryps-catalog.tsv`, Bash/ble.sh/Zsh oraz całym README zastąpić wpis i przykłady nazwą `skitraj`. Opis opcji i końcowy równoważnik `git add` pozostają niezmienione. Smart TAB `gryps ski<TAB>` powinien uzupełniać **pełne** `skitraj`, bez obcinania prefiksu. Po `gryps skitraj -- src/<TAB>` nadal uzupełniać właściwe ścieżki.
4. **Istniejące testy** wywołujące `skitrac` migrować do `skitraj`, ale bez usuwania asercji dotyczących `git add`. Dodać osobny test negatywny, że nazwa `skitrac` niczego nie zmienia. Wyjątkowo dopuszcza się korektę historycznych testów tylko tam, gdzie muszą wywoływać aktualne publiczne API; nie wolno osłabiać ich sensu.
5. Aktualizacja `README.md` i `CHANGELOG.md` musi **jawnie** dokumentować zmianę niekompatybilną oraz migrację skryptów użytkownika. Nie usuwać historycznych wpisów changelogu dla 1.4.0 i starszych wydań (tam `skitrac` jest poprawną nazwą historyczną).
6. W repo przejrzeć wszystkie odwołania przez wyszukiwanie `skitrac` obejmujące kod, dokumentację, man, testy, completion, komunikaty, przykłady i instalatory. Po migracji dopuszczalne wystąpienia starej nazwy to **wyłącznie** teksty historyczne/migracyjne, wskazówki „dawniej” i negatywne testy kompatybilności.
7. Nie robić automatycznej migracji lokalnej konfiguracji użytkownika ani automatycznych zmian w jego zewnętrznych skryptach — tylko informacja i jasny komunikat błędu.

**Przykład po aktualizacji:**

```console
$ gryps skitraj .
📦 [GRYPS] Skitrane. Fanty czekają na przyklepanie.

$ gryps skitrac .
🚨 [STARA BAJERA]
Młody, stary gryps skitrac odsiedział swoje. Teraz mów: gryps skitraj .
Nic nie ruszyłem.
```

Przykłady komunikatów są wzorcowe i podlegają standardowym zasadom TTY/`--cicho`/stderr, a nie obligatoryjnemu zapisowi słowo w słowo.

**Zabronione regresje:** nie zmieniać działania `wywozka` (w tym komunikatu o nieprzyklepanych zmianach i wyboru remote), `dziupla -u`, `rakowiec --ff-only`, `kwity`, `odkitraj`, `odkrec`, `kapus` ani `git config` w kartotece.

## 6. Komunikaty „Gryps gada” — nowe klucze `gryps_tell`

Zasady jak w spec 1.3 §8: żart tylko w TTY i bez `--cicho`; jedna kwestia na wynik; sukces dopiero po kodzie 0; błędy zawsze z konkretnym następnym krokiem.

| Klucz | Kwestia (wzorcowa) | Prefiks |
|---|---|---|
| `ok:odklep` | Odklepane. Papiery wróciły na blat, wszystko czeka w stagingu. | 📄 |
| `info:odklep-zmieszane` | W stagingu leżały już inne fanty. Teraz leżą razem. | ℹ️ |
| `warning:odklep-wywiezione` | Ten papier już wyjechał na wolkę. Przepisujesz historię, którą inni mogą mieć. | ⚠️ |
| `error:odklep-wywiezione` | Tego nie odklepię, młody, to już jest na wolce. Bezpiecznie: gryps kasacja <hash>. Świadomie: gryps odklep -f. | 🚨 |
| `error:odklep-merge` | To był blat dwóch celi. Odklep tego nie rozplącze. | 🚨 |
| `error:odklep-root` | To pierwszy papier w aktach, nie ma do czego się cofać. Popraw go: gryps przyklep --amend -m "opis". | 🚨 |
| `error:odklep-za-malo` | Tyle papierów w aktach nie ma. | 🚨 |
| `error:odklep-pusto` | Pusto w aktach. Nie ma czego odklepywać. | 🚨 |
| `error:w-toku` | Trwa inna robota (<operacja>). Najpierw ją dokończ albo przerwij. | 🚨 |
| `intro:wykipruj` | Lista do wykiprowania. Te fanty nie mają papierów: | 🧹 |
| `warning:wykipruj-ignorowane` | Z -x lecą też ignorowane: .env, node_modules, build. Patrz uważnie. | ⚠️ |
| `empty:wykipruj` | Nie ma czego wykiprować. Na blacie same legalne fanty. | 🧼 |
| `ok:wykipruj` | Wykiprowane. Blat czysty, papiery zostały. | 🧹 |
| `error:wykipruj-zmiana` | Lista się zmieniła w trakcie. Nic nie ruszyłem, odpal jeszcze raz. | 🚨 |
| `info:kipisz-wykipruj` | Nowe pliki zostały na blacie. Wyrzucisz je: gryps wykipruj. | ℹ️ |
| `ok:tabor` | Tabor dojechał. <N> papierów przewiezionych na <baza>. | 🚌 |
| `empty:tabor` | Tabor stoi. Ta celka już jedzie na świeżej bazie. | 🚌 |
| `warning:tabor-wywiezione` / `warning:tabor-wywozka` | Część papierów jest już na wolce. Po taborze: gryps wywozka --force-with-lease. | ⚠️ |
| `error:tabor-brudno` | Na blacie leżą luźne fanty. Tabor ich nie zabierze. | 🚨 |
| `error:tabor-konflikt` | Dymy w taborze! Dwie ekipy walczą o te same linijki. | 🚨 |
| `error:tabor-stoi` | Tabor stoi w połowie drogi. | 🚨 |
| `error:tabor-baza` | Takiej bazy nie ma w aktach. Dokąd mam wieźć? | 🚨 |
| `ok:podkopsaj` | Przemycone. Papier z innej celi leży już u nas. | 🐪 |
| `ok:podkopsaj-nocommit` | Przemyt na blacie, jeszcze nieprzyklepany. | 🐪 |
| `error:podkopsaj-pusty` | Ten fant już tu jest. Pomiń go: gryps podkopsaj --skip. | 🚨 |
| `error:podkopsaj-konflikt` | Przemyt utknął na bramce. Konflikt w plikach. | 🚨 |
| `error:podkopsaj-merge` | To blat dwóch celi. Wskaż rodzica: gryps podkopsaj -m 1 <hash>. | 🚨 |

Kwestie zawierające dane (`<hash>`, `<N>`, `<baza>`, `<operacja>`) składać przez `printf` z argumentami oczyszczonymi z sekwencji sterujących (spec 1.3 §8.2, „Bezpieczeństwo tekstu”). Rozszerzenie `gryps_tell` o parametry jest dopuszczalne, jeśli nie zmienia wydruku istniejących kluczy.

Kody wyjścia: błędy walidacji i blokady GRYPS = **1**; błędy Gita = oryginalny kod Gita; odmowa potwierdzenia = **1**; `empty:*` przy zwykłym wywołaniu = **0**.

---

## 7. Integracja i pliki do zmiany

### 7.1. Zakres plików

| Plik | Oczekiwana modyfikacja |
|---|---|
| `bin/gryps` | **Zastąp `skitrac` przez `skitraj` (bez aliasu), dodaj podpowiedź migracyjną dla starej nazwy;** cztery nowe komendy z kontraktami §4; komunikaty §6; literówki; sugestia po `kipisz`; pełna pomoc/`kmina`/`podpowiedzi`. **Bez ponownego tworzenia kartoteki.** |
| `completions/gryps-catalog.tsv` | Zamiana istniejącego rekordu `skitrac` na `skitraj` (bez duplikatu) oraz cztery wpisy z opisem kończącym się odpowiadającą komendą Git. Grupy: `ratunek` (`odklep`, `wykipruj`), `cele` (`tabor`, `podkopsaj`). |
| `completions/gryps.bash` | Zamiana `skitrac` na `skitraj` w nazwach/metadata `_gryps_meta`, `_gryps_words` i regułach argumentów; zachować pracę z ble.sh (pełne kandydaty, bez odcinania prefiksu), fallback `nosort` dla Bash 3.2. |
| `completions/_gryps` | Te same nazwy (`skitraj` zamiast `skitrac`) i opisy, grupy Zsh w stałej kolejności i jeden wpis na wiersz. |
| `tests/test-v141.sh` (nowy) | Przypadki T51–T85, T86–T102 oraz **T103–T110** i testy bezpieczeństwa. Nazwę `test-v141.sh` wybrano celowo, bo w v1.4.0 może istnieć już `test-identity.sh`. |
| `tests/test-smart-tab.sh` | Aktualizacja *dynamicznego* licznika z 40 na **44** pozycje (zamiana nazwy nie zwiększa liczby wpisów), testy `skitraj` i czterech nowych nazw we wszystkich trzech trybach. Nie zamieniać testów ble.sh w sprawdzanie samego tekstu tablicy. |
| `Makefile` | Nowy test w `make test` oraz `make lint`; w CI sprawdzanie ShellCheck i macOS. |
| `man/gryps.1` | Zamiana dokumentowanej komendy `skitrac` na `skitraj` oraz sekcje dla czterech nowych operacji + ostrzeżenia przed operacjami destrukcyjnymi; zachować opis kartoteki. |
| `README.md` | **Przebudowa struktury, §7.2–7.5**. Kompletna lista komend wysoko (z `skitraj` i bez `skitrac` jako działającej komendy), historia pod nią, brak rozrzuconych tabelek z wersji 1.3 na końcu. |
| `CHANGELOG.md` | Dodać wpis `## [1.4.1] — Ratunek bez kipiszu (data wydania)` i krótko opisać cztery grypsy, trwałe przemianowanie `skitrac` → `skitraj`, komunikaty, TAB i README. Istniejących wpisów nie usuwać. |
| `VERSION` | `1.4.1` — dopiero podczas implementacji, nie w tej specyfikacji. |
| `docs/GRYPS_v1.4.1_SDD.md` | Ten SDD ma trafić do repo jako źródło kontraktu; archiwalnego `docs/GRYPS_v1.3.0_SPEC.md` nie nadpisywać. |

**Uwaga o liczności:** `skitrac` znika, a `skitraj` zajmuje dokładnie jego miejsce — nie dodajemy 45. rekordu ani aliasu.

**Katalog przed zmianą:** v1.4.0 ma dokładnie **40 pozycji**, w tym cztery polecenia kartoteki, pięć pomocniczych oraz cztery aliasy. **Po zmianie: 44 pozycje** (35 grypsów domenowych + 5 pomocniczych + 4 aliasy). Jeśli w repo harness liczby różnią się z powodu równoległych prac, wyprowadzić liczbę z realnego katalogu i potwierdzić brak duplikatów zamiast ślepo wymuszać 44.

### 7.2. README — docelowa architektura informacji (wiążąca)

README ma przestać być kroniką wersji, w której nowe polecenia są dopisywane po sekcji English i podpisie końcowym. Użytkownik po wejściu na GitHub powinien w kilka sekund znaleźć odpowiadający gryps i Gita.

**Docelowa kolejność nagłówków README:**

1. **Logo / hasło / badges** — krótkie, maksymalnie kilka linii; działające linki zamiast `__GH_USER__` (repo: `tkieron/gryps`, jeśli pozostaje poprawnym origin).
2. **Po co GRYPS?** — 2–4 zdania i jeden krótki przykład `lipo → skitraj → przyklep → wywozka`.
3. **Pełen słownik komend** — pierwsza duża sekcja README. Wszystkie nazwy z katalogu, **pogrupowane tematycznie**; kolumny: `Gryps`, `Git`, `Co robi / bezpieczny default`. **Nie dziel listy na „stare” i „od v1.3”**.
4. **Aliasy i komendy narzędziowe** — tuż pod główną tabelą, dla kompletności.
5. **Co nowego / Historia zmian** — skróty v1.4.1, v1.4.0, v1.3.x w tej kolejności; szczegółowy rejestr tylko w [`CHANGELOG.md`](../CHANGELOG.md) (poprawić ścieżkę względną w realnym README: `CHANGELOG.md`). **Żadnych drugich, konkurencyjnych list komend**.
6. **Instalacja i aktualizacja** — Linux `.deb` i `install.sh`, macOS `.zip`/`.tar.gz`, dopasowanie do bieżącej wersji zamiast nieaktualnego `gryps-1.3.0-macos.tar.gz`.
7. **Smart TAB (Bash / ble.sh / Zsh)** — opis, jeden przykład ścieżki `gryps kapus -- src/ts<TAB>` i wskazanie dokumentacji szczegółowej.
8. **Bezpieczeństwo / dobre defaulty** — `odklep` vs `kasacja` vs `kipisz`; `wykipruj -n` vs `-f -x`; przywołać ostrzeżenia o nieodwracalności `git clean`.
9. **Przykłady użycia** — codzienna robota i ratunek, z kompletnymi argumentami.
10. **Rozwój, testy, licencja, English** — na końcu; CTA z gwiazdką nie może poprzedzać dokumentacji poleceń.

Wersje i uwagi techniczne powinny być w historii zmian, nie przemieszane z głównym słownikiem; stary blok `## GRYPS 1.3.0 — nowe grypsy ...` z końca README **przenieść merytorycznie do pełnej tabeli** i usunąć jego duplikat.

### 7.3. README — pełny słownik wymaganych pozycji (v1.4.1)

To jest **kontrolna lista pokrycia** dla harness. Nie należy kopiować dosłownie opisu każdej pozycji z tej tabeli bez uzgodnienia z faktycznym zachowaniem CLI — Git w kolumnie to równoważnik i/lub domyślny skrót.

**📦 Codzienna robota i synchronizacja**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `mury` | `git init` | Postaw nową celę |
| `jumaj` | `git clone` | Zwiń repo z wolki |
| `lipo` | `git status -sb` | Co słychać pod celą? |
| `kwity` | `git diff + git diff --cached` | Wyciągnij dowody zmian |
| `skitraj` | `git add [-A]` | Schowaj fanty do indeksu |
| `odkitraj` | `git restore --staged` | Wyjmij z indeksu, nie z dysku |
| `przyklep` | `git commit` | Podpisz się pod robotą |
| `wywozka` | `git push` | Wyślij urobek na wolkę |
| `rakowiec` | `git pull --ff-only` | Odbierz paczkę bez merge |
| `ucho` | `git fetch` | Posłuchaj co na serwerze |

**🪪 Kartoteka (ISTNIEJE od 1.4.0)**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `ksywa` | `git config user.name` | Ustal ksywę autora |
| `meta` | `git config user.email` | Ustal metę autora |
| `meldunek` | `git config user.name + user.email` | Zameldowanie naraz |
| `kartoteka` | `git config --show-origin` | Sprawdź papiery i ich źródła |

**🚪 Cele i układy**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `celka` | `git branch` | Lista cel i nowe cele |
| `przerzutka` | `git switch` | Zmień celę |
| `spacer` | `git checkout` | Przejdź w historię |
| `blaty` | `git merge` | Dogadaj gałęzie |
| `uklady` | `git remote -v` | Sprawdź kontakty z wolką |
| `tabor` | `git rebase` | Przewieź commity na wskazaną bazę |
| `podkopsaj` | `git cherry-pick` | Przemyć commit(y) z innej gałęzi |

**🕵️ Dochodzenie i historia**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `kapus` | `git blame` | Kto sypnął tę linijkę? |
| `wizjer` | `git show` | Zajrzyj w wybraną akcję |
| `bialko` | `git log` | Prześwietl historię |
| `cynk` | `git reflog` | Tropy po ruchach HEAD |
| `dziara` | `git tag` | Wydziaraj wersję |

**🕳️ Dziupla**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `dziupla` | `git stash push -u` | Schowaj także nowe fanty |
| `wyjmij` | `git stash pop` | Wyjmij fanty z dziupli |
| `spis` | `git stash list` | Co leży w dziupli? |
| `spusc` | `git stash drop` | Spuść wybraną dziuplę |

**🚨 Ratunek (NOWE w 1.4.1)**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `kasacja` | `git revert` | Odwróć wyrok nowym commitem |
| `odkrec` | `git restore --worktree` | Odkręć niezapisane zmiany |
| `kipisz` | `git reset --hard` | Twardy reset! Ostrożnie |
| `odklep` | `git reset --soft HEAD~N` | Odklej ostatnie 1–N commitów; nie ruszaj plików |
| `wykipruj` | `git clean -d` | Podejrzyj i usuń nieśledzone; zawsze zgoda albo jawne -f |

**📖 Pomoc i konfiguracja**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `pomoc` | `gryps pomoc` | Pełen regulamin celi |
| `kmina` | `gryps kmina` | Rozkmiń jeden gryps |
| `bajera` | `gryps bajera` | Nauka pod celą |
| `podpowiedzi` | `gryps podpowiedzi` | Spis grypsów i ich znaczeń |
| `wersja` | `gryps wersja` | Numer aktualnej odsiadki |

**🔁 Aliasowe grypsy**

| Gryps | Odpowiednik Git | Kmina / domyślne zachowanie |
|---|---|---|
| `kopsnij` | `git push` | Alias wywózki |
| `rakieta` | `git pull --ff-only` | Alias rakowca |
| `stojka` | `git fetch` | Alias ucha |
| `zblatuj` | `git merge` | Alias blatów |

**Wymagania dla tabeli README:**

- Każdy z **44 wpisów** katalogu ma dokładnie jedno miejsce; nazwy komend nie mogą się powtarzać. Pomoc i aliasy można umieścić w osobnych krótkich tabelach, ale **bez ich pomijania**.
- `ksywa/meta/meldunek/kartoteka` występują w tabeli jako istniejące, nie „nowo dodane w 1.4.1”.
- Każdy wiersz kończy się rozpoznawalnym odpowiednikiem Git lub jawnie oznaczoną komendą wewnętrzną GRYPS (`gryps pomoc` itd.). W widoku TAB odpowiednik Git pozostaje ostatnim segmentem opisu.
- W tabeli nie kłam o ryzyku: `odklep` tylko staged, `wykipruj` usuwa dane nieodwracalnie, `kipisz` nie kasuje untracked; `tabor` może przepisać historię lokalną; `podkopsaj` tworzy nowy commit (chyba że `-n`).
- Ponieważ README ma charakter użytkowy, nie wpisuj do niego szczegółowego pseudokodu walidacji — ten zostaje w SDD.

### 7.4. README — changelog **pod listą komend**

Krótki przykład układu sekcji (treść wpisów według wyników wdrożenia):

```markdown
## Co nowego? / Historia zmian

### v1.4.1 — Ratunek bez kipiszu
- `odklep`, `wykipruj`, `tabor`, `podkopsaj`.
- Trwałe przemianowanie `skitrac` → `skitraj` (`git add`); stare polecenie nie jest już obsługiwane.
- Wygodniejszy, kompletny słownik i podpowiedzi TAB.

### v1.4.0 — Kartoteka grypsującego
- `ksywa`, `meta`, `meldunek`, `kartoteka`.
- Przyklep bez anonimów.

### Wcześniejsze wydania
Zobacz [pełny CHANGELOG](CHANGELOG.md).
```

`CHANGELOG.md` zostaje źródłem prawdy dla szczegółowej historii, dat i zmian technicznych. Nowy wpis musi opisywać **rzeczywiście wdrożone funkcje**, a nie tylko plan z SDD. Zachować wersje wcześniejsze w porządku malejącym.

### 7.5. README — wymagania jakościowe i instalacyjne

- Usunąć wszystkie placeholdery `__GH_USER__`, jeśli origin jest potwierdzony jako `tkieron/gryps`.
- Zaktualizować w instrukcjach nazwy paczek **do v1.4.1** albo używać wersjo-niezależnych wzorców tam, gdzie są bezpieczne.
- Wyraźnie rozdzielić instalację przez `make install`, paczkę release i `install.sh`; `install.sh` **musi instalować zbudowany** `gryps` z prawidłowym numerem wersji, a nie skrypt z `VERSION=dev`. Jeśli sam instalator wymaga poprawki, wymagać od harness osobnego testu zgodności; nie wprowadzać nieproszonych zmian w systemowych konfiguracjach.
- Zachować działanie/konfigurację ble.sh, pionowy Smart TAB i fallback na systemowym Bash 3.2.
- Przykłady poleceń z kasowaniem danych mają ostrzeżenie i wariant podglądu.
- README powinien być aktualny na datę wydania, a nie prezentować zrzut historii z v1.3 jako nowe funkcje.
- Sprawdzać poprawność wszystkich linków lokalnych (`docs/*`, `CHANGELOG.md`, man, instalatory) i brak powtórzonego nagłówka `## Słownik komend` poza docelową listą.


## 8. Testy akceptacyjne i regresja v1.4.0

Każdy test sprawdza **kod wyjścia i stan repo po poleceniu** (`git rev-parse HEAD`, `git diff --cached --name-only`, obecność plików). Testy z potwierdzeniem w TTY: na Linuxie przez pseudo-terminal (`script -qc`); na macOS mogą być pominięte z komunikatem `SKIP` (inna składnia `script`). Remote = lokalne repo bare.

### Etap A (obowiązkowy) — `odklep`

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T51 | `odklep` niewywiezionego commita | HEAD = poprzedni HEAD~1; staging zawiera zmiany commita; working tree bez zmian; exit 0 |
| T52 | `odklep 2` | dwa commity cofnięte, zmiany obu w stagingu |
| T53 | `odklep` przy już skitranych innych zmianach | oba zestawy w stagingu; w TTY informacja o zmieszaniu |
| T54 | `odklep` w repo bez commitów | exit 1, brak zmian |
| T55 | `odklep` na jedynym (root) commicie | exit 1, HEAD i gałąź bez zmian, podpowiedź `przyklep --amend` |
| T56 | `odklep`, gdy HEAD to merge | exit 1, HEAD bez zmian, podpowiedź `kasacja -m 1` |
| T57 | `odklep` commita obecnego na remote: bez `-f` / z `-f` | bez `-f`: exit 1, HEAD bez zmian; z `-f`: wykonane, exit 0, **brak push** |
| T58 | `odklep` w trakcie merge i w trakcie cherry-pick | exit 1 przed resetem, stan operacji nietknięty |
| T59 | `odklep 0`, `odklep abc`, `odklep --hard`, `odklep HEAD~2` | exit 1; HEAD, index i pliki bez zmian (szczególnie: `--hard` nie dociera do Gita) |
| T60 | `odklep`, potem `przyklep -C ORIG_HEAD` | nowy commit z identycznym tematem i autorem |
| T61 | `--cicho odklep` i wywołanie bez TTY | brak ozdobników na stderr, exit 0, stdout pusty |

### Etap A (obowiązkowy) — `wykipruj`

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T62 | `wykipruj` bez `-n`/`-f`, bez TTY | lista na stdout, exit 1, nic nie usunięto |
| T63 | `wykipruj -n` | lista nieśledzonych (bez ignorowanych), exit 0, nic nie usunięto |
| T64 | `wykipruj -f` z podkatalogu | usunięte nieśledzone w całym repo; ignorowane i śledzone nietknięte |
| T65 | `wykipruj -f -- wybrany/` | usunięta tylko wskazana ścieżka |
| T66 | zagnieżdżone repo (katalog z `.git`) | zostaje po `wykipruj -f` |
| T67 | brak nieśledzonych | `empty`, exit 0 |
| T68 | `wykipruj -x -f` / `-X -f` / `-x -X` | odpowiednio: także ignorowane / tylko ignorowane / błąd użycia |
| T69 | `wykipruj -ff`, `-e wzorzec`, `-i` | exit 1, nic nie usunięto |
| T70 | nazwy ze spacją, Unicode i zaczynające się od `-` | poprawnie wylistowane i usunięte |
| T71 | (Linux, TTY) potwierdzenie `t` / `n` / zmiana listy między podglądem a zgodą | `t`: usunięte; `n`: nic, exit 1; zmiana: nic, exit 1 |

### Etap B (obowiązkowy) — `tabor`

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T72 | `tabor` bez argumentu | exit 1, brak rebase |
| T73 | `tabor main` na czystym drzewie | commity na nowej bazie, exit 0 |
| T74 | `tabor main` przy zmianach tracked; ponownie z `--autostash` | pierwszy: exit 1 przed Gitem, nic nie zmienione; drugi: exit 0, zmiany wróciły |
| T75 | `tabor main` z konfliktem, potem `tabor --abort` | exit ≠ 0, rebase w toku, komunikat konfliktu; po `--abort` stan sprzed operacji |
| T76 | `tabor main`, gdy nie ma czego przewozić | `empty`, exit 0, HEAD bez zmian |
| T77 | `tabor` commitów obecnych na remote | ostrzeżenie o `--force-with-lease`; **brak push** |
| T78 | `tabor -i main` bez TTY | exit 1 przed uruchomieniem |
| T79 | `tabor -f main` | `-f` dociera do Gita jako `--force-rebase` (GRYPS go nie przechwytuje) |

### Etap B (obowiązkowy) — `podkopsaj`

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T80 | `podkopsaj` bez argumentu | exit 1 |
| T81 | jeden commit z innej gałęzi | nowy commit na bieżącej, exit 0 |
| T82 | commit już zastosowany, potem `podkopsaj --skip` | exit ≠ 0 i podpowiedź `--skip`; po `--skip` brak operacji w toku |
| T83 | konflikt, potem `podkopsaj --abort` | komunikat konfliktu; po `--abort` stan sprzed |
| T84 | merge commit bez `-m`; z `-m 1` | pierwszy: exit 1 przed Gitem; drugi: exit 0 |
| T85 | `podkopsaj --no-commit` | zmiany w stagingu, brak nowego commita, komunikat bez „przyklepane” |

### Wspólne

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T86 | literówki z sekcji 5 | podpowiedź poprawnej nazwy, nic się nie wykonuje |
| T87 | katalog, Bash, ble.sh, Zsh | 44 unikalne wpisy (40 istniejących, w tym przemianowana nazwa `skitraj`, + 4 nowe); spójne nazwy, opisy, grupy, prawidłowe pełne wstawianie grypsu przy częściowym prefiksie |
| T88 | `pomoc`, `kmina <nowa>`, `podpowiedzi`, `man`, README | zawierają wszystkie nowe komendy i ich Git, nie gubią kartoteki z v1.4.0 |
| T89 | `kipisz -f` przy obecnych nieśledzonych, w TTY | po resecie podpowiedź `gryps wykipruj`; bez TTY brak tej linii |
| T90 | CI: Bash Linux, systemowy Bash 3.2 na macOS, Zsh | wszystkie testy zielone, brak konstrukcji Bash 4+ |

### Dodatkowe testy dokumentacji, integracji i bezpieczeństwa (v1.4.1)

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T91 | Regresja kartoteki 1.4.0: `ksywa`, `meta`, `meldunek`, `kartoteka`, `przyklep` bez identyfikacji | dotychczasowe testy tożsamości działają bez zmian |
| T92 | README vs katalog | wszystkie 44 nazwy pokryte w słowniku (w tym `skitraj`, bez `skitrac` jako aktualnej komendy), nie więcej niż raz w roli wpisu podstawowego; aliasy opisane |
| T93 | Struktura README | sekcja pełnego słownika znajduje się **przed** historią zmian i instrukcjami szczegółowymi; na końcu README brak starej tabeli v1.3 |
| T94 | Changelog | wpis v1.4.1 nad v1.4.0; nie zaginęły starsze wersje |
| T95 | Linki i placeholdery | brak `__GH_USER__`, brak nieistniejących lokalnych linków, przykłady instalacji nie wskazują v1.3.0 |
| T96 | Pomoc i TAB | nowe polecenia pojawiają się w `gryps pomoc`, `podpowiedzi`, `kmina`, katalogu, Zsh i Bash |
| T97 | ble.sh prefiksy | `gryps od<TAB>` i `gryps tab<TAB>` wstawiają pełną nazwę, a nie nazwę z obciętym prefiksem |
| T98 | macOS Bash 3.2 | fallback bez `-o nosort`; `complete -o filenames` działa; bez niezgodnych konstrukcji składniowych |
| T99 | `wykipruj` ze zmianą między preview a wykonaniem | nie usuwa plików przy wykrytej zmianie listy; testy nietypowych nazw i wywołania w podkatalogu |
| T100 | `odklep` częściowo opublikowanej historii | wycofanie bez `-f` odrzucone; z `-f` tylko lokalna zmiana HEAD, nigdy automatyczny push |
| T101 | Brak TTY i `--cicho` | brak interaktywnych promptów bez terminala, brak żartów w strumieniach maszynowych, zachowane kody wyjścia |
| T102 | Instalacja i build | `make lint`, `make test`, `.deb`, macOS ZIP/TAR, wynik `gryps wersja == 1.4.1` w zbudowanym/instalowanym pliku |

### Zmiana nazwy `skitrac` → `skitraj` — testy obowiązkowe

| ID | Przypadek | Oczekiwany wynik |
|---|---|---|
| T103 | `gryps skitraj` bez argumentów | identyczny staging jak dotychczasowe `skitrac` bez argumentów w v1.4.0, zachowanie kodów wyjścia |
| T104 | `gryps skitraj .` i `gryps skitraj -- src/plik` | dokładnie odpowiednie pliki staged, bez zmian w ścieżkach nieobjętych argumentami |
| T105 | Flagi `git add` przekazywane przez `skitraj` | bez regresji, takie same efekty jak v1.4.0 (`skitrac`) |
| T106 | `gryps skitrac .` po aktualizacji | niezerowy kod wyjścia, brak zmian stagingu, czytelna sugestia `gryps skitraj` w TTY; nie wykonywać operacji automatycznie |
| T107 | `gryps kmina skitraj`, `gryps pomoc`, `gryps podpowiedzi`, `man` | nowa nazwa i `git add` poprawnie opisane; brak starej nazwy jako działającego polecenia |
| T108 | TAB w Bash, ble.sh i Zsh | `gryps ski<TAB>` wstawia pełne `skitraj`; `skitrac` nie jest kandydatem; po `--` uzupełniane są pliki z bieżącego katalogu |
| T109 | Spójność katalogu i README | dokładnie 44 pozycje, jedna `skitraj`, zero pozycji `skitrac` w aktualnym słowniku; historyczne changelogi pozostają poprawne |
| T110 | Migracja / tryb nieinteraktywny | wskazówka zmiany nazwy w README i CHANGELOG; wywołanie starej nazwy niczego nie zmienia, kod niezerowy; brak emoji/żartów w potokach i przy `--cicho` |

**Regresja:** wszystkie testy z v1.2–v1.4.0, w tym `tests/test-identity.sh`, `tests/test-push-feedback.sh`, `tests/test-completion.sh`, `tests/test-smart-tab.sh`, muszą przechodzić po dodaniu 1.4.1. Starszych testów nie wolno wyciszać ani usuwać dla poprawienia licznika.


---

## 9. Bezpieczeństwo i kompatybilność — podsumowanie

- **Granice destrukcji:** `odklep` rusza tylko HEAD (praca w stagingu, odzyskiwalne); `wykipruj` usuwa wyłącznie nieśledzone (nieodzyskiwalne → zawsze podgląd + zgoda albo jawne `-f`); `kipisz` bez zmian. Żadna komenda nie wywołuje niejawnie innej destrukcyjnej operacji.
- **Opublikowana historia:** `odklep` domyślnie odmawia (cofnięcie opublikowanej zmiany robi `kasacja`); `tabor` ostrzega. Nikt nie wykonuje push ani force-push.
- **Zamknięte listy argumentów** dla `odklep` i `wykipruj`, bo przekazane flagi zmieniałyby kategorię ryzyka (`--hard`, `-ff`). `tabor` i `podkopsaj` przekazują argumenty do Gita, bo są ogólnymi narzędziami — z pre-checkami tylko tam, gdzie to opisano.
- **Niezależność od locale:** brak parsowania tekstów Gita; porównanie list w `wykipruj` (krok 7) zestawia dwa wyniki z tego samego procesu i locale, więc tekst nie jest interpretowany.
- **Stan „w toku”** zawsze przez `git rev-parse --git-path`, nie przez zgadywanie ścieżek `.git/` (worktree, submoduły).

---

## 10. Świadomie poza zakresem 1.4.1

- **Ponowna implementacja kartoteki tożsamości**: `ksywa`, `meta`, `meldunek`, `kartoteka` są już częścią v1.4.0. Jedyne zadania: regresja, spójna dokumentacja i zachowanie pomocy / TAB.
- Automatyczne `fetch` przed sprawdzaniem „wywiezione”, automatyczny force-push, automatyczny `merge` i `rebase --autostash` bez jawnej opcji.
- `git clean -ff`, interaktywne wybieranie plików (`git clean -i`), automatyczna destrukcja przez `kipisz`, podmienianie rzeczywistych komunikatów błędu Git.
- `grep`, `worktree`, `bisect`, `submodule`, `rm`/`mv`, nowy alias dla `commit --amend`.
- Zmiana architektury technologicznej CLI, migracja do Pythona / Node, nowe frameworki TAB.
- Publikowanie release, push commitów, tworzenie tagów lub instalowanie na maszynie użytkownika — osobne zadania po wdrożeniu.

## 11. Definition of Done — GRYPS 1.4.1

Wersję można uznać za ukończoną **dopiero**, gdy spełniono wszystkie punkty:

- [ ] `odklep`, `wykipruj`, `tabor`, `podkopsaj` zgodne z kontraktami §4; oba etapy A i B ukończone.
- [ ] Zmiany istniejących komend wyłącznie wg §5, **w tym trwała migracja `skitrac` → `skitraj` bez aliasu**.
- [ ] Komunikaty sukcesu, braku pracy, anulowania i błędu przez `gryps_tell`/`gryps_error`, z zachowaniem kodów Git; zachowany tryb cichy i brak TTY.
- [ ] Nowe grypsy w katalogu, pomocy, `kmina`, Smart TAB we wszystkich trzech trybach i `man gryps`.
- [ ] `ksywa`, `meta`, `meldunek`, `kartoteka` nadal działają i znajdują się w dokumentacji jako funkcje v1.4.0.
- [ ] README ma **pełną listę wysoko**, potem historię zmian; zawiera `skitraj`, nie przedstawia `skitrac` jako dostępnej komendy; jasno opisuje zmianę nazwy; brak duplikatów i starych linków / nazw paczek.
- [ ] `CHANGELOG.md` ma osobny wpis 1.4.1 nad 1.4.0; `VERSION=1.4.1`.
- [ ] Scenariusze T51–T110 i cała istniejąca regresja zielone.
- [ ] `make lint` (ShellCheck), `make test`, `make deb`, `make macos` zielone — **nie deklarować zielonego CI bez uruchomienia**.
- [ ] Natywne testy macOS Bash 3.2 i Zsh lub jasno udokumentowana luka w weryfikacji. Ukończenie wydania wymaga docelowo zielonego CI.
- [ ] Nie było push, force-push, release ani tagów bez osobnej zgody użytkownika.

**Raport implementacyjny harness:** podać SHA/branch bazowy, zakres zmienionych plików, liczbę przechodzących testów, lint/build, ograniczenia i dokładną instrukcję wydania. Samo wygenerowanie paczki nie oznacza wydania na GitHub.

---

## 12. Uwaga o źródłowych eksperymentach Git i ograniczeniach

Poniższe obserwacje przepisano z równoległego SDD odnoszącego się do Git 2.43. Traktować jako dane referencyjne do testów, **nie jako dowód**, że identyczny efekt wystąpi na wszystkich obsługiwanych wersjach i konfiguracjach Git. Harness powinien je ponownie przetestować na obsługiwanych platformach.


### 12.1. Obserwacje z wcześniejszego SDD (Git 2.43)

- `git reset --soft HEAD~1` na root commicie kończy się błędem `ambiguous argument 'HEAD~1'` (kod 128).
- `git reset --soft` w trakcie merge: `Cannot do a soft reset in the middle of a merge` (kod 128).
- `reset --soft` z merge commita wrzuca do stagingu zawartość scalonej gałęzi.
- Po `reset --soft HEAD~2` → `git commit -C ORIG_HEAD` odtwarza opis i autora ostatniego cofniętego commita.
- `git clean -n -d -- ':(top)'` z podkatalogu obejmuje całe repo; Git odmawia usunięcia bieżącego katalogu; `-d -f` pomija zagnieżdżone repozytoria.
- `git rebase` przy zmianach unstaged: `cannot rebase: You have unstaged changes` (kod 1); bez argumentu i bez upstreamu: błąd.
- Pusty cherry-pick (commit już zastosowany): kod 1, `CHERRY_PICK_HEAD` zostaje, wymagane `--skip`.
- Cherry-pick merge commita bez `-m`: kod 128.

### 12.2. Dokumentacja źródłowa Git

- [git-reset](https://git-scm.com/docs/git-reset) — `--soft`, `ORIG_HEAD`.
- [git-clean](https://git-scm.com/docs/git-clean) — `-n`, `-d`, `-f`/`-ff`, `-x`/`-X`, `clean.requireForce`.
- [git-rebase](https://git-scm.com/docs/git-rebase) — `--autostash`, `--continue`/`--abort`/`--skip`, `-f`/`--force-rebase`.
- [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick) — `-m`, `-x`, `--skip`, `--no-commit`.
- [git-rev-list](https://git-scm.com/docs/git-rev-list) — `--not --remotes`, `--merges`, `--count`.
- [gitrevisions](https://git-scm.com/docs/gitrevisions) — `HEAD~N`, `<rev>^!`.
