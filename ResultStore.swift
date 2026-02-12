//
//  ResultStore.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 2/3/26.
//
import Foundation

final class ResultStore {
    
    static let shared = ResultStore()
    private let key = "eyevo.saved.results"
    
    private init() {}
    
    func save(_ record: VisionResultRecord) {
        var all = loadAll()
        all.insert(record, at: 0)
        
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func loadAll() -> [VisionResultRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let records = try? JSONDecoder().decode([VisionResultRecord].self, from: data)
        else {
            return []
        }
        return records
    }
    func exportCSV() -> String {
        let records = loadAll()
        
        var csv = "Date,EstimatedLogMAR,Confidence,Valid,Result\n"
        let formatter = ISO8601DateFormatter()
        
        for r in records {
            csv += "\(formatter.string(from: r.date)),"
            csv += "\(r.estimatedLogMAR ?? 0),"
            csv += "\(r.confidence ?? 0),"
            csv += "\(r.isValid),"
            csv += "\(r.passed ? "PASS" : "REFER")\n"
        }
        
        return csv
    }
}
