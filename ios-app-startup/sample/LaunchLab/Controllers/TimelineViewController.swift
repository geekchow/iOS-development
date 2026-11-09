//  TimelineViewController.swift
//  LaunchLab
//
//  Lists every recorded lifecycle event with its time since process start.

import UIKit

final class TimelineViewController: LoggingViewController, UITableViewDataSource {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var events: [LaunchEvent] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Launch Timeline"

        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            primaryAction: UIAction { _ in LaunchLog.shared.clear() }
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(reload), name: LaunchLog.didChange, object: nil
        )
        reload()
    }

    @objc private func reload() {
        events = LaunchLog.shared.events
        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let first = events.first else { return "No events yet" }
        return String(format: "First event at +%.0f ms after process start", first.millisecondsSinceProcessStart)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let event = events[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = event.message
        content.secondaryText = String(format: "%@ · +%.1f ms", event.layer.rawValue, event.millisecondsSinceProcessStart)
        content.textProperties.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        content.secondaryTextProperties.color = color(for: event.layer)
        cell.contentConfiguration = content
        return cell
    }

    private func color(for layer: LaunchLayer) -> UIColor {
        switch layer {
        case .process:        return .systemGray
        case .app:            return .systemBlue
        case .scene:          return .systemPurple
        case .window:         return .systemOrange
        case .viewController: return .systemGreen
        }
    }
}
