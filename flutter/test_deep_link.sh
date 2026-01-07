#!/bin/bash

# Test Deep Link Script for Simulator
# This script helps test deep links on iOS Simulator

echo "🔗 Testing Deep Link on iOS Simulator"
echo "======================================"
echo ""

# Check if simulator is booted
BOOTED=$(xcrun simctl list devices | grep "Booted" | head -1)
if [ -z "$BOOTED" ]; then
    echo "❌ No booted simulator found!"
    echo "Please boot a simulator first:"
    echo "  xcrun simctl boot <DEVICE_ID>"
    echo ""
    echo "Or run your app first:"
    echo "  flutter run"
    exit 1
fi

echo "✅ Found booted simulator"
echo ""

# Test deep link
DEEP_LINK="compostkaki://reset-password#type=recovery&access_token=test_token_123&refresh_token=test_refresh_456"

echo "📱 Opening deep link: $DEEP_LINK"
echo ""

xcrun simctl openurl booted "$DEEP_LINK"

echo ""
echo "✅ Deep link sent to simulator"
echo ""
echo "📋 What to check:"
echo "  1. App should open (or come to foreground)"
echo "  2. Check Flutter logs for: '🔗 [DEEP LINK] Processing deep link'"
echo "  3. App should navigate to reset password screen"
echo ""
echo "💡 To see logs, run in another terminal:"
echo "  flutter logs"
echo ""
echo "💡 To test with real tokens from email:"
echo "  1. Copy the hash part from email link (after #)"
echo "  2. Run: xcrun simctl openurl booted 'compostkaki://reset-password#<hash>'"

