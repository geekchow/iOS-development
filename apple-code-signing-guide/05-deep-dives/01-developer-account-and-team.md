# 5.1 — The Developer Account & Team

> **Where you are:** first deep dive. The root of identity.
> **What you'll know after this file:** what a Team really is, how the program types differ, how roles limit who can create signing assets, and how teams authenticate automation.

## Role recap
**Owns:** the legally accountable identity behind every certificate, App ID, device, and profile. **Appears in PawPal steps:** 1 (enrollment), 10 (CI access via API keys).

## Internal design

### Apple ID vs. Team
- An **Apple ID** is a *person's* login.
- A **Team** is the *entity* that owns signing assets. One Apple ID can belong to many teams. In Xcode's "Team" dropdown, each entry is a team, not a person.
- The **Team ID** is a 10-character alphanumeric string (e.g. `7XQ4K9P2LM`). It shows up in:
  - the certificate subject (`OU=7XQ4K9P2LM`),
  - the App ID prefix (`7XQ4K9P2LM.com.miachen.pawpal`),
  - entitlements (`com.apple.developer.team-identifier`, `application-identifier`),
  - keychain access groups, so two apps can share keychain items only if they're from the same team.

Because the Team ID ends up inside cryptographically sealed data, **you cannot move an app's signing identity to another team without changing its identity**. App transfers between teams are a deliberate, Apple-mediated process for that reason.

### Program types

| Program | Who | What it unlocks | Notes |
|---|---|---|---|
| **Free (Personal Team)** | Any Apple ID in Xcode | On-device development only | Profiles expire after **7 days**; small device and App ID limits; many capabilities (push, etc.) unavailable; no distribution |
| **Apple Developer Program — Individual** | A person | Full development + App Store / TestFlight / Ad Hoc + Developer ID (macOS) | Seller name = your legal name |
| **Apple Developer Program — Organization** | A legal entity (needs a D-U-N-S number) | Same, plus multiple members with roles | Seller name = company |
| **Apple Developer Enterprise Program** | Large organizations, approved by Apple | **In-House** distribution to employees without the App Store or device lists | Tightly policed; misuse gets certificates revoked, which breaks every installed app at once |

### Roles: who may create signing assets
In organization teams, App Store Connect roles control the Certificates, Identifiers & Profiles section. Simplified:

| Role | Can create dev certs | Can create distribution certs | Can register devices / App IDs / profiles |
|---|---|---|---|
| Account Holder | ✅ | ✅ | ✅ |
| Admin | ✅ | ✅ | ✅ |
| App Manager / Developer | ✅ (own) | Only if granted "Access to Certificates, Identifiers & Profiles" | Limited unless granted |
| Marketing / Sales / Finance | ❌ | ❌ | ❌ |

The design idea: **development identities are personal and cheap; distribution identities are shared and guarded.** Every engineer gets their own Apple Development cert. Very few people should be able to mint an Apple Distribution cert.

### Authenticating automation: App Store Connect API keys
Logging into a CI box with a human Apple ID and 2FA doesn't work. Apple's answer is **App Store Connect API keys**:

- created in App Store Connect → Users and Access → Integrations,
- downloaded *once* as a `.p8` file (an EC private key), with a **Key ID** and **Issuer ID**,
- used to sign short-lived **JWTs** that authenticate API calls, including to the provisioning endpoints (certificates, profiles, devices, bundle IDs).

`xcodebuild` accepts these directly:

```bash
xcodebuild -allowProvisioningUpdates \
  -authenticationKeyPath ~/keys/AuthKey_ABC123XYZ.p8 \
  -authenticationKeyID ABC123XYZ \
  -authenticationKeyIssuerID 69a6de7e-xxxx-xxxx-xxxx-5bc37c11a4d1 \
  -scheme PawPal archive
```

Don't confuse this `.p8` with an **APNs auth key** (also `.p8`), which authenticates your *server* to push notifications and has nothing to do with code signing.

## Interactions
- **→ Portal:** the Team is the owner of every row in Certificates, Identifiers & Profiles.
- **→ Certificates:** every cert's subject carries the Team ID, and its validity depends on the membership being active.
- **→ App Store Connect:** the team's agreements (Paid Apps, etc.) must be accepted before uploads succeed.

## ⚓ Back to the example
- **Step 1.** Mia enrolls as an *Individual*. Apple assigns Team ID `7XQ4K9P2LM`. She's the Account Holder, so she can mint any certificate type. If she'd used only her free Personal Team, step 5's profile would expire every 7 days, and step 3's Push Notifications capability wouldn't be available at all.
- **Step 10.** For CI, she creates an App Store Connect API key with the *App Manager* role (or *Admin* if CI needs to create distribution certs) and stores the `.p8` as a CI secret. CI never sees her Apple ID password.

## Failure behavior
| Situation | Effect |
|---|---|
| **Membership lapses** (fee not renewed) | Existing App Store apps are removed from sale. You can't create new certs or profiles, and existing distribution profiles are invalidated. |
| **Agreements not accepted** | Uploads and TestFlight fail with agreement errors, even though signing itself is fine. |
| **Account terminated for abuse** | Apple revokes the team's certificates. Enterprise and Ad Hoc builds stop launching once devices see the revocation. |
| **API key leaked** | Revoke it in App Store Connect immediately. Keys can't be re-downloaded, so treat the `.p8` like a password. |

---
← [04 — Running example](../04-running-example.md) · Next → [5.2 — Signing Certificates](02-signing-certificates.md) · [Concept map](../03-concept-map.md)
