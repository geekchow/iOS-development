# Part 6 — Full Walkthrough: PawPal End to End

> **Where you are:** Stage 6. The running example from Part 4, replayed at full depth and stitched together from all eight deep dives.
> **What you'll know after this file:** every hop from "Mia enrolls" to "a stranger downloads PawPal", with the concrete data that crosses each boundary and the commands to see it yourself.

## The annotated map

*The Part 3 coordination diagram again, now carrying PawPal's real data on every hop.*

```mermaid
sequenceDiagram
  autonumber
  participant Mia
  participant KC as Mia's Keychain
  participant P as Developer Portal
  participant X as Xcode / codesign
  participant MP as Mia's iPhone
  participant LP as Leo's iPhone
  participant ASC as App Store Connect
  participant U as Any user

  Mia->>P: Enroll → Team 7XQ4K9P2LM
  KC->>P: CSR (RSA-2048 public key)
  P-->>KC: Apple Development: Mia Chen (R8J2N5T7QX), OU=7XQ4K9P2LM
  Mia->>P: App IDs …pawpal, …pawpal.widget + Push, App Groups
  Mia->>P: Device 00008110-…801E
  P-->>X: Dev profiles (cert, App ID, ents, [801E], exp 2026-11-01)
  X->>X: Sign widget → cdhash W; seal app (CodeResources ∋ W, profile)
  X->>MP: Install PawPal.app
  MP->>MP: installd ✔ profile/UDID/cert/ents; AMFI ✔ cdhash; pages lazily
  KC->>P: CSR → Apple Distribution: Mia Chen
  P-->>X: Ad Hoc profile ([801E] only)
  X->>LP: PawPal.ipa
  LP--xX: ✘ UDID 5A6E not in ProvisionedDevices
  Mia->>P: Register 5A6E, regenerate Ad Hoc profile
  X->>LP: PawPal.ipa (re-exported) ✔
  X->>ASC: Upload (App Store profile, aps-environment=production)
  ASC->>ASC: Validate → re-sign with Apple key → FairPlay
  ASC->>U: TestFlight / App Store download (Apple-signed)
```

## Step by step, at full depth

### 1. Identity is created (→ 5.1)
Mia enrolls as an Individual. Apple creates Team `7XQ4K9P2LM`, the string that will show up in her certificate's `OU`, every App ID prefix, `com.apple.developer.team-identifier`, and her keychain access groups. She is Account Holder, so she can create every certificate type.

### 2. A key pair becomes a signing identity (→ 5.2)
Signing into Xcode with automatic signing:
1. Keychain generates an RSA-2048 key pair in `login.keychain-db`. The private key never leaves the Mac.
2. A CSR (public key + subject, self-signed by the private key) goes to the Portal.
3. Apple's WWDR G3 CA issues `Apple Development: Mia Chen (R8J2N5T7QX)`, `OU=7XQ4K9P2LM`, valid one year, with the development marker OID.
4. Keychain pairs cert + key into an identity:
```bash
security find-identity -v -p codesigning
#  1) 9F3A…C1 "Apple Development: Mia Chen (R8J2N5T7QX)"
```
The chain the device will later check: leaf → WWDR G3 → Apple Root CA.

### 3. The app gets a name and powers (→ 5.3)
App IDs `7XQ4K9P2LM.com.miachen.pawpal` and `7XQ4K9P2LM.com.miachen.pawpal.widget` are registered. *Push Notifications* is enabled on the app, *App Groups* (`group.com.miachen.pawpal`) on both. These portal switches mean that profiles generated from now on will *allow* `aps-environment` and the app-group entitlement. Mia's `.entitlements` files *claim* them.

### 4. A device is allowed (→ 5.4)
Plugging in her iPhone registers UDID `00008110-001A2B3C4D5E801E` (1 of 100 iPhone slots this membership year). She enables Developer Mode on the phone.

### 5. Apple signs the permission slip (→ 5.5)
The Portal generates two development profiles, one per App ID. PawPal's says, in Apple-signed form:
- **who:** `DeveloperCertificates = [Mia's dev cert]`, `TeamIdentifier = 7XQ4K9P2LM`
- **what:** `application-identifier = 7XQ4K9P2LM.com.miachen.pawpal`, `aps-environment = development`, `get-task-allow = true`, app group, `keychain-access-groups = 7XQ4K9P2LM.*`
- **where:** `ProvisionedDevices = [00008110-…801E]`
- **until:** `ExpirationDate = 2026-11-01`

