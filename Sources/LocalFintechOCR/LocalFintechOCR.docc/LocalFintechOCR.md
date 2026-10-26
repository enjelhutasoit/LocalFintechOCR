# ``LocalFintechOCR``

Offline card scanning for fintech apps. No cloud, no per-scan cost, no dependencies.

## Overview

Pass an image of a card to ``LocalFintechOCRClient``. The SDK reads the text with Apple Vision,
repairs typical OCR mistakes, validates the card number with the Luhn algorithm, and returns
typed data: card number, network, expiry date, and bank.

All processing happens on the device. Card numbers are masked in every textual
representation, so they do not leak into logs or crash reports by accident.

```swift
let client = LocalFintechOCRClient()
let card = try await client.scan(imageData: jpegData)
```

## Topics

### Scanning

- ``LocalFintechOCRClient``
- ``LocalFintechOCRConfiguration``
