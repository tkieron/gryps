#!/usr/bin/env bash
# One semantic suite for all platforms. Requires an already versioned build.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BASH=${TEST_BASH:-bash}
for suite in run test-v13 test-completion test-smart-tab test-push-feedback test-identity test-v141; do
    "$TEST_BASH" "$ROOT/tests/$suite.sh"
done
if command -v zsh >/dev/null 2>&1; then zsh "$ROOT/tests/test-zsh.zsh"; else echo 'SKIP: test-zsh: brak interpretera zsh'; fi
