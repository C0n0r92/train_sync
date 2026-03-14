# ScanRx Watch App - Testing Guide

## Overview
Test-first approach for Monkey C watch app. All tests assume bugs exist.

## Manual Testing Checklist

### 1. Device Token Authentication
- [ ] **First app open with no token**
  - Expected: Show "Link with phone" screen
  - Actual: _______________
  - Bug suspect: Pairing code wrong format

- [ ] **Token storage after registration**
  - Expected: Token persists in app storage
  - Actual: _______________
  - Bug suspect: Token lost on app restart

- [ ] **Token with 90-day expiry**
  - Expected: Token stored with correct expiry timestamp
  - Actual: _______________
  - Bug suspect: Expiry check off by 1 day

- [ ] **Expired token handling (simulated)**
  - Expected: Show "Please reconnect" screen
  - Actual: _______________
  - Bug suspect: App crashes on 401 instead of showing error

### 2. Workout Fetching & Polling
- [ ] **GET /api/sessions/current on first start**
  - Setup: Create WorkoutSession in API with test device token
  - Expected: App fetches and displays workout blocks
  - Actual: _______________
  - Bug suspect: Missing blocks array crashes parser

- [ ] **Offline mode with cached workout**
  - Setup: Kill network, restart app
  - Expected: Shows cached workout from last sync
  - Actual: _______________
  - Bug suspect: Shows "Loading..." forever without timeout

- [ ] **Poll interval (10 seconds)**
  - Setup: Monitor network requests
  - Expected: Polls every 10 seconds while idle
  - Actual: _______________
  - Bug suspect: Polls every 1 second (battery killer)

- [ ] **Stop polling during active session**
  - Expected: No API calls while block timer running
  - Actual: _______________
  - Bug suspect: Still polls (wasted API calls)

### 3. Block Display & Navigation
- [ ] **Display current block (e.g., "Block 2 of 4")**
  - Setup: 4-block workout loaded
  - Expected: Shows correct block number and type
  - Actual: _______________
  - Bug suspect: Shows wrong block index

- [ ] **Generic block display (all types)**
  - Setup: Run, Rest, Interval, Cooldown blocks
  - Expected: Displays type and target params
  - Actual: _______________
  - Bug suspect: Unknown block type crashes app

- [ ] **Tap to advance between blocks**
  - Expected: Advances 1 block per tap
  - Actual: _______________
  - Bug suspect: Double-tap skips a block

- [ ] **Last block handling**
  - Setup: Tap on last block, then tap advance
  - Expected: Shows "Workout Complete" screen
  - Actual: _______________
  - Bug suspect: Can tap beyond last block (crashes?)

### 4. Timer/Stopwatch
- [ ] **Start timer on block**
  - Expected: Timer starts at 00:00
  - Actual: _______________
  - Bug suspect: Timer doesn't start

- [ ] **Running timer updates every second**
  - Expected: Displays MM:SS format correctly
  - Actual: _______________
  - Bug suspect: Timer counts wrong (off by 1 second)

- [ ] **Block duration captured when advancing**
  - Setup: Run timer for 30 seconds, advance block
  - Expected: Block results show actual_duration=30
  - Actual: _______________
  - Bug suspect: Duration not recorded

