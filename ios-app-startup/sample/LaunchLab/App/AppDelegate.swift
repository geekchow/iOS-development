//  AppDelegate.swift
//  LaunchLab
//
//  Process-level lifecycle: one AppDelegate per process.
//  It does NOT own a window or any UI. Scenes do (see SceneDelegate).
//
//  Note: no `@main` here, because main.swift is the entry point.

import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Launch

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LaunchLog.shared.record(.app, "willFinishLaunchingWithOptions")
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LaunchLog.shared.record(.app, "didFinishLaunchingWithOptions")

        // One-time, process-wide setup belongs here: crash reporting, logging,
        // dependency containers, global appearance. Keep it FAST: everything
        // in this method delays the first frame the user sees.
        AppServices.configure()

        return true
    }

    // MARK: Scene sessions

    /// Called when the system needs a configuration for a NEW scene session.
    /// Not called when an existing session is reconnected.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        LaunchLog.shared.record(.app, "configurationForConnecting (role: \(connectingSceneSession.role.rawValue))")

        // The name must match an entry under UIApplicationSceneManifest →
        // UISceneConfigurations in Info.plist. That entry names SceneDelegate.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user closes scenes (e.g. swipes a window away in the
    /// iPad app switcher). Often delivered on the NEXT launch.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        LaunchLog.shared.record(.app, "didDiscardSceneSessions (\(sceneSessions.count))")
    }
}
