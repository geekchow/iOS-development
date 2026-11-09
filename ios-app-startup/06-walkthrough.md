# Part 6 — Full Walkthrough: One LaunchLab Launch, End to End

> **Where you are:** Stage 6. The running example replayed at full depth, stitched together from all five deep dives.
> **What you'll know after this file:** every hop from tap to first frame and beyond, with the code that runs and the Timeline row it produces.

## The annotated sequence

*Sam's first launch, root swap, background round-trip, and deep links, with every participant.*

```mermaid
sequenceDiagram
  autonumber
  participant Sys as System / dyld
  participant M as main.swift
  participant UIApp as UIApplication
  participant AD as AppDelegate
  participant SD as SceneDelegate
  participant W as UIWindow
  participant VC as View controllers

  Sys->>Sys: Launch screen, spawn, load dylibs, static inits
  Sys->>M: main()  [Process · main() entered]
  M->>UIApp: UIApplicationMain(…, "AppDelegate")
  UIApp->>AD: willFinishLaunching / didFinishLaunching  [App rows]
  AD->>AD: AppServices.configure()
  UIApp->>AD: configurationForConnecting → "Default Configuration"
  UIApp->>SD: init + willConnectTo  [Scene · willConnectTo]
  SD->>W: UIWindow(windowScene:)
  SD->>W: rootViewController = OnboardingVC
  W->>VC: Onboarding loadView, viewDidLoad
  SD->>W: makeKeyAndVisible  [Window rows]
  UIApp->>SD: sceneWillEnterForeground
  W->>VC: Onboarding viewWillAppear → viewIsAppearing → layout
  UIApp->>SD: sceneDidBecomeActive
  W->>VC: Onboarding viewDidAppear
  Sys-->>Sys: First frame. Launch done.
  VC->>W: "Get started" → root = UITabBarController
  W->>VC: Onboarding disappear; Timeline load + appear
  UIApp->>SD: resignActive → didEnterBackground → willEnterForeground → didBecomeActive
  UIApp->>SD: openURLContexts(launchlab://lab) → tab 1
```

## Step by step

### ① Tap → `main` (→ 5.1)
SpringBoard shows the launch screen from `UILaunchScreen`. The kernel spawns the process after checking the code signature, and dyld loads LaunchLab plus UIKit, Foundation, and `os`, applies fixups, and runs static initialisers. Then `main.swift` runs its first line:

```
Process · +142.7 ms   main() entered
```
That 142.7 ms is pure pre-`main` cost, measured from the kernel's process start time.

### ② UIKit takes over (→ 5.1, 5.2)
`UIApplicationMain` creates `UIApplication.shared` and an `AppDelegate`, reads Info.plist, and starts the main run loop. First delegate callbacks:

```
App · +165.2 ms   willFinishLaunchingWithOptions
App · +165.9 ms   didFinishLaunchingWithOptions
App · +166.8 ms   AppServices.configure() done
```
Process-wide setup only, and kept fast. No window here.

### ③ A scene is configured (→ 5.2, 5.3)
The system needs UI for a new session with role `UIWindowSceneSessionRoleApplication`:

```
App · +167.4 ms   configurationForConnecting (role: UIWindowSceneSessionRoleApplication)
```
LaunchLab returns `"Default Configuration"`. Info.plist maps it to `LaunchLab.SceneDelegate` with no storyboard, so UIKit instantiates `SceneDelegate` and a `UIWindowScene`.

### ④ The window and root are built (→ 5.3, 5.4, 5.5)
```
Scene  · +168.1 ms  willConnectTo (session: 3F2A9C1B…)
VC     · +168.9 ms  OnboardingViewController.loadView
VC     · +170.4 ms  OnboardingViewController.viewDidLoad
Window · +170.6 ms  rootViewController = OnboardingViewController
Window · +171.3 ms  makeKeyAndVisible
```
- `UIWindow(windowScene:)` ties the window to this scene.
- `RootRouter.makeInitialRoot()` checks `UserDefaults` and picks onboarding.
- Assigning the root loads its view (`loadView` → `viewDidLoad`, where onboarding builds its stack view).
- `self.window = window` retains it; `makeKeyAndVisible()` shows it and makes it key.
- `connectionOptions.urlContexts` is empty this time, so there's no deep link.

### ⑤ Foreground, appear, first frame (→ 5.3, 5.5)
```
Scene  · sceneWillEnterForeground
VC     · OnboardingViewController.viewWillAppear
VC     · OnboardingViewController.viewIsAppearing
VC     · OnboardingViewController.viewDidLayoutSubviews (first)
Scene  · sceneDidBecomeActive
VC     · OnboardingViewController.viewDidAppear
```
The render server draws the first frame and the launch screen is replaced. **This is the end of launch.** Everything from ① to here is what Xcode Organizer reports as launch time.

### ⑥ Root swap (→ 5.4, 5.5)
*Get started* → `RootRouter.finishOnboarding(in:)` stores the flag and cross-dissolves the window's root to a new `UITabBarController`:
```
Window · rootViewController → UITabBarController
VC     · OnboardingViewController.viewWillDisappear
VC     · TimelineViewController.loadView
VC     · TimelineViewController.viewDidLoad
VC     · TimelineViewController.viewWillAppear
…
VC     · OnboardingViewController.viewDidDisappear
VC     · TimelineViewController.viewDidAppear
```
Onboarding is released (nothing else references it). The Lab tab's VC hasn't loaded yet: tab contents load lazily.

### ⑦ Background and back (→ 5.3, 5.5)
```
Scene · sceneWillResignActive
Scene · sceneDidEnterBackground
Scene · sceneWillEnterForeground
Scene · sceneDidBecomeActive
```
No `App` rows (scene-based apps don't get app-level foreground callbacks) and no `VC` rows (foreground ≠ appearance).

### ⑧ Deep links (→ 5.3, 5.4)
- **Warm:** `Scene · openURLContexts: launchlab://lab`. `DeepLinkHandler` sees the tab bar root and sets `selectedIndex = 1`. The Lab VC now loads and appears for the first time.
- **Cold:** after force-quitting, ①–④ repeat and `Scene · cold-launch URL: launchlab://lab` appears right after `makeKeyAndVisible`. Because onboarding is done, the root is already the tab bar. If it weren't, the handler would swap the root first.

### ⑨ Lifecycle Lab (→ 5.5)
Push, sheet, and full-screen produce three different disappearance patterns. The sheet is the one where the presenter **stays**.

## Recap: the problem, solved

Part 1 asked for a design that gets from tap to first frame quickly, separates process concerns from window concerns, and lets each window live, die, and come back independently. LaunchLab's timeline shows each piece doing its part:

| Need | Who handled it in LaunchLab |
|---|---|
| Load code, start the event loop | System + dyld + `main` → `UIApplicationMain` |
| Once-per-process setup | `AppDelegate.didFinishLaunchingWithOptions` |
| Pick a UI configuration for a new window | `AppDelegate.configurationForConnecting` + Info.plist manifest |
| Build a window's UI, react to its foreground/background | `SceneDelegate` |
| One owner for everything on screen | `UIWindow.rootViewController`, swapped by `RootRouter` |
| Per-screen setup and visibility | View controller lifecycle |
| URLs arriving in either state | `connectionOptions` (cold) + `openURLContexts` (warm) → one handler |

---
← [5.5 — View Controller Lifecycle](05-deep-dives/05-view-controller-lifecycle.md) · Next → [07 — Pitfalls & next steps](07-next-steps.md) · [Concept map](03-concept-map.md)
