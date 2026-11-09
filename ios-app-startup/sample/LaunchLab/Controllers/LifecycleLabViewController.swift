//  LifecycleLabViewController.swift
//  LaunchLab
//
//  Buttons that trigger view-controller transitions, so you can compare the
//  callbacks each one fires in the Timeline tab.

import UIKit

final class LifecycleLabViewController: LoggingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lifecycle Lab"
        view.backgroundColor = .systemGroupedBackground

        let buttons: [UIButton] = [
            makeButton("Push a child (navigation)") { [weak self] in
                self?.navigationController?.pushViewController(DetailViewController(style: "pushed"), animated: true)
            },
            makeButton("Present as sheet (.pageSheet)") { [weak self] in
                // Presenter stays in the hierarchy: NO viewWillDisappear on self.
                let nav = UINavigationController(rootViewController: DetailViewController(style: "sheet"))
                self?.present(nav, animated: true)
            },
            makeButton("Present full screen (.fullScreen)") { [weak self] in
                // Presenter is removed: viewWillDisappear / viewDidDisappear on self.
                let nav = UINavigationController(rootViewController: DetailViewController(style: "full screen"))
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true)
            },
            makeButton("Replace root with onboarding") { [weak self] in
                guard let window = self?.view.window else { return }
                RootRouter.resetOnboarding(in: window)
            },
        ]

        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    private func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.cornerStyle = .large
        config.buttonSize = .large
        return UIButton(configuration: config, primaryAction: UIAction { _ in action() })
    }
}

/// A simple screen whose lifecycle is logged; dismisses itself when presented.
final class DetailViewController: LoggingViewController {

    private let style: String

    init(style: String) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Detail (\(style))"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Go back or close, then check the Timeline tab."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])

        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
            )
        }
    }
}
