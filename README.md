# ScanRx POC - Coach-to-Athlete Workout Distribution Platform

## Overview
ScanRx enables coaches to build workouts, generate QR codes, and distribute them to athletes via watch app. Athletes scan, execute on their Garmin watch, and results flow back for coach analytics.

**Phase 1 MVP**: 6-7 weeks (adjusted from initial 4-5 week estimate based on critical review)

## Architecture Stack
- **Backend**: Ruby on Rails 7+ API + PostgreSQL
- **Coach Web**: React 18+ (form-based builder for v1)
- **Watch App**: Monkey C + Garmin Connect IQ
- **Storage**: Local file storage for QR images (Cloudflare R2 deferred to Phase 2)
- **Authentication**: Devise (web), Device tokens (watch app), JWT (API)

## Core Data Models

### Users & Auth
- `User` (email, role: athlete|coach|admin, created_at)
- `DeviceToken` (athlete_id, token, platform: connect_iq, expires_at)

### Workouts & Distribution
- `Workout` (coach_id, name, blocks: JSONB, is_public, version: int, status: draft|published)
- `WorkoutBlock` (workout_id, position, type, target_params: JSONB)
- `QRCode` (id, workout_id, short_id, variant, expires_at)
- `QRScan` (id, qr_code_id, athlete_id, scanned_at)

### Execution & Results
- `WorkoutSession` (qr_scan_id, athlete_id, workout_id, started_at, completed_at)
- `WorkoutResult` (workout_session_id, block_results: JSONB, completed_at)

## Implementation Timeline (Realistic: 6-7 weeks)

### Week 1: Backend Foundation + Auth
- [ ] Initialize Rails 7 API project (PostgreSQL)
- [ ] User model (Devise) + coach/athlete roles
- [ ] Device token authentication + generation
- [ ] Workout & WorkoutBlock models + associations
- [ ] JWT token generation for API endpoints
- [ ] Password reset + account recovery
- [ ] Basic API endpoint structure

**Scope**: No email confirmation yet (magic links planned for v1.1)

### Week 2: API Completion + Coach Web Basics
- [ ] QR code generation (`rqrcode` gem)
- [ ] QRCode & QRScan models
- [ ] QR endpoint: `GET /api/qr/:short_id` (resolve to workout)
- [ ] Sessions API: `POST /api/sessions` (athlete scans QR)
- [ ] Results API: `POST /api/sessions/:id/results` (athlete uploads workout data)
- [ ] Dashboard endpoint: `GET /api/coaches/:id/dashboard` (analytics)
- [ ] React app: Signup/login for coaches + athletes
- [ ] React app: Form-based workout builder (3-4 block types: Rest, Interval, Run, Cooldown)
- [ ] React app: QR display + download
- [ ] React app: Basic dashboard (scan counts, completion metrics)

**Scope**: Form-based builder (no drag-drop v1), 3-4 block types only

### Week 3: Monkey C Watch App - Spike
- [ ] Garmin SDK setup + Monkey C hello world
- [ ] Device token authentication to ScanRx API
- [ ] Fetch queued workout: `GET /api/sessions/current`
- [ ] Basic workout display (text-only, fetch + cache)
- [ ] Manual tap-to-advance between blocks
- [ ] Session state management (offline cache)

**Scope**: Basic fetch + display, not full per-block UI yet

### Week 4: Watch App - Feature Complete for MVP
- [ ] Generic workout display template (dynamic content)
- [ ] 3-4 block types (Rest, Interval, Run, Cooldown)
- [ ] Manual advance for all blocks
- [ ] POST results back to API with block times
- [ ] Offline mode: queue results if no connectivity
- [ ] Error handling: clear messages for fetch failures

**Scope**: Generic UI (not custom per-block layouts), manual advance only

### Week 5: Integration & Real Device Testing
- [ ] End-to-end testing: Coach builds → QR scans → Watch executes → Results post
- [ ] Test on real Garmin device (not simulator-only)
- [ ] Bug fixes from real device feedback
- [ ] Load testing: 50+ concurrent result POSTs

### Week 6: Polish & Advanced Features
- [ ] Add block types 5-6 (more exercise options)
- [ ] GPS auto-advance for Run blocks
- [ ] Token refresh + expiry lifecycle
- [ ] Error monitoring setup (Sentry)
- [ ] Rate limiting on auth endpoints

### Week 7: Buffer & Store Submission
- [ ] Garmin Store application submission (2-4 week review)
- [ ] Bug fixes, edge cases
- [ ] Performance optimization
- [ ] Final testing & UAT

## Critical Technical Decisions

### QR Code Approach
- ✅ QR encodes: `scanrx.io/w/{short_id}` (short URL only)
- ✅ Workout UUID embedded server-side (allows updates after QR generation)
- ✅ Workout model includes `version` field (track iterations)
- ✅ Status: draft (editable) vs published (immutable)

