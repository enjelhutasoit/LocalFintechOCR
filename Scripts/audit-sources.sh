#!/usr/bin/env bash
# Fails when production code violates the SDK's safety and architecture rules.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
failed=0

forbidden() {
  local description="$1" pattern="$2"
  local hits
  # Ignore comment lines (//, ///).
  hits="$(grep -RInE "$pattern" Sources --include='*.swift' | grep -vE ':[0-9]+:[[:space:]]*//' || true)"
  if [ -n "$hits" ]; then
    echo "FAIL: $description"
    echo "$hits"
    failed=1
  fi
}

forbidden "logging / printing (PII risk)"  '\b(print|debugPrint|NSLog|os_log)\('
forbidden "logger usage (PII risk)"        '\bLogger\('
forbidden "crash-prone calls"              '\b(fatalError|preconditionFailure|precondition|assert)\('
forbidden "force try / force cast"         '(try!|as!)'
forbidden "network or disk access"         '\b(URLSession|FileManager)\b|Data\(contentsOf'

if grep -nE 'unsafeFlags' Package.swift; then
  echo "FAIL: unsafeFlags makes the package unusable as a remote dependency"
  failed=1
fi

# Core must stay free of system frameworks.
core_imports="$(grep -RhE '^import ' Sources/LocalFintechOCRCore | grep -vE '^import Foundation$' || true)"
if [ -n "$core_imports" ]; then
  echo "FAIL: Core may only import Foundation"
  echo "$core_imports"
  failed=1
fi

# Vision may only import Foundation, Vision, and Core.
vision_imports="$(grep -RhE '^import ' Sources/LocalFintechOCRVision \
  | grep -vE '^import (Foundation|Vision|LocalFintechOCRCore)$' || true)"
if [ -n "$vision_imports" ]; then
  echo "FAIL: unexpected import in Vision target"
  echo "$vision_imports"
  failed=1
fi

if [ "$failed" -ne 0 ]; then exit 1; fi
echo "Source audit passed."
