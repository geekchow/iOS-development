# LaunchLab: the sample app

A small UIKit app, built entirely in code with no storyboards, that **records every startup and lifecycle callback** and shows them in a timeline. It's the running example for the [iOS App Startup series](../00-overview.md).

## What it shows

| Screen | What you learn |
|---|---|
| **Onboarding** (first launch only) | Choosing the root view controller at launch, and swapping it afterwards |
| **Timeline** tab | The exact order of `main` → AppDelegate → SceneDelegate → window → view controller callbacks, in ms since the process started |
| **Lifecycle Lab** tab | Which callbacks fire for push, sheet, full-screen, and root replacement |
| `launchlab://lab` URL | Cold vs warm deep links (`connectionOptions.urlContexts` vs `scene(_:openURLContexts:)`) |

## Files

```
LaunchLab/
├── Info.plist                         # scene manifest, launch screen, URL scheme
├── App/
│   ├── main.swift                     # explicit entry point → UIApplicationMain
│   ├── AppDelegate.swift              # process-level lifecycle
│   └── SceneDelegate.swift            # window + root VC, scene lifecycle
├── Infrastructure/
│   ├── LaunchLog.swift                # timestamped event recorder
│   ├── AppServices.swift              # stand-in for app-wide setup
│   ├── RootRouter.swift               # builds and swaps root view controllers
│   └── DeepLinkHandler.swift          # launchlab:// handling
└── Controllers/
    ├── LoggingViewController.swift    # base class that logs VC lifecycle
    ├── OnboardingViewController.swift
    ├── TimelineViewController.swift
    └── LifecycleLabViewController.swift (+ DetailViewController)
```

## Run it

**Option A, with XcodeGen** (generates the project from `project.yml`):

```bash
brew install xcodegen
```

```bash
cd ios-app-startup/sample && xcodegen generate && open LaunchLab.xcodeproj
```

**Option B, by hand in Xcode:**
1. File → New → Project → iOS **App**, Interface **Storyboard**, Language **Swift**, name it `LaunchLab`.
2. Delete `Main.storyboard`, `AppDelegate.swift`, `SceneDelegate.swift`, and `ViewController.swift` from the template.
3. Drag in the `App/`, `Infrastructure/`, and `Controllers/` folders.
4. Replace the target's Info.plist with this one, or in the target's Info tab remove *Main storyboard file base name* and, under *Application Scene Manifest*, remove *Storyboard Name* and set *Delegate Class Name* to `$(PRODUCT_MODULE_NAME).SceneDelegate`. Add the `launchlab` URL type.
5. Build settings: set **Generate Info.plist File** to *No* if you use this Info.plist file.

Then run on a simulator and try:

```bash
xcrun simctl openurl booted launchlab://lab
```

Do it once with the app running (warm link) and once after killing it (cold link), then compare the Timeline.

> I wrote this code without a Mac to build it on, so it hasn't been compiled. It targets iOS 16+ and Xcode 15+. If something doesn't compile, the fix should be small.
