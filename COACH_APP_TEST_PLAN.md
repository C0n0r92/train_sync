# React Coach App - Test Plan

Based on PRD requirements. Tests should assume code has bugs.

---

## 1. Authentication & User Management

### Signup Flow
- [ ] **Coach signup** - Email, password, confirm password, role=coach
  - ✅ Form validates email format
  - ❌ Edge case: Password with special chars (might not escape)
  - ❌ Edge case: Very long email (might break API)
  - ❌ State management: Does signup clear login form state?

- [ ] **Login** - Email & password
  - ✅ Stores JWT token in localStorage
  - ❌ Edge case: Token expires during session (refresh needed?)
  - ❌ Edge case: Multiple login attempts (does it debounce?)
  - ❌ Bug suspect: localStorage might not be cleared on logout

- [ ] **Logout** - Clears token & redirects to login
  - ❌ Does it clear localStorage?
  - ❌ Does it clear in-memory state?
  - ❌ Does it redirect immediately or after API call?

- [ ] **Persistent login** - Token survives page refresh
  - ❌ Bug suspect: Token might not be restored from localStorage on mount
  - ❌ Edge case: Expired token on page load (should redirect to login)

---

## 2. Workout Builder

### Create Workout
- [ ] **Form elements**
  - ✅ Name input field
  - ❌ Bug suspect: No validation on empty name
  - ❌ Bug suspect: Very long names (>255 chars) might break

- [ ] **Block management** (form-based, not drag-drop)
  - ✅ "Add Block" button
  - ✅ Block type dropdown (Rest, Interval, Run, Cooldown)
  - ✅ Target params per block type (duration, distance, reps, etc)
  - ❌ Bug suspect: Can add 0 blocks (creates invalid workout)
  - ❌ Bug suspect: Duplicate block IDs
  - ❌ Edge case: 100+ blocks (memory leak?)

- [ ] **Block editing**
  - ✅ Edit block params in place
  - ❌ Bug suspect: Doesn't persist edits to local state
  - ❌ Edge case: Delete all blocks (should warn user)
  - ❌ Bug suspect: Block order randomized after edit?

- [ ] **Save workout**
  - ✅ POST to `/api/workouts`
  - ✅ Creates as draft status
  - ✅ Sets version=1
  - ❌ Bug suspect: Doesn't validate blocks before saving
  - ❌ Bug suspect: Doesn't show success message
  - ❌ Bug suspect: Doesn't handle API errors gracefully

### Edit Workout (Draft Only)
- [ ] **Load draft** - PATCH `/api/workouts/:id`
  - ❌ Bug suspect: Published workouts might be editable
  - ❌ Bug suspect: Other coach's workouts might be editable

- [ ] **Update blocks**
  - ✅ Add/remove/edit blocks
  - ✅ Updates version
  - ❌ Bug suspect: Doesn't prevent edit of published workout
  - ❌ Bug suspect: Duplicate block IDs on re-add

### Publish Workout
- [ ] **Publish button**
  - ✅ Visible on draft workouts only
  - ❌ Bug suspect: Visible on published workouts too (should disable)
  - ❌ Bug suspect: Published with 0 blocks (API should reject but FE should prevent)

- [ ] **Publish validation**
  - ✅ Requires at least 1 block
  - ✅ POST `/api/workouts/:id/publish`
  - ❌ Bug suspect: No visual feedback during publish
  - ❌ Bug suspect: Doesn't disable button during API call (can double-click)

- [ ] **Post-publish state**
  - ✅ Status changes to published
  - ✅ Can't edit anymore
  - ✅ QR generation button appears
  - ❌ Bug suspect: Edit button still clickable
  - ❌ Bug suspect: Doesn't refresh UI with new status

---

## 3. QR Code Generation & Distribution

### Generate QR
- [ ] **QR generation button**
  - ✅ Only visible on published workouts
  - ❌ Bug suspect: Visible on draft workouts
  - ❌ Bug suspect: Multiple clicks might create multiple QRs

- [ ] **POST `/api/workouts/:id/qr`**
  - ✅ Sends variant (default: public)
  - ✅ Stores short_id from response
  - ❌ Bug suspect: Doesn't handle API errors (invalid workout, etc)
  - ❌ Bug suspect: Doesn't debounce/disable button during request

### Display QR
- [ ] **QR image display**
  - ✅ Shows QR code image from API response
  - ✅ Shows short URL (localhost:3000/qr/{short_id})
  - ❌ Bug suspect: URL wrong format (might have trailing slash or protocol issue)
  - ❌ Bug suspect: Image doesn't load (CORS issue?)

- [ ] **Copy to clipboard**
  - ✅ Button copies short URL to clipboard
  - ✅ Shows "Copied!" confirmation
  - ❌ Bug suspect: Doesn't work in some browsers (missing polyfill?)
  - ❌ Bug suspect: Confirmation text persists forever (should fade)

- [ ] **Download QR**
  - ✅ Downloads QR as PNG/SVG
  - ❌ Bug suspect: Wrong filename (includes slashes?)
  - ❌ Bug suspect: File format wrong (claims PNG but is SVG?)
  - ❌ Bug suspect: Image quality issues

- [ ] **Multiple QRs per workout**
  - ✅ Can generate multiple QRs
  - ❌ Bug suspect: Shows only latest QR (should show all)
  - ❌ Bug suspect: Old QRs expire but UI doesn't reflect it

---

