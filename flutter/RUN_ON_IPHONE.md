# Running CompostKaki on Your iPhone 📱

This guide will walk you through running the Flutter app on your physical iPhone.

## Prerequisites

1. **macOS** (you're on macOS, so ✅)
2. **Xcode** - Download from the Mac App Store (free)
3. **Apple Developer Account** - Free account works for development
4. **Flutter SDK** - Should already be installed
5. **Your iPhone** - Connected via USB cable

## Step-by-Step Instructions

### Step 1: Install/Update Xcode

1. Open the **Mac App Store**
2. Search for "Xcode" and install/update it
3. Open Xcode once to accept the license agreement
4. Install additional components when prompted:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

### Step 2: Install CocoaPods (iOS Dependency Manager)

```bash
sudo gem install cocoapods
```

### Step 3: Get Flutter Dependencies

Navigate to your Flutter project directory:

```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter pub get
```

### Step 4: Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

### Step 5: Set Up Code Signing in Xcode

1. **Open the iOS project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **Important**: Open `.xcworkspace`, NOT `.xcodeproj`

2. **Select the Runner project** in the left sidebar

3. **Select the "Runner" target** (under TARGETS)

4. **Go to "Signing & Capabilities" tab**

5. **Check "Automatically manage signing"**

6. **Select your Team:**
   - If you have an Apple Developer account, select it from the dropdown
   - If you don't have one, click "Add Account..." and sign in with your Apple ID
   - A free Apple ID works for development (no paid developer account needed)

7. **Change the Bundle Identifier** if needed:
   - It should be unique (e.g., `com.yourname.compostkaki`)
   - Xcode will suggest one based on your Apple ID

### Step 6: Connect Your iPhone

1. **Unlock your iPhone**

2. **Connect iPhone to Mac** via USB cable

3. **Trust the computer** on your iPhone:
   - When prompted, tap "Trust This Computer"
   - Enter your iPhone passcode if asked

4. **Enable Developer Mode** on iPhone (iOS 16+):
   - Go to **Settings → Privacy & Security → Developer Mode**
   - Toggle it ON
   - Restart your iPhone when prompted

### Step 7: Verify Device Connection

Check if Flutter detects your iPhone:

```bash
flutter devices
```

You should see your iPhone listed, something like:
```
iPhone (mobile) • 00008030-001A... • ios • iOS 17.0
```

### Step 8: Run the App

**Option A: Using Flutter Command Line (Recommended)**

```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter run
```

Flutter will automatically detect your iPhone and install the app.

**Option B: Using Xcode**

1. In Xcode, select your iPhone from the device dropdown (top toolbar)
2. Click the **Play button** (▶️) or press `Cmd + R`

### Step 9: Trust Developer Certificate (First Time Only)

When you run the app for the first time:

1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Tap on your Apple ID/Developer account
3. Tap **"Trust [Your Name]"**
4. Confirm by tapping **"Trust"**

Now you can open the app on your iPhone!

## Troubleshooting

### Issue: "No devices found"

**Solution:**
```bash
# Check if device is connected
flutter devices

# If not showing, try:
# 1. Unlock your iPhone
# 2. Trust the computer on iPhone
# 3. Restart both devices
```

### Issue: "Code signing error" or "No signing certificate"

**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Go to **Runner → Signing & Capabilities**
3. Make sure "Automatically manage signing" is checked
4. Select your Team from the dropdown
5. If no team appears, click "Add Account..." and sign in with Apple ID

### Issue: "Failed to launch app" or "Unable to install"

**Solution:**
1. Make sure Developer Mode is enabled on iPhone (iOS 16+)
2. Trust the developer certificate (Step 9 above)
3. Check that your iPhone is unlocked
4. Try disconnecting and reconnecting the USB cable

### Issue: "Pod install failed"

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Issue: "Flutter doctor shows iOS issues"

**Solution:**
```bash
flutter doctor -v
```

Fix any issues shown:
- Install Xcode Command Line Tools: `xcode-select --install`
- Accept Xcode license: `sudo xcodebuild -license accept`
- Install CocoaPods: `sudo gem install cocoapods`

### Issue: App crashes immediately after launch

**Solution:**
1. Check the console output in Xcode or terminal
2. Verify Supabase credentials in `lib/main.dart`
3. Make sure your iPhone has internet connection
4. Check Xcode console for specific error messages

## Quick Commands Reference

```bash
# Navigate to project
cd /Users/itzsihui/CompostKaki/flutter

# Get Flutter dependencies
flutter pub get

# Install iOS dependencies
cd ios && pod install && cd ..

# Check connected devices
flutter devices

# Run on iPhone
flutter run

# Clean build (if having issues)
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run

# Open in Xcode
open ios/Runner.xcworkspace
```

## Running Without USB Cable (Wireless Debugging)

Once you've set up the app once via USB, you can enable wireless debugging:

1. **In Xcode:**
   - Window → Devices and Simulators
   - Select your iPhone
   - Check "Connect via network"

2. **On iPhone:**
   - Settings → Developer → Enable "Connect via network"

3. **Disconnect USB** and run:
   ```bash
   flutter run
   ```

## Making Code Changes (After Initial Setup)

Once you've completed the initial setup, here's what you need to do when making code changes:

### For Regular Code Changes (Dart/Flutter code)

**If the app is already running:**
- Just **save your changes** in Cursor/your editor
- The app will **automatically hot-reload** on your iPhone
- Or press `r` in the terminal for manual hot-reload
- Press `R` for hot-restart (if hot-reload doesn't work)

**If the app is not running:**
```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter run
```

### When You Add New Dependencies

If you added new packages to `pubspec.yaml`:
```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter pub get
flutter run
```

If you added iOS-specific native dependencies:
```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### When You Modify Native iOS Code

If you changed files in `ios/` folder (like `Info.plist`, native Swift/Objective-C code):
```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Steps You DON'T Need to Repeat

✅ **You DON'T need to repeat these** (one-time setup):
- Installing Xcode
- Installing CocoaPods
- Setting up code signing (unless you change bundle ID or team)
- Connecting iPhone via USB (unless disconnected)
- Trusting the computer on iPhone
- Enabling Developer Mode
- Trusting developer certificate

### Quick Reference for Daily Development

**Most common workflow:**
1. Make code changes in Cursor
2. Save the file
3. App automatically hot-reloads on iPhone ✨

**If hot-reload doesn't work:**
```bash
# In the terminal where flutter run is active:
R  # Press R for hot-restart
```

**If you need to restart completely:**
```bash
cd /Users/itzsihui/CompostKaki/flutter
flutter run
```

## Next Steps

- The app will hot-reload automatically when you make code changes
- Press `r` in the terminal to hot-reload manually
- Press `R` to hot-restart
- Press `q` to quit

Enjoy testing CompostKaki on your iPhone! 🌱











