import SwiftUI

@main
struct InstrumentClusterApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    init() {
        // Configure app-wide optimizations
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.isCalibrated {
                    DashboardView()
                        .environmentObject(appState)
                        .preferredColorScheme(.dark)
                } else {
                    CalibrationView()
                        .environmentObject(appState)
                        .preferredColorScheme(.dark)
                }
                
                // Debug performance overlay (only in debug builds)
                #if DEBUG
                if showPerformanceOverlay {
                    PerformanceOverlay()
                        .environmentObject(performanceMonitor)
                }
                #endif
            }
            .onAppear {
                performanceMonitor.startMonitoring()
            }
            .onDisappear {
                performanceMonitor.stopMonitoring()
            }
        }
    }
    
    private func setupAppearance() {
        // Optimize rendering
        UIView.appearance().isOpaque = true
        
        // Disable animation for better performance when needed
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            UIView.setAnimationsEnabled(false)
        }
    }
    
    #if DEBUG
    @State private var showPerformanceOverlay = false
    #endif
}

// MARK: - Performance Overlay (Debug Only)
#if DEBUG
struct PerformanceOverlay: View {
    @EnvironmentObject private var monitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FPS: \(monitor.currentFPS, specifier: "%.1f")")
            Text("Avg: \(monitor.averageFPS, specifier: "%.1f")")
            Text("Mem: \(monitor.memoryUsageMB, specifier: "%.1f") MB")
            Text("Thermal: \(thermalStateText)")
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(8)
        .background(.black.opacity(0.7))
        .foregroundColor(.green)
        .cornerRadius(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding()
        .allowsHitTesting(false)
    }
    
    private var thermalStateText: String {
        switch monitor.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
#endif
