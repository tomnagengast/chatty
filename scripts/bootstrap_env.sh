#!/usr/bin/env bash
set -euo pipefail
git init
echo ".claude/.last-*.json" >> .gitignore

# Optional tools
command -v swift-format >/dev/null || echo "Tip: install swift-format via Homebrew."
command -v swiftlint >/dev/null || echo "Tip: install swiftlint via Homebrew."
