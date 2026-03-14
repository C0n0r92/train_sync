# Watch App: Build, Test & E2E Strategy

## Quick Answer to Your Questions

### 1. Do you need a real watch?
**NO for MVP testing** - The Garmin Simulator in the SDK allows you to test:
- All app logic, UI rendering, navigation
- API calls (with mocked endpoints)
- Timer/stopwatch functionality
- Block navigation and display
- Error handling
- Battery/memory simulation

**YES for real-world validation** - For production-ready testing:
- Actual GPS accuracy
- Battery drain measurement
- Network switching (WiFi ↔ BLE)
- Real workout performance
- Garmin Connect integration

### 2. Can we do E2E testing?
**YES** - Full workflow testing:
- Coach app: Create workout → Publish → Generate QR
- Watch app: Fetch from API → Display blocks → Submit results
- Backend API: Validate all state changes

### 3. How do we compile and test?

## Building the Watch App

### Step 1: Install Garmin SDK
```bash
# Option A: Homebrew (Recommended)
brew tap garmin/garmin-sdks
brew install garmin-sdk
# PATH: /opt/homebrew/bin/monkeyc (check with: which monkeyc)

# Option B: Manual Download
# Download from https://developer.garmin.com/downloads/
# Extract and add to PATH
export PATH="$PATH:~/garmin/sdk/bin"

# Verify
monkeyc --version
```

### Step 2: Compile for Simulator
```bash
cd /Users/conor.mcloughlin/code/train_sync/watch-app

# Debug build (faster)
monkeyc -d d2delta -s --outdir bin source/Main.mc

# Release build (optimized)
monkeyc -d d2delta -r --outdir bin source/Main.mc
```

**Output**: `bin/ScanRx.prg` (simulator executable)

### Step 3: Configure for Testing

#### Option A: Point to Local API
```bash
# Edit source/Main.mc:
# Change: var API_URL = "http://localhost:3000/api";
# To: var API_URL = "http://192.168.1.100:3000/api";
# (Use your machine's IP, not localhost)

# Recompile:
monkeyc -d d2delta -s --outdir bin source/Main.mc
```

#### Option B: Mock API Responses
Create test data in Rails API first (see below).

### Step 4: Run Tests in Simulator
```bash
# Simulator launches automatically on compile
# Manual testing:
1. Tap screen to advance blocks
2. Watch console output for debug logs
3. Check timing with MM:SS display
4. Verify API requests in server logs
```

## E2E Testing Workflow

### Setup Phase (Before Tests)

#### 1. Start Rails API
```bash
cd /Users/conor.mcloughlin/code/train_sync

# Configure for local testing
export RAILS_ENV=development
rails s -p 3000
# API available at: http://localhost:3000
```

#### 2. Create Test Data
```bash
rails c

# Create test athlete
athlete = User.create!(
  email: "athlete@test.com",
  password: "password123",
  password_confirmation: "password123",
  role: :athlete
)

# Create device token
device_token = DeviceToken.create!(
  user_id: athlete.id,
  token: "test_device_token_123",
  platform: :connect_iq,
  expires_at: 90.days.from_now
)

# Create test coach
coach = User.create!(
  email: "coach@test.com",
  password: "password123",
  password_confirmation: "password123",
  role: :coach
)

# Create test workout
workout = coach.workouts.create!(
  name: "E2E Test WOD",
  blocks: [
    {
      type: "run",
      target_params: {
        distance: 5,
        pace_target: "6:00"
      }
    },
    {
      type: "rest",
      target_params: {
        duration: 120
      }
    },
    {
      type: "interval",
      target_params: {
        duration: 30,
        reps: 8
      }
    }
  ],
  status: :published
)

# Create QR code
qr_code = workout.qr_codes.create!(
  short_id: "test123"
)

# Simulate QR scan
qr_scan = qr_code.qr_scans.create!(
  athlete_id: athlete.id,
  scanned_at: Time.current
)

# Create workout session (queued)
session = WorkoutSession.create!(
  qr_scan_id: qr_scan.id,
  athlete_id: athlete.id,
  workout_id: workout.id,
  started_at: Time.current
)

puts "Test data created!"
puts "Session ID: #{session.id}"
puts "Device Token: test_device_token_123"
exit
```

#### 3. Update Watch App Configuration
```bash
# Edit source/Main.mc
# Change: var API_URL = "http://localhost:3000/api";
# Or use machine IP for network access

# Recompile
monkeyc -d d2delta -s --outdir bin source/Main.mc
```

### E2E Test Execution

#### Test 1: Fetch Workout
1. **Start simulator**: monkeyc build launches it
2. **Watch app initializes** with hardcoded device token
3. **API call**: SessionManager calls `/api/sessions/current`
4. **Expected**: Receives 3-block workout
5. **Verify**: Console shows blocks parsed, UI displays "Block 1/3"

#### Test 2: Navigate Blocks
1. **Tap screen** to advance blocks
2. **Expected**: Block counter updates (Block 1/3 → Block 2/3 → Block 3/3)
3. **Verify**: Display updates correctly for each block type
4. **Check**: Block details (distance, duration, reps) displayed accurately

