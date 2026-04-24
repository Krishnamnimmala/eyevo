//
//  Untitled.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/20/26.
//

// swift
import UIKit

class OptotypeViewController: UIViewController {
    private let optotypeView = OptotypeView() // assumes view exposes a `display(_:)` or `image` API
    private var refreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOptotypeView()
        scheduleRefreshTimer(interval: 1.0)
        generateAndDisplayOptotype()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    private func setupOptotypeView() {
        optotypeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optotypeView)
        NSLayoutConstraint.activate([
            optotypeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            optotypeView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            optotypeView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            optotypeView.heightAnchor.constraint(equalTo: optotypeView.widthAnchor)
        ])
    }

    private func scheduleRefreshTimer(interval: TimeInterval) {
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.generateAndDisplayOptotype()
        }
        RunLoop.main.add(t, forMode: .common)
        refreshTimer = t
    }

    private func generateAndDisplayOptotype() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            // Replace with the actual generator call from `Optotype.swift`
            let optotypeData = Optotype.generateNext() // adjust to your API

            DispatchQueue.main.async {
                // Update the view on main thread
                self.optotypeView.display(optotypeData) // adjust to your view API
                self.optotypeView.isHidden = false
                self.view.bringSubviewToFront(self.optotypeView)
                self.optotypeView.setNeedsDisplay()
                // Play sound feedback if needed
                AudioManager.shared.playSound(named: "click")
            }
        }
    }

    // Debug helper
    func dumpOptotypeViewState() {
        let v = optotypeView
        print("[OptotypeState] frame:\(v.frame) hidden:\(v.isHidden) alpha:\(v.alpha) window:\(String(describing: v.window))")
    }
}
