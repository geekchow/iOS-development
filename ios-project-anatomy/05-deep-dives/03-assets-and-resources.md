# 5.3 — Assets and Resources

> **Where you are:** third deep dive. Everything in the bundle that is not code.
> **What you'll know after this file:** what goes in `Assets.xcassets` versus `Resources/`, how each is transformed at build time, and how code finds them at run time.

## Role recap

**Owns:** images, colours, translated text, runtime configuration and the privacy manifest. **Example steps:** B4, R2.

## Internal design

### Two containers, two treatments

| | `Assets.xcassets` | `Resources/` |
|---|---|---|
| What it is | An **asset catalog**: a folder format Apple defines | An ordinary folder; the name is a team choice |
| Build treatment | **Compiled** by `actool` into one binary file, `Assets.car` | **Copied** as they are |
| Holds | App icon, images, named colours, symbols | Strings files, plists, privacy manifest, anything else |
| Looked up by | Name: `Color("AccentBlue")`, `Image("logo")` | File name through `Bundle.main`, or localisation APIs |

### Inside the asset catalog

```
Assets.xcassets/
├── AppIcon.appiconset/     ← icon images + Contents.json
└── AccentBlue.colorset/    ← Contents.json with light and dark values
```

Each entry is a folder with a `Contents.json` that describes **variants**: the same name can resolve to different data for light or dark mode, for 2x or 3x screens, for iPhone or iPad. You ask for `AccentBlue`; the system picks the variant. This is the reason to prefer the catalog over loose image files.

The app icon is special: the build setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` tells `actool` which set is the icon, and it also emits loose `AppIcon60x60@2x.png` files and writes the icon keys into `Info.plist`.

### Inside Resources

```
Resources/
├── en.lproj/        Localizable.strings   InfoPlist.strings
├── zh-Hans.lproj/   Localizable.strings   InfoPlist.strings
├── zh-Hant.lproj/   Localizable.strings
├── config.plist
├── PrivacyInfo.xcprivacy
└── StoreKit.storekit
```

| File | Purpose | Who reads it |
|---|---|---|
| `*.lproj/Localizable.strings` | UI text per language: `"tab.lookup" = "查词";` | Your code, by key |
| `*.lproj/InfoPlist.strings` | Translations of `Info.plist` values, such as the app name and permission sentences | iOS |
| `config.plist` | Runtime settings: backend URL, analytics ID, feature switches | Your code, through `Services/Config.swift` |
| `PrivacyInfo.xcprivacy` | **Privacy manifest**: declares collected data and the reasons for using certain APIs | The App Store, during review |
| `StoreKit.storekit` | Local definitions of in-app purchase products for testing | Xcode's scheme (see [5.1](01-project-targets-and-schemes.md)) |

An `.lproj` folder ("language project") is the system's convention for localisation: one folder per language, same file names inside. At run time the system picks the folder that best matches the user's language settings.

### How code finds a resource

```swift
// Services/Config.swift — a file copied into the bundle, read by name
if let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
   let dict = NSDictionary(contentsOf: url) { … }
```

`Bundle.main` is the running app's bundle folder. Lookups are by **name, not by project path**: the `Resources/` folder does not exist inside the `.app`. Compare source and product:

| In the navigator | In `AIPowerDict.app` |
|---|---|
| `Assets.xcassets/` | `Assets.car`, `AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png` |
| `Resources/en.lproj/Localizable.strings` | `en.lproj/Localizable.strings` |
| `Resources/config.plist` | `config.plist` |
| `Resources/PrivacyInfo.xcprivacy` | `PrivacyInfo.xcprivacy` |

The bundle is **flat** apart from `.lproj` folders. Two resources with the same file name in different source folders collide.

## Interactions

- **← Project (5.1):** membership in Copy Bundle Resources decides whether a file ships.
- **→ Info.plist (5.2):** `InfoPlist.strings` overrides plist values per language; `actool` adds icon keys.
- **→ Views and Services (5.5, 5.6):** they look resources up by name. The link is a string, so the compiler cannot check it.

## ⚓ Back to the example

**B4.** The build log shows a `CompileAssetCatalog` step producing `Assets.car`, and one `CopyStringsFile` or `CpResource` line per file in `Resources/`.

**R2.** `ContentView` defines each tab with a key:

```swift
// App/ContentView.swift
case .lookup: "tab.lookup"
```

and the strings files supply the text:

```
en.lproj/Localizable.strings        "tab.lookup" = "Lookup";
zh-Hans.lproj/Localizable.strings   "tab.lookup" = "查词";
zh-Hant.lproj/Localizable.strings   "tab.lookup" = "查詞";
```

AIPowerDict resolves the key through its own `LanguageManager` service (`lm.s("tab.lookup")`), which lets the user switch language inside the app instead of following the system setting. Projects without that need use SwiftUI's built-in lookup, `Text("tab.lookup")`.

**R5 (preview).** The backend address that `AIService` contacts for "serendipity" is read from `config.plist`.

## Failure behavior

| Symptom | Cause |
|---|---|
| The UI shows `tab.lookup` literally | Key missing from the strings file for that language, or the file is not in the target. |
| `Color("AccentBlu")` renders nothing, with a console warning | Typo in a name. Generated symbols (`Color(.accentBlue)`, Xcode 15 and later) turn this into a compile error. |
| A resource loads on your machine but not in a clean build | It was added on disk but not to Copy Bundle Resources. |
| Secrets extracted from a shipped app | **Anything in the bundle is readable by anyone who unzips the IPA (iOS App Store Package).** A plist is not a safe place for a secret; treat values there as public and enforce security on the server. |
| App Store rejects the upload over privacy reasons | `PrivacyInfo.xcprivacy` is missing a required-reason API declaration. |

---
Next → [5.4 — The App folder](04-app-entry-point.md) · Back to [concept map](../03-concept-map.md)
