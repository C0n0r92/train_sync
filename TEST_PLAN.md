# ScanRx Week 2 API Test Plan

Based on PRD requirements, this document defines test cases for each API endpoint. Tests assume potential bugs and validate behavior, not just code correctness.

---

## 1. Authentication Endpoints

### POST /api/auth/signup
**Purpose**: Create new coach or athlete account

#### Test Cases
1. ✅ Valid coach signup - email, password, password confirmation, role=coach
2. ✅ Valid athlete signup - email, password, password confirmation, role=athlete
3. ❌ Missing email - should fail
4. ❌ Missing password - should fail
5. ❌ Password mismatch (password != password_confirmation) - should fail
6. ❌ Duplicate email - should fail (uniqueness)
7. ❌ Invalid email format - should reject (e.g., "notanemail")
8. ❌ Weak password - consider minimum strength
9. ❌ Missing role - should default or fail
10. ✅ Response includes JWT token (if configured)

---

## 2. Workout Management

### POST /api/workouts (Create)
**Purpose**: Coach creates new workout

#### Test Cases
1. ✅ Valid workout: name, blocks (empty array for draft), status=draft
2. ✅ Workout creates with version=1
3. ✅ Workout associates with authenticated coach
4. ❌ Missing name - should fail
5. ❌ Empty name - should fail
6. ❌ Unauthenticated request - should fail with 401
7. ❌ Non-coach user tries to create - should fail
8. ✅ Multiple workouts per coach - allowed
9. ✅ Blocks can be empty on creation (draft state)
10. ✅ is_public defaults to false

### PATCH /api/workouts/:id (Update)
**Purpose**: Coach updates draft workout

#### Test Cases
1. ✅ Update draft workout - name, blocks - should succeed
2. ✅ Version increments on update
3. ❌ Update published workout - should fail (immutable)
4. ❌ Non-owner coach updates another's workout - should fail
5. ❌ Athlete tries to update - should fail
6. ✅ Update blocks with valid exercise data
7. ❌ Invalid blocks JSON - should fail
8. ✅ Empty blocks allowed in draft

### POST /api/workouts/:id/publish
**Purpose**: Coach publishes workout (immutable)

#### Test Cases
1. ✅ Publish draft workout - status changes to published
2. ❌ Publish already-published workout - should fail
3. ❌ Publish with empty blocks - should fail (published = complete)
4. ✅ Published workout cannot be edited
5. ❌ Non-owner cannot publish
6. ✅ Published timestamp recorded

### GET /api/workouts/:id
**Purpose**: Fetch workout details

#### Test Cases
1. ✅ Coach can fetch own workout
2. ✅ Athlete can fetch published workout
3. ✅ Non-owner cannot fetch draft workout (privacy)
4. ✅ Public workouts visible to all

---

## 3. QR Code Management

### POST /api/workouts/:id/qr (Generate)
**Purpose**: Create QR code for workout

#### Test Cases
1. ✅ Generate QR for published workout - creates short_id
2. ✅ short_id is unique
3. ✅ short_id is URL-safe (alphanumeric)
4. ❌ Generate QR for draft workout - should fail
5. ❌ Generate QR for unpublished workout - should fail
6. ✅ QR encodes: `scanrx.io/w/{short_id}` (or localhost in dev)
7. ✅ Multiple QRs per workout allowed
8. ✅ Can set variant: public, squad, single_use
9. ✅ Can set expiry_at for single_use QRs
10. ✅ Default variant is public
11. ❌ Non-owner cannot generate QR
12. ✅ QR code persists in database

### GET /api/qr/:short_id (Resolve)
**Purpose**: Resolve QR to workout (athlete initial scan)

#### Test Cases
1. ✅ Valid short_id returns workout details
2. ❌ Invalid short_id returns 404
3. ✅ Expired QR returns error or 404
4. ✅ Single_use QR can only be scanned once (edge case: concurrent scans?)
5. ✅ Returns full workout structure (name, blocks, etc.)
6. ✅ Public endpoint - no auth required
7. ✅ Response includes QR code ID for session tracking
8. ❌ Malformed short_id rejects gracefully

---

## 4. Session Management

### POST /api/sessions (Start Session)
**Purpose**: Athlete scans QR, registers device, starts session

#### Test Cases
1. ✅ Valid scan: qr_code_id, athlete_id (or device_token), device_token
2. ✅ Creates QRScan record with scanned_at
3. ✅ Creates WorkoutSession record (pending state)
4. ✅ Device token registered (DeviceToken created)
5. ✅ Device token has 90-day expiry
6. ❌ Expired QR - should fail
7. ❌ Single_use QR scanned twice - second should fail
8. ❌ Missing device_token - should fail
9. ❌ Invalid QR code - should fail
10. ✅ Multiple sessions per athlete allowed
11. ✅ Session includes queue of blocks from workout
12. ❌ Same athlete + QR twice - separate sessions or block?
13. ✅ Returns session_id for result submission

