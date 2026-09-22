#!/bin/bash
# Writes SHA256SUMS for every webrtc-*.zip in the given directory (default:
# current). Output is in `sha256sum` format so it can be verified with
# `sha256sum -c SHA256SUMS --ignore-missing`.
set -euo pipefail
dir="${1:-.}"
cd "$dir"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum webrtc-*.zip > SHA256SUMS
else
  shasum -a 256 webrtc-*.zip > SHA256SUMS
fi
cat SHA256SUMS
