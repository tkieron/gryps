# Gryps – Makefile
#   make                       – buduje dist/gryps z wstrzykniętą wersją
#   make install               – instaluje do /usr/local (sudo)
#   make install PREFIX=~/.local – instaluje tylko dla siebie, bez sudo
#   make test / lint / deb / macos
#   make demo                  – renderuje docs/demo.gif (pip install pyte pillow)
#   make promo                 – pionowy short do TikToka/Shorts w dist/ (+ numpy, ffmpeg)
#   make skit                  – 15-sekundowy skecz „Pod celą” w dist/

PREFIX  ?= /usr/local
DESTDIR ?=
VERSION := $(shell cat VERSION)

BINDIR  := $(PREFIX)/bin
COMPDIR := $(PREFIX)/share/bash-completion/completions
ZSHDIR  := $(PREFIX)/share/zsh/site-functions
MANDIR  := $(PREFIX)/share/man/man1
DOCDIR  := $(PREFIX)/share/doc/gryps

.PHONY: all build install uninstall test lint deb macos windows test-windows test-windows-package demo promo skit clean

all: build

build:
	VERSION="$(VERSION)" sh packaging/build.sh

install: build
	install -d $(DESTDIR)$(BINDIR) $(DESTDIR)$(COMPDIR) $(DESTDIR)$(ZSHDIR) $(DESTDIR)$(MANDIR) $(DESTDIR)$(DOCDIR)
	install -m 0755 dist/gryps            $(DESTDIR)$(BINDIR)/gryps
	install -m 0644 completions/gryps.bash $(DESTDIR)$(COMPDIR)/gryps
	install -m 0644 completions/_gryps $(DESTDIR)$(ZSHDIR)/_gryps
	gzip -9n < dist/gryps.1 > $(DESTDIR)$(MANDIR)/gryps.1.gz
	chmod 0644 $(DESTDIR)$(MANDIR)/gryps.1.gz
	install -m 0644 README.md $(DESTDIR)$(DOCDIR)/README.md

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/gryps $(DESTDIR)$(COMPDIR)/gryps $(DESTDIR)$(ZSHDIR)/_gryps $(DESTDIR)$(MANDIR)/gryps.1.gz
	rm -rf $(DESTDIR)$(DOCDIR)

TEST_BASH ?= bash
test: build
	TEST_BASH="$(TEST_BASH)" $(TEST_BASH) tests/run-platform-tests.sh
	$(TEST_BASH) tests/test-build.sh
	$(TEST_BASH) tests/test-portability.sh
	$(TEST_BASH) tests/test-portability-paths.sh

lint:
	shellcheck -s bash bin/gryps completions/gryps.bash packaging/build-deb.sh tests/*.sh
	shellcheck -s sh packaging/macos/*.sh packaging/windows/*.sh packaging/build.sh packaging/verify-release.sh packaging/publish-release.sh

deb:
	bash packaging/build-deb.sh

macos:
	sh packaging/macos/build-macos.sh
	bash tests/test-macos.sh

windows: build
	sh packaging/windows/build-gitbash.sh
	$(TEST_BASH) tests/test-windows-package.sh

test-windows-package: windows
	$(TEST_BASH) tests/test-windows-install.sh

test-windows: test-windows-package
	$(TEST_BASH) tests/test-windows.sh

demo: build
	python3 docs/demo/render.py docs/demo.gif

promo: build
	python3 docs/promo/short.py dist/gryps-short.mp4

skit: build
	python3 docs/promo/skit.py dist/gryps-skecz.mp4

clean:
	rm -rf dist
