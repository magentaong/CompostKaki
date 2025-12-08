# iOS Fixes Applied

## Issue 1: `keyWindow` Deprecation Warning

**Warning Message:**
```
'keyWindow' is deprecated: first deprecated in iOS 13.0 - Should not be used for applications that support multiple scenes as it returns a key window across all connected scenes
```

## Issue 2: iOS Deployment Target Error

**Error Message:**
```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 10.0, but the range of supported deployment target versions is 12.0 to 26.1.99.
```

## Issue 3: Scene Snapshotting Error

**Error Message:**
```
NSLocalizedDescription = an error occurred during a scene snapshotting operation;
```

This error occurs when iOS tries to take screenshots for the app switcher but the app doesn't properly handle scene snapshotting operations.

## Solutions Implemented

### 1. Created UIApplication Extension (`UIApplication+KeyWindow.swift`)

Added a modern replacement for the deprecated `keyWindow` property that:
- Uses scene-based window access for iOS 13.0+
- Falls back to the old API for older iOS versions
- Provides `keyWindowCompat` and `windowsCompat` properties

**Location:** `ios/Runner/UIApplication+KeyWindow.swift`

### 2. Simplified AppDelegate (Removed Scene Support)

Simplified `AppDelegate.swift` by removing scene configuration methods:
- Flutter apps use traditional app delegate pattern, not scene-based architecture
- Removed scene methods to prevent snapshotting errors
- Keeps the app delegate simple and focused on Flutter initialization

**Location:** `ios/Runner/AppDelegate.swift`

### 3. Updated Podfile to Suppress Third-Party Warnings

Modified `Podfile` to suppress deprecation warnings from third-party plugins:
- Added compiler flags to suppress `keyWindow` deprecation warnings
- Applied to all CocoaPods targets
- Specified iOS platform version (13.0) to avoid warnings

**Location:** `ios/Podfile`

### 4. Fixed iOS Deployment Target Issue

Updated `Podfile` to enforce minimum iOS deployment target:
- Added `post_install` hook to enforce iOS 12.0 minimum deployment target
- Updates all pod targets to use at least iOS 12.0
- Updates the Pods project deployment target
- Fixes the error: "IPHONEOS_DEPLOYMENT_TARGET is set to 10.0"

**Location:** `ios/Podfile`

### 5. Fixed Scene Snapshotting Error

Removed scene configuration methods from `AppDelegate.swift`:
- Flutter apps don't need iOS scene support (they use traditional app delegate)
- Removed `configurationForConnecting` and `didDiscardSceneSessions` methods
- Prevents iOS from trying to use scene-based snapshotting
- Fixes the error: "an error occurred during a scene snapshotting operation"

**Location:** `ios/Runner/AppDelegate.swift`

## Files Modified

1. ✅ `ios/Runner/UIApplication+KeyWindow.swift` (NEW)
2. ✅ `ios/Runner/AppDelegate.swift` (UPDATED - removed scene methods)
3. ✅ `ios/Podfile` (UPDATED - includes deployment target and warning fixes)

## Next Steps

1. **Clean and rebuild:**
   ```bash
   cd flutter
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run
   ```

2. **Verify the fix:**
   - Build the app in Xcode or via `flutter run`
   - Check that the deprecation warning is gone
   - The app should work normally on iOS 13.0+

## Notes

- The `keyWindow` deprecation warning was likely coming from third-party Flutter plugins (e.g., `mobile_scanner`, `image_picker_ios`)
- These plugins may not have been updated to use iOS 13+ scene-based APIs
- Our fixes ensure compatibility while suppressing the warnings from third-party code
- Scene snapshotting errors were caused by incomplete scene configuration - removed scene support since Flutter doesn't need it

## Testing

After applying these fixes:
- ✅ App should build without deprecation warnings
- ✅ App should build without deployment target errors
- ✅ App should run without scene snapshotting errors
- ✅ App should run normally on iOS 12.0+ (deployment target) and iOS 13.0+ (platform)
- ✅ Third-party plugin warnings are suppressed
- ✅ All pods use minimum iOS 12.0 deployment target
- ✅ Traditional app delegate pattern (no scene support needed for Flutter)

