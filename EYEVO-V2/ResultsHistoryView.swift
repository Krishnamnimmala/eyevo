import SwiftUI

struct ResultsHistoryView: View {

    // MARK: - Share Wrapper
    struct ShareFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    // MARK: - Store
    private let store = ResultStore.shared

    // MARK: - Display Date Formatter
    private let displayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // MARK: - Filename Date Formatter
    private let fileNameFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return df
    }()

    // MARK: - Share State
    @State private var shareFile: ShareFile?

    var body: some View {
        NavigationView {
            Group {
                let records = store.loadAll()

                if records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)

                        Text("No results available")
                            .font(.headline)

                        Text("Completed screening results will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(records) { record in
                        VStack(alignment: .leading, spacing: 8) {

                            // PASS / REFER + Date
                            HStack {
                                Text(record.overallPassed ? "PASS" : "REFER")
                                    .foregroundColor(record.overallPassed ? .green : .orange)
                                    .font(.headline)

                                Spacer()

                                Text(displayFormatter.string(from: record.startTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            // Eyevo ID
                            if !record.eyevoID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                HStack {
                                    Text("Eyevo ID")
                                    Spacer()
                                    Text(record.eyevoID)
                                }
                            }

                            // Test ID
                            if !record.id.uuidString.isEmpty {
                                HStack {
                                    Text("Test ID")
                                    Spacer()
                                    Text(record.id.uuidString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            // Left Eye
                            HStack {
                                Text("Left logMAR")
                                Spacer()
                                Text(record.leftEyeLogMAR.map { String(format: "%.2f", $0) } ?? "-")
                            }

                            // Right Eye
                            HStack {
                                Text("Right logMAR")
                                Spacer()
                                Text(record.rightEyeLogMAR.map { String(format: "%.2f", $0) } ?? "-")
                            }

                            // Confidence
                            HStack {
                                Text("Confidence")
                                Spacer()
                                Text(String(format: "%.0f%%", record.confidence * 100))
                            }

                            // Reliability
                            HStack {
                                Text("Reliability")
                                Spacer()
                                Text(record.reliabilityLabel)
                                    .foregroundColor(reliabilityColor(record.reliabilityLabel))
                            }

                            // Not Sure Count
                            HStack {
                                Text("Not Sure")
                                Spacer()
                                Text("\(record.notSureCount)")
                            }

                            // Total Responses
                            HStack {
                                Text("Total Responses")
                                Spacer()
                                Text("\(record.totalResponseCount)")
                            }

                            // Duration
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(Int(record.duration ?? 0)) sec")
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Past Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportCSVFile()
                    }
                    .disabled(store.loadAll().isEmpty)
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
        let timestamp = fileNameFormatter.string(from: Date())
        let filename = "EYEVO_Results_\(timestamp).csv"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            shareFile = ShareFile(url: url)
        } catch {
            print("Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Reliability Color
    private func reliabilityColor(_ label: String) -> Color {
        switch label.lowercased() {
        case "high":
            return .green
        case "moderate":
            return .orange
        case "low":
            return .red
        default:
            return .secondary
        }
    }
}
