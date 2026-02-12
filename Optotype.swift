//
//  Optotype.swift.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/14/26.
//

// Optotype model (canonical definition moved here from VisionCoreModels.swift)

enum Optotype {
    case tumblingE

    var symbol: String {
        switch self {
        case .tumblingE:
            return "E"
        }
    }
}
