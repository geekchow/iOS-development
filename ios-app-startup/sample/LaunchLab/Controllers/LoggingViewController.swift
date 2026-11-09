//  LoggingViewController.swift
//  LaunchLab
//
//  Base class that records every view-controller lifecycle callback.
//  Subclass it to watch a screen's lifecycle in the Timeline tab.

import UIKit

class LoggingViewController: UIViewController {

    private var name: String { String(describing: type(of: self)) }
    private var hasLoggedFirstLayout = false

    private func log(_ callback: String) {
        LaunchLog.shared.record(.viewController, "\(name).\(callback)")
    }

    // loadView: creates self.view. Only override it if you build the view
    // yourself instead of calling super; we just log and call super.
    override func loadView() {
        log("loadView")
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log("viewDidLoad")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log("viewWillAppear")
    }

    // iOS 17 API, back-deployed to iOS 13 when built with Xcode 15+.
    // Traits and geometry are final here: the best place for appearance-time layout work.
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        log("viewIsAppearing")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Layout runs MANY times; log only the first pass to keep the timeline readable.
        if !hasLoggedFirstLayout {
            hasLoggedFirstLayout = true
            log("viewDidLayoutSubviews (first)")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        log("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        log("viewDidDisappear")
    }
}