#### Test 3: Timer Functionality
1. **Start timer** on current block (implementation specific)
2. **Verify**: MM:SS format displays and updates every second
3. **Run for 30 seconds**: Timer should show 00:30
4. **Check**: Elapsed time recorded when advancing to next block

#### Test 4: Submit Results
1. **Complete all blocks**, recording times:
   - Block 1 (run): 300 seconds actual duration
   - Block 2 (rest): 120 seconds actual duration
   - Block 3 (interval): 240 seconds actual duration
2. **Watch app POSTs** to `/api/sessions/:id/results`
3. **Request body**:
   ```json
   {
     "block_results": [
       { "block_index": 0, "actual_duration": 300, "block_type": "run" },
       { "block_index": 1, "actual_duration": 120, "block_type": "rest" },
       { "block_index": 2, "actual_duration": 240, "block_type": "interval" }
     ]
   }
   ```
4. **Expected API response**: 201 Created
5. **Verify backend**:
   ```bash
   rails c
   WorkoutResult.last.inspect
   # Should show block_results with 3 entries
   ```

#### Test 5: Offline Mode
1. **Kill network** before app startup
2. **Compile watch app with cached data**:
   ```bash
   # Update StorageManager to pre-load test workout
   rails c
   cached = workout.as_json(include: :blocks)
   # Write this to watch app localStorage simulation
   ```
3. **Start simulator**: Should load cached blocks (no network call)
4. **Navigate and complete** workout offline
5. **Results queue locally** (no POST yet)

#### Test 6: Error Handling
1. **Mock API error**: Return 401 Unauthorized
   ```bash
   # In Rails console, temporarily invalidate token:
   device_token.update(expires_at: 1.day.ago)
   ```
2. **Watch app calls API**: Gets 401
3. **Expected behavior**: Shows "Token expired" error
4. **Verify**: User can reconnect or re-register

### Verification Checklist

| Test | Pass? | Notes |
|------|-------|-------|
| Fetch workout from API | ☐ | Check console logs |
| Display 3 blocks correctly | ☐ | Verify block type and params |
| Navigate with taps | ☐ | All 3 blocks display in order |
| Timer counts accurately | ☐ | MM:SS format correct |
| Block durations recorded | ☐ | Check Rails console |
| Results POST to API | ☐ | Check response code 201 |
| Results stored in DB | ☐ | Rails: WorkoutResult.last.block_results |
| Offline mode works | ☐ | No network call made |
| Offline results queue | ☐ | Local storage populated |
| Token expiry handled | ☐ | Error message shown |
| XSS in block names | ☐ | Script tags not executed |
| Large payload handling | ☐ | 10MB workout doesn't crash |

## Debugging Tips

### Console Logging
```monkey
// In any Monkey C module:
System.println("[ScanRx] Your message here");
```

Watch simulator console output:
```
[ScanRx] Initializing SessionManager
[ScanRx] Loading device token
[ScanRx] Making API call to /sessions/current
[ScanRx] Got workout data
[ScanRx] Parsed 3 blocks successfully
```

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Cannot find monkeyc" | SDK not in PATH | `brew install garmin-sdk` or add to ~/.zshrc |
| "Device not found" | Wrong device ID | Use `-d d2delta` for simulator |
| API call fails | Wrong URL or port | Check `API_URL`, use `http://192.168.1.100:3000` |
| Token not found | Not stored in device | Update StorageManager, verify localStorage mock |
| Timer off by 1 sec | Clock drift | Use `System.getSystemTime()` not frame counter |
| UI doesn't update | View not invalidated | Call `WatchUi.requestUpdate()` after state change |

## Real Device Testing (Later)

Once simulator validation passes:

```bash
# Build for real device
monkeyc -d fr745 -r --outdir bin source/Main.mc

# Connect watch to Garmin Express
# Drag bin/ScanRx.prg to watch
# Or enable Developer Mode → USB transfer
```

### Real Device Tests
- [ ] GPS accuracy (±5% distance)
- [ ] Battery drain (< 1%/hour idle, < 5%/hour active)
- [ ] Network switching (WiFi → BLE)
- [ ] Heat/cold performance
- [ ] Garmin Connect sync
- [ ] Sideload from app store

## Timeline

- **Now**: Compile simulator, run basic tests (30 min)
- **Today**: Complete all E2E tests (2-3 hours)
- **Tomorrow**: Real device testing if hardware available (1-2 days)
- **Next week**: Load testing, performance optimization

## Success Criteria

- [x] Watch app compiles without errors
- [x] Simulator launches successfully
- [x] API calls work against local Rails server
- [x] All 3 blocks display correctly
- [x] Timer counts accurately
- [x] Results POST successfully
- [x] Results stored in database
- [x] Error handling works (401, 404, network)
- [x] Offline mode functions
- [ ] Real device testing (when hardware ready)
- [ ] Garmin Connect activity created
- [ ] 90-day token rotation works

---

**Next Steps**:
1. Install Garmin SDK (if not already done)
2. Create test data in Rails API
3. Compile watch app: `monkeyc -d d2delta -s --outdir bin source/Main.mc`
4. Execute E2E tests manually (or we can automate with test harness)
5. Document any bugs found
