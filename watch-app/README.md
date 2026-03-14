# ScanRx Connect IQ Watch App

Garmin Connect IQ application for displaying and executing workout sessions from ScanRx coach app.

## Project Structure

```
watch-app/
├── source/                      # Monkey C source files
│   ├── Main.mc                 # App entry point, lifecycle
│   ├── SessionManager.mc       # API polling, session state
│   ├── BlockDisplay.mc         # Block UI rendering
│   ├── HomeView.mc             # Home screen
│   ├── StorageManager.mc       # Token & cache persistence
│   └── ...                     # Additional modules
├── resources/
│   ├── layouts/                # Screen layouts
│   └── strings/                # UI text strings
├── bin/                        # Compiled output
├── manifest.xml                # App metadata
├── TESTING.md                  # Comprehensive test plan
└── README.md                   # This file
```

## Installation

### Prerequisites

- macOS 10.15+ or Linux
- Garmin SDK (Connect IQ)

### Install Garmin SDK

#### Option A: Homebrew (Recommended)
```bash
brew tap garmin/garmin-sdks
brew install garmin-sdk
```

#### Option B: Manual Download
1. Download from: https://developer.garmin.com/downloads/
2. Extract to: `~/garmin/sdk`
3. Add to PATH: `export PATH="$PATH:~/garmin/sdk/bin"`

### Verify Installation
```bash
which monkeyc
# Should output: /opt/homebrew/bin/monkeyc (or your SDK path)

monkeyc --version
# Should show: version X.X.X
```

## Development

### Build for Simulator
```bash
# Debug build
monkeyc -d d2delta -s --outdir bin source/Main.mc

# Release build
monkeyc -d d2delta -r --outdir bin source/Main.mc
```

### Build for Real Device
```bash
# For Fenix 5X Plus
monkeyc -d fenix5xplus -r --outdir bin source/Main.mc

# For Fenix 6
monkeyc -d fenix6 -r --outdir bin source/Main.mc
```

### Supported Devices
- d2delta (Simulator)
- fenix5xplus
- fr745
- fr945
- fenix6
- (See manifest.xml for full list)

## Testing

See `TESTING.md` for comprehensive test plan and procedures.

### Quick Test
1. Build for simulator: `monkeyc -d d2delta -s --outdir bin source/Main.mc`
2. Simulator opens automatically
3. Use Device Simulator to:
   - Tap screen to advance blocks
   - Monitor console output for debug logs
   - Check API requests being sent

### Test Against Local API
```bash
# Update source/Main.mc:
var API_URL = "http://192.168.1.100:3000/api";  # Your machine IP

# Create test session:
rails c
athlete = User.create!(email: "athlete@test.com", password: "test123", role: :athlete)
token = DeviceToken.create!(user_id: athlete.id, token: "test_device_123",
                           platform: :connect_iq, expires_at: 90.days.from_now)
```

## API Integration

### Device Token Authentication
All requests include:
```
Header: X-Device-Token: <token>
```

### Endpoints Used

#### GET /api/sessions/current
Fetch queued workout for device
```
Request:
  Headers: { X-Device-Token: "device_token_123" }

Response (200):
  {
    "id": "session_123",
    "workout": {
      "id": "workout_456",
      "name": "Test WOD",
      "blocks": [...]
    }
  }

Response (204 No Content):
  No workout queued

Response (401):
  Token invalid or expired
```

#### POST /api/sessions/:id/results
Submit completed workout results
```
Request:
  Headers: { X-Device-Token: "device_token_123" }
  Body: {
    "block_results": [
      { "block_index": 0, "actual_duration": 300, "block_type": "run" },
      { "block_index": 1, "actual_duration": 120, "block_type": "rest" }
    ]
  }

Response (201):
  { "success": true }

Response (401):
  Unauthorized

Response (404):
  Session not found
```

## Features

### MVP Features
- [x] Device token authentication
- [x] Poll API for queued workouts
- [x] Display generic blocks (type + params)
- [x] Manual tap-to-advance between blocks
- [x] Timer/stopwatch for blocks
- [x] Submit block results to API
- [x] Offline caching (cached workout)
- [x] Token expiry handling

### Future Features
- [ ] GPS auto-advance for Run blocks
- [ ] Heart rate display
- [ ] Garmin Connect integration (sync as activity)
- [ ] Result retry queue (offline result sync)
- [ ] Per-block custom UI (not generic)
- [ ] Voice cues/notifications
- [ ] Competitor comparison

## Known Limitations

### Current MVP
- Generic block display (not per-type UI)
- Manual tap only (no GPS auto-advance)
- No result retry queue (one-shot submit)
- No Garmin Connect sync
- No heart rate data

### Testing
- Simulator only (no real device yet)
- Hardcoded test API URLs
- No automated test framework

## Debugging

### Enable Logging
All logs go to simulator console output
```monkey
// In any module:
System.println("[ScanRx] Debug message");
```

### Common Issues

| Problem | Solution |
|---------|----------|
| "Cannot find monkeyc" | Check PATH, verify SDK installation |
| "Device not found" | Specify device: `-d d2delta` |
| "Network request fails" | Use machine IP not localhost, check firewall |
| "Token storage not working" | Check device storage quota, verify StorageManager |
| "App crashes on JSON parse" | Add null checks, log input data |
| "Timer runs slow" | Use System.getSystemTime(), not frame counter |

## Build & Deploy

### Sideload to Real Device
```bash
# Build for device
monkeyc -d fenix5xplus -r --outdir bin source/Main.mc

# Connect watch to Garmin Express
# Drag .prg file to watch
# Or: Enable developer mode → USB transfer
```

### Connect IQ Store
1. Create developer account: https://connect.garmin.com/
2. Submit app for review
3. Pass Garmin's security audit
4. App available in Connect IQ Store

## Code Quality

### Conventions
- CamelCase for class names
- camelCase for methods/variables
- UPPER_CASE for constants
- Comments for non-obvious logic
- Log prefix: `[ScanRx]`

### Testing
- Assume bugs exist in all code
- Test edge cases explicitly
- Verify error handling
- Check offline scenarios
- Monitor battery/performance

## Contributing

1. Clone the repo
2. Create a feature branch
3. Make changes (tests first!)
4. Build & test in simulator
5. Verify on real device if possible
6. Submit PR with test results

## License

Copyright 2026 ScanRx. All rights reserved.

## Support

- Issues: See GitHub issues
- Docs: See TESTING.md, WATCH_APP_SETUP.md
- API: See backend Rails API docs
