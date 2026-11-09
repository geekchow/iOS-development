# Part 4 — The Running Example: Shipping PawPal

> **Where you are:** Stage 4, the spine of the series.
> **What you'll know after this file:** one realistic scenario, traced shallowly, that every deep dive comes back to. Learn the steps by number. Later articles refer to them ("recall step 5…").

## The scenario in three sentences

**Mia** is an indie developer building **PawPal**, an iOS app that reminds pet owners about vet visits using **push notifications** and shares data with a home-screen widget via an **App Group**. She debugs it on her own iPhone, sends a test build to her friend **Leo**'s iPhone, then ships it to everyone through **TestFlight** and the **App Store**. Along the way she sets up **CI** and hits two classic errors.

## Fixed facts we'll reuse

| Thing | Value |
|---|---|
| Team | "Mia Chen" (Individual), **Team ID `7XQ4K9P2LM`** |
| Bundle ID | `com.miachen.pawpal` |
| App ID | `7XQ4K9P2LM.com.miachen.pawpal` |
| Widget extension bundle ID | `com.miachen.pawpal.widget` |
| App Group | `group.com.miachen.pawpal` |
| Mia's iPhone UDID | `00008110-001A2B3C4D5E801E` |
| Leo's iPhone UDID | `00008120-000F1E2D3C4B5A6E` |

## The journey, traced shallowly

Each concept and component is **bolded** where it first shows up.

### Step 1 — Join the program
Mia enrolls in the **Apple Developer Program** as an Individual and pays the annual fee. Apple creates her **Team** with Team ID `7XQ4K9P2LM`. She is the **Account Holder**.

### Step 2 — Get a development certificate
In Xcode → Settings → Accounts she signs in. With automatic signing, Xcode asks her **Keychain** to generate a **private key** and a CSR, sends it to the **Developer Portal**, and gets back an **Apple Development certificate**. Keychain pairs the two into a **signing identity**: `Apple Development: Mia Chen (R8J2N5T7QX)`.

### Step 3 — Register the App ID and turn on capabilities
She creates the **App ID** `7XQ4K9P2LM.com.miachen.pawpal` and enables the **Push Notifications** and **App Groups** **capabilities**. In Xcode this produces a `PawPal.entitlements` file containing **entitlements** like `aps-environment` and `com.apple.security.application-groups`.

### Step 4 — Register her iPhone
She plugs in her iPhone. Xcode reads the **UDID** and registers it as a **device** on the team.

### Step 5 — Get a development provisioning profile
The Portal produces an **iOS App Development provisioning profile** listing: her dev certificate, the App ID, the allowed entitlements (`aps-environment = development`, `get-task-allow = true`, the App Group…), her iPhone's UDID, and an expiry date. Apple signs it.

### Step 6 — Build and sign
**Xcode** compiles PawPal and the widget, copies the profile into the bundle as `embedded.mobileprovision`, and runs **`codesign`**, which writes a **code signature** (per-page hashes in a CodeDirectory, signed by her private key) into each binary. The widget is signed first, the app last.

### Step 7 — Install and run on her iPhone
**installd** checks the profile: Apple-signed? Not expired? Her UDID listed? Signing cert listed? Entitlements within what's allowed? Then, at launch, **AMFI** and the **kernel** check the code signature and each page as it's loaded. PawPal runs, the debugger attaches (thanks to `get-task-allow`), and she gets a push token from the *sandbox* APNs environment.

### Step 8 — Ad Hoc build for Leo  *(failure #1)*
Mia exports an **Ad Hoc** build and AirDrops the `.ipa` to Leo. It **fails to install**: Leo's UDID isn't in the profile. She registers Leo's UDID, regenerates the **Ad Hoc profile** (signed with her **Apple Distribution certificate**), re-exports, and it installs.

### Step 9 — Upload to App Store Connect, TestFlight, Review
She archives with an **App Store** distribution profile (no device list) and uploads to **App Store Connect**. Apple processes the build. External testers install via **TestFlight**. After **App Review**, Apple **re-signs** the app with its own key and publishes it.

### Step 10 — CI breaks  *(failure #2)*
Mia moves builds to a CI Mac. The first run fails with `errSecInternalComponent` / *"No signing certificate 'iOS Distribution' found"*: the CI machine has the profile but **not the private key**. She fixes it by importing a `.p12` into a temporary unlocked keychain (or by switching to **cloud-managed certificates** with an **App Store Connect API key**).

### Step 11 — A year later
Her distribution cert expires. The App Store version keeps working, because Apple re-signed it. Leo's Ad Hoc build stops launching, because its profile has expired.

## Which deep dive covers which steps

| Deep dive | PawPal steps |
|---|---|
| 5.1 Developer Account & Team | 1, 10 (roles, API keys) |
| 5.2 Signing Certificates | 2, 8, 10, 11 |
| 5.3 App IDs & Entitlements | 3, 6, 7 |
| 5.4 Devices | 4, 8 |
| 5.5 Provisioning Profiles | 5, 8, 9, 11 |
| 5.6 codesign | 6 |
| 5.7 On-device verification | 7, 8, 11 |
| 5.8 Distribution & re-signing | 8, 9, 11 |

---
← [03 — Concept map](03-concept-map.md) · Next → [5.1 — Developer Account & Team](05-deep-dives/01-developer-account-and-team.md)
