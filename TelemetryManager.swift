import Foundation

/// Very small telemetry recorder that persists simple event dictionaries to UserDefaults
/// and prints them to the console. Designed for local debug and later replacement with a
/// secure/opt-in upload mechanism.
final class TelemetryManager {
    static let shared = TelemetryManager()
    private let key = "EYEVO.telemetry.events"
    private let queue = DispatchQueue(label: "TelemetryManager.queue")

    private init() {}

    func record(event: String, metadata: [String: Any] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var dict: [String: Any] = ["event": event, "timestamp": timestamp]
        metadata.forEach { dict[$0] = $1 }

        // Store in UserDefaults as array of JSON-encoded strings
        queue.async {
            var existing = UserDefaults.standard.array(forKey: self.key) as? [String] ?? []
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
                let s = String(data: data, encoding: .utf8) ?? ""
                existing.append(s)
                UserDefaults.standard.set(existing, forKey: self.key)
            }

            // Also print for immediate debug visibility
            print("[Telemetry] \(dict)")
        }
    }

    func fetchEvents() -> [[String: Any]] {
        let arr = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return arr.compactMap { s in
            guard let data = s.data(using: .utf8) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
