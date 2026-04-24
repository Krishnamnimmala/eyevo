import SwiftUI

struct CreditCardCalibrationView: View {
    
    let onCalibrationComplete: () -> Void
    
    @State private var cardWidthPoints: CGFloat = 260
    @State private var errorMessage: String?
    @State private var isValidMeasurement: Bool = false
    
    private let eyevoBlue = Color(red: 0.00, green: 0.48, blue: 1.00)
    
    private let minWidth: CGFloat = 160
    private let maxWidthMultiplier: CGFloat = 0.85
    private let fineStep: CGFloat = 0.5
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            ScrollView {
                
                VStack(spacing: 28) {
                    
                    // MARK: Header
                    
                    VStack(spacing: 10) {
                        
                        Text("Screen Calibration")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Align a standard ID-sized object with the outline below.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    
                    // MARK: Card Preview
                    
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isValidMeasurement ? Color.green : eyevoBlue.opacity(0.85),
                                lineWidth: 3
                            )
                            .frame(
                                width: cardWidthPoints,
                                height: cardWidthPoints * 0.63
                            )
                        
                        Text("85.60 mm reference")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .offset(y: (cardWidthPoints * 0.63 / 2) + 18)
                    }
                    
                    
                    // MARK: Slider
                    
                    Slider(
                        value: $cardWidthPoints,
                        in: minWidth...(UIScreen.main.bounds.width * maxWidthMultiplier)
                    )
                    .tint(eyevoBlue)
                    .padding(.horizontal, 28)
                    .onChange(of: cardWidthPoints) { _ in
                        validateMeasurement()
                    }
                    
                    
                    // MARK: Fine Adjustment
                    
                    HStack(spacing: 30) {
                        
                        Button {
                            adjustWidth(by: -fineStep)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(eyevoBlue)
                        }
                        
                        Text("Fine adjust")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button {
                            adjustWidth(by: fineStep)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(eyevoBlue)
                        }
                    }
                    
                    
                    // MARK: Instruction Card
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("How to calibrate")
                            .font(.headline)
                        
                        Text("""
• Hold your phone upright (portrait mode)
• Use a rigid ID-sized object (85.60 mm wide)
• Place it horizontally against the screen
• Adjust the slider until edges align
""")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Text("EYEVO does not scan or access physical objects.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(18)
                    .padding(.horizontal)
                    
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            
            // MARK: Confirm Button (Pinned Bottom)
            
            Button(action: saveCalibration) {
                
                Text("Confirm Calibration")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(isValidMeasurement ? eyevoBlue : Color.gray.opacity(0.4))
                    .cornerRadius(18)
                    .padding(.horizontal)
            }
            .disabled(!isValidMeasurement)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            validateMeasurement()
        }
    }
    
    
    // MARK: Fine Adjust
    
    private func adjustWidth(by amount: CGFloat) {
        
        let maxWidth = UIScreen.main.bounds.width * maxWidthMultiplier
        
        cardWidthPoints = min(
            max(cardWidthPoints + amount, minWidth),
            maxWidth
        )
        
        validateMeasurement()
    }
    
    
    // MARK: Validation
    
    private func validateMeasurement() {
        
        let pxPerMM = CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: cardWidthPoints
        )
        
        // realistic iPhone px/mm range
        isValidMeasurement = (pxPerMM > 4 && pxPerMM < 20)
    }
    
    
    // MARK: Save
    
    private func saveCalibration() {
        
        let pxPerMM = CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: cardWidthPoints
        )
        
        guard pxPerMM > 4 && pxPerMM < 20 else {
            errorMessage = "Calibration appears invalid. Please adjust and try again."
            return
        }
        
        CalibrationStore.shared.save(pxPerMM: pxPerMM)
        onCalibrationComplete()
    }
}