### Device Token Lifecycle
- ✅ 90-day expiry
- ✅ Refresh on 401 response (not proactive 6-hour refresh)
- ✅ Revocation: Coach can invalidate athlete's token from web app
- ✅ Re-auth: Athlete re-scans QR on new device (generates new token)

### Watch App Authentication
- ✅ Device token stored in Garmin app storage (encrypted at rest where possible)
- ⚠️ **Risk**: Garmin storage is not encrypted. Documented as limitation.
- ✅ Fallback: Clear "reconnect" error message + re-scan flow

### Offline Mode
- ✅ Cache most recent synced workout locally
- ✅ Queue results if network unavailable at session start
- ✅ Sync on next network restore
- ⚠️ **UX**: Clear error messages (not silent failures)

### Scope Reductions (vs. initial plan)
- ❌ ~~Drag-drop workout builder~~ → Form-based v1
- ❌ ~~10 block types~~ → 3-4 block types v1 (expandable)
- ❌ ~~GPS auto-advance~~ → Manual advance v1 (Week 6 add-on)
- ❌ ~~Result sync to Garmin Connect~~ → Backend storage v1
- ❌ ~~Email confirmation~~ → Magic links (v1.1)
- ❌ ~~Sidekiq retry queue~~ → Synchronous + local queue (v1.1)
- ❌ ~~Cloudflare R2~~ → Local file storage (v2 migration)

## API Endpoints Summary

### Authentication
- `POST /api/auth/signup` - Create user (coach or athlete)
- `POST /api/auth/login` - Get JWT token
- `POST /api/auth/refresh` - Refresh JWT
- `POST /api/athletes/:id/devices` - Register device token

### Workouts (Coach)
- `POST /api/workouts` - Create workout
- `PATCH /api/workouts/:id` - Update workout (draft only)
- `POST /api/workouts/:id/publish` - Publish (immutable)
- `GET /api/workouts/:id` - Fetch workout details
- `POST /api/workouts/:id/qr` - Generate QR code

### QR & Sessions (Athlete)
- `GET /api/qr/:short_id` - Resolve QR → workout details
- `POST /api/sessions` - Start session (athlete scans QR, provides device token)
- `GET /api/sessions/current` - Fetch queued workout for device
- `POST /api/sessions/:id/results` - Submit completed workout results

### Dashboard (Coach)
- `GET /api/coaches/:id/dashboard` - Analytics (scans, starts, completions)

## Testing & Verification

### Backend Tests
- Unit: Workout, QRCode, DeviceToken validations
- Integration: Signup → Create workout → Generate QR → Scan → Queue session → Post results
- Load test: 50+ concurrent result POSTs

### Watch App Tests
- Simulator: Authenticate → Fetch → Display → Advance → Submit
- Real device: GPS tracking, battery, connectivity edge cases

### E2E Workflow
1. Coach creates "Tuesday WOD" (Run 5k → Interval 30s × 8 → Rest 2 min)
2. Publishes & generates QR
3. Athlete scans QR with phone
4. Device token registered, workout queued on API
5. Watch app fetches workout, displays blocks
6. Athlete completes workout (manual tap between blocks)
7. Results POST to API
8. Coach views dashboard: 1 scan, 1 start, 1 completion ✅

## Known Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Monkey C learning curve | Start tutorials Week 1 (parallel). Spike approach in Week 3. |
| Workout versioning bugs | Test draft/published state transitions thoroughly. |
| Device token expiry breaks re-auth | Clear error UX, re-scan flow, test device loss scenario. |
| Watch app memory constraints | Start with 3-4 blocks, test on device, profile memory. |
| Offline sync race conditions | Queue-based approach with idempotent POST (session_id as key). |
| Garmin Store approval delays | Use sideload for beta testing. Don't depend on Store for MVP launch. |

## Deployment & Environment Setup

### Development
- Rails: `localhost:3000`
- React: `localhost:3001` (proxy to API)
- Garmin Simulator: Local SDK

### Staging
- API: Heroku/Fly.io
- React: Netlify/Vercel
- Watch app: Sideload via Garmin Connect IQ app

### Production
- Defer to Phase 2
- Cloudflare R2 for QR images
- APM: Sentry for error tracking

## Next Steps
1. Initialize Rails 7 API project ✅
2. Create User, Workout, WorkoutBlock models
3. Implement Devise + JWT auth
4. Build QR generation endpoint
5. Deploy to staging for Week 1 testing

---

**Started**: 2026-03-14
**Phase 1 Target Completion**: 2026-05-09 (6 weeks from start)
**Last Updated**: Implementation in progress
