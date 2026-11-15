# 7 — Pitfalls and Next Steps

> **Where you are:** the end of the series.
> **What you'll know after this file:** the mistakes this structure most often produces, how the layout varies between projects, and what to explore next.

## A lookup table: "where does this go?"

| I want to add… | Put it in | Then remember to |
|---|---|---|
| A new screen | `Views/<Feature>/` | Reach it from `ContentView` or an existing view |
| State and logic for that screen | `ViewModels/` | Mark it `@Observable` and `@MainActor` |
| A new kind of stored data | `Models/` | Add the type to the schema in `App/AIPowerDictApp.swift` |
| A call to a new backend endpoint or system framework | `Services/` | Keep `import` of any SDK (Software Development Kit) inside the service |
| A helper on `String` or `Date` | `Extensions/` | Keep it stateless |
| An image or a named colour | `Assets.xcassets` | Provide dark-mode and scale variants |
| A piece of UI (User Interface) text | every `Resources/*.lproj/Localizable.strings` | Add the key to all languages |
| A permission (camera, location, …) | `Info.plist` usage description | Translate it in `InfoPlist.strings` |
| A capability (iCloud, push, App Groups) | *Signing & Capabilities* tab → `.entitlements` | Check the provisioning profile includes it |
| A third-party library | *File › Add Package Dependencies* | Link the product to the target; commit `Package.resolved` |
| A widget or share extension | A **new target** | Give it its own `Info.plist` and entitlements |

## Common pitfalls

1. **File on disk, not in the target.** The most frequent cause of "cannot find in scope" and of resources that are `nil` at run time. Check target membership first.
2. **Treating the bundle as private.** Every file in `Resources/` ships readable. Keys and secrets placed in a plist can be extracted from the IPA (iOS App Store Package). Keep real secrets on the server and treat client-side values as identifiers, not as protection.
3. **Shipping test-only files.** A generator that copies "everything that is not Swift" will also ship files such as a `.storekit` test configuration. Harmless, but worth excluding.
4. **Folders mistaken for walls.** Nothing stops a View from calling `AIService` directly. If the layering matters to you, enforce it in review, or move layers into local Swift packages where `import` and `public` make the boundary real.
5. **Massive view model.** Moving all logic out of views can turn one view model into the new dumping ground. Split by feature, and push reusable rules down into services.
6. **Hand-editing generated files.** If the project is generated (XcodeGen, Tuist), changes made in Xcode's UI vanish at the next generation. Edit the generator's input.
7. **Changing persistent models casually.** Renaming or retyping a stored property can make existing users' data unreadable. Plan migrations.
8. **Debug and Release drifting apart.** Settings and `#if DEBUG` branches differ by configuration. Test a Release build before shipping.

## How other projects vary

The system-contract rows of the [four-kinds table](02-what.md) are the same everywhere. The team-convention rows vary:

| Variation | Looks like | When teams choose it |
|---|---|---|
| **Layer-first** (this project) | `Models/`, `Views/`, `ViewModels/`, `Services/` | Small to medium apps; easy to learn |
| **Feature-first** | `Features/Lookup/{View,ViewModel,Model}`, `Features/Review/…`, `Core/` | Larger apps; one feature's files stay together |
| **Modular** | Several local Swift packages or framework targets | Big teams; faster incremental builds; enforced boundaries |
| **UIKit classic** | `AppDelegate.swift`, `SceneDelegate.swift`, `Controllers/`, `Main.storyboard` | Older or UIKit-based apps |
| **More targets** | `…Tests` (unit), `…Widget`, `…Watch App`, `…NotificationService` | As the product grows beyond one app |

Other entries you will meet: `Preview Content/` (assets used only by SwiftUI previews, stripped from release builds), `.xcconfig` files (build settings as text), `Localizable.xcstrings` (the newer single-file string catalog), `Frameworks/` group (linked system libraries), `.xcworkspace` (several projects together), `Podfile` (CocoaPods).

## Exercises

1. In Xcode, select `LookupView.swift`, open the File inspector and find its target membership. Untick it, build, read the error, tick it again.
2. Build, then right-click `AIPowerDict.app` under Products › *Show in Finder* › *Show Package Contents*. Match each file to a row of the table in [5.8](05-deep-dives/08-products-and-tests.md).
3. Run `plutil -p` on the built `Info.plist` and find a value that was a `$(…)` placeholder in the source.
4. Run `codesign -d --entitlements - AIPowerDict.app` and compare with the `.entitlements` file.
5. Add a key to only one `Localizable.strings`, use it in a view, and switch the simulator's language to see the fallback behaviour.
6. Open the Report navigator after a build and find the `CompileAssetCatalog`, `SwiftCompile`, `Ld` and `CodeSign` steps. Map them to B3–B6.

## Where to go next

- **What happens between launching the bundle and the first frame:** the [iOS app startup series](../ios-app-startup/00-overview.md).
- **How B6 really works, and what a provisioning profile is:** the [Apple code signing series](../apple-code-signing-guide/00-overview.md).
- **Apple documentation:** "Bundle Programming Guide" (bundle layout), "Information Property List" (every `Info.plist` key), "Entitlements" (every entitlement key), "Configuring the build settings of a target", "Privacy manifest files".
- **Tools:** XcodeGen and Tuist (project generation), `xcodebuild -showBuildSettings` (print every resolved setting for a target).

---
Back to [overview](00-overview.md) · [concept map](03-concept-map.md)
