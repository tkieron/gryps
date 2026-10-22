#!/usr/bin/env bash
# Reproduce the MSYS native-process boundary while all Git operations stay real.
# MSYS leaves absolute POSIX arguments containing [] unconverted. On Linux,
# //path denotes the same filesystem path and stands in for cygpath output.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
    MINGW*_NT-*|MSYS_NT-*)
        echo 'SKIP: Linux MSYS-boundary fixture: natywny Windows sprawdza test-portability.sh bez atrap'
        exit 0 ;;
esac
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/tools"
REAL_GIT=$(command -v git)
export REAL_GIT
cat > "$WORK/tools/git" <<'STUB'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in
        /tmp/*'['*|/tmp/*']'*)
            echo "fatal: Invalid path '/tmp': No such file or directory" >&2
            exit 128 ;;
    esac
done
exec "$REAL_GIT" "$@"
STUB
cat > "$WORK/tools/uname" <<'STUB'
#!/bin/sh
printf '%s\n' MINGW64_NT-10.0
STUB
cat > "$WORK/tools/cygpath" <<'STUB'
#!/bin/sh
case "$1" in -m|-w) shift ;; -u) printf '%s\n' "$2"; exit 0 ;; *) exit 2 ;; esac
case "$1" in /*) printf '/%s\n' "$1" ;; *) exit 2 ;; esac
STUB
chmod +x "$WORK/tools/"*
# Literal /tmp is deliberate: it models the exact failed CI fixture. This
# affects only the subprocess, never the developer's shell or Git settings.
PATH="$WORK/tools:$PATH" TMPDIR=/tmp bash "$ROOT/tests/test-portability.sh" > "$WORK/run.log" 2>&1 || {
    cat "$WORK/run.log" >&2
    echo 'FAIL: fixture przekazał nieprzekonwertowaną ścieżkę POSIX z [] do native Git' >&2
    exit 1
}
# The native launcher also passes a []-containing extraction directory to
# native unzip. Stop at that boundary; archive/lifecycle coverage lives in W01–W05.
cat > "$WORK/tools/unzip" <<'STUB'
#!/usr/bin/env bash
while [[ $# -gt 0 ]]; do
    if [[ $1 == -d ]]; then
        case "$2" in
            /tmp/*'['*|/tmp/*']'*) echo "native unzip: unconverted POSIX directory" >&2; exit 128 ;;
        esac
        exit 99 # Native destination accepted; do not actually unpack a ZIP.
    fi
    shift
done
exit 2
STUB
chmod +x "$WORK/tools/unzip"
code=0
PATH="$WORK/tools:$PATH" USERPROFILE="$WORK" bash "$ROOT/tests/test-windows.sh" > "$WORK/launcher.log" 2>&1 || code=$?
if [[ $code != 99 ]]; then
    cat "$WORK/launcher.log" >&2
    echo 'FAIL: launcher nie przekazał natywnej ścieżki rozpakowania do unzip' >&2
    exit 1
fi
echo 'PASS: MSYS-boundary regression, absolutne ścieżki z [] i cygpath, rzeczywiste operacje Git'
