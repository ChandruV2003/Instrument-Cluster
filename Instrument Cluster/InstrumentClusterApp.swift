import SwiftUI

@main
struct InstrumentClusterApp: App {
    @StateObject private var appState = AppState()      // calibration & prefs

    var body: some Scene {
        WindowGroup {
            if appState.isCalibrated {
                DashboardView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)        // feel free to drop
            } else {
                CalibrationView()
                    .environmentObject(appState)
            }
        }
    }
}
