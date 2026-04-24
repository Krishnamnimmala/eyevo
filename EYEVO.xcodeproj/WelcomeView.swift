import SwiftUI

struct WelcomeView: View {
    
    @ObservedObject private var audioManager = AudioManager.shared
    
    let onStart: () -> Void
    
    // MARK: - Brand Colors
    private let eyevoBlue = Color(red: 0.00, green: 0.48, blue: 1.00)
    private let ctaBackground = Color(red: 0.88, green: 0.94, blue: 1.00)
    
    // MARK: - Calibration Status
    private var isCalibrated: Bool {
        CalibrationStore.shared.pxPerMM != nil
    }
    
    private func recalibrate() {

        CalibrationStore.shared.clear()

        audioManager.speak("Calibration reset. Please recalibrate your screen.")

        onStart()   // RootFlowView will redirect to calibration
    }
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // MARK: - Fixed Top Section
                VStack(spacing: 8) {
                    
                    Text("EYEVO")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(eyevoBlue)
                    
                    Text("Eyevo ID: \(EyevoIDStore.shared.eyevoID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Audio Guidance", isOn: $audioManager.isEnabled)
                        .padding(.horizontal)
                    
                    Text("Quick smartphone vision screening")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                
                // MARK: - Scrollable Middle Content
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Calibration Card
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Text("Screen Calibration")
                                .font(.headline)
                            
                            Text("""
To ensure accurate visual scaling, your screen must be calibrated once for this device.
""")
                                .font(.footnote)
                            
                            Text("""
Use any standard ID-sized object (85.60 mm wide), such as:
• Driver’s license  
• Access badge  
• Employee ID  
• Payment card  

Place it horizontally against the screen during setup.
""")
                                .font(.footnote)
                            
                            Text("EYEVO does not scan, photograph, or access physical objects.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if isCalibrated {

                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)

                                    Text("Calibration verified")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }

                                Button("Recalibrate Screen") {
                                    recalibrate()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)

                            } else {

                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)

                                    Text("Calibration required before screening")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        
                        // MARK: How To Card
                        VStack(alignment: .leading, spacing: 14) {
                            
                            Text("How to use EYEVO")
                                .font(.headline)
                            
                            HowStepRow(
                                icon: "iphone",
                                title: "Hold your phone comfortably",
                                subtitle: "Keep it at eye level"
                            )
                            
                            HowStepRow(
                                icon: "eye",
                                title: "Follow on-screen prompts",
                                subtitle: "Simple visual directions"
                            )
                            
                            HowStepRow(
                                icon: "checkmark.circle",
                                title: "Get a quick screening result",
                                subtitle: "Saved on your device"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        
                        Text("Device-stored results — your privacy first")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        VStack(spacing: 6) {
                            
                            Text("EYEVO provides vision screening guidance only and does not replace a comprehensive clinical eye examination.")
                            
                            Text("If you receive a REFER result or notice vision changes, consult a licensed eye care professional.")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
                
                
                // MARK: - Fixed Bottom Buttons
                HStack(spacing: 16) {
                    
                    NavigationLink {
                        ResultsHistoryView()
                    } label: {
                        VStack(spacing: 2) {
                            Text("View")
                                .font(.footnote)
                            Text("Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(eyevoBlue)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(ctaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        handleStartTapped()
                    } label: {
                        VStack(spacing: 2) {
                            Text("Start")
                                .font(.footnote)
                            Text("Screening")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(eyevoBlue)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(ctaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .onAppear {
                audioManager.speak("Welcome to Eyevo.")
            }
        }
    }
    
    // MARK: - Start Logic
    
    private func handleStartTapped() {

        if isCalibrated {

            audioManager.speak("Starting vision screening.")
            onStart()

        } else {

            audioManager.speak("Calibration required. Opening calibration setup.")

            CalibrationStore.shared.clear()

            onStart()
        }
    }
}

// MARK: - Step Row

private struct HowStepRow: View {
    
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 10) {
            
            Image(systemName: icon)
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(title)
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
