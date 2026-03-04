//
//  ResultStore.swift
//  EYEVO
//

import Foundation

final class ResultStore {
 
    static let shared = ResultStore()
    
    private let key = "vision_results"
    
    private init() {}
    
    // MARK: - Save
    
    func save(_ record: VisionResultRecord) {
        
        var records = loadAll()
        records.insert(record, at: 0)
        
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Load
    
    func loadAll() -> [VisionResultRecord] {
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([VisionResultRecord].self, from: data)
        else { return [] }
        
        return records
    }
    
    // MARK: - Clear All (for debugging / migration)
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - Export CSV
    
    func exportCSV() -> String {
        
        let records = loadAll()
        
        var csv = """
        Start Time,End Time,Duration (sec),Left logMAR,Right logMAR,Confidence,Result
        """
        
        csv += "\n"
        
        for record in records {
            
            let start = record.startTime.formatted(
                date: .abbreviated,
                time: .standard
            )
            
            let end = record.endTime?.formatted(
                date: .abbreviated,
                time: .standard
            ) ?? ""
            
            let duration = record.duration.map { String(format: "%.0f", $0) } ?? ""
            
            let leftLogMAR = record.leftEyeLogMAR.map {
                String(format: "%.2f", $0)
            } ?? ""
            
            let rightLogMAR = record.rightEyeLogMAR.map {
                String(format: "%.2f", $0)
            } ?? ""
            
            let confidence = String(format: "%.0f%%", record.confidence * 100)
            
            let result = record.overallPassed ? "PASS" : "REFER"
            
            csv += "\(start),\(end),\(duration),\(leftLogMAR),\(rightLogMAR),\(confidence),\(result)\n"
        }
        
        return csv
    }
}

