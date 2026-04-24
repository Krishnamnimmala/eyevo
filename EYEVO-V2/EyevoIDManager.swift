//
//  EyevoIDManager.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 3/21/26.
//

import Foundation

enum EyevoIDManager {
    private static let storageKey = "eyevo_persistent_id"

    static func getOrCreateID() -> String {
        if let existing = UserDefaults.standard.string(forKey: storageKey),
           !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return existing
        }

        let suffix = UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .prefix(6)
            .uppercased()

        let newID = "EYEVO-\(suffix)"
        UserDefaults.standard.set(newID, forKey: storageKey)
        return newID
    }
}
