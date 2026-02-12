//
//  Untitled.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/23/26.
//
import Foundation

/// 1-up / 2-down staircase with step-size decay.
/// Designed for screening (stable, fast, explainable).
final class StaircaseAlgorithm: AdaptiveAlgorithm {

    func start(session: VisionTestSession) {
        // Default “fast then precise” step schedule
        session.stepSize = 0.20
        session.consecutiveCorrect = 0
        session.lastDirection = 0
        session.reversalCount = 0
        session.reversalLogMARs.removeAll()
        // Keep currentLogMAR as engine/session sets it (e.g., 0.8)
    }

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        // NOTE: Engine already appends responses/counters in the clean engine I gave you.
        // But if your engine still appends, do NOT double-append here.
        // This algorithm assumes engine handles `responses` and per-phase counters.

        // 1) Update confidence (simple, screening-safe)
        if !correct {
            session.confidence = max(0.0, min(1.0, session.confidence - 0.05))
        }

        // 2) Determine whether we step, and direction
        var direction: Int? = nil  // -1 down (harder), +1 up (easier)

        if correct {
            session.consecutiveCorrect += 1
            if session.consecutiveCorrect >= 2 {
                direction = -1
                session.consecutiveCorrect = 0
            }
        } else {
            session.consecutiveCorrect = 0
            direction = +1
        }

        // If no step this trial, nothing else to do.
        guard let dir = direction else { return }

        // 3) Reversal detection (direction change)
        if session.lastDirection != 0, dir != session.lastDirection {
            session.reversalCount += 1
            // record the "turning point" estimate
            session.reversalLogMARs.append(session.currentLogMAR)
        }
        session.lastDirection = dir

        // 4) Step-size decay (by reversal count)
        // Fast early, precise near threshold.
        if session.reversalCount >= 4 {
            session.stepSize = 0.05
        } else if session.reversalCount >= 2 {
            session.stepSize = 0.10
        } else {
            session.stepSize = 0.20
        }

        // 5) Apply step
        session.currentLogMAR += Double(dir) * session.stepSize
        session.currentLogMAR = max(-0.2, min(1.2, session.currentLogMAR))
    }

    /// Optional: provide a diagnostic confidence signal (0..1).
    /// Keep it simple: more reversals + more trials => higher stability.
    func diagnosticConfidence(session: VisionTestSession) -> Double {
        let t = Double(session.totalTrials)
        let r = Double(session.reversalCount)

        // Saturating stability curve (screening-friendly)
        let trialsScore = min(1.0, t / 20.0)
        let reversalScore = min(1.0, r / 6.0)

        return max(0.0, min(1.0, 0.5 * trialsScore + 0.5 * reversalScore))
    }
}

