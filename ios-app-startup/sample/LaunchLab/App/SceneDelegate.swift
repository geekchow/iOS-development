//  SceneDelegate.swift
//  LaunchLab
//
//  UI-level lifecycle: one SceneDelegate per scene (per window on iPad / Mac,
//  usually exactly one on iPhone). It owns the UIWindow and decides the root
//  view controller.

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// UIKit reads this property; keep a strong reference or the window disappears.
    var window: UIWindow?

    // MARK: Connect / disconnect

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        LaunchLog.shared.record(.scene, "willConnectTo (session: \(session.persistentIdentifier.prefix(8))…)")

        guard let windowScene = scene as? UIWindowScene else { return }

        // 1. Create a window attached to THIS scene.
        let window = UIWindow(windowScene: windowScene)

        // 2. Pick the root view controller (onboarding or main UI).
        window.rootViewController = RootRouter.makeInitialRoot()
        LaunchLog.shared.record(.window, "rootViewController = \(RootRouter.describe(window.rootViewController))")

        // 3. Keep it alive and put it on screen.
        self.window = window
        window.makeKeyAndVisible()
        LaunchLog.shared.record(.window, "makeKeyAndVisible")

        // 4. Cold-launch deep link: the URL arrives HERE, not in openURLContexts.
        if let url = connectionOptions.urlContexts.first?.url {
            LaunchLog.shared.record(.scene, "cold-launch URL: \(url.absoluteString)")
            DeepLinkHandler.handle(url, in: window)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // The scene was released (backgrounded and reclaimed, or closed).
        // The session may come back later via willConnectTo.
        LaunchLog.shared.record(.scene, "sceneDidDisconnect")
    }

    // MARK: Foreground / background

    func sceneWillEnterForeground(_ scene: UIScene) {
        LaunchLog.shared.record(.scene, "sceneWillEnterForeground")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        LaunchLog.shared.record(.scene, "sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        LaunchLog.shared.record(.scene, "sceneWillResignActive")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        LaunchLog.shared.record(.scene, "sceneDidEnterBackground")
    }

    // MARK: URLs while running

    /// Warm deep link: the app (scene) is already running.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, let window else { return }
        LaunchLog.shared.record(.scene, "openURLContexts: \(url.absoluteString)")
        DeepLinkHandler.handle(url, in: window)
    }
}
