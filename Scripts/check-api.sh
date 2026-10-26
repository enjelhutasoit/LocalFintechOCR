#!/usr/bin/env bash
# Fails when the public API breaks compatibility with a released tag.
# Usage: Scripts/check-api.sh v1.0.0
set -euo pipefail

BASELINE="${1:?usage: check-api.sh <baseline-tag>}"
cd "$(cd "$(dirname "$0")/.." && pwd)"

git fetch --tags --quiet
swift package diagnose-api-breaking-changes "$BASELINE" --products LocalFintechOCR
echo "No breaking API changes against $BASELINE."
