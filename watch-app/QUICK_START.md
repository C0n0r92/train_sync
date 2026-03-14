# Watch App E2E Testing: Quick Start Guide

## 5-Minute Setup

### Step 1: Terminal 1 - Start Rails API
```bash
cd /Users/conor.mcloughlin/code/train_sync

# Start server
rails s -p 3000

# You should see:
# => Booting Puma
# => Rails 7.x.x application starting in development
# => Listening on http://localhost:3000
```

### Step 2: Terminal 2 - Create Test Data
```bash
cd /Users/conor.mcloughlin/code/train_sync

# Run setup script
rails runner watch-app/scripts/setup_test_data.rb

# You should see:
# ✓ Created test athlete: athlete@test.com
# ✓ Created device token: test_device_token_123
# ✓ Created test coach: coach@test.com
# ✓ Created test workout: E2E Test WOD - 3 Blocks
# ✓ Created QR code: test123
# ✓ Created workout session (queued)
```

### Step 3: Check Garmin SDK
```bash
which monkeyc

# If found: /opt/homebrew/bin/monkeyc (or similar)
# If NOT found: Install with: brew install garmin-sdk
```

### Step 4: Terminal 3 - Compile Watch App
```bash
cd /Users/conor.mcloughlin/code/train_sync/watch-app

# Compile for simulator
monkeyc -d d2delta -s --outdir bin source/Main.mc

# Wait for:
# 🔨 Compiling...
# ✓ Build complete
# 🚀 Launching Garmin Simulator...
```

**Garmin Simulator will launch automatically!**

---

## What to Do in the Simulator

### Test 1: Verify Workout Loaded (30 seconds)
**Expected**: Watch shows "Block 1/3 - RUN" with distance and pace

```
Watch Screen:
┌─────────────────┐
│   Block 1/3     │
│   RUN           │
│  Distance: 5km  │
│  Pace: 6:00/km  │
│   TAP TO START  │
└─────────────────┘

Check Rails Console (Terminal 1):
- See "GET /api/sessions/current 200" log
- Device token in request headers
```

### Test 2: Navigate Blocks (1 minute)
**Action**: Tap screen 3 times to advance through all blocks

```
Tap 1:
Block 1 (Run) → Block 2 (Rest)

Tap 2:
Block 2 (Rest) → Block 3 (Interval)

Tap 3:
Block 3 (Interval) → "Workout Complete" screen
```

**Expected**: Each block displays with correct type and parameters

### Test 3: Timer (2 minutes)
**Action**: Start timer on each block, let it run

```
Block 1 (Run):
[START] → 00:01 → 00:02 → ... 00:30 [ADVANCE]

Block 2 (Rest):
[START] → 00:01 → 00:02 → ... 00:30 [ADVANCE]

Block 3 (Interval):
[START] → 00:01 → ... → 00:30 [ADVANCE]
```

**Expected**: Timer displays MM:SS format, increments every 1 second

### Test 4: Submit Results (30 seconds)
**Expected**: After last block, results POST to API

```
Rails Console Output (Terminal 1):
POST /api/sessions/123/results 201

Check Rails (Terminal 2):
rails c
WorkoutResult.last.block_results
# Should show:
# [
#   {"block_index"=>0, "actual_duration"=>30, "block_type"=>"run"},
#   {"block_index"=>1, "actual_duration"=>30, "block_type"=>"rest"},
#   {"block_index"=>2, "actual_duration"=>30, "block_type"=>"interval"}
# ]
```

---

## Debugging if Tests Fail

### Issue 1: "Cannot load API"
```
Watch Screen: ERROR: Network failure

Check:
1. Is Rails running? (Terminal 1)
   $ curl http://localhost:3000/api/sessions/current \
     -H "X-Device-Token: test_device_token_123"

   Expected: Should return session JSON

2. Check Rails logs for 401 errors
   If 401: device token wrong or expired
```

### Issue 2: "No blocks displayed"
```
Watch Screen: Empty or "Block 1/0"

Check:
1. Did test data create successfully?
   $ rails c
   $ Workout.last.blocks.size
   # Should be 3

2. Check device token is registered:
   $ DeviceToken.find_by(token: 'test_device_token_123')
   # Should exist
```

### Issue 3: "Timer off by 1 second"
```
Expected: 00:01 after 1 second
Actual: 00:00 after 1 second

This is a BUG! File it:
- Off-by-one in elapsed time calculation
- Check SessionManager line: elapsedSeconds += 1
```

### Issue 4: "Results not posted"
```
Expected: 201 response from POST
Actual: Error or no request

Check:
1. Is session ID correct?
   $ rails c
   $ WorkoutSession.last.id

2. Check block_results format:
   Should be array of objects with:
   - block_index (0, 1, 2)
   - actual_duration (seconds)
   - block_type (string)
```

---

## Full Test Coverage (5-10 minutes)

### Test Matrix

| Test | Steps | Expected | Status |
|------|-------|----------|--------|
| API fetch | Start app | GET /sessions/current succeeds | ☐ |
| Block 1 display | See screen | "RUN" with distance/pace | ☐ |
| Block 2 display | Tap once | "REST" with duration | ☐ |
| Block 3 display | Tap twice | "INTERVAL" with duration/reps | ☐ |
| Timer starts | Tap block | MM:SS format shows | ☐ |
| Timer increments | Wait 10s | Shows 00:10 | ☐ |
| Advance block | Tap screen | Next block displays | ☐ |
| Completion | Tap last | "Workout Complete" shown | ☐ |
| Results POST | Complete | 201 to API | ☐ |
| Results stored | Check DB | block_results saved | ☐ |
| Token in header | Check logs | X-Device-Token: test_* | ☐ |
| Error handling | Kill network | Graceful error message | ☐ |

---

## Advanced Testing (Optional)

### Offline Mode
```bash
# Kill network while app running
# Expected: Uses cached data

# In watch-app/source/StorageManager.mc:
# Ensure getCachedWorkout() returns data
```

### Large Payload (10 blocks)
```bash
# Create workout with 10 blocks:
rails c
workout.update!(blocks: [
  # ... 10 different block types
])

# Recompile and test
# Expected: Handles all 10 blocks without crash
```

### Token Expiry
```bash
# Expire device token:
rails c
DeviceToken.find_by(token: 'test_device_token_123')
  .update(expires_at: 1.day.ago)

# Restart app
# Expected: 401 error, "Token expired" message
```

### XSS in Block Names
```bash
# Create workout with XSS payload:
rails c
workout.update!(name: "<script>alert('xss')</script>")

# Restart app
# Expected: Script NOT executed, shown as text
```

---

## Next: Real Device (Optional)

Once simulator tests pass:

```bash
# Build for real device (FR745)
monkeyc -d fr745 -r --outdir bin source/Main.mc

# Connect watch to Garmin Express
# Drag bin/ScanRx.prg to watch
# Or USB transfer via Developer Mode

# Test on real device:
# [ ] GPS tracking accuracy
# [ ] Battery drain (< 1%/hour idle)
# [ ] Network switching (WiFi ↔ BLE)
# [ ] Temperature tolerance
# [ ] Garmin Connect sync
```

---

## Success! You've Validated E2E

✅ Coach app creates workout
✅ Watch app fetches from API
✅ Watch displays blocks correctly
✅ Watch submits results back
✅ API stores results in database
✅ Error handling works

**Ready for:** Real device testing, performance optimization, production deployment

---

**Time to complete all tests**: 10-15 minutes
**You'll find bugs like**: Off-by-one timer errors, missing headers, XSS issues, memory leaks with large data

Ready? Start with Terminal 1 above! 🚀
