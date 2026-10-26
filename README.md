# LocalFintechOCR

Offline card OCR for fintech apps. Image in, typed and PII-masked card data out.
100% on-device, zero cloud, zero per-scan cost, zero dependencies.

## Installation (Swift Package Manager)

```swift
.package(url: "https://github.com/enjelhutasoit/LocalFintechOCR.git", from: "1.0.0")
```

Requires iOS 15+ / macOS 12+, Swift 6.0+.

## Usage

```swift
import LocalFintechOCR

let client = LocalFintechOCRClient()

do {
    let card = try await client.scan(imageData: jpegData)
    print(card.cardNumber)        // •••• 1111 (masked)
    print(card.network)           // .visa
    print(card.expiry?.formatted) // "12/34"
    print(card.bank?.bank.name)   // "MANDIRI"

    if card.expiry?.isExpired(asOf: Date(), calendar: .current) == true { /* reject */ }
} catch let error as CardImageScanError {
    switch error {
    case .recognition(let reason): break   // OCR engine failed
    case .scan(let reason): break          // no card, empty text, or two different cards
    }
}
```

Full card number: `card.cardNumber.digits` (explicit, so every use is easy to find in review).

Already have text from another OCR engine? Use `try client.scan(text:)`.

## Configuration

```swift
var config = LocalFintechOCRConfiguration.default
config.banks.append(Bank(name: "SEABANK"))
let client = LocalFintechOCRClient(configuration: config)
```

## Guarantees

- No network, no disk, no logging. Enforced by `Scripts/audit-sources.sh` in CI.
- Typed errors, no force unwraps in production code, no crashes on hostile input.
- Card numbers are Luhn-validated. Ambiguous scans (two different cards) fail instead of guessing.

## Limits

- Luhn and network detection are integrity heuristics, not proof that a card is real.
- OCR quality depends on image quality and OS version.
- A bank name sharing a line with other text may not be detected.
- Review `CardNetworkRule.defaults` and `Bank.defaults` for your market before shipping.

## Development

```bash
swift test
./Scripts/audit-sources.sh
./Scripts/check-api.sh <last-release-tag>
```
