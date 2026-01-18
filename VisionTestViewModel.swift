import Foundation
import Combine
import os.log

private let log = Logger(subsystem: "com.yourcompany.eyevo", category: "Flow")

@MainActor
final class VisionTestViewModel: ObservableObject {

    // MARK: - Published State (Observed by UI)

    /// UI-facing lifecycle phase (NOT the engine phase)
    @Published var phase: VisionTestPhase = .preparing

    /// Explicit publisher for SwiftUI (.onReceive)
    var phasePublisher: Published<VisionTestPhase>.Publisher {
        $phase
    }

    /// The current stimulus to render (engine-driven)
    @Published var currentStimulus: Stimulus?

    /// ✅ SINGLE SOURCE OF TRUTH FOR UI SIZE RENDERING
    /// SwiftUI reads ONLY from this (not from session or engine)
    @Published var currentLogMAR: Double = 0.4

    // MARK: - Engine & Session

    let engine: VisionTestEngine
    private var session: VisionTestSession

    // MARK: - Init

    init(engine: VisionTestEngine) {
        self.engine = engine
        self.session = VisionTestSession()

        trace("VM init: \(ObjectIdentifier(self).hashValue)")
        trace("Engine id: \(ObjectIdentifier(engine).hashValue)")

        self.phase = .preparing
        self.currentStimulus = nil
    }

    convenience init() {
        self.init(engine: VisionTestEngine())
    }

    // New convenience initializer to inject an AdaptiveAlgorithm directly
    convenience init(algorithm: AdaptiveAlgorithm) {
        let engine = VisionTestEngine(algorithm: algorithm)
        self.init(engine: engine)
    }

    // MARK: - Flow Entry Points

    /// Called when user arrives at test screen / taps Start
    func beginTest() {
        session = engine.startSession()
        trace("BEGIN TEST → engine phase = \(session.phase)")

        currentStimulus = nil
        updateUIPhase(from: session.phase)
    }

    /// Advances stimulus flow (called after beginTest and after each response)
    func getNextStimulus() {
        trace("GET NEXT STIMULUS → before = \(session.phase)")

        if session.phase == .completed {
            updateUIPhase(from: session.phase)
            return
        }

        let stimulus = engine.nextStimulus(session: session)

        // ✅ publish together (FIX)
        currentStimulus = stimulus
        currentLogMAR = stimulus.sizeLogMAR

        // Gatekeeper is interactive but UI stays in preparing
        if session.phase == .gatekeeper {
            phase = .preparing
        } else {
            updateUIPhase(from: session.phase)
        }
    }

    /// Submit a response for the current stimulus
    func submitResponse(_ direction: ResponseDirection) {
        guard let stimulus = currentStimulus else { return }

        let correct = (direction == stimulus.expectedAnswer)

        engine.submitResponse(
            session: session,
            direction: direction,
            phase: stimulus.phase,   // engine-level phase
            correct: correct,
            rtMs: 0
        )

        // Clear stimulus; UI will request next
        currentStimulus = nil
        updateUIPhase(from: session.phase)
    }

    /// Produce final outcome once session is completed
    func finalizeSession() -> TestOutcome {
        engine.finalizeSession(session: session)
    }

    // MARK: - UI Phase Mapping

    /// Converts engine/internal phase to UI phase
    private func updateUIPhase(from testPhase: TestPhase) {
        switch testPhase {
        case .gatekeeper:
            phase = .preparing
        case .tumblingE, .sloan10:
            phase = .running
        case .completed:
            phase = .completed
        }
    }

    // MARK: - Logging

    private func trace(_ msg: String) {
        log.info("\(msg, privacy: .public)")
    }
}
