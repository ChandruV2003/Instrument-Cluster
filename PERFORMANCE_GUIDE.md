# Performance Tuning Guide

This guide helps you optimize the Instrument Cluster app for your specific needs and device.

## 🎯 Performance Modes

### High Performance Mode (Default)
**Best for:** Plugged in, newer devices (iPhone 12+)

```swift
// In AppState.swift
@AppStorage("highPerformanceMode") var highPerformanceMode: Bool = true
```

**Characteristics:**
- 60 FPS target
- 60 Hz IMU updates
- Immediate UI responses
- Full Metal acceleration
- Battery: ~5-10% per hour

### Standard Mode
**Best for:** Battery operation, older devices

```swift
@AppStorage("highPerformanceMode") var highPerformanceMode: Bool = false
```

**Characteristics:**
- 30 FPS target
- 30 Hz IMU updates
- Slightly delayed animations
- Full Metal acceleration
- Battery: ~3-5% per hour

### Automatic Mode (Recommended)
The app automatically switches modes based on:
- Battery level (<20% = standard mode)
- Thermal state (serious/critical = standard mode)
- Power adapter status (charging = high performance)

## ⚙️ Advanced Tuning

### 1. GPS Update Frequency

**Location:** `LocationManager.swift`

```swift
// Current settings (optimized)
m.distanceFilter = 5  // meters
private let significantUpdateInterval: TimeInterval = 0.5  // seconds
```

**Tuning Options:**

For **maximum responsiveness** (more battery usage):
```swift
m.distanceFilter = 2  // meters
private let significantUpdateInterval: TimeInterval = 0.25  // seconds
```

For **maximum battery life** (less responsive):
```swift
m.distanceFilter = 10  // meters
private let significantUpdateInterval: TimeInterval = 1.0  // seconds
```

### 2. IMU Update Rate

**Location:** `MotionManager.swift`

```swift
// Current settings
private var updateInterval: TimeInterval = 1.0 / 60.0  // 60 Hz
```

**Tuning Options:**

For **ultra-smooth g-force display** (more CPU usage):
```swift
private var updateInterval: TimeInterval = 1.0 / 120.0  // 120 Hz
```

For **better battery** (less smooth):
```swift
private var updateInterval: TimeInterval = 1.0 / 30.0  // 30 Hz
```

### 3. Speed Limit Caching

**Location:** `SpeedLimitService.swift`

```swift
// Current settings
func isValid(for newCoordinate: CLLocationCoordinate2D, 
             cacheLifetime: TimeInterval = 300) -> Bool {
    // Check if cache is fresh (within 5 minutes)
    guard Date().timeIntervalSince(timestamp) < cacheLifetime else { return false }
    
    // Check if new location is within 50 meters
    return cachedLocation.distance(from: newLocation) < 50
}
```

**Tuning Options:**

For **maximum accuracy** (more API calls):
```swift
cacheLifetime: TimeInterval = 60  // 1 minute
distance < 20  // 20 meters
```

For **minimum data usage** (less accurate):
```swift
cacheLifetime: TimeInterval = 600  // 10 minutes
distance < 100  // 100 meters
```

### 4. Animation Responsiveness

**Location:** `SpeedometerView.swift`

```swift
// Current settings
withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
```

**Tuning Options:**

For **instant updates** (less smooth):
```swift
withAnimation(.linear(duration: 0.1))
```

For **ultra-smooth** (slower response):
```swift
withAnimation(.spring(response: 1.0, dampingFraction: 0.9))
```

### 5. Speed Smoothing

**Location:** `LocationManager.swift`

```swift
// Current settings
private var speedHistory: [Double] = []
private let speedHistorySize = 3  // Use median of 3 samples
```

**Tuning Options:**

For **instant speed** (more jittery):
```swift
private let speedHistorySize = 1  // No smoothing
```

For **very smooth** (delayed):
```swift
private let speedHistorySize = 5  // Median of 5 samples
```

## 🔋 Battery Optimization Strategies

### Strategy 1: Minimal Battery Impact
Perfect for long road trips without charging.

```swift
// AppState.swift
@AppStorage("highPerformanceMode") var highPerformanceMode: Bool = false

// LocationManager.swift
m.distanceFilter = 10
private let significantUpdateInterval: TimeInterval = 1.0

// MotionManager.swift
private var updateInterval: TimeInterval = 1.0 / 30.0

// SpeedLimitService.swift
cacheLifetime: TimeInterval = 600
distance < 100
```

**Expected battery: ~2-3% per hour**

### Strategy 2: Balanced
Good mix of performance and battery life.

```swift
// Use current default settings
// Auto-adjusts based on battery/thermal state
```

**Expected battery: ~3-5% per hour**

### Strategy 3: Maximum Performance
For when plugged into car charger.

```swift
// AppState.swift
@AppStorage("highPerformanceMode") var highPerformanceMode: Bool = true

// LocationManager.swift
m.distanceFilter = 2
private let significantUpdateInterval: TimeInterval = 0.25

// MotionManager.swift
private var updateInterval: TimeInterval = 1.0 / 120.0

// SpeedLimitService.swift
cacheLifetime: TimeInterval = 60
distance < 20
```

**Expected battery: ~10-15% per hour (use while charging)**

## 🌡️ Thermal Management

### Monitoring Thermal State

The app automatically monitors thermal state and adjusts performance:

```swift
// PerformanceMonitor.swift
var shouldReduceQuality: Bool {
    averageFPS < 45 || thermalState == .serious || thermalState == .critical
}
```

### Custom Thermal Thresholds

Edit `AppState.swift`:

