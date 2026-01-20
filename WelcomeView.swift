import SwiftUI

struct WelcomeView: View {

    let onStart: (Bool) -> Void

    @AppStorage("useQuest") private var storedUseQuest: Bool = false
    @State private var showingInfo = false
    @State private var showingTelemetry = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to EYEVO")
                .font(.largeTitle)

            HStack {
                Toggle("Use QUEST algorithm (experimental)", isOn: $storedUseQuest)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                Button(action: { showingInfo = true }) {
                    Image(systemName: "info.circle")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About QUEST algorithm")
            }
            .padding(.horizontal)

            Button("Start Vision Test") {
                onStart(storedUseQuest)
            }
            .buttonStyle(.borderedProminent)

            #if DEBUG
            Button("View Debug Logs") {
                showingTelemetry = true
            }
            .buttonStyle(.bordered)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .sheet(isPresented: $showingInfo) {
            VStack(alignment: .leading, spacing: 16) {
                Text("About QUEST vs Staircase")
                    .font(.headline)
                Text("QUEST is a Bayesian adaptive algorithm that estimates a user's threshold more efficiently by maintaining a posterior over possible thresholds. Staircase is a simpler step-based method that is more conservative and robust in noisy settings.")
                Text("This app uses Staircase by default. If you enable QUEST, the engine will attempt to use QUEST after a short warm-up, but will automatically fall back to the Staircase method if performance becomes unstable. QUEST is experimental — enable it to try faster adaptive estimation, but Staircase is recommended for conservative screening.")
                Spacer()
                Button("Done") { showingInfo = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        #if DEBUG
        .sheet(isPresented: $showingTelemetry) {
            TelemetryViewerLocal()
        }
        #endif
    }
}

#if DEBUG
// Local debug-only telemetry viewer to avoid a missing-file build error when
// `TelemetryViewer.swift` isn't compiled into the app target. This mirrors the
// standalone TelemetryViewer implementation but uses a different symbol name
// (TelemetryViewerLocal) so it won't conflict if the real file is present.
struct TelemetryViewerLocal: View {
    @State private var events: [[String: Any]] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(events.enumerated()), id: \.0) { idx, evt in
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
