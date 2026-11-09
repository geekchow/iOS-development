//  OnboardingViewController.swift
//  LaunchLab
//
//  Shown as the window's root on first launch. Tapping "Get started" swaps
//  the root to the main tab bar interface.

import UIKit

final class OnboardingViewController: LoggingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let icon = UIImageView(image: UIImage(systemName: "bolt.horizontal.circle.fill"))
        icon.tintColor = .systemIndigo
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let title = UILabel()
        title.text = "Welcome to LaunchLab"
        title.font = .preferredFont(forTextStyle: .largeTitle)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center

        let body = UILabel()
        body.text = "This app records every startup and lifecycle callback so you can see the order in which iOS calls your code."
        body.font = .preferredFont(forTextStyle: .body)
        body.adjustsFontForContentSizeCategory = true
        body.textColor = .secondaryLabel
        body.numberOfLines = 0
        body.textAlignment = .center

        var config = UIButton.Configuration.filled()
        config.title = "Get started"
        config.cornerStyle = .large
        config.buttonSize = .large
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let window = self?.view.window else { return }
            RootRouter.finishOnboarding(in: window)
        })

        let stack = UIStackView(arrangedSubviews: [icon, title, body, button])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }
}
