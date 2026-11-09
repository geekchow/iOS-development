//  main.swift
//  LaunchLab
//
//  Most apps put `@main` on their AppDelegate and let Swift generate this
//  function. LaunchLab writes it out by hand so you can see the real entry
//  point: the process starts here, after dyld has loaded every library.

import UIKit

LaunchLog.shared.record(.process, "main() entered")

// UIApplicationMain never returns. It:
//   1. creates the UIApplication singleton (class name = 3rd argument, nil means UIApplication),
//   2. creates the app delegate from the class name in the 4th argument,
//   3. reads Info.plist (scene manifest, launch screen, URL types...),
//   4. starts the main run loop and begins delivering lifecycle callbacks.
_ = UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
