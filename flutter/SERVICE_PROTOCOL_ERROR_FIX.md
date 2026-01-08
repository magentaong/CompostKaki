# Fix: Flutter Service Protocol Connection Error

## Error Message
```
Error connecting to the service protocol: failed to connect to
http://127.0.0.1:49871/5mS4iRfAsbY=/ HttpException: Connection closed before full
header was received, uri = http://127.0.0.1:49871/5mS4iRfAsbY=/ws
```

## What This Means
This error occurs when the Flutter debug service connection is interrupted. The Dart VM service protocol is used for debugging, hot reload, and development tools.

## Quick Fixes (Try in Order)

### 1. Stop and Restart the App
- **In VS Code/Android Studio**: Stop the debug session (click the stop button)
- **In Terminal**: Press `Ctrl+C` to stop the running app
- Restart the app with `flutter run`

### 2. Restart Flutter Daemon
```bash
cd flutter
flutter pub get
flutter run
```

### 3. Clean and Rebuild
```bash
cd flutter
flutter clean
flutter pub get
flutter run
```

### 4. Kill All Flutter Processes
```bash
# Kill all Flutter/Dart processes
pkill -f flutter
pkill -f dart

# Then restart
cd flutter
flutter run
```

### 5. Restart Your IDE
- Close VS Code/Android Studio completely
- Reopen the project
- Run the app again

### 6. Check for Port Conflicts
```bash
# Check if port 49871 (or similar) is in use
lsof -i :49871

# If something is using it, kill it
kill -9 <PID>
```

## Prevention Tips

1. **Always stop the app properly** before closing your IDE
2. **Don't force-quit the IDE** while debugging
3. **Use `flutter run` in terminal** if IDE debugging is unreliable
4. **Restart Flutter daemon** if you see connection issues:
   ```bash
   flutter pub get
   ```

## If Problem Persists

1. **Check Flutter version**:
   ```bash
   flutter --version
   flutter upgrade
   ```

2. **Verify device connection**:
   ```bash
   flutter devices
   ```

3. **Run in release mode** (to bypass debug service):
   ```bash
   flutter run --release
   ```

4. **Check for firewall/antivirus** blocking localhost connections

## Common Causes

- App crashed during debugging
- IDE was closed while app was running
- Network/firewall blocking localhost connections
- Multiple Flutter processes running simultaneously
- Corrupted build cache

## iOS Device-Specific Issue

If you see this error **after the app successfully launches** (like in your case):
- ✅ App builds and installs successfully
- ✅ App initializes (you see logs like "Supabase init completed")
- ❌ Then service protocol connection fails

**This is a known iOS debugging issue.** The app is still running fine, but:
- Hot reload won't work
- Debugging features won't work
- The app itself functions normally

### iOS-Specific Solutions

1. **Use `flutter run` with explicit device**:
   ```bash
   flutter devices  # List available devices
   flutter run -d <device-id>  # Run on specific device
   ```

2. **Try profile mode** (more stable than debug):
   ```bash
   flutter run --profile
   ```

3. **Use Xcode for debugging** instead of Flutter CLI:
   - Open `flutter/ios/Runner.xcworkspace` in Xcode
   - Select your device
   - Click Run (▶️)
   - This uses Xcode's native debugger (more stable)

4. **Enable network debugging** (if using physical device):
   ```bash
   # Check if device is on same network
   flutter devices
   
   # If device shows "network" connection, use:
   flutter run -d <network-device-id>
   ```

5. **Restart iOS device** (sometimes helps with connection issues)

6. **Use simulator instead** (most reliable for debugging):
   ```bash
   # List simulators
   xcrun simctl list devices
   
   # Run on simulator
   flutter run -d <simulator-id>
   ```

### Current Situation
Based on your terminal output:
- ✅ App launched successfully
- ✅ All services initialized (Supabase, deep links, router)
- ⚠️ Debug service connection lost (but app still runs)

**The app is working!** You just can't use hot reload or debugging features.

## Status
✅ Build cleaned - ready to restart
