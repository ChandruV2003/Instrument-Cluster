import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var motion = MotionManager()
    @StateObject private var location = LocationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Performance: cache computed tilt to avoid recalculation
    private var tilt: Tilt {
        Tilt(roll:  motion.tilt.roll  - app.rollBias,
             pitch: motion.tilt.pitch - app.pitchBias)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color(.systemBackground).ignoresSafeArea()
                
                // Adaptive layout based on orientation
                DashboardContent(
                    geometry: geo,
                    tilt: tilt,
                    motion: motion,
                    location: location,
                    speedLimit: app.speedLimitMPH
                )
                
                // Overlay chips (speed limit, altitude)
                OverlayChips(
                    speedLimit: app.speedLimitMPH,
                    altitude: location.altitudeFt
                )
                .padding(.top, 12)
                .padding(.leading, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { 
                app.isCalibrated = false 
            }
            .onChange(of: location.lastLocation) { _, newLoc in
                Task {
                    await handleLocationChange(newLoc)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                handleScenePhaseChange(phase)
            }
            .task {
                await startSensors()
            }
            .onDisappear {
                stopSensors()
            }
        }
    }
    
    private func handleLocationChange(_ newLoc: CLLocation?) async {
        guard let loc = newLoc else { return }
        
        // Async fetch with proper error handling
        do {
            if let sl = try await SpeedLimitService.fetchSpeedLimit(for: loc.coordinate) {
                await MainActor.run {
                    app.speedLimitMPH = sl
                }
            }
        } catch {
            // Silently handle errors - don't disrupt UI
            print("Speed limit fetch failed: \(error.localizedDescription)")
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            motion.setHighPerformanceMode(true)
        case .inactive, .background:
            motion.setHighPerformanceMode(false)
        @unknown default:
            break
        }
    }
    
    @MainActor
    private func startSensors() async {
        motion.start()
        location.start()
    }
    
    private func stopSensors() {
        motion.stop()
        location.stop()
    }
}

// MARK: - Dashboard Content Layout
private struct DashboardContent: View {
    let geometry: GeometryProxy
    let tilt: Tilt
    let motion: MotionManager
    let location: LocationManager
    let speedLimit: Double?
    
    private var isLandscape: Bool {
        geometry.size.width > geometry.size.height
    }
    
    private var big: CGFloat {
        min(geometry.size.width, geometry.size.height) * 0.75
    }
    
    private var flank: CGFloat {
        big * 0.62
    }
    
    private var gap: CGFloat {
        flank * 0.14
    }
    
    var body: some View {
        if isLandscape {
            LandscapeLayout(
                tilt: tilt,
                motion: motion,
                location: location,
                speedLimit: speedLimit,
                big: big,
                flank: flank,
                gap: gap
            )
        } else {
            PortraitLayout(
                tilt: tilt,
                motion: motion,
                location: location,
                speedLimit: speedLimit,
                big: big,
                flank: flank,
                gap: gap
            )
        }
    }
}

// MARK: - Landscape Layout
private struct LandscapeLayout: View {
    let tilt: Tilt
    let motion: MotionManager
    let location: LocationManager
    let speedLimit: Double?
    let big: CGFloat
    let flank: CGFloat
    let gap: CGFloat
    
    var body: some View {
        let totalW = flank + big + flank + gap * 2
        
        HStack(spacing: gap) {
            TiltIndicator(tilt: tilt)
                .frame(width: flank, height: flank)
            
            SpeedometerView(
                speedMPS: location.speedMPS,
                accelDelta: motion.deltaV,
                speedLimit: speedLimit,
                maxMPH: 160
            )
            .frame(width: big, height: big)
            
            GForceMeter(gVector: motion.gVector)
                .frame(width: flank, height: flank)
        }
        .frame(width: totalW)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Portrait Layout
private struct PortraitLayout: View {
    let tilt: Tilt
    let motion: MotionManager
    let location: LocationManager
    let speedLimit: Double?
    let big: CGFloat
    let flank: CGFloat
    let gap: CGFloat
    
    var body: some View {
        VStack(spacing: gap) {
            SpeedometerView(
                speedMPS: location.speedMPS,
                accelDelta: motion.deltaV,
                speedLimit: speedLimit,
                maxMPH: 160
            )
            .frame(width: big, height: big)
            
            HStack(spacing: gap) {
                TiltIndicator(tilt: tilt)
                    .frame(width: flank, height: flank)
                
                GForceMeter(gVector: motion.gVector)
                    .frame(width: flank, height: flank)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Overlay Chips
private struct OverlayChips: View {
    let speedLimit: Double?
    let altitude: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sl = speedLimit {
                ChipView(icon: "speedometer", text: "\(Int(sl)) mph")
            }
            ChipView(icon: "mountain.2.fill", text: "\(Int(altitude)) ft")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .frame(width: 600, height: 340)
}
