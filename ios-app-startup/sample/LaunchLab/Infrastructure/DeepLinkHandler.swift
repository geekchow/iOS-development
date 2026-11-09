//  DeepLinkHandler.swift
//  LaunchLab
//
//  launchlab://timeline  → select the Timeline tab
//  launchlab://lab       → select the Lifecycle Lab tab
//
//  Try it in the Simulator:
//    xcrun simctl openurl booted launchlab://lab

import UIKit

@MainActor
enum DeepLinkHandler {
    static func handle(_ url: URL, in window: UIWindow) {
        guard url.scheme == "launchlab" else { return }

        // Deep links need the main interface; skip onboarding if necessary.
        if !(window.rootViewController is UITabBarController) {
            RootRouter.finishOnboarding(in: window)
        }
        guard let tabs = window.rootViewController as? UITabBarController else { return }

        switch url.host {
        case "timeline": tabs.selectedIndex = 0
        case "lab":      tabs.selectedIndex = 1
        default:         break
        }
    }
}