### 6. The bundle is sealed (→ 5.6)
Inside out:
1. **Widget:** profile copied to `PawPalWidget.appex/embedded.mobileprovision`; final entitlements written to `.xcent`; `codesign --force --sign 9F3A…C1 --entitlements PawPalWidget.appex.xcent PawPalWidget.appex`. CodeDirectory = page hashes + special slots (Info.plist, CodeResources, entitlements XML and DER). CMS blob = Mia's private-key signature over the CodeDirectory hash, plus the cert chain. Result: cdhash **W**.
2. **App:** profile copied to `PawPal.app/embedded.mobileprovision`; `_CodeSignature/CodeResources` records hashes of every resource, the profile, and `PlugIns/PawPalWidget.appex → cdhash W`. The `PawPal` executable's CodeDirectory covers all of that via special slots. Signed. Result: cdhash **A**.
```bash
codesign --verify --deep --strict --verbose=2 PawPal.app
# PawPal.app: valid on disk
# PawPal.app: satisfies its Designated Requirement
```

### 7. The iPhone decides (→ 5.7)
- **installd** verifies the profile's Apple signature, the date, UDID `…801E` ∈ list, the signing cert ∈ `DeveloperCertificates`, `application-identifier` match, and the signed entitlements ⊆ profile entitlements, for the app *and* the widget.
- **Launch:** the kernel registers cdhash A; AMFI/amfid validates the CMS chain to Apple Root and the profile constraints; entitlements are attached to the process. As pages fault in, each is hashed and compared. `apsd` sees `aps-environment = development` → sandbox push token. The debugger attaches because of `get-task-allow`.

### 8. Ad Hoc for Leo, broken and then fixed (→ 5.2, 5.4, 5.5, 5.7, 5.8)
- Archive (`Product → Archive`) → `Distribute App → Release Testing`. Xcode needs a **distribution** identity, so it creates `Apple Distribution: Mia Chen` via a second CSR, plus an **Ad Hoc profile** (`get-task-allow = false`, `aps-environment = production`, devices = `[…801E]`).
- Export re-signs the archive with that identity and profile, then zips to `PawPal.ipa`.
- On Leo's phone, installd's UDID check fails → install rejected.
- Fix: register `00008120-000F1E2D3C4B5A6E` → regenerate Ad Hoc profile (now both UDIDs) → re-export → install ✔. Leo doesn't need Developer Mode because this isn't a development-signed build.

### 9. To the world (→ 5.5, 5.8)
- Export with method `app-store-connect` → re-signed with the App Store profile (no devices, `beta-reports-active = true`) → upload.
- App Store Connect checks that the upload's signature chains to Team `7XQ4K9P2LM`, the profile type is App Store, and the entitlements are allowed. It processes the build, thins it, **re-signs with Apple's key**, and applies FairPlay.
- TestFlight testers, then App Store users after Review, install a build whose signature authority is Apple. Their phones have no device list to consult. Push now uses production APNs.

### 10. CI (→ 5.1, 5.2, 5.6)
The CI Mac needs either:
- **Manual assets:** the distribution `.p12` imported into an unlocked temporary keychain with `set-key-partition-list` (otherwise `errSecInternalComponent`), plus the App Store profiles installed. Or:
- **Automatic via API key:** `xcodebuild -allowProvisioningUpdates -authenticationKeyPath … -authenticationKeyID … -authenticationKeyIssuerID …`, letting Xcode fetch profiles and use cloud-managed distribution signing.

### 11. A year later (→ 5.2, 5.7, 5.8)
- Dev and distribution certs expire → new builds need new certs and profiles.
- Leo's Ad Hoc install stops launching (profile expired).
- App Store installs keep working: Apple's signature, not Mia's, is the one being checked.

## Recap: the problem, solved
Part 1 asked five questions every device must answer offline, in milliseconds. PawPal's journey answered them all:

| Question | Answered by | In PawPal |
|---|---|---|
| Q1 **Who?** | Certificate chain to Apple Root + profile's `DeveloperCertificates` | Mia's cert, `OU=7XQ4K9P2LM` |
| Q2 **Modified?** | CodeDirectory page hashes + CodeResources + CMS signature | cdhashes W and A, checked page by page |
| Q3 **Allowed to do?** | Entitlements, approved by App ID → profile, sealed by codesign | push and App Group worked; a missing capability would have failed |
| Q4 **Where?** | Profile's `ProvisionedDevices` | Leo was rejected until he was added |
| Q5 **Revocable?** | Expiry + revocation of certs/profiles; Apple re-signing for the Store | Ad Hoc build expired; App Store build lived on |

---
← [5.8 — Distribution & Re-signing](05-deep-dives/08-distribution-and-resigning.md) · Next → [07 — Troubleshooting & next steps](07-next-steps.md) · [Concept map](03-concept-map.md)