- [ ] **Negative duration edge case**
  - Setup: Server sends negative duration in target
  - Expected: Displays "-100s" (not ideal, but doesn't crash)
  - Actual: _______________
  - Bug suspect: Timer counts backwards

### 5. Result Submission
- [ ] **POST /api/sessions/:id/results with block results**
  - Setup: Complete 2-block workout, capture times
  - Expected: API returns 201, result stored
  - Actual: _______________
  - Bug suspect: Uses wrong session ID

- [ ] **Block results structure**
  - Expected: { block_index: 0, actual_duration: 30, block_type: "run" }
  - Actual: _______________
  - Bug suspect: Duration in wrong units (ms vs sec)

- [ ] **Include X-Device-Token in header**
  - Expected: Header contains device token
  - Actual: _______________
  - Bug suspect: Doesn't include header (401 error)

- [ ] **Error handling on POST failure**
  - Setup: Network error during submission
  - Expected: Shows "Retry?" button, queues locally
  - Actual: _______________
  - Bug suspect: Results lost without warning

- [ ] **404 on non-existent session**
  - Expected: Shows "Session not found" error
  - Actual: _______________
  - Bug suspect: Crashes or generic error

### 6. Offline Mode & Caching
- [ ] **Cache workout after first fetch**
  - Expected: Workout stored locally
  - Actual: _______________
  - Bug suspect: Cache never written

- [ ] **Use cached workout when offline**
  - Setup: Fetch workout, kill network, restart
  - Expected: Displays cached blocks
  - Actual: _______________
  - Bug suspect: Requires network (can't proceed offline)

- [ ] **Cache cleared after successful new fetch**
  - Setup: Sync new workout
  - Expected: Old cached data replaced
  - Actual: _______________
  - Bug suspect: Uses stale cache even after fresh fetch

- [ ] **Queue results locally if POST fails**
  - Setup: Network down, try submit results
  - Expected: Results stored, "Will sync when online" message
  - Actual: _______________
  - Bug suspect: Results lost forever

### 7. Battery & Performance
- [ ] **Minimal battery drain during idle polling**
  - Setup: App idle for 1 hour, monitor battery
  - Expected: Small drain (screen off, 1 poll per 10 sec)
  - Actual: _______________
  - Bug suspect: Constant polling drains battery in hours

- [ ] **CPU usage during timer**
  - Setup: Run timer for 5 minutes
  - Expected: Reasonable CPU (not always running)
  - Actual: _______________
  - Bug suspect: Continuous CPU spin (battery killer)

- [ ] **Large workout (20+ blocks)**
  - Setup: Create 20-block workout
  - Expected: App loads and navigates smoothly
  - Actual: _______________
  - Bug suspect: Hangs or crashes

### 8. Hardware Integration
- [ ] **GPS for Run blocks**
  - Expected: GPS enabled during run blocks only
  - Actual: _______________
  - Bug suspect: GPS always on (battery drain)

- [ ] **Distance tracking accuracy**
  - Setup: Run with GPS enabled
  - Expected: Distance matches actual run distance (within 5%)
  - Actual: _______________
  - Bug suspect: Distance wildly wrong

- [ ] **Screen stays on during workout**
  - Expected: Screen doesn't timeout
  - Actual: _______________
  - Bug suspect: Screen times out after 30s (data loss)

### 9. Edge Cases & Crashes
- [ ] **Malformed JSON response**
  - Setup: Mock API to return invalid JSON
  - Expected: Graceful error message, no crash
  - Actual: _______________
  - Bug suspect: App force closes

- [ ] **Network timeout (no response in 5 sec)**
  - Expected: Shows "Connection timeout" error
  - Actual: _______________
  - Bug suspect: Hangs forever waiting for response

- [ ] **Intermittent connectivity**
  - Setup: Toggle WiFi/BLE on and off
  - Expected: Retries failed requests, eventually syncs
  - Actual: _______________
  - Bug suspect: Fails after first error (doesn't retry)

- [ ] **App backgrounding during timer**
  - Setup: Start timer, press home button
  - Expected: Timer pauses, resumes on foreground
  - Actual: _______________
  - Bug suspect: Timer keeps running (battery waste)

- [ ] **Device reboot during active workout**
  - Setup: Run timer, restart watch
  - Expected: Can resume from cached data
  - Actual: _______________
  - Bug suspect: Loses all progress

## Garmin Simulator Testing

### Setup
```bash
# 1. Install Garmin SDK (see WATCH_APP_SETUP.md)
# 2. Build for simulator
monkeyc -d d2delta -s --outdir bin source/Main.mc

# 3. Simulator opens with watch app
```

### Testing Workflow
1. **API Mocking**: Update API_URL to point to local test server
2. **Network Failure Simulation**: Kill network during tests
3. **Manual Tap**: Tap on simulator screen to advance blocks
4. **Timer Testing**: Verify MM:SS display accuracy

## Test Data Setup

### Required API Endpoints
1. **POST /api/auth/signup** - Create test athlete
2. **POST /api/sessions** - Create session from QR scan
3. **GET /api/sessions/current** - Return queued workout
4. **POST /api/sessions/:id/results** - Accept results

### Sample Test Workout
```json
{
  "id": "session_123",
  "workout": {
    "id": "workout_456",
    "name": "Test WOD",
    "blocks": [
      { "type": "run", "target_params": { "distance": 5, "pace_target": "6:00" } },
      { "type": "rest", "target_params": { "duration": 120 } },
      { "type": "interval", "target_params": { "duration": 30, "reps": 8 } }
    ]
  }
}
```

## Bugs Found & Fixed

| Test | Bug Found | Status |
|------|-----------|--------|
| Timer counts off by 1 second | To be discovered | Pending |
| Token not persisting on restart | To be discovered | Pending |
| App crashes on malformed JSON | To be discovered | Pending |
| Polling interval wrong | To be discovered | Pending |
| Missing device token in header | To be discovered | Pending |
| Double-tap skips block | To be discovered | Pending |

## Performance Metrics

Record actual performance during testing:

- **API latency**: ________ ms
- **UI response time**: ________ ms
- **Memory usage**: ________ KB
- **Battery drain (1 hour idle)**: ________%
- **Crash count**: ________

## Sign-off

- [ ] All critical path tests passed
- [ ] No app crashes during testing
- [ ] Results submit successfully
- [ ] Offline mode works
- [ ] Battery drain acceptable
- [ ] Ready for real device testing

**Tested by**: _______________
**Date**: _______________
