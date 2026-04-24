import SwiftUI

#if DEBUG
struct TelemetryViewer: View {
    @State private var events: [[String: Any]] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(events.enumerated()), id: \.
                    0) { idx, evt in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(evt["event"] as? String ?? "event")
                            .font(.headline)
                        Text(jsonString(for: evt))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Telemetry Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        TelemetryManager.shared.clear()
                        load()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reload") { load() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        events = TelemetryManager.shared.fetchEvents()
    }

    private func jsonString(for dict: [String: Any]) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]) {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
}
#endif
