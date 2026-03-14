# Monkey C Watch App - Test Plan

Based on PRD requirements. Assume code has bugs. Focus on real device edge cases.

---

## 1. Device Token Authentication

### Token Lifecycle
- [ ] **First app open** - No token stored
  - ✅ Show "Link with phone" screen
  - ✅ Display pairing code or QR
  - ❌ Bug suspect: Pairing code might be wrong format
  - ❌ Bug suspect: QR doesn't render on small watch screen

- [ ] **Token registration**
  - ✅ Device token generated (SecureRandom.hex)
  - ✅ Stored in Garmin app storage
  - ❌ Bug suspect: Storage fails (low memory) - app crashes?
  - ❌ Bug suspect: Token not actually saved (lost on restart)
  - ❌ Bug suspect: Plain text in storage (security issue)

- [ ] **Token expiry (90 days)**
  - ✅ Stored with expires_at timestamp
  - ❌ Bug suspect: Expiry check wrong (off by 1 day?)
  - ❌ Bug suspect: Doesn't warn user before expiry
  - ❌ Bug suspect: Doesn't refresh proactively

- [ ] **Expired token handling**
  - ✅ API returns 401
  - ✅ App shows "Please reconnect" screen
  - ❌ Bug suspect: App crashes on 401
  - ❌ Bug suspect: Shows generic "Error" message instead of helpful prompt

### Reconnection Flow
- [ ] **Re-pairing** - User scans new QR
  - ✅ New device token generated
  - ✅ Old token replaced
  - ❌ Bug suspect: Old token still used after re-pairing
  - ❌ Bug suspect: Both tokens active (doubles sessions)

---

## 2. Workout Fetching & Polling

### Initial Fetch
- [ ] **GET `/api/sessions/current`** with device token
  - ✅ Returns queued workout after QR scan
  - ✅ Includes full blocks array
  - ❌ Bug suspect: Missing blocks (API returns null)
  - ❌ Bug suspect: Blocks in wrong format

