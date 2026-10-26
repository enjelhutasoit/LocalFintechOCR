# Changelog

All notable changes to this project are documented here.
The project follows [Semantic Versioning](https://semver.org).

## [1.0.0]

### Added
- `LocalFintechOCRClient`: single public entry point (`scan(imageData:)`, `scan(text:)`).
- `LocalFintechOCRConfiguration`: all tunable behavior as plain data.
- DocC catalog, README, source audit script, API-breakage script.

### Stability
- Public API is covered by Semantic Versioning from this release.

## [0.8.0]
- `TextRecognizing` port, `RecognizedTextAssembler`, `CardImageScanner`, `VisionTextRecognizer`.

## [0.7.0]
- `CardScanPipeline`, `CardScanResult`, `CardScanError`.

## [0.6.0]
- `Bank`, `BankNameMatcher` (OCR repair, normalization, relative threshold).

## [0.5.0]
- `ExpiryDate`, `ExpiryDateParser`, `CardNetworkDetector`, `CardNetworkRule`.

## [0.4.0]
- `CardNumber` (PII-masked), `CardNumberExtractor`.

## [0.3.0]
- `OCRTextSanitizer`, `OCRConfusionTable`.

## [0.2.0]
- `LevenshteinDistance` (two-row).

## [0.1.0]
- Package scaffold, CI, `LuhnValidator`.
