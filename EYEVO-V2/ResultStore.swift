import Foundation

final class ResultStore {

    static let shared = ResultStore()

    private let storageKey = "vision_result_records"

    private init() {}

    // MARK: - Load All

    func loadAll() -> [VisionResultRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            let records = try JSONDecoder().decode([VisionResultRecord].self, from: data)
            return records.sorted { $0.startTime > $1.startTime }
        } catch {
            print("[ResultStore] Failed to load records:", error)
            return []
        }
    }

    // MARK: - Save One Record

    func save(_ record: VisionResultRecord) {
        var records = loadAll()
        records.insert(record, at: 0)
        saveAll(records)
    }

    // MARK: - Save All

    func saveAll(_ records: [VisionResultRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("[ResultStore] Failed to save records:", error)
        }
    }

    // MARK: - Replace All (Useful for Future Migration)

    func replaceAll(with records: [VisionResultRecord]) {
        saveAll(records)
    }

    // MARK: - Clear All (Debug / Admin Use Only)

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Export CSV

    func exportCSV() -> String {
        let records = loadAll()

        let csvFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = .current
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()

        let header = [
            "Test ID",
            "Eyevo ID",
            "Start Time",
            "End Time",
            "Duration (sec)",
            "Left logMAR",
            "Right logMAR",
            "Left Passed",
            "Right Passed",
            "Confidence",
            "Result",
            "Not Sure Count",
            "Total Responses",
            "Reliability"
        ].joined(separator: ",")

        let rows = records.map { record in
            let testID = csvSafe(record.id.uuidString)
            let eyevoID = csvSafe(record.eyevoID)
            let startTime = csvSafe(csvFormatter.string(from: record.startTime))

            let endTimeString = record.endTime.map { csvFormatter.string(from: $0) } ?? ""
            let endTime = csvSafe(endTimeString)

            let durationSeconds = record.duration.map { Int($0) } ?? 0
            let duration = csvSafe("\(durationSeconds)")

            let leftLogMAR = csvSafe(
                record.leftEyeLogMAR.map { String(format: "%.2f", $0) } ?? ""
            )

            let rightLogMAR = csvSafe(
                record.rightEyeLogMAR.map { String(format: "%.2f", $0) } ?? ""
            )

            let leftPassed = csvSafe(
                record.leftEyePassed.map { $0 ? "PASS" : "REFER" } ?? ""
            )

            let rightPassed = csvSafe(
                record.rightEyePassed.map { $0 ? "PASS" : "REFER" } ?? ""
            )

            let confidence = csvSafe(String(format: "%.0f%%", record.confidence * 100))
            let result = csvSafe(record.overallPassed ? "PASS" : "REFER")

            let notSureCount = csvSafe("\(record.notSureCount)")
            let totalResponses = csvSafe("\(record.totalResponseCount)")
            let reliability = csvSafe(record.reliabilityLabel)

            return [
                testID,
                eyevoID,
                startTime,
                endTime,
                duration,
                leftLogMAR,
                rightLogMAR,
                leftPassed,
                rightPassed,
                confidence,
                result,
                notSureCount,
                totalResponses,
                reliability
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - CSV Safe Helper

    private func csvSafe(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
