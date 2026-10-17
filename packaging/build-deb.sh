#!/usr/bin/env bash
# Buduje paczkę .deb do dist/. Wersja z pliku VERSION (albo zmiennej VERSION).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PKG_NAME="gryps"
VERSION="${VERSION:-$(cat VERSION)}"
RELEASE="${RELEASE:-1}"
ARCH="all"
FULL_VERSION="${VERSION}-${RELEASE}"
MAINTAINER="${MAINTAINER:-Gryps Maintainers <gryps@localhost>}"
DEB_NAME="${PKG_NAME}_${FULL_VERSION}_${ARCH}"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "📦 Buduję paczkę ${DEB_NAME}.deb ..."

make --no-print-directory -s install DESTDIR="$STAGE" PREFIX=/usr VERSION="$VERSION" >/dev/null

# Debian trzyma licencję jako 'copyright' w katalogu doc
install -Dm0644 LICENSE "$STAGE/usr/share/doc/$PKG_NAME/copyright"

mkdir -p "$STAGE/DEBIAN"
INSTALLED_SIZE="$(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)"
cat > "$STAGE/DEBIAN/control" <<CTRL
Package: $PKG_NAME
Version: $FULL_VERSION
Section: vcs
Priority: optional
Architecture: $ARCH
Depends: git, bash (>= 3.2)
Recommends: less, bash-completion
Installed-Size: $INSTALLED_SIZE
Maintainer: $MAINTAINER
Homepage: https://github.com/__GH_USER__/gryps
Description: Git w grypserze - system kontroli wersji dla prawilnych ludzi
 Gryps to nakladka na Gita, ktora tlumaczy codzienne komendy na gware
 wiezienna (grypsere): skitrac, przyklep, wywozka, przerzutka, kipisz...
 Zawiera nowe komendy kwity, odkitraj, kapus, dziara, cynk, kasacja,
 uklady, odkrec, podpowiedzi TAB oraz zabawne komunikaty bledow. Pod spodem zawsze dziala zwykly git.
CTRL

mkdir -p dist
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "dist/${DEB_NAME}.deb" >/dev/null
echo "✅ dist/${DEB_NAME}.deb"
