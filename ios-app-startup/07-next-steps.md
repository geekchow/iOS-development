# Part 7 — Pitfalls, SwiftUI & Next Steps

> **Where you are:** the practical appendix.
> **What you'll know after this file:** the common startup mistakes, how SwiftUI's `App` maps onto what you've learned, how to measure launch time, and exercises with LaunchLab.

## 1. Where does this code go?

| I want to… | Put it in |
|---|---|
| Initialise crash reporting / analytics / DI | `AppDelegate.didFinishLaunchingWithOptions` |
| Register background tasks, set notification delegate | `AppDelegate.didFinishLaunchingWithOptions` |
| Create the window and first screen | `SceneDelegate.scene(_:willConnectTo:options:)` |
| Decide onboarding vs login vs main | A router called from `willConnectTo`; swap `window.rootViewController` later |
| Handle a URL / universal link / quick action | **Both** `connectionOptions` in `willConnectTo` **and** the warm callbacks |
| Pause media when interrupted | `sceneWillResignActive` |
| Save state / hide sensitive content | `sceneDidEnterBackground` |
| Refresh data when the user returns | `sceneWillEnterForeground` (or observe `UIScene.willEnterForegroundNotification` in the VC) |
| Build a screen's views | `viewDidLoad` |
| Refresh a screen when navigated back to | `viewWillAppear` |
| Geometry-dependent setup before first display | `viewIsAppearing` |
| Start animations / log screen views | `viewDidAppear` |

## 2. Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Old app-level callbacks after adopting scenes | `applicationDidBecomeActive` never called | Move to `sceneDidBecomeActive` |
| `var window` missing in SceneDelegate, or window not stored | Black screen | `self.window = window` |
| Cold deep links ignored | Link works only when the app is open | Read `connectionOptions` |
| Refreshing in `viewWillAppear` on return from background | Stale data | Scene foreground notification |
| Heavy synchronous work in `didFinishLaunching` / `viewDidLoad` | Long launch screen, watchdog kill | Defer, run off the main thread, load lazily |
| Presenting onboarding modally over main UI at launch | Flash of main UI; double loading | Choose the root in the router |
| Deleting session data in `sceneDidDisconnect` | User returns to an empty window | Delete in `didDiscardSceneSessions` |
| Storyboard in manifest + programmatic window | Unexpected UI / duplicate windows | Choose one |
| Too many dynamic frameworks / `+load` work | High pre-`main` time | Static linking / mergeable libraries; remove `+load` |

## 3. SwiftUI: same machinery, different surface

```swift
@main
struct LaunchLabApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate   // optional
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()                          // ≈ root view controller
                .onOpenURL { url in /* cold AND warm links */ }
        }
        .onChange(of: scenePhase) { _, phase in    // ≈ SceneDelegate foreground/background
            print(phase)                           // .active / .inactive / .background
        }
    }
}
```

| UIKit | SwiftUI |
|---|---|
| `@main` AppDelegate → `UIApplicationMain` | `@main struct …: App`, which still starts a `UIApplication` underneath |
| AppDelegate | `@UIApplicationDelegateAdaptor` (when you need process callbacks) |
| Scene manifest + SceneDelegate | `WindowGroup` (one per window); `scenePhase` for state |
| `window.rootViewController` | The `WindowGroup`'s root view, hosted by a `UIHostingController` |
| `connectionOptions` + `openURLContexts` | `.onOpenURL`, which handles both cases |
| `viewWillAppear` / `viewDidAppear` | `.onAppear` / `.task` (similar but not identical semantics) |

UIKit and SwiftUI mix: `UIHostingController(rootView:)` can be a root VC in LaunchLab, and `UIViewControllerRepresentable` brings UIKit into SwiftUI.

## 4. Measuring launch

- **Xcode Organizer → Launch Time:** real-world launch times from users' devices.
- **Instruments → App Launch template:** pre-`main` (dyld, static init), `UIApplicationMain`, scene setup, and first frame, each as a separate phase.
- **`XCTApplicationLaunchMetric`** in a UI test: catches launch-time regressions in CI.
- **MetricKit** (`MXAppLaunchMetric`): launch histograms in production.
- **LaunchLab's Timeline:** a quick sanity check of ordering and gaps.

Typical goals: first frame within ~400 ms on a recent device; keep pre-`main` small; do nothing in `didFinishLaunching` that the first screen doesn't need.

## 5. Exercises with LaunchLab

1. **Measure setup cost.** Add `Thread.sleep(forTimeInterval: 0.5)` in `AppServices.configure()` and watch every later timestamp shift. Then move it to `DispatchQueue.global().async`.
2. **Cold vs warm links.** Run `xcrun simctl openurl booted launchlab://lab` with the app running, then after killing it, and compare the timelines. Comment out the `connectionOptions` block and repeat.
3. **Sheet vs full screen.** In the Lab, compare which rows the presenter gets.
4. **Background ≠ disappear.** Go home and back, and note that no VC rows appear. Add a `UIScene.willEnterForegroundNotification` observer to `TimelineViewController` and log it.
5. **Multi-window (iPad simulator).** Open two LaunchLab windows. Note two `willConnectTo` rows with different session IDs but only one `didFinishLaunching`.
6. **Swap the root to SwiftUI.** Return `UIHostingController(rootView: Text("Hello"))` from `RootRouter.makeMainInterface()`.
7. **Use a storyboard instead.** Add `UISceneStoryboardFile` to the manifest and remove the window code. Where does the root come from now?

## 6. Further reading

- Apple: *Managing your app's life cycle*, *Responding to the launch of your app*, *Specifying the scenes your app supports*, *Supporting multiple windows on iPad*.
- Apple: *TN3187: Migrating to the UIKit scene-based life cycle*.
- Apple: *Reducing your app's launch time*.
- WWDC: *Introducing Multiple Windows on iPad* (2019), *Architecting Your App for Multiple Windows* (2019), *Optimizing App Launch* (2019), *What's new in UIKit* (2023, `viewIsAppearing`).
- UIKit docs: `UIViewController` "Managing the view" and "Responding to view-related events".

---
← [06 — Walkthrough](06-walkthrough.md) · [00 — Overview](00-overview.md) · [Concept map](03-concept-map.md)
