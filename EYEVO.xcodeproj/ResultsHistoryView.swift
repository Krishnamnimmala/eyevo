import SwiftUI

struct ResultsHistoryView: View {

    // MARK: - Share Wrapper
    struct ShareFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    // MARK: - Store
    private let store = ResultStore.shared

    // MARK: - Date Formatter
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // MARK: - Share State
    @State private var shareFile: ShareFile?

    var body: some View {
        NavigationView {
            List(store.loadAll()) { record in

                VStack(alignment: .leading, spacing: 8) {

                    // PASS / REFER + Date
                    HStack {
                        Text(record.overallPassed ? "PASS" : "REFER")
                            .foregroundColor(record.overallPassed ? .green : .red)
                            .font(.headline)

                        Spacer()

                        Text(formatter.string(from: record.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Left Eye
                    HStack {
                        Text("Left logMAR")
                        Spacer()
                        Text(record.leftEyeLogMAR.map {
                            String(format: "%.2f", $0)
                        } ?? "-")
                    }

                    // Right Eye
                    HStack {
                        Text("Right logMAR")
                        Spacer()
                        Text(record.rightEyeLogMAR.map {
                            String(format: "%.2f", $0)
                        } ?? "-")
                    }

                    // Confidence
                    HStack {
                        Text("Confidence")
                        Spacer()
                        Text(String(format: "%.0f%%", record.confidence * 100))
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Past Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportCSVFile()
                    }
                }
            }
        }
        .sheet(item: $shareFile) { file in
            ShareSheet(activityItems: [file.url])
        }
    }

    // MARK: - Export Logic
    private func exportCSVFile() {
        let csv = store.exportCSV()

        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .short
        ).replacingOccurrences(of: "/", with: "-")
         .replacingOccurrences(of: ":", with: "-")

        let filename = "EYEVO_Results_\(timestamp).csv"

        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(filename)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            shareFile = ShareFile(url: url)
        } catch {
            print("Export failed:", error)
        }
    }
}
