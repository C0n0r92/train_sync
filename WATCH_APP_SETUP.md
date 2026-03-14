# Monkey C Watch App - Development Setup

## Prerequisites

### 1. Garmin SDK Installation (macOS)

```bash
# Option A: Homebrew (Recommended)
brew tap garmin/garmin-sdks
brew install garmin-sdk

# Option B: Manual Download
# Download from: https://developer.garmin.com/downloads/
# Extract to: ~/garmin/sdk
```

### 2. Verify Installation

```bash
# Check SDK version
ls -la ~/.garmin/monkeyc/bin/monkeyc

# Or check Homebrew path
which monkeyc

# Expected: /opt/homebrew/bin/monkeyc (or similar)
```

### 3. IDEs (Pick One)

**Option A: VS Code (Recommended)**
```bash
# Install extension: "Garmin Extensions" by Garmin
# This provides:
- Syntax highlighting
- Code completion
- Built-in compiler
- Simulator launch
```

**Option B: Eclipse**
- Download from Garmin SDK
- More features but slower

**Option C: Command Line Only**
```bash
# Compile:
monkeyc -d device_name -r --outdir bin source_file.mc

# Run in simulator:
monkeyc -d device_name -s --outdir bin source_file.mc
```

---

## Project Structure

```
watch-app/
├── source/
│   ├── Main.mc           (Entry point, app lifecycle)
│   ├── SessionManager.mc (API polling, state)
│   ├── BlockDisplay.mc   (UI rendering)
│   ├── ResultsUploader.mc (API result submission)
│   └── StorageManager.mc (Cache, token persistence)
├── resources/
│   ├── strings/
│   │   └── strings.xml   (UI text)
│   └── layouts/
│       └── layout.xml    (Screen definitions)
├── manifest.xml          (App metadata)
├── monkeyc.iq           (IQ file for release)
└── README.md
```

---

## 1. Initialize Project

```bash
cd /path/to/train_sync
mkdir watch-app
cd watch-app

# Create manifest.xml
cat > manifest.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest version="1.0">
    <application>
        <appName>ScanRx</appName>
        <version>0.1.0</version>
        <entry>Main</entry>
        <permissions>
            <permission>Communications</permission>
            <permission>SensorHistory</permission>
        </permissions>
        <supports>
            <device id="fenix5xplus"/>
            <device id="fr745"/>
            <device id="fr945"/>
            <!-- Add more device types as needed -->
        </supports>
    </application>
</manifest>
EOF

mkdir -p source resources/layouts resources/strings
```

---

## 2. Core Modules

### Main.mc - App Lifecycle

```monkey
using Toybox.Application;
using Toybox.WatchUi;

class ScanRxApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Load token from storage
        // Check for queued workout
        // Initialize SessionManager
    }

    function onStop(state) {
        // Save session state
        // Stop polling
    }

    function getInitialView() {
        // Show HomeView (list of blocks) or ConnectView (pairing)
        return [new HomeView(), new HomeViewDelegate()];
    }
}

function getApp() {
    return Application.getApp();
}
```

### SessionManager.mc - API & State

```monkey
using Toybox.Communications;
using Toybox.System;

class SessionManager {
    var deviceToken;
    var currentSession;
    var workoutBlocks;
    var currentBlockIndex;

    function initialize() {
        loadDeviceToken();
        checkForQueuedWorkout();
    }

    function loadDeviceToken() {
        // Load from secure storage
        // If expired (>90 days), show reconnect screen
    }

    function checkForQueuedWorkout() {
        // GET /api/sessions/current
        // On success: parse blocks, show HomeView
        // On error: show OfflineView (cached) or ConnectView
    }

    function nextBlock() {
        currentBlockIndex++;
        if (currentBlockIndex >= workoutBlocks.size()) {
            showCompletionScreen();
        }
    }

    function submitResults() {
        // POST /api/sessions/:id/results
        // Handle offline: queue results locally
        // On success: show "Results saved" screen
    }
}
```

### BlockDisplay.mc - UI Rendering

```monkey
using Toybox.WatchUi;
using Toybox.Graphics;

class BlockDisplay extends WatchUi.View {
    var block;
    var blockIndex;
    var totalBlocks;
    var elapsedTime;

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Display block type
        dc.drawText(
            dc.getWidth() / 2,
            50,
            Graphics.FONT_LARGE,
            "Block " + blockIndex + "/" + totalBlocks,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Display block details
        drawBlockDetails(dc);

        // Display timer
        drawTimer(dc);

        // Display "TAP TO CONTINUE"
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() - 50,
            Graphics.FONT_SMALL,
            "TAP TO CONTINUE",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function drawBlockDetails(dc) {
        // Render block type specific info
        // Rest: duration
        // Run: distance, pace target
        // Interval: duration, reps
        // etc.
    }

    function drawTimer(dc) {
        // Display MM:SS elapsed time
        // Update every second
    }
}
```

### StorageManager.mc - Persistence

```monkey
using Toybox.Application;

class StorageManager {
    static var STORAGE_KEY_TOKEN = "device_token";
    static var STORAGE_KEY_EXPIRES = "token_expires_at";
    static var STORAGE_KEY_CACHED_WORKOUT = "cached_workout";

    function saveDeviceToken(token, expiresAt) {
        // Store encrypted if possible
        // Use Application.Storage.setValue()
    }

    function loadDeviceToken() {
        // Retrieve and check expiry
        // Return null if expired or missing
    }

    function cacheWorkout(blocks) {
        // Store workout JSON locally
        // For offline mode
    }

    function getCachedWorkout() {
        // Retrieve if no network available
    }
}
```

