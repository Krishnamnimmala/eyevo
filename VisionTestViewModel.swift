
import SwiftUI
import Combine

let engine = VisionTestEngine()
var session = VisionTestSession()

final class VisionTestViewModel: ObservableObject {
    
    private let engine = VisionTestEngine()
    private var session = VisionTestSession()
    
    @Published var currentStimulus: Stimulus?
    @Published var phase: TestPhase = .tumblingE
    
    // MARK: - Lifecycle
    
    func beginTest() {
        session = engine.startSession()
    }
    
    // MARK: - Stimulus Flow
    
    struct Stimulus {
        let phase: TestPhase
        let optotype: Optotype
        let symbol: String
        let expectedAnswer: Direction   // ✅ CHANGE
        let sizeLogMAR: Double
    }

    
    // MARK: - Response Handling
    
    func submitResponse(_ direction: Direction) {
        guard let stim = currentStimulus else { return }

        let correct = (direction == stim.expectedAnswer)
        let rtMs = 0

        engine.submitResponse(
            session: session,
            direction: direction,
            phase: stim.phase,
            correct: correct,
            rtMs: rtMs
        )

        currentStimulus = nil
    }
        


// MARK: - Phase / Session Control
    func shouldStopPhase() -> Bool {
        engine.shouldStopPhase(session: session)
    }

    func finalizePhase() {
        engine.finalizePhase(session: session)
        engine.maybeSwitchToSloan(session: session)
    }

    func finalizeSession() -> TestOutcome {
        engine.finalizeSession(session: session)
    }

