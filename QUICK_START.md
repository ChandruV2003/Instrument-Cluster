# Quick Start Guide 🚀

Get your Instrument Cluster app running in your Tesla Model Y in 5 minutes!

## ✅ Prerequisites

- iPhone with iOS 16.0 or later
- Xcode 15.0 or later
- USB cable or wireless debugging setup
- Phone mount for dashboard

## 📋 5-Minute Setup

### Step 1: Build the App (2 minutes)

```bash
# Navigate to the project
cd /Users/admin/Developer/Instrument-Cluster

# Open in Xcode
open "Instrument Cluster.xcodeproj"
```

In Xcode:
1. Select your iPhone from the device menu
2. Press ⌘R (or click the Play button)
3. Trust developer certificate on your iPhone if prompted
4. Wait for build to complete (~30 seconds)

### Step 2: Grant Permissions (30 seconds)

When the app launches, you'll see two permission prompts:

1. **Location Permission** → Tap "Allow While Using App"
   - Required for: Speed, altitude, speed limits
   
2. **Motion Permission** → Tap "Allow"
   - Required for: G-force, tilt, acceleration

### Step 3: Calibrate (1 minute)

1. **Mount your phone** on the dashboard
   - Use a quality mount
   - Ensure it's level and stable
   - Good GPS visibility (near windshield)

2. **Tap "Calibrate"**
   - Phone should be level
   - Car should be stationary
   - This zeros the tilt reference

3. **Done!** Main dashboard appears

### Step 4: Start Driving (30 seconds)

The app will automatically:
- ✅ Track your speed via GPS
- ✅ Show g-forces during acceleration/braking
- ✅ Display tilt during turns
- ✅ Fetch posted speed limits (requires internet)

### Step 5: Optimize for Your Tesla (1 minute)

**For best results:**

1. **Connect to car's WiFi/Hotspot** (for speed limits)
2. **Plug into USB charger** (enables high performance mode)
3. **Position for easy viewing** without obstructing instruments
4. **Set screen brightness** to ~75% (good visibility, saves battery)

## 🎯 Layout Guide

### Landscape Mode (Recommended)
```
┌─────────────────────────────────────┐
│ Speed: 55 mph    Alt: 500 ft       │
│                                     │
│  [Tilt]    [Speedometer]  [G-Force]│
│   15°           65                  │
│   -5°           MPH                 │
│                                     │
└─────────────────────────────────────┘
```

### Portrait Mode (Alternative)
```
┌─────────────────┐
│ 55mph   500ft   │
│                 │
│  [Speedometer]  │
│       65        │
│      MPH        │
│                 │
│ [Tilt][G-Force] │
│  15°      0.3g  │
│                 │
└─────────────────┘
```

## 🚗 Using in Your Tesla Model Y

### Mounting Position

**Option 1: Center Dashboard** (Recommended)
- Best: Landscape mode
- Position: Between seats
- Angle: Slightly toward driver
- Benefits: Easy to see, doesn't block anything

**Option 2: Left of Steering Wheel**
- Best: Portrait mode
- Position: Where instrument cluster would be
- Angle: Facing driver
- Benefits: Traditional cluster position

**Option 3: Right Dashboard**
- Best: Portrait mode
- Position: Passenger side
- Angle: Toward driver
- Benefits: Passenger can monitor too

### What You'll See

#### Speed Display
- **Green arc**: Under speed limit
- **Orange arc**: 5-10 mph over
- **Red arc**: 10+ mph over
- **Red notch**: Posted speed limit
- **Digital readout**: Current speed

#### Tilt Indicator (Left/Bottom-Left)
- **Orange line**: Horizon
- **Roll angle**: Bank in turns
- **Pitch angle**: Uphill/downhill

#### G-Force Meter (Right/Bottom-Right)
- **Blue dot**: Current g-force
- **Yellow ghost**: Peak g-force (fades)
- **Number**: G-force magnitude
- **Rings**: ±0.5g and ±1g reference

## ⚙️ Quick Settings

### Performance Mode

**High Performance** (when charging):
- 60 FPS smooth animations
- Instant speed updates
- ~5-10% battery per hour
- Auto-enabled when plugged in

**Standard Mode** (on battery):
- 30 FPS animations
- Slightly delayed updates
- ~3-5% battery per hour
- Auto-enabled at low battery

### Recalibration

**When to recalibrate:**
- Phone mount moved
- Tilt readings seem off
- After remounting phone

**How:**
1. Park on level ground
2. Ensure phone is level
3. Double-tap anywhere on screen
4. Tap "Calibrate" again

## 📊 Reading the Dashboard

### Speed Indicator (Top-Left Chip)
```
🏎️ 55 mph ← Posted speed limit
```
- Shows only when data available
- Updates every 20+ meters
- Requires internet connection

