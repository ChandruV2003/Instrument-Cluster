import SwiftUI

/// Chooses between the Calibration screen (first-launch / double-tap)
/// and the main Dashboard once the user has calibrated.
struct ContentView: View {
    @StateObject private var appState = AppState()   // holds bias + prefs

    var body: some View {
        Group {
            if appState.isCalibrated {
                DashboardView()
                    .environmentObject(appState)
            } else {
                CalibrationView()
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)     // comment out if you want system
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 600, height: 340)
}
