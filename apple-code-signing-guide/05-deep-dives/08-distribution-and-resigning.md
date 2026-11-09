# 5.8 — Distribution & Apple Re-signing

> **Where you are:** last deep dive. How the same building blocks are combined differently for each way an app reaches people, including macOS.
> **What you'll know after this file:** the distribution methods side by side, what App Store Connect does to your binary, why store apps survive cert expiry, and how macOS's Developer ID + notarization fits in.

## Role recap
**Owns:** getting a signed build from the developer to users at scale, and for the App Store, *replacing* the developer's signature with Apple's. **Appears in PawPal steps:** 8 (Ad Hoc), 9 (TestFlight & App Store), 11 (long-term behavior).

## Internal design

### Distribution methods compared

| Method | Cert | Profile | Who can install | Review | Signature users' devices see |
|---|---|---|---|---|---|
| **Development** | Apple Development | Development (UDIDs) | Registered devices, Developer Mode | none | Developer's |
| **Ad Hoc** | Apple Distribution | Ad Hoc (UDIDs) | Up to 100 registered devices per family | none | Developer's |
| **TestFlight** | Apple Distribution | App Store Connect | Internal (team members) + up to 10,000 external testers | Beta review for external | **Apple's** |
| **App Store** | Apple Distribution | App Store Connect | Everyone | Full App Review | **Apple's** |
| **Enterprise In-House** | Enterprise Distribution | In-House (all devices) | Employees of the org | none (policy-bound) | Developer's |
| **Custom Apps / Apple Business Manager** | Apple Distribution | App Store Connect | Specific organizations | App Review | **Apple's** |
| **macOS Developer ID** | Developer ID Application | optional (only if using restricted entitlements) | Anyone, via direct download | Notarization (automated scan) | Developer's + notarization ticket |

### What happens after you upload

*How does Mia's signed archive become the build that users download?*

```mermaid
sequenceDiagram
  autonumber
  participant X as Xcode / altool / Transporter
  participant ASC as App Store Connect
  participant Proc as Apple processing
  participant Rev as App Review
  participant Store as App Store / TestFlight CDN
  participant U as User's iPhone
  X->>ASC: Upload .ipa (signed: Apple Distribution: Mia, App Store profile)
  ASC->>Proc: Validate signature, profile type, entitlements, Info.plist, SDK
  Proc->>Proc: Generate per-device variants (app thinning)
  Proc->>Proc: Re-sign with Apple's own certificate; apply FairPlay encryption
  Proc-->>ASC: Build "Ready to Test" / "Ready for Review"
  ASC->>Store: TestFlight distribution
  ASC->>Rev: Submit for review
  Rev-->>ASC: Approved
  ASC->>Store: Release
  U->>Store: Download
  Store-->>U: Apple-signed, encrypted variant; no embedded device list needed
```

Why the upload's signature still matters, even though it gets replaced:
- It **authenticates the upload** as really coming from Team `7XQ4K9P2LM`.
- Its **entitlements are what Apple will keep** in the re-signed build, after checking they're allowed for the App ID. So `aps-environment` must already be `production`, and `get-task-allow` must be `false`.
- The App Store profile's *type* tells Apple this is intended for store distribution.

Why re-signing is so useful:
- Users' devices don't need to be in any device list.
- **Your certificate expiring or being revoked doesn't break live App Store installs.**
- Apple can apply FairPlay DRM and device-specific thinning centrally.

### Exporting: `xcodebuild -exportArchive`
The same `.xcarchive` can be exported for different methods. The `ExportOptions.plist` decides which:

```xml
<dict>
  <key>method</key>          <string>app-store-connect</string>  <!-- or release-testing (ad hoc), debugging, enterprise, developer-id -->
  <key>teamID</key>          <string>7XQ4K9P2LM</string>
  <key>signingStyle</key>    <string>manual</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>com.miachen.pawpal</key>        <string>PawPal AppStore</string>
    <key>com.miachen.pawpal.widget</key> <string>PawPal Widget AppStore</string>
  </dict>
</dict>
```
(Older Xcode versions used `app-store` and `ad-hoc` for the method names.) Export **re-signs** the archived app with the chosen distribution identity and profiles. That's why one archive can become both an Ad Hoc `.ipa` and an App Store upload.

### macOS: Developer ID + Hardened Runtime + Notarization
Outside the Mac App Store there's no Apple re-signing, so:
1. Sign with **Developer ID Application**, with **Hardened Runtime** enabled (`--options runtime`) and a secure timestamp.
2. Submit to the **notary service** (`xcrun notarytool submit PawPal.zip --wait`). Apple scans it and records its cdhashes.
3. **Staple** the ticket (`xcrun stapler staple PawPal.app`) so Gatekeeper can verify offline.
4. On first launch, **Gatekeeper** checks: valid Developer ID signature + notarization ticket (stapled or fetched online) → allowed.

Revoking a Developer ID cert, or revoking notarization for specific cdhashes, lets Apple disable known malware after the fact.

## Interactions
- **← codesign (5.6):** produces the developer-signed upload / Ad Hoc / Enterprise `.ipa`.
- **← Profiles (5.5):** export method ⇒ profile type.
- **→ On-device verification (5.7):** for store builds the device verifies **Apple's** signature; for others, the developer's signature + embedded profile.

## ⚓ Back to the example
- **Step 8 (Ad Hoc).** `Distribute App → Release Testing` re-signs the archive with *Apple Distribution: Mia Chen* and the Ad Hoc profile. The `.ipa` keeps *her* signature, so Leo's phone does all the profile checks from 5.7 itself. Hence the UDID failure.
- **Step 9 (TestFlight → App Store).** `Distribute App → App Store Connect` re-signs with the App Store profile (`aps-environment = production`, `beta-reports-active = true`). Upload, processing, then Apple re-signs. TestFlight testers and later App Store users run a build whose `Authority` chain is Apple's, not Mia's. Push tokens now come from **production** APNs, so her server must use the production endpoint.
- **Step 11.** Mia's distribution cert expires. Live App Store users notice nothing. She just creates a new cert (or relies on cloud-managed signing) before her next upload.

## Failure behavior
| Situation | Effect |
|---|---|
| Upload signed with a dev profile | Validation error: invalid provisioning profile / missing beta entitlement |
| `get-task-allow = true` in upload | Rejected at validation |
| Entitlement not allowed for App ID | `ITMS-90xxx` style validation error at upload |
| Enterprise cert revoked | All installed enterprise apps stop launching |
| Mac app not notarized | Gatekeeper blocks: *"cannot be opened because Apple cannot check it for malicious software"* |

---
← [5.7 — On-Device Verification](07-on-device-verification.md) · Next → [06 — Full Walkthrough](../06-walkthrough.md) · [Concept map](../03-concept-map.md)