### Altitude Indicator (Top-Left Chip)
```
🏔️ 500 ft ← Current altitude
```
- Always visible
- Updates with GPS
- In feet (not meters)

### Speedometer
```
     65
    MPH
```
- Large digital readout
- Updates in real-time
- GPS + IMU fusion

### Tilt Display
```
Roll  15° ← Banking left/right
Pitch -5° ← Uphill/downhill
```
- Positive roll = leaning right
- Positive pitch = uphill

### G-Force Display
```
    0.75
```
- 0.0g = No acceleration
- Positive = Acceleration/right turn
- Negative = Braking/left turn

## 🔋 Battery Tips

### For Long Trips (4+ hours)

1. **Use car's USB charging**
   - Enables high performance mode
   - No battery concerns
   - Better cooling

2. **If unplugged:**
   - Reduce screen brightness to 50%
   - Close background apps first
   - App auto-reduces performance at <20%

### Battery Life Estimates

| Mode | Screen | Battery Life |
|------|--------|--------------|
| High Performance | 100% | 2-3 hours |
| High Performance | 75% | 3-4 hours |
| Standard | 75% | 5-7 hours |
| Standard | 50% | 7-10 hours |

## 🎨 Customization Quick Wins

### Change Max Speed

Edit line 49 in `DashboardView.swift`:
```swift
maxMPH: 160  // Change to 120 or 200
```

### Change Speed Warning Colors

Edit lines 100-104 in `SpeedometerView.swift`:
```swift
case ..<5:    return .green    // Under 5 mph over
case 5..<10:  return .orange   // 5-10 mph over
default:      return .red      // 10+ mph over
```

### Change Update Speed

Edit line 12 in `LocationManager.swift`:
```swift
m.distanceFilter = 5  // Change to 2 (faster) or 10 (slower)
```

## 🐛 Common Issues & Fixes

### Speed Not Showing
**Solution:**
1. Check Location permission is "While Using"
2. Go outside for better GPS signal
3. Wait 30 seconds for GPS lock
4. Check Settings → Privacy → Location Services

### Speed Limit Missing
**Solutions:**
- Enable WiFi/cellular data
- Wait to travel 20+ meters
- Not all roads have data (rural areas)
- Check internet connection

### Tilt Incorrect
**Solutions:**
1. Double-tap to recalibrate
2. Ensure phone is level when calibrating
3. Check mount is secure
4. Recalibrate on level ground

### App Laggy
**Solutions:**
1. Close background apps
2. Restart iPhone
3. Check device isn't overheating
4. Lower screen brightness
5. Reduce performance in code

### High Battery Drain
**Solutions:**
1. Plug into car charger
2. Lower screen brightness
3. Close background apps
4. App will auto-optimize at low battery

## 🎯 Pro Tips

### For Best Performance
1. ✅ Use car's USB charging
2. ✅ Close all background apps
3. ✅ Update to latest iOS
4. ✅ Clean phone's GPS area
5. ✅ Use landscape orientation

### For Best Accuracy
1. ✅ Mount near windshield (GPS)
2. ✅ Keep phone cool
3. ✅ Recalibrate after moving mount
4. ✅ Wait for GPS lock before driving
5. ✅ Enable WiFi for speed limits

### For Safety
1. ✅ Set up before driving
2. ✅ Don't interact while moving
3. ✅ Ensure it doesn't block view
4. ✅ Use voice control if needed
5. ✅ Passenger can monitor

## 📱 Orientation Tips

### Switching Orientations

**To Landscape:**
- Rotate phone to left or right
- Gauges arrange horizontally
- Best for wide dashboard mounting

**To Portrait:**
- Rotate phone upright
- Gauges stack vertically
- Best for traditional cluster position

**Auto-Rotation:**
- Works automatically
- Smooth transitions
- No lag or stuttering

## 🎉 You're Ready!

Your Instrument Cluster is now ready for use in your Tesla Model Y!

**Quick Recap:**
- ✅ Built and installed
- ✅ Permissions granted
- ✅ Calibrated
- ✅ Mounted in car
- ✅ Optimized settings

**Next Steps:**
- Take a short drive to test
- Adjust mount position if needed
- Tweak settings to preference
- Enjoy your enhanced Tesla experience!

---

## 📚 Further Reading

- **README.md** - Complete documentation
- **PERFORMANCE_GUIDE.md** - Advanced tuning
- **CHANGELOG.md** - What's new

## ❓ Need Help?

1. Check this guide
2. Review README.md
3. Check Xcode console for errors
4. Verify permissions granted
5. Try recalibrating

---

**Happy driving! 🚗⚡**

