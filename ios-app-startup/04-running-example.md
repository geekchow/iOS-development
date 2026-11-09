# Part 4 — The Running Example: LaunchLab

> **Where you are:** Stage 4, the spine of the series.
> **What you'll know after this file:** the sample app, and one launch story traced shallowly. Every deep dive returns to these numbered steps.

## The app in three sentences

**LaunchLab** is a small UIKit app (in [`sample/`](sample/README.md)) that records every startup and lifecycle callback with a timestamp measured from process creation. On first launch it shows an **Onboarding** screen; tapping *Get started* swaps in the main UI, a **tab bar** with a *Timeline* of events and a *Lifecycle Lab* for experimenting with navigation. It also responds to the URL `launchlab://lab`.

## The story

**Sam** installs LaunchLab, opens it, gets through onboarding, switches to another app, comes back, and later taps a `launchlab://lab` link in Notes.

### Step 1: Tap → process
Sam taps the icon. The **system** shows the **launch screen** (from `UILaunchScreen` in Info.plist), creates a **process**, and **dyld** loads LaunchLab's binary and UIKit.

### Step 2: `main`
**`main()`** runs (LaunchLab writes it out in `main.swift`). It records `"main() entered"` and calls **`UIApplicationMain`**.

### Step 3: UIApplication + AppDelegate
`UIApplicationMain` creates the **`UIApplication`** singleton and the **AppDelegate**, reads Info.plist, starts the **run loop**, then calls `willFinishLaunchingWithOptions` and `didFinishLaunchingWithOptions`, where LaunchLab configures app-wide services.

### Step 4: A scene is requested
The system needs a UI, so it creates a **scene session** and asks the AppDelegate `configurationForConnecting`. LaunchLab returns `"Default Configuration"`, which Info.plist maps to `SceneDelegate`.

### Step 5: SceneDelegate builds the window
UIKit creates the **`UIWindowScene`** and the **SceneDelegate**, then calls `scene(_:willConnectTo:options:)`. LaunchLab creates a **`UIWindow`**, asks `RootRouter` for a **root view controller** (onboarding, since this is the first launch), and calls `makeKeyAndVisible()`.

### Step 6: The first view controller loads and appears
The window needs its root's view, so `OnboardingViewController` gets `loadView` → `viewDidLoad`. The scene moves to the foreground (`sceneWillEnterForeground`), the VC gets `viewWillAppear` → `viewIsAppearing` → layout, the scene becomes active (`sceneDidBecomeActive`), and the VC gets `viewDidAppear`. The **first frame** is drawn and the launch screen goes away. **Launch is complete.**

### Step 7: Root swap
Sam taps *Get started*. `RootRouter` replaces `window.rootViewController` with a `UITabBarController` that contains two `UINavigationController`s. Onboarding gets `viewWillDisappear`/`viewDidDisappear` and is released. The Timeline screen gets `viewDidLoad` and the appear callbacks.

### Step 8: Background and back
Sam swipes home: `sceneWillResignActive` → `sceneDidEnterBackground`. Sam comes back: `sceneWillEnterForeground` → `sceneDidBecomeActive`. **The Timeline VC's `viewWillAppear` does not fire**, because its place in the hierarchy never changed.

### Step 9: Deep link
- **Warm** (app in background): Sam taps `launchlab://lab`, and the scene gets `scene(_:openURLContexts:)`, which selects the *Lifecycle Lab* tab.
- **Cold** (Sam force-quit the app first): steps 1–5 run again, and this time the URL arrives inside `connectionOptions.urlContexts` in `willConnectTo`. `openURLContexts` is *not* called.

### Step 10: Lifecycle Lab
Sam pushes a detail screen, presents a sheet, and presents a full-screen modal. The Timeline shows that the **sheet** doesn't make the presenter disappear, but **full-screen** does.

## Which deep dive covers which steps

| Deep dive | Steps |
|---|---|
| 5.1 Process launch & `main` | 1, 2 |
| 5.2 UIApplication & AppDelegate | 3, 4 |
| 5.3 UIScene & SceneDelegate | 4, 5, 8, 9 |
| 5.4 UIWindow & root VC | 5, 7, 9 |
| 5.5 View controller lifecycle | 6, 7, 8, 10 |

The [interactive demo](demo/launch-sequence.html) animates steps 1–10 lane by lane.

---
← [03 — Concept map](03-concept-map.md) · Next → [5.1 — Process launch & main](05-deep-dives/01-process-launch-and-main.md)