## 4. Dashboard

### Workout List
- [ ] **Display workouts**
  - ✅ Lists all coach's workouts (paginated?)
  - ✅ Shows: name, status (draft/published), last updated
  - ❌ Bug suspect: Shows other coaches' workouts
  - ❌ Bug suspect: Doesn't handle 100+ workouts (performance?)

- [ ] **Workout stats**
  - ✅ Scan count - total QRScans
  - ✅ Started count - WorkoutSessions with started_at
  - ✅ Completed count - WorkoutSessions with completed_at
  - ❌ Bug suspect: Stats don't update in real-time
  - ❌ Bug suspect: Stats include deleted sessions

- [ ] **Sort/filter**
  - ✅ Sort by: newest, alphabetical, most scanned
  - ❌ Bug suspect: Filter doesn't work (always shows all)
  - ❌ Bug suspect: Sort doesn't persist on refresh

### Workout Details View
- [ ] **Click workout**
  - ✅ Shows full details: blocks, stats, QRs
  - ✅ Edit button (if draft)
  - ✅ Publish button (if draft)
  - ❌ Bug suspect: Doesn't show QR codes
  - ❌ Bug suspect: Can edit published workout

- [ ] **Real-time stats**
  - ✅ Shows last scan time
  - ✅ Shows last completion time
  - ❌ Bug suspect: Data is stale (doesn't refetch)
  - ❌ Bug suspect: Timestamps wrong format/timezone

---

## 5. Error Handling & Edge Cases

### API Error Handling
- [ ] **Network errors**
  - ❌ Bug suspect: No error message displayed
  - ❌ Bug suspect: App crashes instead of showing error
  - ❌ Bug suspect: Doesn't retry failed requests

- [ ] **401 Unauthorized**
  - ✅ Redirects to login
  - ❌ Bug suspect: Doesn't clear localStorage
  - ❌ Bug suspect: Doesn't show "session expired" message

- [ ] **403 Forbidden** (editing another's workout)
  - ✅ Shows error message
  - ❌ Bug suspect: Doesn't prevent edit form submission
  - ❌ Bug suspect: Error message is generic "Unauthorized"

- [ ] **422 Unprocessable**
  - ✅ Shows field-level validation errors
  - ❌ Bug suspect: Generic "Error occurred" message
  - ❌ Bug suspect: Doesn't highlight failed fields

### Form Edge Cases
- [ ] **XSS injection** (name field)
  - ❌ Bug suspect: HTML injected into name displays unescaped
  - ❌ Bug suspect: Script tags in name execute

- [ ] **Long inputs**
  - ❌ Bug suspect: 10MB block JSON breaks app
  - ❌ Bug suspect: 1000-char name breaks UI layout

- [ ] **Rapid clicks**
  - ❌ Bug suspect: Double-clicking "Publish" creates duplicate
  - ❌ Bug suspect: Multiple "Add Block" clicks create dupes

- [ ] **Concurrent edits**
  - ❌ Bug suspect: Edit in one tab, refresh in another - state inconsistent
  - ❌ Bug suspect: Version conflict not handled

---

## 6. Navigation & Routing

- [ ] **Routes exist**
  - ✅ `/login` - Login page
  - ✅ `/signup` - Signup page
  - ✅ `/workouts` - Dashboard (list)
  - ✅ `/workouts/new` - Create
  - ✅ `/workouts/:id` - Detail view
  - ✅ `/workouts/:id/edit` - Edit (if draft)

- [ ] **Protected routes**
  - ❌ Bug suspect: `/workouts` accessible without login
  - ❌ Bug suspect: Can navigate directly to `/workouts/999` (404 handling?)

- [ ] **Redirect logic**
  - ✅ Logged-in user sees `/workouts`, not `/login`
  - ❌ Bug suspect: Logs out but stays on dashboard
  - ❌ Bug suspect: Infinite redirect loop somewhere

---

## 7. UI/UX Issues (Likely Bugs)

- [ ] **Loading states**
  - ❌ Button says "Save" while loading (should say "Saving...")
  - ❌ No loading spinner while fetching data
  - ❌ User can click button multiple times while loading

- [ ] **Responsive design**
  - ❌ Layout breaks on mobile (blocks stack weirdly)
  - ❌ QR image too large on small screens

- [ ] **Accessibility**
  - ❌ Form labels not associated with inputs
  - ❌ Error messages not announced to screen readers

- [ ] **Data persistence**
  - ❌ Create form clears on page refresh (should warn user)
  - ❌ Unsaved changes not detected (should show warning)

---

## Test Execution Strategy

1. **Manual testing first** (smoke tests)
   - Create account
   - Build workout
   - Publish
   - Generate QR
   - View dashboard

2. **Jest unit tests**
   - Component rendering
   - Form validation
   - State management

3. **React Testing Library** (integration tests)
   - User workflows
   - API mocking with MSW
   - Error scenarios

4. **Cypress e2e tests** (if time)
   - Full workflow: signup → create → publish → view
   - Real API integration

---

## Known Risk Areas (Assume Bugs Here)

1. **Token persistence** - localStorage quirks with different browsers
2. **Form state** - React state management bugs with multiple edits
3. **API error handling** - Generic error messages, no retry logic
4. **Race conditions** - Double-click publish, concurrent edits
5. **XSS/Security** - HTML escaping in form inputs
6. **Responsive design** - Mobile layout broken
7. **Accessibility** - ARIA labels missing