- [ ] **Offline mode** - No network on first open
  - ✅ Shows cached workout from last session
  - ❌ Bug suspect: Shows "Loading..." forever (doesn't timeout)
  - ❌ Bug suspect: Crashes if no cached workout

- [ ] **Timeout handling**
  - ✅ 5 second timeout on API call
  - ❌ Bug suspect: Timeout too long (10 sec) - kills battery
  - ❌ Bug suspect: No timeout (hangs forever)
  - ❌ Bug suspect: Retries without backoff (hammers API)

### Polling for New Workouts
- [ ] **Poll every 10 seconds** (while idle)
  - ✅ Checks for new queued workout
  - ❌ Bug suspect: Polls constantly (drains battery in 1 hour)
  - ❌ Bug suspect: Doesn't poll at all
  - ❌ Bug suspect: API not called, just uses stale cache

- [ ] **Stop polling during workout**
  - ✅ Pauses polling while session active
  - ❌ Bug suspect: Still polls (wasted API calls)
  - ❌ Bug suspect: Never resumes polling after workout

---

## 3. Workout Display & Navigation

### Block Display
- [ ] **Generic workout display**
  - ✅ Shows list of blocks (not custom per-type in MVP)
  - ✅ Current block highlighted
  - ✅ Block index/total (e.g., "Block 2 of 4")
  - ❌ Bug suspect: Shows wrong block
  - ❌ Bug suspect: Doesn't highlight current
  - ❌ Bug suspect: Index off-by-one error

- [ ] **Block details**
  - ✅ Shows: type, target params (distance, duration, reps)
  - ✅ Readable on small watch screen
  - ❌ Bug suspect: Text too small (unreadable)
  - ❌ Bug suspect: Long block names truncated weirdly

### Manual Tap-to-Advance
- [ ] **Tap to next block**
  - ✅ Button/gesture advances to next block
  - ✅ Updates current block UI
  - ❌ Bug suspect: Double-tap skips a block
  - ❌ Bug suspect: Tap doesn't register (too fast/slow?)
  - ❌ Bug suspect: Can't go back to previous block

- [ ] **Last block handling**
  - ✅ Final tap shows "Workout Complete"
  - ❌ Bug suspect: Can tap beyond last block (crashes?)
  - ❌ Bug suspect: Doesn't show completion screen

---

## 4. Block Type Handling (MVP: Generic Display)

### All Block Types Supported
- [ ] Rest, Interval, Run, Cooldown
  - ✅ Displays type name
  - ✅ Shows target params
  - ✅ Renders without crashing
  - ❌ Bug suspect: Unknown block type crashes app
  - ❌ Bug suspect: Missing target_params field crashes parsing

### Target Params Display
- [ ] **Rest block** - Duration (seconds)
  - ✅ Shows: "Rest 120s"
  - ❌ Bug suspect: Duration in wrong units (milliseconds as seconds?)

- [ ] **Interval block** - Duration, reps
  - ✅ Shows: "Interval 30s x 8 reps"
  - ❌ Bug suspect: Missing reps shows "x undefined"

- [ ] **Run block** - Distance (km), pace target
  - ✅ Shows: "Run 5km @ 6:00/km"
  - ❌ Bug suspect: Distance shown as miles when metric expected
  - ❌ Bug suspect: Pace calculation wrong (shows 5:00 when 6:00)

- [ ] **Cooldown block** - Duration
  - ✅ Shows: "Cooldown 300s"
  - ❌ Bug suspect: Duration in wrong format

---

## 5. Timer/Stopwatch Functionality

### Session Timer
- [ ] **Start button**
  - ✅ Starts timer for current block
  - ✅ Records block start time
  - ❌ Bug suspect: Timer doesn't start
  - ❌ Bug suspect: Timer runs but doesn't record start_time

- [ ] **Running timer display**
  - ✅ Shows elapsed time (MM:SS)
  - ✅ Updates every second
  - ❌ Bug suspect: Timer counts wrong (off by 1 second)
  - ❌ Bug suspect: Timer freezes (stops updating)

- [ ] **Block duration tracking**
  - ✅ Records actual duration when advancing blocks
  - ✅ Stores in block_results array
  - ❌ Bug suspect: Duration not recorded
  - ❌ Bug suspect: Duration wildly wrong (negative time?)

---

## 6. Result Submission

### Result Capture
- [ ] **Block results structure**
  - ✅ Captures: block_index, actual_duration, block_type
  - ✅ JSON format matches API expectations
  - ❌ Bug suspect: block_index wrong (off-by-one)
  - ❌ Bug suspect: Duration in wrong units (ms vs seconds)
  - ❌ Bug suspect: Missing required fields

- [ ] **Session result collection**
  - ✅ Array of blocks with times
  - ❌ Bug suspect: Duplicate blocks in array
  - ❌ Bug suspect: Blocks out of order

### Submission to API
- [ ] **POST `/api/sessions/:id/results`**
  - ✅ Sends device token header
  - ✅ Sends block_results array
  - ✅ Handles 201 success response
  - ❌ Bug suspect: Uses wrong session ID
  - ❌ Bug suspect: Doesn't include device token
  - ❌ Bug suspect: JSON encoding wrong (string instead of array)

- [ ] **Error handling**
  - ✅ Network error: show "Try again" button
  - ✅ 401 error: redirect to reconnect screen
  - ✅ 404 error: "Session not found"
  - ❌ Bug suspect: Crashes on any error
  - ❌ Bug suspect: Loses result data on failed submission

### Offline Result Queue
- [ ] **No network at completion**
  - ✅ Stores result locally
  - ✅ Shows "Synced offline" message
  - ❌ Bug suspect: Result lost on app crash
  - ❌ Bug suspect: Stored but never synced (lost forever)

- [ ] **Retry on network restore**
  - ✅ Syncs queued results when network returns
  - ❌ Bug suspect: Doesn't retry (queue ignored)
  - ❌ Bug suspect: Retries too fast (hammers API)
  - ❌ Bug suspect: Deletes queue without syncing

---

## 7. Offline Mode & Caching

### Workout Caching
- [ ] **Cache last synced workout**
  - ✅ Stored locally after successful fetch
  - ✅ Used if no network available
  - ❌ Bug suspect: Cache not stored (always requires network)
  - ❌ Bug suspect: Cache corrupted (can't parse)

- [ ] **Cache invalidation**
  - ✅ Synced copy updated on each successful fetch
  - ❌ Bug suspect: Uses stale cache even after fetch
  - ❌ Bug suspect: Cache never updated

### Offline Execution
- [ ] **Run workout completely offline**
  - ✅ Display blocks from cache
  - ✅ Record times (stopwatch works)
  - ✅ Manual tap-to-advance works
  - ❌ Bug suspect: Timer doesn't work offline
  - ❌ Bug suspect: Can't complete workout without network

---

## 8. Battery & Performance

### Battery Usage
- [ ] **Idle polling** - Minimal drain
  - ❌ Bug suspect: Polling every 1 second (drains battery in hours)
  - ❌ Bug suspect: Doesn't pause polling (always on)

- [ ] **During workout** - Stopwatch running
  - ❌ Bug suspect: Continuous CPU usage (battery drain)
  - ❌ Bug suspect: GPS always on (even for non-run blocks)

- [ ] **Memory usage**
  - ❌ Bug suspect: Memory leak (app crashes after 10 workouts)
  - ❌ Bug suspect: Large workout data not cleaned up

### Performance
- [ ] **Fast screen transitions**
  - ❌ Bug suspect: 500ms lag between blocks (UX bad)
  - ❌ Bug suspect: Blocks sometimes don't render

- [ ] **Large workouts** (20+ blocks)
  - ❌ Bug suspect: App crashes or hangs
  - ❌ Bug suspect: Scroll performance poor

---

## 9. Hardware Integration

### GPS (Run Blocks Only)
- [ ] **GPS tracking**
  - ✅ Records distance while running
  - ✅ Updates pace calculation
  - ❌ Bug suspect: GPS doesn't enable (distance always 0)
  - ❌ Bug suspect: Distance wildly wrong (10km when actually 1km)

- [ ] **Auto-advance on distance**
  - ⚠️ **MVP doesn't have this - manual only**
  - Future: Auto-advance when Run block distance hit

### Heart Rate Monitor
- [ ] **HR display** (optional in MVP)
  - ⚠️ **Not required for MVP**
  - Future: Show current HR during blocks

### Screen
- [ ] **Screen stays on during workout**
  - ❌ Bug suspect: Screen times out after 30s (data loss)
  - ❌ Bug suspect: Can't read display in sunlight (too dim)

---

## 10. Edge Cases & Crash Scenarios

### Network Failures
- [ ] **Lose connection mid-workout**
  - ✅ App keeps running (doesn't crash)
  - ✅ Results queue locally
  - ❌ Bug suspect: App force closes
  - ❌ Bug suspect: Timer stops

- [ ] **Intermittent connectivity** (switching between WiFi/BLE)
  - ❌ Bug suspect: API calls fail (wrong endpoint)
  - ❌ Bug suspect: Results sent twice (duplicate)

### Unexpected Data
- [ ] **Malformed block** (missing target_params)
  - ❌ Bug suspect: App crashes parsing JSON
  - ❌ Bug suspect: Skips rendering that block

- [ ] **Huge block JSON** (10MB)
  - ❌ Bug suspect: Out of memory crash
  - ❌ Bug suspect: Takes 30 seconds to parse

- [ ] **Negative durations** (API sends -100)
  - ❌ Bug suspect: Displays "-100s" (confusing)
  - ❌ Bug suspect: Timer counts backwards

### Device-Specific
- [ ] **Multiple device registrations**
  - ❌ Bug suspect: Both devices get queued workout (race condition)
  - ❌ Bug suspect: Session created twice

- [ ] **App backgrounding**
  - ✅ Pause timer if app goes background
  - ❌ Bug suspect: Timer keeps running (battery waste)
  - ❌ Bug suspect: State lost when backgrounded

- [ ] **Device reboot during workout**
  - ✅ Can resume from offline cache
  - ❌ Bug suspect: Loses all progress (no persistence)

---

## 11. Security Issues (Likely Bugs)

- [ ] **Device token exposure**
  - ❌ Token stored unencrypted in app storage
  - ❌ Token sent in plain HTTP (not HTTPS)

- [ ] **Result data tampering**
  - ❌ Client-side result duration could be faked (app just records what watch says)
  - ❌ Not a bug per se, but security concern

- [ ] **Man-in-the-middle**
  - ❌ No certificate pinning (could intercept token)

---

## Test Execution Strategy

### 1. Garmin Simulator (Development)
```
- Install Garmin SDK
- Build hello-world
- Test device token auth
- Mock API responses
- Test offline caching
```

### 2. Real Device Testing (After MVP Complete)
```
- Test on actual Garmin watch (FR745, Fenix 6, etc)
- Real GPS tracking
- Battery drain measurement
- Network switching (WiFi → BLE)
- Actual QR scan (not simulated)
```

### 3. Automated Tests (Monkey C)
```
- Unit tests for timer logic
- Device token encryption
- Block parsing
- Result JSON formatting
```

---

## Known Risk Areas (Assume Bugs Here)

1. **Timer accuracy** - Off-by-one errors, clock drift
2. **Device token persistence** - Lost on app crash, not encrypted
3. **Network retry logic** - Hammers API or fails silently
4. **JSON parsing** - Crashes on malformed data
5. **Offline caching** - Cache corruption, never syncs
6. **Memory leaks** - App crashes after 10 workouts
7. **GPS integration** - Distance calculation way off
8. **Screen management** - Times out during workout
9. **Result submission** - Wrong session ID, duplicate sends
10. **Edge cases** - Negative durations, huge data, concurrent requests

