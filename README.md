## For the person with the developer account

1. Clone this repo and open `Lock.xcodeproj` in Xcode.
2. Set your Apple Developer team and replace `com.example.Lock` with the real bundle identifier.
3. Enable Family Controls and NFC Tag Reading on that App ID.
4. Run on a physical iPhone. Turn on Beta mode for the first test, then turn it off to try the real key and Screen Time blocking.

# Lock

Lock is a small SwiftUI iOS MVP for a physical NFC focus key:

**Tap your NFC tag in the app to lock selected distracting apps. Tap it again to unlock them.**

The implementation uses public Apple APIs only:

- `CoreNFC` for foreground tag scanning.
- `FamilyControls` for user-approved app and category selection.
- `ManagedSettings` for shielding the selected apps, categories, and web domains.

`DeviceActivity` is not included in this MVP because the requested behavior is immediate NFC-triggered locking/unlocking, not scheduled monitoring or usage-threshold enforcement. The service boundaries leave room to add a Device Activity monitor extension later.

## Public API limitations

iOS does not allow a third-party app to silently receive arbitrary NFC tag taps in the background and immediately unlock other apps. Lock therefore starts an NFC reader session from the app UI. The service boundary is intentionally small (`NFCManaging`) so this behavior can be replaced if Apple expands public NFC capabilities later.

Family Controls also requires Apple entitlement approval and user authorization. The app cannot enumerate installed apps manually and does not attempt to do so; it uses Apple’s `FamilyActivityPicker`.

## Beta mode

Lock includes a persisted Beta mode toggle in onboarding and Settings. When Beta mode is on:

- NFC scans are simulated.
- The app registers a simulated beta key.
- Lock/unlock transitions update local state only.
- Managed Settings are not changed.

When Beta mode is off, Lock uses the real Core NFC and Screen Time code paths.

Use Beta mode for internal TestFlight smoke tests, then turn it off to verify the real NFC and Family Controls behavior on a physical iPhone.

## NFC tags

You do not need to write any custom payload to the NFC tag for this MVP. Lock reads the tag identifier exposed by Core NFC and stores that as the registered physical key.

Use a normal NFC tag such as NTAG213/215/216. During setup, tap the tag once to register it. Later, use the same physical tag to lock and unlock.

If a tag cannot be read consistently, try a different tag type. Some payment cards, access cards, transit cards, and security badges may not expose a stable identifier that third-party apps can use.

## Requirements

- Xcode with iOS SDK support.
- A physical iPhone with NFC support.
- A real NFC tag.
- Apple Developer account with the Family Controls entitlement enabled.
- Near Field Communication Tag Reading capability.

## Entitlements

`Lock/Lock.entitlements` includes:

- `com.apple.developer.family-controls`
- `com.apple.developer.nfc.readersession.formats` with `TAG` and `NDEF`

You still need to enable matching capabilities for your app identifier in the Apple Developer portal and in Xcode signing.

## Running

1. Open `Lock.xcodeproj` in Xcode.
2. Set your development team and bundle identifier.
3. Confirm the Family Controls and NFC capabilities are enabled.
4. Run on a physical iPhone. The simulator cannot scan real NFC tags and cannot fully exercise Screen Time restrictions.
5. Grant Screen Time authorization, choose apps/categories, and register a tag.

## Internal TestFlight checklist

1. Replace `com.example.Lock` with the real bundle identifier.
2. Select the correct Apple Developer team in Signing & Capabilities.
3. Confirm the App ID has Family Controls and NFC Tag Reading enabled.
4. Archive with the `Lock` scheme.
5. Upload to App Store Connect.
6. Add the build to an internal testing group.
7. First smoke test with Beta mode on.
8. Turn Beta mode off and verify real Screen Time authorization, app selection, NFC registration, lock, and unlock.

## Tests

The core state transitions are covered with mocks:

- onboarding completion
- NFC tag registration
- valid tag lock
- valid tag unlock
- invalid tag rejection
- blocking failure
- persisted state restoration
- beta mode simulated NFC registration
- beta mode simulated lock transition

Run tests from Xcode with the `Lock` scheme.
