//
//  VisionResultRecord.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 2/3/26.
//

import Foundation

struct VisionResultRecord: Identifiable, Codable {

    let id: UUID
    let date: Date

    /// Final estimated acuity (if available)
    let estimatedLogMAR: Double?

    /// Confidence of the estimate (0–1)
    let confidence: Double?

    /// Whether the test met validity criteria
    let isValid: Bool

    /// PASS / REFER decision
    let passed: Bool
}
