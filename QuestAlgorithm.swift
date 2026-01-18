import Foundation

/// A compact, testable QUEST-like Bayesian adaptive algorithm.
/// This implementation uses a discretized posterior over threshold (logMAR)
/// and a logistic psychometric function. It's intentionally simple and
/// designed to be a pluggable `AdaptiveAlgorithm` for the engine.
final class QuestAlgorithm: AdaptiveAlgorithm {

    // Discretized threshold grid (logMAR)
    private let grid: [Double]
    private var posterior: [Double]

    // Psychometric params
    private let gamma: Double = 0.25  // chance level (4AFC)
    private let lapse: Double = 0.02  // lapse rate
    private let slope: Double = 3.0   // psychometric slope (per logMAR)

    // Prior spread in logMAR
    private let priorSD: Double = 0.3

    init(minLogMAR: Double = -0.2, maxLogMAR: Double = 1.2, step: Double = 0.01) {
        var g: [Double] = []
        var x = minLogMAR
        while x <= maxLogMAR + 1e-9 {
            g.append(x)
            x += step
        }
        grid = g
        posterior = Array(repeating: 1.0 / Double(grid.count), count: grid.count)
    }

    func start(session: VisionTestSession) {
        // initialize prior as a normal centered at the session's starting logMAR
        let mean = session.currentLogMAR
        posterior = grid.map { x in
            exp(-0.5 * pow((x - mean) / priorSD, 2.0))
        }
        normalizePosterior()
    }

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        // The stimulus size presented is assumed to be session.currentLogMAR
        let x = session.currentLogMAR

        // Compute likelihood for each candidate threshold in grid
        var newPosterior = [Double](repeating: 0.0, count: grid.count)
        for (i, t) in grid.enumerated() {
            // logistic psychometric: p = gamma + (1 - gamma - lapse) * S(x; t, slope)
            let S = 1.0 / (1.0 + exp(-slope * (x - t)))
            let p = gamma + (1.0 - gamma - lapse) * S
            let likelihood = correct ? p : (1.0 - p)
            newPosterior[i] = posterior[i] * likelihood
        }

        posterior = newPosterior
        if posterior.reduce(0.0, +) <= 0.0 {
            // Numerical underflow or degenerate likelihoods: reset to uniform
            posterior = Array(repeating: 1.0 / Double(grid.count), count: grid.count)
        } else {
            normalizePosterior()
        }

        // Update session bookkeeping similar to staircase's counts
        if correct { session.correctInPhase += 1 }
        session.responses.append((correct: correct, rtMs: rtMs))
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1

        // Update confidence as a simple proxy from posterior sharpness
        let peak = posterior.max() ?? 0.0
        session.confidence = max(0.0, min(1.0, peak * 1.2))

        // Choose next stimulus: posterior mean
        let meanEstimate = zip(grid, posterior).map(*).reduce(0.0, +)
        session.currentLogMAR = max(grid.first ?? -0.2, min(grid.last ?? 1.2, meanEstimate))
    }

    func nextSize(session: VisionTestSession) -> Double {
        return session.currentLogMAR
    }

    // MARK: - Diagnostic Confidence (posterior entropy)

    func diagnosticConfidence(session: VisionTestSession) -> Double {
        // Compute Shannon entropy of the posterior and normalize to [0,1]
        // Higher diagnosticConfidence => lower entropy (more confident)
        let eps = 1e-12
        let p = posterior.map { max($0, eps) }
        let entropy = -p.reduce(0.0) { $0 + $1 * log($1) }
        let maxEntropy = log(Double(p.count))
        guard maxEntropy > 0 else { return 0.0 }
        let normalized = 1.0 - (entropy / maxEntropy) // 0..1
        return max(0.0, min(1.0, normalized))
    }

    // MARK: - Helpers

    private func normalizePosterior() {
        let s = posterior.reduce(0.0, +)
        guard s > 0 else { return }
        for i in 0..<posterior.count { posterior[i] /= s }
    }
}
