import SwiftUI

struct DebugSettingsView: View {
    @AppStorage("debug.staircaseStep") private var step: Double = 0.08
    @AppStorage("debug.staircaseReversals") private var reversals: Int = 5
    @AppStorage("debug.staircaseVerbose") private var verbose: Bool = false

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Staircase")) {
                    HStack {
                        Text("Step size")
                        Spacer()
                        Text(String(format: "%.3f", step))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $step, in: 0.01...0.2, step: 0.01)

                    Stepper(value: $reversals, in: 1...10) {
                        Text("Reversals to stop: \(reversals)")
                    }

                    Toggle("Verbose staircase logging", isOn: $verbose)
                }

                Section(header: Text("Notes")) {
                    Text("Changes here take effect on next session start. Values are persisted via UserDefaults (debug.* keys).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Debug Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

#if DEBUG
struct DebugSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DebugSettingsView()
    }
}
#endif
