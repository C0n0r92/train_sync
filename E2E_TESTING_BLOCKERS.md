# E2E Watch App Testing: Compilation Blockers & Status

**Date**: 2026-03-14
**Status**: 🟡 **BLOCKED** - Infrastructure ready, compilation failing

---

## What's Working ✅

### Infrastructure
- ✅ Rails API running on localhost:3000
- ✅ Test data created (athlete, coach, 3-block workout)
- ✅ Garmin Connect IQ Simulator running (PID: 34112)
- ✅ Simulator responsive (shell connected, device id: 2462812303)
- ✅ Java OpenJDK 17 installed and working
- ✅ SDK 9.1.0 installed with API database

### Watch App Code
- ✅ 5 Monkey C modules syntactically valid
- ✅ Manifest.xml properly configured
- ✅ API_URL pointing to localhost:3000
- ✅ All classes and methods defined

---

## Blockers 🚫

### 1. SDK 1.1.0 (GitHub Archive)
**Issue**: Exit code 102 with no error output
**Attempts**:
- Direct compilation with manifest
- With devices.xml specified
- With API database specified
- With and without device ID flag
- With warnings enabled

**Root Cause**: SDK 1.1.0 appears incompatible with current Java/macOS setup. Silent exit code 102 suggests internal JVM error or missing dependency.

**Status**: **DEAD END** - Cannot debug without error messages

### 2. SDK 9.1.0 (Official from SDK Manager)
**Issue**: Compilation requires valid private key signing, rejects generated RSA keys

**What Happens**:
```bash
$ monkeyc -m manifest.xml -o bin/ScanRx.prg -y ~/.Garmin/ConnectIQ/keys/dev.pkcs8.key source/Main.mc
ERROR: Unable to load private key: java.security.InvalidKeyException: invalid key format
Exit: 101
```

**Key Generation Attempts**:
1. ✅ Generated RSA 2048-bit key with `openssl genrsa`
2. ✅ Converted to PKCS8 format with `openssl pkcs8`
3. ❌ Java KeyStore rejects both formats

**Why This Happens**:
- SDK 9.1.0 uses Java's internal key loader
- Requires specific key format (likely DER-encoded)
- No documentation on exact format expected
- Can't compile sample apps either (same error)

**Status**: **PARTIALLY SOLVABLE** - Need correct key format or alternative signing method

---

## Attempted Workarounds

### 1. Compile Without Signing
❌ **Failed** - SDK 9.1.0 always requires `-y` flag
- No development/debug mode available
- No bypass for simulator-only builds

### 2. Use Older SDK
❌ **Failed** - SDK 1.1.0 doesn't compile (exit code 102)
- Multiple attempts with different flag combinations
- Same silent failure every time

### 3. Pre-built Sample Apps
❌ **Failed** - Same key format error even with official samples

---

## Possible Solutions

### A. Generate Correct Key Format (Most Likely)
**Effort**: 1-2 hours

Garmin's SDK expects keys in specific format. Options:
1. Use Garmin's official key generation tool (if exists)
2. Generate key via ConnectIQ.app GUI (hidden in SDK)
3. Use Java keytool to generate in correct format
4. Find example key from Garmin documentation

```bash
# Worth trying:
keytool -genkeypair -alias dev -keystore dev.jks -keyalg RSA -keysize 2048
monkeyc ... -y dev.jks
```

### B. Contact Garmin Developer Support
**Effort**: 1-3 days

File issue explaining SDK 9.1.0 key format rejection. May have:
- Alternative signing method
- Unsigned simulator builds
- Known working key examples

### C. Downgrade SDK to Version That Works
**Effort**: 2-4 hours

Find a known-working monkeyc version (before v9.1.0):
- Try v6.x, v7.x, v8.x from Garmin archives
- May have different key requirements
- Risk: May not support newer Garmin devices

### D. Use Official ConnectIQ IDE (VS Code Extension)
**Effort**: 30 minutes

Garmin provides Monkey C extension for VS Code that handles compilation:
- Automatically manages keys
- Simulator integration built-in
- May bypass manual compilation issues

Install from VS Code Marketplace: "Monkey C" by Garmin

### E. Docker Container with Pre-configured SDK
**Effort**: 2-3 hours

Use official Garmin Docker images with working SDK:
- All tools pre-configured
- Keys pre-generated
- No local environment issues

---

## Current Recommendation

**Try Solution D (VS Code Extension) First** - Quickest path:

1. Install VS Code (if not already)
2. Add Monkey C extension by Garmin
3. Open watch-app project
4. Extension handles key management automatically
5. Build → Run in Simulator

**If that fails**, try Solution A (keytool):

```bash
# Generate key in Java format
keytool -genkeypair -alias scanrx-dev -keystore ~/.Garmin/scanrx.jks \
  -keyalg RSA -keysize 2048 -storepass password123 -keypass password123 \
  -dname "CN=ScanRx,O=Dev,C=US"

# Try compiling
monkeyc ... -y ~/.Garmin/scanrx.jks
```

---

## What Simulator Can Already Do (Waiting)

Once compilation works, E2E testing will verify:

| Test | Expected |
|------|----------|
| API fetch | GET /sessions/current returns workout ✅ |
| Block display | Shows 3 blocks (Run, Rest, Interval) |
| Navigation | Tap advances through blocks |
| Timer | MM:SS format increments correctly |
| Results POST | 201 response to /sessions/1/results |
| Database | block_results stored in WorkoutResult |

---

## Timeline Impact

- ✅ **API & Data**: Ready now (no blocking)
- ❌ **Watch Compilation**: Blocked on key format
- 🟡 **E2E Testing**: Can't run until compilation fixed
- 🟡 **Real Device**: Can test without compilation once app loads

---

## Technical Debt

1. **No .gitignore for SDK**: `~/.Garmin/` should be excluded
2. **No key management**: Need documented key generation for team
3. **Manifest outdated**: Should use newer format for v9.1.0+
4. **No fallback plan**: Only one compilation path attempted

---

**Next Action**: Try VS Code extension (Solution D) or keytool generation (Solution A).
**Blocker Level**: Medium (infrastructure works, compilation blocked)
**Estimated Time to Resolution**: 30 minutes to 3 hours depending on solution chosen.