---

## 3. API Integration

### Authentication

```monkey
function makeAuthenticatedRequest(url, method, options) {
    // Add X-Device-Token header
    options = options || {};
    options["headers"] = {
        "X-Device-Token" => StorageManager.loadDeviceToken()
    };

    Communications.makeWebRequest(
        url,
        null,
        method,
        new Communications.HttpRequestOptions(options),
        new ResponseHandler()
    );
}

class ResponseHandler extends Communications.ResponseListener {
    function onResponse(responseCode, responseData) {
        // Handle 200: parse and display
        // Handle 401: show reconnect screen
        // Handle 4xx: show error
        // Handle 5xx: queue for retry
    }

    function onError(error) {
        // Network error: show offline mode
    }
}
```

### API Calls

```monkey
// Fetch queued workout
function fetchQueuedWorkout() {
    var url = "http://localhost:3000/api/sessions/current";
    makeAuthenticatedRequest(url, Communications.HTTP_REQUEST_METHOD_GET, {});
}

// Submit results
function submitWorkoutResults(sessionId, blockResults) {
    var url = "http://localhost:3000/api/sessions/" + sessionId + "/results";
    var body = {
        "block_results" => blockResults
    };
    makeAuthenticatedRequest(
        url,
        Communications.HTTP_REQUEST_METHOD_POST,
        {"requestBody" => body}
    );
}
```

---

## 4. Local Testing Setup

### 1. Run Rails API Locally

```bash
cd train_sync
rails s -p 3000

# API available at: http://localhost:3000
```

### 2. Configure Watch App for Local API

Edit `source/Main.mc`:
```monkey
var API_URL = "http://localhost:3000/api";
// or
var API_URL = "http://192.168.1.100:3000/api"; // Your machine IP
```

### 3. Run in Garmin Simulator

```bash
# VS Code: Open source/Main.mc, press Cmd+Shift+B to build & run
# Or command line:
monkeyc -d d2delta -s --outdir bin source/Main.mc

# This launches simulator with watch app
```

### 4. Testing Workflow

1. **Start API** with test data:
```bash
rails c
coach = User.create!(email: "coach@example.com", password: "test123", role: :coach)
workout = coach.workouts.create!(
  name: "Test Workout",
  blocks: [
    {type: "run", distance: 5},
    {type: "rest", duration: 120}
  ],
  status: :published
)
qr = workout.qr_codes.create!(short_id: "test123")
```

2. **Simulate scan** - Manually create session:
```bash
rails c
athlete = User.create!(email: "athlete@example.com", password: "test123", role: :athlete)
qr_scan = qr.qr_scans.create!(athlete_id: athlete.id)
session = WorkoutSession.create!(
  qr_scan_id: qr_scan.id,
  athlete_id: athlete.id,
  workout_id: workout.id,
  started_at: Time.current
)
```

3. **Register device** - Manual:
```bash
rails c
token = DeviceToken.create!(
  user_id: athlete.id,
  token: "test_device_token_12345",
  platform: :connect_iq,
  expires_at: 90.days.from_now
)
```

4. **Test watch app** - In simulator:
- Hardcode `device_token = "test_device_token_12345"`
- Tap "Fetch Workout"
- Should display blocks
- Tap through blocks
- Submit results
- Check API: `session.reload.completed_at` should be set

---

## 5. Build & Compile

### Development Build

```bash
monkeyc -d d2delta -r --outdir bin source/Main.mc
# Creates: bin/ScanRx.prg (for testing)
```

### Release Build

```bash
monkeyc -r -d d2delta --exclude "test" --outdir bin source/Main.mc
# Creates optimized APK for Garmin Store
```

---

## 6. Debugging

### Enable Logging

```monkey
using Toybox.System;

function log(msg) {
    System.println("[ScanRx] " + msg);
}

// In simulator: Check "System" output
```

### Common Issues

| Problem | Solution |
|---------|----------|
| "Cannot find monkeyc" | Check PATH: `echo $PATH`, verify Garmin SDK install |
| "Device not found" | Select correct device in VS Code or `-d device_name` |
| "Network request fails" | Check firewall, use machine IP not localhost |
| "Token storage not working" | Check device storage quota, use compression |
| "App crashes on JSON parse" | Add null checks, log input data |
| "Timer runs slow" | Use system time, not frame counter |

---

## 7. Real Device Testing (Later)

Once watch app is stable:

```bash
# Sideload to real device:
monkeyc -d fenix5xplus -r --outdir bin source/Main.mc

# Connect watch to Garmin Express
# Drag .prg file to watch
# Or: Enable developer mode → USB transfer
```

---

## 8. Integration Checklist

- [ ] Hello-world app builds & runs in simulator
- [ ] Can fetch workout from local API
- [ ] Can display blocks (generic format)
- [ ] Timer works offline
- [ ] Can submit results (hardcoded session ID)
- [ ] Offline caching persists across app restart
- [ ] Device token loads from storage
- [ ] Expired token shows reconnect screen
- [ ] Error handling doesn't crash app
- [ ] Builds for release without errors

