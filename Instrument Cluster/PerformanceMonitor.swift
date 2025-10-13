import Foundation
import SwiftUI
import Combine

/// Monitors app performance metrics for optimization
@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var averageFPS: Double = 60.0
    @Published var memoryUsage: UInt64 = 0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsHistory: [Double] = []
    private let maxHistorySize = 30
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupMonitoring()
    }
    
    func startMonitoring() {
        // FPS monitoring using CADisplayLink
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)
        
        // Memory monitoring
        startMemoryMonitoring()
    }
    
    nonisolated func stopMonitoring() {
        Task { @MainActor in
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let elapsed = displayLink.timestamp - lastTimestamp
        if elapsed > 0 {
            let fps = 1.0 / elapsed
            currentFPS = fps
            
            // Track average
            fpsHistory.append(fps)
            if fpsHistory.count > maxHistorySize {
                fpsHistory.removeFirst()
            }
            averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
        }
        
        lastTimestamp = displayLink.timestamp
        frameCount += 1
    }
    
    private func setupMonitoring() {
        // Monitor thermal state
        NotificationCenter.default
            .publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.thermalState = ProcessInfo.processInfo.thermalState
                }
            }
            .store(in: &cancellables)
        
        thermalState = ProcessInfo.processInfo.thermalState
    }
    
    private func startMemoryMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateMemoryUsage()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            memoryUsage = info.resident_size
        }
    }
    
    // Helper to get memory in MB
    var memoryUsageMB: Double {
        Double(memoryUsage) / (1024 * 1024)
    }
    
    // Performance recommendations
    var shouldReduceQuality: Bool {
        averageFPS < 45 || thermalState == .serious || thermalState == .critical
    }
    
    deinit {
        stopMonitoring()
    }
}

