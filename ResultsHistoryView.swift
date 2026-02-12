import SwiftUI

struct ResultsHistoryView: View {

    @State private var records: [VisionResultRecord] = []
    @State private var showShareSheet = false
    @State private var exportText = ""

    var body: some View {

        List {
            Section {

                ForEach(records) { record in
                    VStack(alignment: .leading, spacing: 8) {

                        Text(
                            record.date.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.headline)

                        Text(record.passed ? "PASS" : "REFER")
                            .fontWeight(.bold)
                            .foregroundColor(record.passed ? .green : .orange)

                        if let logMAR = record.estimatedLogMAR {
                            Text(String(format: "Estimated logMAR: %.2f", logMAR))
                                .font(.subheadline)
                        }

                        if let confidence = record.confidence {
                            Text(String(format: "Confidence: %.0f%%", confidence * 100))
                                .font(.subheadline)
                        }

                        if !record.isValid {
                            Text("Result marked as low confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

            } header: {
                Text("Test History")
            }
        }
        .navigationTitle("Vision Results")

        // 📤 Export button
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportText = ResultStore.shared.exportCSV()
                    showShareSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(records.isEmpty)
            }
        }

        // Share sheet
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [exportText])
        }

        .onAppear {
            records = ResultStore.shared.loadAll()
        }
    }
}
