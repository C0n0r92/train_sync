#!/bin/bash
#
# ScanRx Watch App Simulator Runner
# Starts the simulator and loads the compiled app
#

set -e

# Configuration
SDK_PATH="/Users/conor.mcloughlin/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
PROJECT_DIR="/Users/conor.mcloughlin/code/train_sync/watch-app"
PRG_FILE="$PROJECT_DIR/bin/ScanRx.prg"
DEVICE="${1:-fenix7}"  # Default to fenix7, or use first argument

# Check if app is compiled
if [ ! -f "$PRG_FILE" ]; then
    echo "ERROR: Compiled app not found at $PRG_FILE"
    echo "Run build.sh first:"
    echo "  $PROJECT_DIR/scripts/build.sh"
    exit 1
fi

# Check if simulator is already running
if pgrep -f "ConnectIQ.app/Contents/MacOS/simulator" > /dev/null; then
    echo "Simulator is already running"
else
    echo "Starting simulator..."
    open "$SDK_PATH/bin/ConnectIQ.app"
    sleep 3
fi

echo "Loading ScanRx into simulator (device: $DEVICE)..."
"$SDK_PATH/bin/monkeydo" "$PRG_FILE" "$DEVICE"

echo ""
echo "App loaded. Check simulator window."
