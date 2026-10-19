# GRYPS v1.3.3 — Smart TAB w pionie

## Zamierzony wygląd

```text
📦 CODZIENNA ROBOTA
  lipo          Co słychać pod celą? — git status -sb
  kwity         Wyciągnij dowody zmian — git diff + git diff --cached
  skitraj       Schowaj fanty do indeksu — git add [-A]

🕵️ DOCHODZENIE
  kapus         Kto sypnął tę linijkę? — git blame
  cynk          Tropy po ruchach HEAD — git reflog
```

Komendy są w kolejności grup z katalogu. **Wstawienie TAB dopisuje wyłącznie nazwę**.

## Standardowy Bash (Zorin OS, Mint)

GRYPS korzysta z `complete -o nosort`, by zachować kolejność grup. Żeby **każdy wynik był w osobnym wierszu**, uruchom w terminalu:

```bash
bind 'set completion-display-width 0'
```

Na stałe dopisz do `~/.inputrc` (opcja działa globalnie także dla innych programów):

```text
set completion-display-width 0
```

Samo Readline wyświetla tylko nazwy, bez nagłówków i opisów. Pełny pogrupowany widok w każdym terminalu:

```bash
gryps podpowiedzi
```

## Bash + ble.sh

Dodaj do `~/.blerc`:

```bash
ble-import core-complete -C 'bleopt complete_menu_style=desc menu_desc_multicolumn_width='
```

Opcja `menu_desc_multicolumn_width=` wyłącza dodatkowe kolumny w menu opisu. Wyniki są wypisywane pojedynczo, mają prefiks grupy w opisie i kończą się odpowiednikiem Gita. **ble.sh nie zapewnia w tym trybie osobnych nieklikalnych nagłówków grup tak jak Zsh.**

W razie potrzeby sprawdź po załadowaniu ble.sh:

```bash
bleopt complete_menu_style
bleopt menu_desc_multicolumn_width
```

## Zsh (macOS i Linux)

GRYPS 1.3.3 korzysta z `compadd -l` (jedna pozycja na wiersz), `-V` (zachowuje kolejność), `-X` (nagłówki grup), `-d` (opisy). Konfiguracja:

```zsh
autoload -Uz compinit; compinit
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' menu select
```

Autouzupełnianie ścieżek po `gryps kapus -- src/<TAB>` pozostaje bez zmian.

## Ograniczenia

- Standardowy Bash: jedna nazwa w wierszu, ale bez opisów na samym TAB.
- Bash + ble.sh: pojedyncze wiersze z opisem i etykietą grupy, bez oddzielnych nagłówków.
- Zsh: osobne nagłówki i wiersze z opisem i Gitem.
- Zmiana szerokości w Bash przez `bind` lub `~/.inputrc` dotyczy również innych komend.
