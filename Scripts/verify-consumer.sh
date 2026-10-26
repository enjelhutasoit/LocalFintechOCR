#!/usr/bin/env bash
# Verifies the package can be consumed as a dependency by an external project.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/Consumer/Sources/Consumer"

cat > "$TMP/Consumer/Package.swift" <<EOF
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Consumer",
    platforms: [.macOS(.v12)],
    dependencies: [.package(path: "$ROOT")],
    targets: [
        .executableTarget(
            name: "Consumer",
            dependencies: [.product(name: "LocalFintechOCR", package: "$(basename "$ROOT")")]
        )
    ]
)
EOF

cat > "$TMP/Consumer/Sources/Consumer/main.swift" <<'EOF'
import Foundation
import LocalFintechOCR

guard LuhnValidator.isValid("4111111111111111") else { exit(1) }
_ = CardImageScanner(recognizer: VisionTextRecognizer())
print("consumer-ok")
EOF

swift build --package-path "$TMP/Consumer"
swift run   --package-path "$TMP/Consumer" Consumer | grep -q "consumer-ok"
echo "Consumer verification passed."
