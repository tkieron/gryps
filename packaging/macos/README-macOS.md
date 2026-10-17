# GRYPS na macOS — instalacja

CLI działa na **Intel x86_64** i **Apple Silicon arm64**. Nie potrzebuje Homebrew, Pythona ani uprawnień administratora. Korzysta z systemowego Bash 3.2 i Gita; w terminalu macOS domyślny jest Zsh.

## Instalacja

1. Rozpakuj `gryps-1.3.0-macos.zip` dwuklikiem w Finderze (albo wariant `.tar.gz` przez `tar -xzf gryps-1.3.0-macos.tar.gz`).
2. Otwórz Terminal w rozpakowanym katalogu.
3. Uruchom:

```sh
./install.sh --configure-zsh
```

4. Otwórz nowy Terminal i wpisz:

```sh
gryps wersja
gryps pomoc
```

Instalator zapisuje tylko pliki GRYPS pod `~/.local` oraz — **wyłącznie z flagą** `--configure-zsh` — dopisuje oznaczony blok do `~/.zshrc`. Nic nie zmienia w konfiguracji Git i nie wymaga `sudo`.

Jeżeli Git nie jest zainstalowany, macOS może poprosić o doinstalowanie Command Line Tools; można to zrobić poleceniem `xcode-select --install`.

## Dodatkowe opcje

- Bez modyfikowania konfiguracji powłoki: `./install.sh`. Wtedy samodzielnie dodaj `~/.local/bin` do `PATH`.
- Inny katalog: `PREFIX=/ścieżka ./install.sh` (wówczas ręcznie ustaw `PATH` i completion).
- Strona pomocy: `man -M "$HOME/.local/share/man" gryps` (nie zależy od konfiguracji MANPATH).
- Usunięcie: `./uninstall.sh` — usuwa pliki, ale celowo pozostawia `.zshrc` do ręcznego przeglądu.

## TAB completion

- **Zsh (domyślny na macOS)**: `./install.sh --configure-zsh` dodaje katalog `~/.local/share/zsh/site-functions` do `fpath` i inicjalizuje `compinit`.
- **Bash 3.2**: podpowiedzi można załadować poleceniem `source ~/.local/share/bash-completion/completions/gryps`; do trwałej konfiguracji dodaj je do `~/.bash_profile`. Nie wymaga nowego Basha ani Homebrew.

Pakiet jest uniwersalny, bo składa się wyłącznie ze skryptów. To **CLI**, nie aplikacja `.app` z interfejsem graficznym.

Nowe komendy v1.3: `kwity`, `odkitraj`, `kapus`, `dziara`, `cynk`, `kasacja`, `uklady`, `odkrec`. `gryps --cicho <komenda>` wyłącza żartobliwe komunikaty. `dziupla` chowa domyślnie także nieśledzone pliki.


## GRYPS 1.3.3 — grupowane TAB
Dopisz po `compinit` do `~/.zshrc`:

```zsh
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' menu select
```

Zobacz `gryps podpowiedzi` i dokument `docs/GRYPS-TAB-1.3.3.md` w źródłach.
