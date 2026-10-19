<div align="center">

```
   ____ ______   ______  ____
  / ___|  _ \ \ / /  _ \/ ___|
 | |  _| |_) \ V /| |_) \___ \
 | |_| |  _ < | | |  __/ ___) |
  \____|_| \_\|_| |_|   |____/
```

**System Kontroli Wersji dla Prawilnych Ludzi**

Git w grypserze. Koniec z frajerskimi komendami.

[![CI](https://github.com/__GH_USER__/gryps/actions/workflows/ci.yml/badge.svg)](https://github.com/__GH_USER__/gryps/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/__GH_USER__/gryps?label=wyrok)](https://github.com/__GH_USER__/gryps/releases/latest)
[![Licencja: MIT](https://img.shields.io/badge/licencja-MIT-blue.svg)](LICENSE)

</div>

---

<p align="center">
  <img src="docs/demo.gif" alt="Demo: gryps jumaj, przerzutka, skitrac, przyklep, wywozka, bialko i kipisz w terminalu" width="810">
</p>

Gryps to nakładka na Gita, która nadaje codziennym komendom nazwy z gwary więziennej. Pod spodem zawsze pracuje zwykły `git`, a opcje Gita są przekazywane dalej (poza opisanymi skrótami). Gryps dokłada czytelne komunikaty, samouczek, podpowiedzi pod TABem i blokadę przed przypadkowym kipiszem.

### Autouzupełnianie TAB (Bash/Zsh)

GRYPS podpowiada nazwy komend, gałęzie oraz **pliki względem bieżącego katalogu** (także podkatalogi). Separator `--` kończy opcje Gita i nie wyłącza podpowiedzi plików, np.:

```bash
gryps kapus -- src/ts<TAB>
gryps kapus -L 1,10 -- src/ts<TAB>
gryps kwity -- src/<TAB>
gryps odkitraj -- src/<TAB>
```

Po aktualizacji pakietu uruchom nowy terminal, żeby załadować aktualne skrypty podpowiedzi. Na Linuxie z Bash można też odświeżyć je w istniejącej sesji: `source /usr/share/bash-completion/completions/gryps` (instalacja `.deb`), ewentualnie odpowiedni plik z katalogu `~/.local/share/bash-completion/completions/`.

## GRYPS 1.4.0 — Kartoteka grypsującego 🪪

Zarządzanie danymi Git autora commita (domyślnie **tylko bieżące repo**):

```bash
gryps ksywa "Twoja Ksywa"          # git config --local user.name
gryps meta "ty@example.com"          # git config --local user.email
gryps meldunek "Twoja Ksywa" "ty@example.com"
gryps kartoteka                      # efektywne wartości i ich źródła
gryps meldunek --global "Twoja Ksywa" "ty@example.com"
```

Bez wartości `ksywa` i `meta` pokazują aktualne ustawienie; `meldunek` bez argumentów pyta interaktywnie (bez terminala wymaga obu wartości). `--global` musi być jawne. Nieudanego commita GRYPS nie ponawia automatycznie. Jeśli Git nie potrafi ustalić tożsamości autora/commitera, `przyklep` podpowiada `meldunek` zamiast wyświetlać ogólny błąd.

## GRYPS 1.3.3 — podpowiedzi TAB

`gryps podpowiedzi` pokazuje pogrupowany słownik z odpowiednikami Git.
Bogatsze menu ble.sh i Zsh: [GRYPS TAB](docs/GRYPS-TAB-1.3.3.md).

## Instalacja

**Debian / Ubuntu** – pobierz `.deb` z [ostatniego wydania](https://github.com/__GH_USER__/gryps/releases/latest):

```bash
sudo apt install ./gryps_*_all.deb
```

**macOS (Intel i Apple Silicon)** — pobierz paczkę ZIP (Finder) lub TAR.GZ, bez Homebrew, dla domyślnego Zsh i systemowego Bash 3.2:

```sh
tar -xzf gryps-1.3.0-macos.tar.gz
cd gryps-1.3.0-macos
./install.sh --configure-zsh
# otwórz nowy Terminal
gryps wersja
```

Instrukcja i dezinstalator: [packaging/macos/README-macOS.md](packaging/macos/README-macOS.md). Nie wymaga `sudo`; instalacja do `~/.local`. Potrzebny jest Git (na macOS można zainstalować Command Line Tools).

**Jeden plik, bez roota:**

```bash
mkdir -p ~/.local/bin
curl -fsSL https://github.com/__GH_USER__/gryps/releases/latest/download/gryps -o ~/.local/bin/gryps
chmod +x ~/.local/bin/gryps
```

**Ze źródeł** (z podpowiedziami pod TABem i `man gryps`):

```bash
git clone https://github.com/__GH_USER__/gryps.git && cd gryps
make install PREFIX=~/.local     # albo: sudo make install
```

Wymagania: `git` (obsługujący `git switch`) i `bash` 3.2+. Na macOS zadziała systemowy Bash; powłoką interaktywną może być Zsh. Opcjonalnie `less` i podpowiedzi TAB.

## Słownik komend

| Gryps | Git | Co robi |
|---|---|---|
| `mury` | `git init` | Stawiasz mury nowej celi |
| `jumaj <url>` | `git clone` | Zawijasz repo z wolki |
| `lipo` | `git status` | Patrzysz przez lipo (oko), co się dzieje w celi |
| `skitrac [plik]` | `git add` | Kitrasz fanty; bez argumentów wszystko (`-A`) |
| `przyklep <opis> [flagi]` | `git commit -m` | Przyklepujesz papiery bez `-m`; flagi po opisie trafiają do Git |
| `wywozka` · `kopsnij` | `git push` | Pierwszy push ustawia upstream zgodnie z konfiguracją remote |
| `rakowiec` · `rakieta` | `git pull` | Odbierasz rakietę (paczkę) z wolki |
| `ucho` · `stojka` | `git fetch` | Stójka przy drzwiach: co nowego, bez ruszania plików |
| `celka [nazwa]` | `git branch` | Lista cel albo nowa celka |
| `przerzutka <celka>` | `git switch` | Przeniesienie do innej celi (`-c` nowa, `-` powrót) |
| `spacer <cel>` | `git checkout` | Spacer po historii |
| `blaty` · `zblatuj <celka>` | `git merge` | Blatujesz się z inną celą |
| `wizjer [hash]` | `git show` | Zaglądasz przez wizjer w commit |
| `bialko` | `git log --graph` | Kwity sprawy jako zwięzły graf |
| `dziupla` | `git stash push -u` | Chowa zmiany śledzone i nieśledzone, bez ignorowanych |
| `wyjmij` | `git stash pop` | Wyciągasz z dziupli na blat |
| `spis` | `git stash list` | Lista dziupli |
| `spusc` | `git stash drop` | Spuszczasz dziuplę (pyta o potwierdzenie) |
| `kipisz` | `git reset --hard` | Rewizja: cofa śledzone pliki do HEAD; nie usuwa nieśledzonych |

Pomoc w terminalu:

```bash
gryps pomoc            # lista komend (przewijana w less)
gryps bajera           # samouczek: typowy dzień na robocie
gryps przyklep -h      # szczegóły jednej komendy
man gryps              # pełne akta
```

## Bezpieczeństwo

Gryps wywołuje prawdziwego Gita, ale ma kilka jawnych ułatwień i zabezpieczeń:

- `kipisz` i `spusc` pytają o potwierdzenie, a bez terminala odmawiają, dopóki nie dasz `-f`;
- `skitrac` bez argumentów robi `git add -A`, czyli bierze całe repo, nie tylko bieżący katalog;
- `wywozka` z ustawionym upstreamem sprawdza, czy są nowe commity. Gdy jest tylko staging, informuje o konieczności wykonania `przyklep`, zamiast fałszywie ogłaszać udany transport. Przy gotowych commitach wykonuje push i ostrzega, że nieprzyklepane zmiany nie zostały wysłane. W potokach i `--cicho` zachowuje czyste komunikaty Git.
- `wywozka` na celce bez upstreamu (bez dodatkowych argumentów) dla `push.default=simple|upstream|current` używa `git -c push.default=current push --set-upstream`. Git **sam** wybiera remote z uwzględnieniem `branch.<celka>.pushRemote`, `remote.pushDefault` i innych ustawień; `origin` nie ma sztucznego pierwszeństwa. Przy `push.default=matching|nothing` zachowuje natywną semantykę Git. Jeśli przekażesz argumenty, trafią do `git push` bez zmian;
- `przyklep` zbiera wyrazy opisu tylko do pierwszej opcji. Przykłady: `gryps przyklep "feat" --no-verify` oraz `gryps przyklep -m "feat" --amend`. Tekst zaczynający się od `-` podawaj w trybie z `-m`;
- `dziupla` domyślnie chowa zmiany **śledzone i nieśledzone** (`git stash push -u`), z pominięciem plików `.gitignore`;
- `kipisz` usuwa zmiany w **śledzonych** plikach (także staged), ale **nie** wykonuje `git clean`, więc nowe nieśledzone pliki zwykle pozostają (wyjątek: kolidują z odtwarzanymi plikami śledzonymi).

Kolory wyłączysz zmienną `NO_COLOR=1`. Same znikają, kiedy wyjście idzie do pliku albo potoku.

## Skąd te słowa

Nazwy pochodzą z grypsery, gwary polskich więzień. Gdzie się dało, trzymamy się [słownika gwary więziennej](https://www.zpozdrowieniem.pl/blog/gamzac-grypsem-slownik-gwary-wieziennej): *rakieta* to paczka, *stójka* to nasłuchiwanie przy drzwiach, *przerzutka* to przeniesienie do innej celi, *kipisz* to rewizja. Kilka nazw (*jumaj*, *dziupla*, *bajera*) to ogólny polski slang. Projekt jest żartem językowym, nie pochwałą więziennej subkultury.

## Rozwój

```bash
make test       # testy na prawdziwych repozytoriach w katalogu tymczasowym
make lint       # shellcheck
make deb        # paczka .deb do dist/
make macos      # paczka .tar.gz dla macOS (Intel / Apple Silicon)
make demo       # od nowa renderuje docs/demo.gif (wymaga: pip install pyte pillow)
make promo      # pionowy short 9:16 do TikToka/Shorts (dodatkowo numpy i ffmpeg)
make skit       # 15-sekundowy skecz „Pod celą”
```

Chcesz dorzucić komendę albo lepsze słowo? Zajrzyj do [CONTRIBUTING.md](CONTRIBUTING.md).

---

<details>
<summary>🇬🇧 English</summary>

**Gryps** is a thin Git wrapper that renames everyday commands into *grypsera*, Polish prison slang. `gryps skitrac` stashes away your loot (`git add`), `gryps przyklep` stamps the papers (`git commit -m`), `gryps wywozka` ships it out (`git push`, setting the upstream for new branches), and `gryps kipisz` is the cell search that discards tracked uncommitted changes (`git reset --hard`, without deleting untracked files, with a confirmation prompt). Real `git` runs underneath; the documented shortcuts and safety checks are the only differences. Includes a tutorial (`gryps bajera`), bash completion, a man page and a `.deb` package. MIT licensed.

</details>

Jak Ci się podoba, zostaw ⭐ – w celi każda paczka się liczy.

## GRYPS 1.3.0 — nowe grypsy i bajera terminalowa

| Gryps | Git | Domyślny patent |
|---|---|---|
| `kwity` | `git diff` | Dwa zakresy: unstaged i staged; `--staged` ogranicza do indexu |
| `odkitraj` | `git restore --staged` | Odkłada cały staging do working tree, bez utraty plików |
| `kapus` | `git blame` | Wskazuje autora linii; wymaga pliku |
| `dziara` | `git tag` | Lista tagów, a z nazwą utworzenie taga |
| `cynk` | `git reflog` | 20 ostatnich lokalnych ruchów HEAD |
| `kasacja` | `git revert` | Odwraca wskazany commit bez edytora |
| `uklady` | `git remote` | Adresy remote: `git remote -v` |
| `odkrec` | `git restore --worktree` | Odrzuca tylko unstaged po potwierdzeniu; `-f` bez pytania |

Gryps gada po swojemu, ale tylko w interaktywnym terminalu (stdout i stderr TTY).
Oryginalne dane Git pozostają na stdout, bajera jest wypisywana na stderr.
`gryps --cicho <komenda>` i `GRYPS_CICHO=1` wyłączają żarty.
Poza TTY oraz przy formatach `--porcelain`, `-z`, `--quiet`, `--exit-code`,
`--line-porcelain` GRYPS nie dokleja ozdobników do wyników Gita.

Przykłady:

```sh
gryps kwity --stat
gryps skitrac
gryps odkitraj -- plik.txt
gryps przyklep "Przyklepana robota"
gryps dziupla                      # także nieśledzone, ale nie ignored
gryps cynk
gryps odkrec -f -- src/App.java     # UWAGA: traci zmiany unstaged
gryps --cicho lipo --porcelain -z  # czysto dla skryptów
```

W przypadku błędnych komend GRYPS nie uruchamia niczego automatycznie.
Diagnoza błędów Git pozostaje widoczna, a skrypt zachowuje ich kod wyjścia.
