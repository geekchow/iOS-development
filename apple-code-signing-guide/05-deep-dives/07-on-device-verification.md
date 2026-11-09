# 5.7 — On-Device Verification: installd, AMFI & the Kernel

> **Where you are:** seventh deep dive, the enforcement side. Everything earlier *produced* claims; this is where the iPhone *checks* them.
> **What you'll know after this file:** the two checkpoints (install time and run time), what each verifies, how profiles and trust are cached on the device, Developer Mode, Enterprise trust, and revocation.

## Role recap
**Owns:** deciding, offline and quickly, whether code may be installed and executed, and with which entitlements. **Appears in PawPal steps:** 7 (her phone), 8 (Leo's rejection), 11 (expiry).

## Internal design

### Checkpoint 1: install time (`installd` / MobileInstallation)
When an `.app`/`.ipa` arrives (Xcode, AirDrop, MDM, TestFlight, App Store), the install daemon checks:

| # | Check | Uses |
|---|---|---|
| 1 | The profile's CMS signature chains to **Apple Root CA** | Built-in root |
| 2 | Profile not expired; platform matches | `ExpirationDate`, `Platform` |
| 3 | This device's UDID ∈ `ProvisionedDevices` (or `ProvisionsAllDevices`) | Device identity |
| 4 | The binary's signing cert ∈ profile's `DeveloperCertificates` | CMS blob vs profile |
| 5 | App's `application-identifier` matches the profile's (with wildcards) | Entitlements |
| 6 | Every signed entitlement is allowed by the profile's `Entitlements` | Subset check |
| 7 | Code signature itself is well formed and valid; nested code too | CodeDirectory, CodeResources |

App Store and TestFlight builds skip the profile-based checks 2–6 in their usual form, because they arrive **signed by Apple** (5.8).

### Checkpoint 2: run time (kernel + AMFI)
**AMFI** (Apple Mobile File Integrity) is a kernel extension plus a userland helper daemon (`amfid`).

*What happens between tapping the PawPal icon and the first instruction executing?*

```mermaid
sequenceDiagram
  autonumber
  participant SB as SpringBoard
  participant K as Kernel (exec)
  participant AMFI as AMFI kext
  participant amfid as amfid (userland)
  participant VM as VM page-fault handler
  SB->>K: launch PawPal
  K->>K: Load Mach-O, find LC_CODE_SIGNATURE, register CodeDirectory
  K->>AMFI: Is this cdhash trusted?
  alt In static/loadable trust cache (Apple platform code)
    AMFI-->>K: trusted
  else Third-party code
    AMFI->>amfid: Validate signature + profile for this cdhash
    amfid->>amfid: Verify CMS chain → Apple Root, profile constraints, entitlements
    amfid-->>AMFI: OK + entitlements
  end
  AMFI-->>K: Allowed; attach entitlements to process
  loop Each executable page, on first touch
    VM->>VM: Hash page, compare to CodeDirectory slot
    VM-->>K: mismatch → SIGKILL (CODESIGNING)
  end
```

Key points:
- **Lazy page validation** is the payoff of per-page hashes: a 200 MB app launches without hashing 200 MB.
- **No unsigned executable memory.** iOS refuses to make writable pages executable for third-party apps (no JIT without a special entitlement), so you can't download code and run it.
- **Entitlements become process properties.** Daemons like `apsd` and `securityd` ask the kernel for the caller's *signed* entitlements. There's no way to fake them from inside the app.
- **Crash signature.** Code-signing kills appear as `Termination Reason: CODESIGNING` / `EXC_BAD_ACCESS (Code Signature Invalid)` in crash logs.

### Developer Mode (iOS/iPadOS 16+, watchOS 9+)
Development-signed apps (`get-task-allow`, debug profiles) won't launch until the user enables **Settings → Privacy & Security → Developer Mode** and restarts. This blocks social-engineering attacks that talk users into installing "dev" builds. Ad Hoc, TestFlight, App Store, and Enterprise builds don't require it.

### Enterprise trust
For In-House builds, the first launch is blocked until the user explicitly trusts the developer under **Settings → General → VPN & Device Management** (MDM-installed apps can be pre-trusted). The device also checks the enterprise certificate's revocation status online (OCSP) periodically. A revoked enterprise cert disables every app signed with it across all devices.

### Revocation and expiry, summarized

| Build type | Profile expires | Cert expires | Cert revoked |
|---|---|---|---|
| Development | Stops launching | Stops (profile invalid) | Stops |
| Ad Hoc | Stops launching | Stops (profile invalid) | Stops |
| Enterprise | Stops launching | Stops | **Stops everywhere** (OCSP) |
| App Store / TestFlight | n/a (Apple-signed) | **Unaffected** | **Unaffected** |

(TestFlight builds expire after 90 days for their own reasons.)

## Interactions
- **← codesign:** consumes CodeDirectory, CMS blob, entitlements, embedded profile.
- **← Portal (indirectly):** via the Apple-signed profile, and via OCSP for revocation.
- **→ OS services:** hands verified entitlements to the sandbox, `apsd`, keychain, container manager.

## ⚓ Back to the example
- **Step 7.** Mia hits Run. Xcode installs over USB/Wi-Fi; `installd` checks 1–7: profile signed by Apple ✔, expires 2026-11-01 ✔, UDID `…801E` listed ✔, signing cert listed ✔, `application-identifier` matches ✔, entitlements (`aps-environment=development`, App Group, `get-task-allow`) ⊆ profile ✔. She has Developer Mode on. At launch, `amfid` validates the cdhash and the kernel attaches entitlements. The debugger can attach because `get-task-allow = true`.
- **Step 8.** On Leo's phone, check 3 fails: `00008120-…5A6E` isn't in `ProvisionedDevices`, so the install is rejected before any code runs. Leo doesn't need Developer Mode for Ad Hoc builds.
- **Step 11.** A year later, Leo taps PawPal and the Ad Hoc profile has expired. The app won't open. Meanwhile, millions of App Store installs keep running, because their signature is Apple's.

## Failure behavior
| Symptom | Likely cause |
|---|---|
| *"Unable to Install … integrity could not be verified"* | Profile/device/cert/entitlement mismatch (checks 3–6) |
| App opens and instantly disappears, crash log `CODESIGNING` | Binary modified after signing, or a nested framework is unsigned or mis-signed |
| *"Untrusted Developer"* alert | Enterprise build not yet trusted in Settings |
| Dev build won't launch on iOS 16+ | Developer Mode off |
| Push token never arrives | `aps-environment` missing in signed entitlements |

---
← [5.6 — codesign](06-codesign-and-the-signature.md) · Next → [5.8 — Distribution & Re-signing](08-distribution-and-resigning.md) · [Concept map](../03-concept-map.md)
