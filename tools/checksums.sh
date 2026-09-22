#!/bin/bash
# Считает SHA256SUMS по всем webrtc-*.zip в каталоге (по умолчанию — текущем).
# Формат — как у `sha256sum`, чтобы проверять `sha256sum -c SHA256SUMS`.
set -euo pipefail
dir="${1:-.}"
cd "$dir"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum webrtc-*.zip > SHA256SUMS
else
  shasum -a 256 webrtc-*.zip > SHA256SUMS
fi
cat SHA256SUMS
