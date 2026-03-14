#!/bin/bash
#
# ScanRx Watch App Build Script
# Compiles the Monkey C source code for the Garmin simulator
#

set -e

# Configuration
SDK_PATH="/Users/conor.mcloughlin/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
PROJECT_DIR="/Users/conor.mcloughlin/code/train_sync/watch-app"
KEY_FILE="$PROJECT_DIR/keys/developer_key.der"
OUTPUT_FILE="$PROJECT_DIR/bin/ScanRx.prg"
DEVICE="${1:-fenix7}"  # Default to fenix7, or use first argument

# Verify SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "ERROR: SDK not found at $SDK_PATH"
    exit 1
fi

# Verify key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Developer key not found at $KEY_FILE"
    echo "Generate one with:"
    echo "  cd $PROJECT_DIR/keys"
    echo "  openssl genpkey -algorithm RSA -out private_key.pem -outform PEM -pkeyopt rsa_keygen_bits:4096"
    echo "  openssl pkcs8 -topk8 -inform PEM -outform DER -in private_key.pem -out developer_key.der -nocrypt"
    exit 1
fi

# Create output directory
mkdir -p "$PROJECT_DIR/bin"

echo "Building ScanRx for device: $DEVICE"
echo "SDK: $SDK_PATH"
echo ""

# Run compiler
"$SDK_PATH/bin/monkeyc" \
    -d "$DEVICE" \
    -f "$PROJECT_DIR/monkey.jungle" \
    -o "$OUTPUT_FILE" \
    -y "$KEY_FILE"

echo ""
echo "BUILD SUCCESSFUL"
echo "Output: $OUTPUT_FILE"
echo ""
echo "To run in simulator:"
echo "  1. Start simulator: open '$SDK_PATH/bin/ConnectIQ.app'"
echo "  2. Load app: '$SDK_PATH/bin/monkeydo' '$OUTPUT_FILE' $DEVICE"
