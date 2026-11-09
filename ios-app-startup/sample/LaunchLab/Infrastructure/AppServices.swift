//  AppServices.swift
//  LaunchLab
//
//  Stand-in for the process-wide setup a real app does in
//  didFinishLaunchingWithOptions (analytics, crash reporting, DI container...).

import UIKit

enum AppServices {
    static func configure() {
        // Global appearance is process-wide, so it belongs at app level.
        UIView.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .systemIndigo
        LaunchLog.shared.record(.app, "AppServices.configure() done")
    }
}
