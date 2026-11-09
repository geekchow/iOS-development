//  LaunchLog.swift
//  LaunchLab
//
//  A tiny thread-safe recorder of lifecycle events. Each event is stamped
//  with milliseconds since the PROCESS started (read from the kernel), so the
//  first event shows how long dyld + static initialisation took before main().

import Foundation
import os

enum LaunchLayer: String, CaseIterable {
    case process = "Process"
    case app = "App"
    case scene = "Scene"
    case window = "Window"
    case viewController = "VC"
}

struct LaunchEvent {
    let layer: LaunchLayer
    let message: String
    let millisecondsSinceProcessStart: Double
}

final class LaunchLog: @unchecked Sendable {

    static let shared = LaunchLog()

    /// Posted on the main queue whenever a new event is recorded.
    static let didChange = Notification.Name("LaunchLog.didChange")

    private let lock = NSLock()
    private var storage: [LaunchEvent] = []
    private let processStart: Date
    private let logger = Logger(subsystem: "com.example.launchlab", category: "lifecycle")

    private init() {
        processStart = LaunchLog.processStartDate() ?? Date()
    }

    var events: [LaunchEvent] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    func record(_ layer: LaunchLayer, _ message: String) {
        let ms = Date().timeIntervalSince(processStart) * 1000
        let event = LaunchEvent(layer: layer, message: message, millisecondsSinceProcessStart: ms)

        lock.lock()
        storage.append(event)
        lock.unlock()

        // Also visible in Xcode's console and in Console.app.
        logger.log("[\(layer.rawValue, privacy: .public)] +\(ms, format: .fixed(precision: 1))ms \(message, privacy: .public)")

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: LaunchLog.didChange, object: nil)
        }
    }

    func clear() {
        lock.lock(); storage.removeAll(); lock.unlock()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: LaunchLog.didChange, object: nil)
        }
    }

    /// Asks the kernel when this process was created (before dyld ran).
    private static func processStartDate() -> Date? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return nil }
        let start = info.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: TimeInterval(start.tv_sec) + TimeInterval(start.tv_usec) / 1_000_000)
    }
}
