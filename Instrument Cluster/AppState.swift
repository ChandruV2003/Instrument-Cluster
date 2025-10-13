import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @AppStorage("isCalibrated") var isCalibrated: Bool = false
    @AppStorage("rollBias") var rollBias: Double = 0
    @AppStorage("pitchBias") var pitchBias: Double = 0
    @AppStorage("highPerformanceMode") var highPerformanceMode: Bool = true
    
    @Published var speedLimitMPH: Double?       // pulled from API
    
    // Performance metrics
    @Published var frameRate: Double = 60.0
    @Published var batteryLevel: Float = 1.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Monitor battery level for performance adjustments
        setupBatteryMonitoring()
        
        // Monitor performance metrics
        setupPerformanceMonitoring()
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default
            .publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.batteryLevel = UIDevice.current.batteryLevel
                    self.adjustPerformanceForBattery()
                }
            }
            .store(in: &cancellables)
        
        // Initial check
        batteryLevel = UIDevice.current.batteryLevel
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor for thermal state changes
        NotificationCenter.default
            .publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.adjustPerformanceForThermalState()
                }
            }
            .store(in: &cancellables)
    }
    
    private func adjustPerformanceForBattery() {
        let batteryState = UIDevice.current.batteryState
        
        // Auto-adjust performance based on battery
        if batteryState == .unplugged && batteryLevel < 0.2 {
            // Low battery: reduce performance
            highPerformanceMode = false
        } else if batteryState == .charging || batteryState == .full {
            // Charging or full: enable high performance
            highPerformanceMode = true
        }
    }
    
    private func adjustPerformanceForThermalState() {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .nominal, .fair:
            // Normal operation
            break
        case .serious, .critical:
            // Reduce performance to prevent overheating
            highPerformanceMode = false
        @unknown default:
            break
        }
    }
}