### GET /api/sessions/current (Fetch Queued Workout)
**Purpose**: Watch app polls for queued workout

#### Test Cases
1. ✅ Device token auth - validates token
2. ✅ Returns latest queued WorkoutSession
3. ✅ Includes full workout blocks
4. ❌ Expired device token - returns 401
5. ❌ Invalid device token - returns 401
6. ✅ Null if no queued session
7. ✅ Workout cached for offline mode
8. ✅ Returns session_id for results

---

## 5. Results Submission

### POST /api/sessions/:id/results (Submit Results)
**Purpose**: Watch app submits completed workout results

#### Test Cases
1. ✅ Valid results: session_id, block_results (array of block times/data)
2. ✅ Creates WorkoutResult record
3. ✅ Marks WorkoutSession as completed (completed_at = now)
4. ✅ Device token auth - validates token
5. ❌ Expired device token - fails
6. ❌ Invalid session_id - fails
7. ❌ Missing block_results - fails
8. ❌ Malformed block_results JSON - fails
9. ✅ Idempotent - same submission twice shouldn't double-count
10. ✅ Results stored in block_results JSONB (flexible format)
11. ✅ Completion timestamp recorded
12. ✅ Multiple result submissions from same session handled gracefully
13. ❌ Attempt to submit results for non-existent session - fails

---

## 6. Dashboard Analytics

### GET /api/coaches/:id/dashboard
**Purpose**: Coach views workout analytics

#### Test Cases
1. ✅ Coach can fetch own dashboard
2. ❌ Coach cannot fetch other coach's dashboard
3. ❌ Athlete cannot fetch coach dashboard
4. ✅ Returns list of workouts with stats:
   - scan_count (total QRScans)
   - started_count (WorkoutSessions with started_at)
   - completed_count (WorkoutSessions with completed_at)
5. ✅ Stats grouped by workout_id
6. ✅ Timestamps included (last scan, last completion)
7. ✅ Pagination or limit support (doesn't load 1000+ workouts)
8. ✅ Empty list if no workouts
9. ❌ Invalid coach_id - returns 404

---

## 7. Cross-Cutting Concerns

### Authentication & Authorization
- [ ] Unauthenticated requests to protected endpoints return 401
- [ ] Wrong user type (athlete vs coach) returns 403
- [ ] Device token validation works
- [ ] JWT tokens have reasonable expiry

### Data Validation
- [ ] All inputs sanitized (no SQL injection, XSS)
- [ ] Timestamps always in UTC
- [ ] JSONB data properly escaped

### Edge Cases
- [ ] Concurrent result submissions (race condition?)
- [ ] Single_use QR + concurrent scans (race condition?)
- [ ] Device token refresh near expiry
- [ ] Null/missing optional fields handled gracefully
- [ ] Very large block_results payload (10MB?)
- [ ] Very long workout (100 blocks?)

### Error Responses
- [ ] All 4xx/5xx responses include error message
- [ ] Validation errors include field details
- [ ] 404s vs 403s properly distinguished
- [ ] No stack traces in production errors

---

## Test Execution Strategy

1. **Unit Tests** (RSpec)
   - Model validations
   - Associations
   - Enums
   - Scopes

2. **Request/Integration Tests** (RSpec request specs)
   - Full HTTP request/response cycle
   - Auth flows
   - Create → Update → Publish → QR → Scan → Results flow
   - Error cases

3. **Edge Cases & Fuzzing**
   - Concurrent requests
   - Race conditions
   - Malformed input
   - Boundary values

4. **Coverage Target**
   - Minimum 80% code coverage
   - 100% of critical paths (auth, results submission)

---

## Known Risk Areas (Assume Bugs Here)

1. **QR Code Single-Use**: Multi-athlete simultaneous scans - race condition?
2. **Device Token Expiry**: Refresh logic might not work at boundaries
3. **Results Idempotency**: How do we prevent duplicate results?
4. **Timezone Handling**: Timestamps in different zones might cause issues
5. **Concurrent Updates**: What if coach publishes while athlete is downloading?
6. **JSON Storage**: JSONB columns might not be properly indexed/queried
7. **Foreign Key Cascades**: Are deleted records cascading correctly?
8. **CORS**: Will watch app API calls work cross-origin?

---

End of Test Plan
