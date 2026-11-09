//  RootRouter.swift
//  LaunchLab
//
//  Decides WHICH view controller is the window's root, and swaps it.
//  The root view controller is the single entry point of everything the
//  user sees in a window.

import UIKit

@MainActor
enum RootRouter {

    private static let onboardingDoneKey = "hasCompletedOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingDoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingDoneKey) }
    }

    /// Called once per scene connection, from SceneDelegate.
    static func makeInitialRoot() -> UIViewController {
        hasCompletedOnboarding ? makeMainInterface() : makeOnboarding()
    }

    /// The main UI: a tab bar controller whose tabs are navigation controllers.
    ///
    ///   UITabBarController            ← window.rootViewController
    ///   ├─ UINavigationController
    ///   │   └─ TimelineViewController
    ///   └─ UINavigationController
    ///       └─ LifecycleLabViewController
    static func makeMainInterface() -> UITabBarController {
        let timeline = UINavigationController(rootViewController: TimelineViewController())
        timeline.tabBarItem = UITabBarItem(title: "Timeline", image: UIImage(systemName: "list.bullet.rectangle"), tag: 0)

        let lab = UINavigationController(rootViewController: LifecycleLabViewController())
        lab.tabBarItem = UITabBarItem(title: "Lifecycle Lab", image: UIImage(systemName: "flask"), tag: 1)

        let tabs = UITabBarController()
        tabs.viewControllers = [timeline, lab]
        return tabs
    }

    static func makeOnboarding() -> UIViewController {
        OnboardingViewController()
    }

    /// Replace the whole UI in a window, e.g. after onboarding or logout.
    /// The old root (and everything under it) is released.
    static func setRoot(_ newRoot: UIViewController, in window: UIWindow, animated: Bool = true) {
        LaunchLog.shared.record(.window, "rootViewController → \(describe(newRoot))")
        guard animated else {
            window.rootViewController = newRoot
            return
        }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = newRoot
        }
    }

    static func finishOnboarding(in window: UIWindow) {
        hasCompletedOnboarding = true
        setRoot(makeMainInterface(), in: window)
    }

    static func resetOnboarding(in window: UIWindow) {
        hasCompletedOnboarding = false
        setRoot(makeOnboarding(), in: window)
    }

    static func describe(_ vc: UIViewController?) -> String {
        guard let vc else { return "nil" }
        return String(describing: type(of: vc))
    }
}
