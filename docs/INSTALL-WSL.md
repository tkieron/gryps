# Windows (WSL2 — alternatywa)

Główna ścieżka Windows to **Git Bash**, który nie wymaga WSL.
WSL2 uruchamia zwykły wariant Linux GRYPS, instalowany z `.deb`.
Poniższa instrukcja wymaga sprawdzenia na rzeczywistym WSL2 przed zamknięciem
akceptacji W15; lokalne testy Linux nie zastępują tego sprawdzenia.

1. Potrzebujesz Windows 11 lub Windows 10 w wersji 2004 (build 19041+)
   oraz uprawnień do włączenia funkcji systemowej WSL. Zgodnie z
   [instrukcją Microsoft](https://learn.microsoft.com/windows/wsl/install)
   uruchom **PowerShell jako administrator** i wykonaj:

   ```powershell
   wsl --install -d Ubuntu
   ```

   Może być potrzebny restart. Jeśli WSL jest już zainstalowane, sprawdź
   `wsl -l -v` i uruchom Ubuntu; preferowana wersja to WSL2 (kolumna VERSION=2).
   W środowisku firmowym zastosuj procedurę administratora organizacji.
   Instalator GRYPS nie włącza WSL i nie obchodzi ograniczeń systemu.

2. W terminalu **Ubuntu**, a nie w Git Bash ani w PowerShell:

   ```bash
   sudo apt update && sudo apt install -y git bash
   ```

3. Pobierz `gryps_1.5.0-1_all.deb` z
   [wydania v1.5.0](https://github.com/tkieron/gryps/releases/tag/v1.5.0)
   do Ubuntu. Dla innego wydania użyj jego faktycznej nazwy pliku.

   ```bash
   sudo apt install ./gryps_1.5.0-1_all.deb
   gryps wersja
   gryps pomoc
   ```

   Oczekiwane: `Gryps wersja 1.5.0`. Wewnątrz repo sprawdź `gryps lipo`.
   Odinstalowanie paczki: `sudo apt remove gryps` w Ubuntu.

4. Dla wydajności i prawidłowej obsługi metadanych trzymaj repo narzędzi
   Linux w `~/workspace/`, zamiast na `/mnt/c`. Nie pracuj jednocześnie
   Gitem Windows i Linux w tym samym drzewie roboczym. WSL ma oddzielną
   konfigurację Git: sprawdź `gryps kartoteka`, a w razie potrzeby wykonaj
   `gryps meldunek` w repo w Ubuntu. GRYPS nie zmienia `core.autocrlf`
   ani `core.filemode`; różnice zakończeń linii i bitu wykonywalności
   wynikają z konfiguracji Git i systemu plików.

Podpowiedzi Bash w `.deb` korzystają z `bash-completion`; można doinstalować
`sudo apt install bash-completion` i otworzyć nowy terminal Ubuntu.
Nie instaluj `.deb` w Git Bash. Alternatywna instrukcja:
[Windows Git Bash](../packaging/windows/README-Windows.md).
