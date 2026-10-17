# Jak dołożyć swoje

Pull requesty mile widziane. Kilka zasad, żeby gryps był prawilny:

1. **Słowo z gwary, nie z sufitu.** Nowa nazwa komendy powinna mieć znaczenie w grypserze, które pasuje do tego, co robi komenda Gita. W opisie PR podaj źródło (np. [ten słownik](https://www.zpozdrowieniem.pl/blog/gamzac-grypsem-slownik-gwary-wieziennej)). Bez wulgaryzmów i bez słów, które w gwarze służą do poniżania ludzi.
2. **Git pod spodem.** Komenda ma wołać `git` i przekazywać argumenty bez zmian (`"$@"`). Żadnej własnej logiki, która zmienia znaczenie flag Gita.
3. **Nieodwracalne = potwierdzenie.** Jeśli komenda może skasować czyjąś pracę, pyta o zgodę i ma flagę `-f`.
4. **Wszystko w komplecie.** Nowa komenda trafia do:
   - `bin/gryps` – obsługa w `case`, `show_help`, `show_cmd_help`,
   - `completions/gryps.bash` – lista `commands`,
   - `man/gryps.1`, tabeli w `README.md` i `CHANGELOG.md`,
   - `tests/run.sh` – przynajmniej jeden test.
5. Przed PR: `make lint test`.
6. Zmieniłeś wygląd komunikatów? Odśwież demo: `make demo` (scenariusz jest w `docs/demo/render.py`, w liście `STEPS`).

## Wydanie nowej wersji

1. Podbij `VERSION` i dopisz sekcję w `CHANGELOG.md`.
2. `git tag v$(cat VERSION) && git push --tags`.
3. GitHub Actions zbuduje `.deb` i samodzielny plik `gryps` i podepnie je pod wydanie.
