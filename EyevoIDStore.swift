//
//  TesterIDStore.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 3/4/26.
//

import Foundation

@MainActor
final class EyevoIDStore {

    static let shared = EyevoIDStore()

    private let key = "eyevo_device_id"

    private init() {}

    var eyevoID: String {

        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let newID = generateID()
        UserDefaults.standard.set(newID, forKey: key)

        print("Generated EyevoID:", newID)
        
        return newID
    }

    private func generateID() -> String {

        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomPart = String((0..<6).map { _ in characters.randomElement()! })

        return "EYEVO-\(randomPart)"
    }
}