```swift
private func adjustPerformanceForThermalState() {
    let thermalState = ProcessInfo.processInfo.thermalState
    
    switch thermalState {
    case .nominal:
        // Maximum performance
        highPerformanceMode = true
    case .fair:
        // Slight reduction
        highPerformanceMode = true
    case .serious:
        // Significant reduction
        highPerformanceMode = false
    case .critical:
        // Emergency reduction
        highPerformanceMode = false
        // Could add more aggressive throttling here
    @unknown default:
        break
    }
}
```

## 📊 Performance Monitoring

### Enable Debug Overlay

1. Build for debugging
2. Check `PerformanceMonitor` metrics
3. Adjust settings based on results

### Key Metrics

**FPS (Frames Per Second):**
- 60 FPS = Perfect
- 45-59 FPS = Good
- 30-44 FPS = Acceptable
- <30 FPS = Poor (adjust settings)

**Memory Usage:**
- <100 MB = Excellent
- 100-150 MB = Good
- 150-200 MB = Acceptable
- >200 MB = Investigate memory leaks

**Thermal State:**
- Nominal = Perfect
- Fair = Good
- Serious = Reduce performance
- Critical = Emergency throttling

## 🎨 Rendering Optimization

### Metal Acceleration

All views use `.drawingGroup()` for GPU rendering:

```swift
// SpeedometerView.swift
Circle()
    .trim(from: 0, to: 0.75)
    .rotation(.degrees(135))
    .stroke(Color.secondary.opacity(0.15))
    .drawingGroup()  // Metal acceleration
```

**When to use:**
- ✅ Complex paths and shapes
- ✅ Multiple overlapping views
- ✅ Animated content
- ❌ Simple text and images
- ❌ Static backgrounds

### Animation Optimization

Use appropriate animation types:

**Linear:** Fastest, least CPU
```swift
.animation(.linear(duration: 0.016), value: speed)  // 60 FPS
```

**Spring:** Smooth, more CPU
```swift
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: speed)
```

**Custom:** Full control
```swift
.animation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3), value: speed)
```

## 🔧 Device-Specific Settings

### iPhone 15 Pro / Pro Max
- High Performance Mode: ✅
- 120 Hz IMU: ✅
- Full GPU acceleration: ✅
- Expected FPS: 60

### iPhone 13 / 14 / 15
- High Performance Mode: ✅
- 60 Hz IMU: ✅
- Full GPU acceleration: ✅
- Expected FPS: 60

### iPhone 11 / 12 / SE
- Standard Mode recommended
- 30-60 Hz IMU: Adaptive
- Full GPU acceleration: ✅
- Expected FPS: 45-60

### iPhone X / XS / XR
- Standard Mode recommended
- 30 Hz IMU: ✅
- Selective GPU acceleration
- Expected FPS: 30-45

## 📱 Testing Performance

### Quick Test Procedure

1. **Build for Release** (not Debug)
   - Debug builds are ~50% slower
   - Release builds use full optimization

2. **Monitor Battery**
   - Note starting battery %
   - Run for 30 minutes
   - Calculate hourly rate

3. **Check Thermal**
   - Start with cool device
   - Monitor temperature after 15 min
   - Adjust if reaching "serious" state

4. **Measure Responsiveness**
   - Speed updates should be instant
   - G-force should track movements
   - Tilt should follow device

### Benchmarking Settings

Create these configurations for testing:

**Minimum:**
```swift
// 30 Hz IMU, 10m GPS filter, 1s throttle
// Expected: 2-3% battery/hour, 30-45 FPS
```

**Balanced (Default):**
```swift
// 60 Hz IMU, 5m GPS filter, 0.5s throttle
// Expected: 3-5% battery/hour, 55-60 FPS
```

**Maximum:**
```swift
// 120 Hz IMU, 2m GPS filter, 0.25s throttle
// Expected: 10-15% battery/hour, 60 FPS
```

## 🎯 Recommended Settings by Use Case

### Daily Commute (Battery Powered)
```
High Performance: OFF
GPS Filter: 10m
GPS Throttle: 1.0s
IMU Rate: 30 Hz
Speed Cache: 10 min
```

### Track Day (Plugged In)
```
High Performance: ON
GPS Filter: 2m
GPS Throttle: 0.25s
IMU Rate: 120 Hz
Speed Cache: 1 min
```

### Road Trip (Battery Powered)
```
High Performance: AUTO
GPS Filter: 5m
GPS Throttle: 0.5s
IMU Rate: 60 Hz (auto 30)
Speed Cache: 5 min
```

### City Driving (Battery Powered)
```
High Performance: AUTO
GPS Filter: 5m
GPS Throttle: 0.5s
IMU Rate: 60 Hz
Speed Cache: 5 min
```

## 💡 Pro Tips

1. **Always use car charger for extended use**
2. **Enable airplane mode if speed limit not needed** (saves battery)
3. **Reduce screen brightness** (biggest battery saver)
4. **Close background apps** before starting
5. **Use landscape mode** (better layout, same performance)
6. **Let device cool** between sessions
7. **Clean GPS/speaker area** for best reception
8. **Update iOS** for latest performance improvements

## 🐛 Troubleshooting Performance

### Low FPS (<45)
1. Check thermal state (might be throttling)
2. Close background apps
3. Restart device
4. Switch to standard mode
5. Reduce IMU update rate

### High Battery Drain (>10%/hr)
1. Check if high performance mode is on
2. Reduce GPS update frequency
3. Increase speed limit cache time
4. Lower IMU update rate
5. Reduce screen brightness

### Laggy Animations
1. Check if device is thermal throttling
2. Ensure Metal acceleration enabled
3. Simplify animations (use linear)
4. Reduce update frequencies

### Memory Warnings
1. Check for memory leaks
2. Reduce speed history size
3. Clear speed limit cache more often
4. Restart app

---

**Remember:** Always test changes in a safe environment before using while driving!


