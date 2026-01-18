//
//  VisionCoreModels.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/15/26.
//

import Foundation

// MARK: - UI Phase (ViewModel & SwiftUI only)

enum VisionTestPhase: Equatable {
    case preparing
    case running
    case completed
}

enum Optotype {
    case tumblingE
    case sloanLetter
}

enum ResponseDirection: String, CaseIterable {
    case up, down, left, right
}


// MARK: - Engine Phase (Internal state machine)

enum TestPhase: Equatable {
    case gatekeeper
    case tumblingE
    case sloan10
    case completed
}

struct Stimulus {
    let phase: TestPhase
    let optotype: Optotype
    let symbol: String
    let expectedAnswer: ResponseDirection
    let sizeLogMAR: Double
}

struct TestOutcome {
    let estimatedLogMAR: Double?
    let confidence: Double?
    let isValid: Bool
    let passed: Bool
}
